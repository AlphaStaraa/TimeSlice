// Integral of the inner shadow's cubic feather, measured from the dark edge.
/* 对单侧阴影的渐隐函数作解析积分。 */ float shadowArea42(float distance,float solid,float feather){
 float d=max(0.0f,distance);
 float t=clamp((d-solid)/feather,0.0f,1.0f);
 return min(d,solid)+feather*t*(1-t*t*(1-.5f*t));
}

/* 将阴影积分扩展到重复的切片边界。 */ float repeatedShadowArea42(float distance,float solid,float feather){
 return floor(distance)*(solid+.5f*feather)+shadowArea42(frac(distance),solid,feather);
}

/* 按像素覆盖过滤单侧阴影，减轻锯齿与浓淡跳变。 */ float filteredLight42(float distance,float span,float coverage,float filterWidth,bool repeat,TFParams p){
 if(span<=1 || coverage<=0)return 1;
 float width=min(.78f,max(p.shadowWidth,1.5f/span));
  float halfPixel=.5f*filterWidth/span;
 if(distance>width+halfPixel && (!repeat || distance<1-halfPixel))return 1;
 float feather=width*max(.025f,p.shadowSoftness),solid=width-feather;
 float lo=distance-halfPixel,hi=distance+halfPixel;
 float area=repeat ? repeatedShadowArea42(hi,solid,feather)-repeatedShadowArea42(lo,solid,feather):
                     shadowArea42(hi,solid,feather)-shadowArea42(lo,solid,feather);
 float dark=clamp(area/(2*halfPixel),0.0f,1.0f)*smoothstep(1.0f,2.5f,span);
 return 1-p.shadowStrength*coverage*dark;
}

/* 根据选定边位返回单侧渐隐的遮光系数。 */ float edgeLight42(float phase,float span,float coverage,TFParams p){
 return filteredLight42(p.shadowSide>0 ? phase:1-phase,span,coverage,1.0f,false,p);
}

/* 对重复切片边界计算连续阴影遮光。 */ float tiledLight42(float phase,float span,float coverage,TFParams p){
 // An oblique edge crosses both axes of a square pixel.
 return filteredLight42(p.shadowSide>0 ? phase:1-phase,span,coverage,1.3f,true,p);
}

/* 把直条边界映射到一致的栅格坐标。 */ float stripeBorder42(float cut,float lengthPx,float count){
 if(max(lengthPx,count)<=32768.0f){
  uint n=uint(count), numerator=2u*uint(cut)*uint(lengthPx);
  return numerator<=n ? 0.0f:float((numerator+n-1u)/(2u*n));
 }
 return clamp(ceil(cut*lengthPx/count-.5f),0.0f,lengthPx);
}

/* 在直条像素中心计算阴影，保持逐像素取样稳定。 */ float stripeLight42(float axis,float index,float lengthPx,float count,bool reverse,float coverage,TFParams p){
 float span=lengthPx/count;
 if(span<=1)return 1;
 bool leading=p.shadowSide>0;
 float cut=index+(leading ? 0.0f:1.0f);
 float edge=stripeBorder42(cut,lengthPx,count);
 float center=floor(axis*lengthPx)+.5f;
 if(reverse)center=lengthPx-center;
 float distance=max(.5f,leading ? center-edge:edge-center);
 return filteredLight42(distance/span,span,coverage,1.0f,false,p);
}

#define MAC_EDGE(f,phase,span,coverage) \
 if(p.shadowStrength>0){f.light=edgeLight42(phase,span,coverage,p);}
#define MAC_TILED_EDGE(f,phase,span,coverage) \
 if(p.shadowStrength>0){f.light=tiledLight42(phase,span,coverage,p);}

/* 估计当前几何方向的像素跨度以统一阴影尺度。 */ float coordSpan42(float2 uv,TFParams p){
 float2 size=float2(p.sampleW,p.sampleH);
 float2 v=(uv-float2(p.cx,p.cy))*size;
 float2 radii=max(float2(p.cx,p.cy),1-float2(p.cx,p.cy))*size;
 if(p.customMap!=0)return min(size.x,size.y);
 switch(p.shape){
  case 1:return size.y;
  case 2:case 12:{
   float a=p.angle*PI3/180;
   return size.x*abs(cos(a))+size.y*abs(sin(a));
  }
  case 3:return PI3*length(v);
  case 4:return 2*PI3*length(v);
  case 5:case 14:{
   float2 outside=max(float2(0),max(-float2(p.cx,p.cy),float2(p.cx,p.cy)-1))*size;
   return length(radii)-length(outside);
  }
  case 6:return (radii.x+radii.y)*.707107f;
  case 7:return min(radii.x,radii.y);
  case 9:return min(2*PI3*length(v),length(radii)/1.5f);
  case 13:return length(radii)*.56f;
  default:return size.x;
 }
}

#ifdef SHIREN_MAC_NEXT
/* 以冻结几何固定单侧阴影，不随播放方向翻转。 */ float frozenShadow53(float2 uv,TFParams p,float coverage){
 TFParams geometry=p;geometry.direction=0;
 if(p.direction>=2 && p.shape!=8 && p.shape!=10)geometry.slices*=2;
 Coord c=coordinate3(uv,geometry,0);
 float n=max(2.0f,geometry.slices);
 if(p.shape==8||p.shape==10){
  float cells=p.shape==10 ? ceil(n/2):n;
  float2 grid=gridSize3(cells,float2(p.outputW,p.outputH));
  float cols=grid.x+(c.cell.y<cells-grid.x*grid.y ? 1:0);
  float phase=c.frac.x,span=p.sampleW/cols;
  if(p.shape==10){
   float cut=1-c.frac.y;bool first=phase<cut;
   span*=first ? cut:1-cut;
   phase=first ? phase/max(cut,1e-6f):(phase-cut)/max(1-cut,1e-6f);
  }
  return filteredLight42(p.shadowSide>0 ? phase:1-phase,span,coverage,1,false,p);
 }
 float phase=clamp(c.raw*n-c.index,0.0f,1.0f);
 float span=coordSpan42(uv,geometry)/n;
 return filteredLight42(p.shadowSide>0 ? phase:1-phase,span,coverage,1,false,p);
}
#endif
/* 按形状和取样方式选择统一的阴影计算。 */ float sliceLight42(float2 uv,Coord c,TFParams p,float coverage){
#ifdef SHIREN_MAC_NEXT
 if(p.family==0 && p.customMap==0)return frozenShadow53(uv,p,coverage);
#endif
 float n=max(2.0f,p.slices);
 if((p.shape==8||p.shape==10) && p.customMap==0 && p.direction<2){
  float cells=p.shape==10 ? ceil(n/2):n;
  float2 dim=float2(p.outputW,p.outputH),grid=gridSize3(cells,dim);
  float cols=grid.x+(c.cell.y<cells-grid.x*grid.y ? 1:0);
  float x=c.frac.x;
  float span=p.sampleW/cols;
  if(p.shape==10){
   float cut=1-c.frac.y;
   bool first=x<cut;
   span*=first ? cut:1-cut;
   x=first ? x/max(cut,1e-6f):(x-cut)/max(1-cut,1e-6f);
  }
  float phase=p.direction==1 ? 1-x:x;
  return p.shape==8 ? tiledLight42(phase,span,coverage,p):edgeLight42(phase,span,coverage,p);
 }
 float span=coordSpan42(uv,p);
 if(p.direction>=2)span*=.5f;
 if(p.pixel>0 && p.family==2){
  float slope=max(.01f,(p.customMap!=0 && (p.flags&2)!=0) ? 2*p.span:2*p.density);
  float phase=frac(slope*c.raw-2*p.cycles*p.u);
  return tiledLight42(phase,span/slope,coverage,p);
 }
 if(isStripe42(p))
  return stripeLight42(p.shape==1 ? uv.y:uv.x,c.index,span,n,p.direction==1,coverage,p);
 return tiledLight42(clamp(c.raw*n-c.index,0.0f,1.0f),span/n,coverage,p);
}
