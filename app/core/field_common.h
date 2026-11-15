static const float PI3=3.14159265359f;
struct TFParams {
 float outTime,u,sourceDuration,aspect;
 float slices,pixel,span,cycles;
 float cx,cy,angle,turns;
 float build,softness,density,sourceReverse;
 float sourceStart,sourceEnd,outputW,outputH;
 uint family,shape,design,ending;
 uint direction,playback,origin,viewMode;
 uint frames,customMap,waveSources,flags;
#ifdef SHIREN_MAC42
 float shadowStrength,shadowWidth,shadowSoftness,shadowSide;
 float sampleW,sampleH,reserved0,reserved1;
#endif
};
struct Field {
 float a,b,weight,shade;float2 uvA,uvB;
#ifdef SHIREN_MAC42
 float light;
#endif
};
struct Coord {float raw,q,index,coverage;float2 cell,frac;};
/* 将时间折返为往复播放的归一化位置。 */ float bounce3(float x){return 1-abs(2*frac(x*.5f)-1);}
/* 按保持、循环或往复模式约束时间取样。 */ float play3(float x,uint mode){return mode==0 ? clamp(x,0.0f,1.0f):(mode==2 ? frac(x):bounce3(x));}
/* 围绕原点旋转二维几何坐标。 */ float2 rot3(float2 v,float a){return float2(cos(a)*v.x+sin(a)*v.y,-sin(a)*v.x+cos(a)*v.y);}
// Integer hashing keeps cloud contours reproducible across CPU, Metal and D3D12.
/* 用整数散列产生跨后端一致的伪随机值。 */ float hash3(float2 p){uint h=uint(int(p.x))*1597334677u ^ uint(int(p.y))*3812015801u;h^=h>>16;h*=2246822519u;h^=h>>13;h*=3266489917u;h^=h>>16;return float(h & 16777215u)/16777216.0f;}
/* 对网格散列平滑插值，生成连续噪声。 */ float noise3(float2 p){float2 i=floor(p),f=frac(p);f=f*f*(3-2*f);return lerp(lerp(hash3(i),hash3(i+float2(1,0)),f.x),lerp(hash3(i+float2(0,1)),hash3(i+1),f.x),f.y);}
/* 叠加多个频率的噪声生成稳定的分形纹理。 */ float fbm3(float2 p){float v=0,a=.5f;for(int i=0;i<5;i++){v+=a*noise3(p);p=rot3(p*2.03f,.53f)+float2(7.3f,1.7f);a*=.5f;}return v/.96875f;}
/* 显式定义坐标轴角度，避免Metal快速数学在零分母处产生整行或整列伪影。 */ float axisAngle3(float y,float x){
 if(abs(x)+abs(y)<1e-6f)return 0;
 if(abs(y)<1e-6f)return x<0 ? PI3:0;
 if(abs(x)<1e-6f)return y>0 ? PI3*.5f:-PI3*.5f;
 return atan2(y,x);
}
/* 按画面宽高比与目标格数计算网格行列。 */ float2 gridSize3(float n,float2 size){float rows=clamp(round(sqrt(n*size.y/size.x)),1.0f,min(size.y,n));return float2(floor(n/rows),rows);}
#ifdef SHIREN_MAC42
/* 判断条形冻结是否需要亚像素覆盖积分。 */ bool filteredFreeze52(TFParams p){
 if(p.family!=0 || p.customMap!=0 || p.pixel>0 || (p.shape!=0&&p.shape!=1&&p.shape!=2))return false;
 // Full-resolution stripes whose boundaries already align to pixels retain
 // exact single-slice samples, including one slice per output pixel.
 if(p.shape!=2 && p.direction<2 && p.outputW==p.sampleW && p.outputH==p.sampleH){
  float pitch=(p.shape==1 ? p.sampleH:p.sampleW)/max(2.0f,p.slices);
  if(abs(pitch-round(pitch))<1e-6f)return false;
 }
 return true;
}
/* 判断是否属于可使用直条采样的几何。 */ bool isStripe42(TFParams p){
 return p.customMap==0 && p.direction<2 && (p.shape==0||p.shape==1||p.shape==11);
}
/* 确定像素中心所在的直条编号，并统一边界归属。 */ float rasterStripeIndex42(float pixel,float lengthPx,float count){
 // At an exact half-pixel cut, the first pixel of the next slice owns the tie.
 if(max(lengthPx,count)<=32768.0f){
  uint index=(2u*uint(pixel)+1u)*uint(count)/(2u*uint(lengthPx));
  return min(float(index),count-1);
 }
 return min(floor((pixel+.5f)*count/lengthPx),count-1);
}
#endif
Coord coordinate3(float2 uv,TFParams p,float mapValue){
 Coord c;c.cell=0;c.frac=0;c.index=0;c.coverage=1;float q=uv.x;float n=max(2.0f,p.slices);
 float2 dim=float2(p.outputW,p.outputH),v=(uv-float2(p.cx,p.cy))*dim;
 float2 radii=max(float2(p.cx,p.cy),1-float2(p.cx,p.cy))*dim;
 float rmax=max(length(radii),1.0f);float2 outside=max(float2(0),max(-float2(p.cx,p.cy),float2(p.cx,p.cy)-1))*dim;float rmin=length(outside);
 switch(p.shape){
  case 0:q=uv.x;break;
  case 1:q=uv.y;break;
  case 2:case 12:{float a=p.angle*PI3/180;float2 axis=float2(cos(a),sin(a));float lo=min(0.0f,dim.x*axis.x)+min(0.0f,dim.y*axis.y);float span=max(1.0f,abs(dim.x*axis.x)+abs(dim.y*axis.y));q=(dot(uv*dim,axis)-lo)/span;if(p.shape==12)q+=.07f*(2*abs(2*frac(uv.y*6)-1)-1);break;}
  case 3:{float angle=0;switch(p.origin){case 1:angle=axisAngle3(v.y,v.x);break;case 2:angle=axisAngle3(v.x,-v.y);break;case 3:angle=axisAngle3(-v.x,v.y);break;default:angle=axisAngle3(-v.y,-v.x);break;}c.coverage=(angle>=0&&angle<=PI3)?1:0;q=clamp(angle/PI3,0.0f,1.0f);break;}
  case 4:{
   // Mac 旋转起点用角度控制：0度正上方，正角度沿顺时针。
#ifdef SHIREN_MAC_NEXT
   float startAngle=p.angle/360.0f;
#else
   float startAngle=0.0f;
#endif
   float rotationAngle=axisAngle3(v.x,-v.y);
#ifdef SHIREN_MAC_NEXT
   // Metal 快速数学在分母为负零时可能翻转 atan2；显式定义坐标轴与圆心。
   if(abs(v.x)+abs(v.y)<1e-6f)rotationAngle=0;
   else if(abs(v.y)<1e-6f)rotationAngle=v.x>0 ? PI3*.5f:-PI3*.5f;
   else if(abs(v.x)<1e-6f)rotationAngle=v.y<0 ? 0:PI3;
#endif
   q=frac(rotationAngle/(2*PI3)+1-p.turns*p.u-startAngle);break;
  }
  case 5:case 14:q=(length(v)-rmin)/max(1.0f,rmax-rmin);break;
  case 6:case 7:{
   float2 vr=rot3(v,p.angle*PI3/180+p.turns*2*PI3*p.u);
   if(p.shape==6)q=(abs(vr.x)+abs(vr.y))/max(1.0f,radii.x+radii.y);
   else q=max(abs(vr.x)/max(radii.x,1.0f),abs(vr.y)/max(radii.y,1.0f));
   break;
  }
  case 8:case 10:{
   float cells=p.shape==10 ? max(1.0f,ceil(n/2)):n;
   float2 gs=gridSize3(cells,dim);float row=min(floor(uv.y*gs.y),gs.y-1);float extra=cells-gs.x*gs.y;
   float cols=gs.x+(row<extra ? 1:0);float col=min(floor(uv.x*cols),cols-1);
   float index=row*gs.x+min(row,extra)+col;c.cell=float2(col,row);c.frac=frac(float2(uv.x*cols,uv.y*gs.y));
   if(p.shape==10)index=min(n-1,index*2+(c.frac.x+c.frac.y>=1 ? 1:0));
   q=index/max(1.0f,n-1);break;
  }
  case 9:{float a=axisAngle3(v.y,v.x)/(2*PI3)+.5f;float r=length(v)/rmax;q=frac(a+1.5f*r);break;}
  case 11:q=uv.x;break;
  case 13:{float a=axisAngle3(v.y,v.x);q=length(v)/max(1.0f,rmax*(.78f+.22f*cos(5*a)));break;}
 }
 if(p.customMap!=0){q=mapValue;c.coverage=1;}
 q=clamp(q,0.0f,1.0f);
 if(p.direction==1)q=1-q;
 if(p.direction>=2){
  if(p.shape==8||p.shape==10)q=max(abs(uv.x-.5f),abs(uv.y-.5f))*2;
  else q=abs(q-.5f)*2;
  if(p.direction==3)q=1-q;
 }
 c.raw=q;c.index=min(floor(q*n),n-1);
#ifdef SHIREN_MAC_NEXT
 // An analytically exact cut can land a few float ULPs to either side on Metal.
 // Own that tie consistently, including subpixel samples and one-sided shadows.
 float edge=round(q*n);
 if(abs(q*n-edge)<.0001f){c.raw=edge/n;c.index=min(edge,n-1);}
#endif
#ifdef SHIREN_MAC42
 #ifdef SHIREN_MAC_NEXT
 if(isStripe42(p) && p.reserved0<=0){
#else
 if(isStripe42(p) && !(filteredFreeze52(p) && p.reserved0>0)){
#endif
  float lengthPx=p.shape==1 ? p.sampleH:p.sampleW;
  float pixel=floor((p.shape==1 ? uv.y:uv.x)*lengthPx);
  c.index=rasterStripeIndex42(p.direction==1 ? lengthPx-1-pixel:pixel,lengthPx,n);
 }
#endif
 c.q=p.pixel>0 ? q:c.index/(n-1);
 return c;
}
/* 建立只读取单一源时刻的时间场。 */ Field single3(float2 uv,float t){
 Field f;f.a=t;f.b=t;f.weight=0;f.shade=1;f.uvA=uv;f.uvB=uv;
#ifdef SHIREN_MAC42
 f.light=1;
#endif
 return f;
}
#ifdef SHIREN_MAC42
#include "shadow.h"
#include "creative.h"
#else
#define MAC_EDGE(f,phase,span,coverage)
#define MAC_TILED_EDGE(f,phase,span,coverage)
#endif
/* 求解冻结展开阶段、冻结取样和结束后的流动。 */ Field frozen3(float2 uv,Coord c,TFParams p){
 float build=clamp(p.build,.1f,.9f),u=p.u;float held=p.pixel>0 ? c.raw:min(1.0f,(c.index+1)/max(2.0f,p.slices));
#ifdef SHIREN_MAC_NEXT
 // 昼夜分割只重映射冻结片选帧。未冻结底片的 progress 连续播放完整素材，
 // 展开到中央时可同时看到新铺开的夜景切片和仍处于蓝调时段的底片。
 if((p.flags&1024)!=0){float skip=clamp(p.reserved1,0.0f,1.0f);held=held*(1-skip)+(held>.5f ? skip:0.0f);}
#endif
 if(u<build){
  float progress=u/build;float a;
  if(p.pixel>0 || (p.flags&1)!=0){float aa=max(1.0f/max(p.outputW,p.outputH),p.softness*.003f);a=1-smoothstep(progress-aa,progress+aa,c.raw);}
  else a=progress>=c.q ? 1:0;
  Field f=single3(uv,progress);f.b=held;f.weight=a;return f;
 }
 float after=clamp((u-build)/(1-build),0.0f,1.0f);float t=held;
 switch(p.ending){
  case 0:t=held;break;
  case 1:t=clamp(held+after,0.0f,1.0f);break;
  case 2:{float release=c.q*.65f;float dt=max(0.0f,after-release)/max(.05f,1-release);t=clamp(held+dt,0.0f,1.0f);break;}
  case 3:
#ifdef SHIREN_MAC42
   t=after>0 ? play3(held-2*p.cycles*after,p.playback):held;
#else
   t=play3(held+2*p.cycles*after,p.playback);
#endif
   break;
  case 4:t=bounce3(held-2*p.cycles*after);break;
 }
 return single3(uv,t);
}
/* 将相对时间图转换为有方向的源时差。 */ float relative3(Coord c,TFParams p){
 float d=(p.flags&4)!=0 ? (c.raw*255-128)/128:((p.flags&8)!=0 ? (c.raw*65535-32768)/32768:2*c.raw-1);
 if(p.pixel==0){float positive=ceil((p.slices-1)/2),negative=floor((p.slices-1)/2);float bins=max(1.0f,d<0?negative:positive);d=round(d*bins)/bins;}
 return p.span*d;
}
/* 求解基础切片的时间差与流动位置。 */ Field basic3(float2 uv,Coord c,TFParams p){
 float clock=2*p.cycles*p.u,t;
 if(p.customMap!=0){t=play3((p.flags&2)!=0 ? p.u+relative3(c,p):c.q+clock,p.playback);return single3(uv,t);}
 if(p.design==0){t=.2f+.8f*frac(p.cycles*p.u-c.q);}
 else if(p.design==5){t=bounce3(1-clock-p.span*c.q);}
 else if(p.shape==11){float j=c.index;float phase=clock*(int(j)%2==0 ? 1.0f:-1.0f);t=play3(1+phase-p.span*c.q,p.playback);}
 else{t=play3(1+clock-p.span*c.q,p.playback);}
 return single3(uv,t);
}
/* 求解波纹在当前形状与输出时间下的源取样。 */ Field wave3(float2 uv,Coord c,TFParams p){
 float phase=(p.customMap!=0 && (p.flags&2)!=0) ? 2*p.cycles*p.u+relative3(c,p):2*p.cycles*p.u-2*p.density*c.q;
 return single3(uv,play3(phase,p.playback));
}
/* 按创意效果编号生成对应的时间场。 */ Field creative3(float2 uv,Coord c,TFParams p){
 float u=p.u,clock=2*p.cycles*u,n=max(2.0f,p.slices),depth=p.span;
 float2 center=float2(p.cx,p.cy),metric=float2(p.aspect,1),v=(uv-center)*metric;
 Field f=single3(uv,bounce3(clock));
 switch(p.design){
  case 9:{
   float a=axisAngle3(v.x,-v.y)/(2*PI3),r=length(v)/max(length(metric*.5f),.001f);
   float phase=frac(2*a+r*1.5f*depth),band=p.pixel>0 ? phase-p.cycles*u:phase*n;
   if(p.pixel==0)phase=floor(band)/(n-1);
   f.a=f.b=.2f+.8f*frac(p.cycles*u-phase);
   MAC_TILED_EDGE(f,frac(band),min(PI3*length(v)*p.sampleH,p.sampleH)/(p.pixel>0 ? 1.0f:n),1)
   break;
  }
  case 10:{
   float q=clamp(1-abs(uv.x-center.x)*2,0.0f,1.0f),band=q*(n-1);
   if(p.pixel==0)q=floor(band)/(n-1);
   f.a=f.b=bounce3(clock-.8f*depth*q);
   MAC_TILED_EDGE(f,frac(p.pixel>0 ? .8f*depth*q-clock:band),.5f*p.sampleW/(p.pixel>0 ? .8f*depth:n-1),1)
   break;
  }
  case 11:{
   float2 cell=c.cell,local=c.frac;
   float edge=max(.004f,p.softness*.16f);float ah=1-smoothstep(.24f,.24f+edge,abs(local.y-.5f));float av=1-smoothstep(.24f,.24f+edge,abs(local.x-.5f));
   bool over=(int(floor(cell.x)+floor(cell.y))%2)==0;
   float ht=bounce3(clock-uv.x*depth),vt=bounce3(clock+uv.y*depth+1);
   if(ah>0||av>0){f.a=over?vt:ht;f.b=over?ht:vt;f.weight=over?ah:av;if(ah==0)f.a=f.b=vt;if(av==0)f.a=f.b=ht;}
#ifdef SHIREN_MAC42
   if(p.shadowStrength>0 && (ah>0||av>0)){
    bool horizontal=av==0||(ah>0&&over);
    float coverage=horizontal ? ah:av;
    float phase=clamp(((horizontal ? local.y:local.x)-.26f)/.48f,0.0f,1.0f);
    float2 grid=gridSize3(n,float2(p.outputW,p.outputH));
    float cols=grid.x+(cell.y<n-grid.x*grid.y ? 1:0);
    f.light=edgeLight42(phase,.48f*(horizontal ? p.sampleH/grid.y:p.sampleW/cols),coverage,p);
   }
#endif
   break;
  }
  case 12:{
   float sum=0;uint sources=clamp(p.waveSources,2u,4u);
   for(uint i=0;i<sources;i++){
    float a=2*PI3*i/sources;float2 o=center+float2(.18f*cos(a),.18f*sin(a));
    float r=length((uv-o)*metric),band=r*n;
    if(p.pixel==0)r=floor(band)/n;
    sum+=bounce3(clock-r*1.3f*depth);
#ifdef SHIREN_MAC42
    if(p.shadowStrength>0){
     float phase=frac(p.pixel>0 ? r*1.3f*depth-clock:band);
     f.light=min(f.light,tiledLight42(phase,p.sampleH/(p.pixel>0 ? 1.3f*depth:n),1,p));
    }
#endif
   }
   f.a=f.b=sum/sources;break;
  }
  case 13:{
   float2 o=center+float2(.22f*sin(2*PI3*u),.13f*cos(2*PI3*u));
   float2 local=(uv-o)*metric;
   float r=length(local),radius=.17f+.04f*sin(2*PI3*u),edge=max(.002f,p.softness*.16f);
   f.b=bounce3(clock+.8f*depth);f.weight=1-smoothstep(radius-edge,radius+edge,r);
#ifdef SHIREN_MAC42
   if(p.shadowStrength>0 && f.weight>0){
    float halfWidth=sqrt(max(.000001f,radius*radius-local.y*local.y));
    float phase=clamp(.5f+.5f*local.x/halfWidth,0.0f,1.0f);
    f.light=edgeLight42(phase,2*halfWidth*p.sampleH,f.weight,p);
   }
#endif
   break;
  }
  case 400:{
   float tails=max(n,2.0f),gap=.65f/tails;float head=frac(u*p.cycles)*1.65f;
   float d=head-uv.x;float j=floor(d/gap);float local=frac(d/gap);
   if(j>=0&&j<tails){float aa=max(.015f,p.softness*.15f);float a=smoothstep(0.0f,aa,local)*(1-smoothstep(.65f,.65f+aa,local));f.b=clamp(1-j/tails,0.0f,1.0f);f.weight=a*(1-.65f*j/tails);}
   MAC_EDGE(f,clamp(1-local/.65f,0.0f,1.0f),gap*.65f*p.sampleW,f.weight)
   break;
  }
  case 401:{
   float progress=bounce3(2*p.cycles*u);float row=floor(uv.y*n);float tooth=(int(row)%2==0 ? 1.0f:-1.0f)*.025f;
   float gap=.35f*smoothstep(progress-.06f,progress+.06f,uv.y);float seam=center.x+tooth;
   bool outside=abs(uv.x-seam)>gap;
   if(outside)f.a=f.b=uv.x<seam ? .08f:.95f;
   MAC_EDGE(f,clamp((uv.x-seam+gap)/.22f+1,0.0f,1.0f),.22f*p.sampleW,(outside&&uv.x<seam) ? 1.0f:0.0f)
#ifdef SHIREN_MAC42
   if(p.shadowStrength>0 && p.shadowSide>0)
    f.light=edgeLight42(clamp((uv.x-seam-gap)/.22f,0.0f,1.0f),.22f*p.sampleW,(outside&&uv.x>seam) ? 1.0f:0.0f,p);
#endif
   break;
  }
  case 402:{
   float a=axisAngle3(v.y,v.x),r=length(v),petals=n;float shape=.72f+.28f*cos(a*petals);
   float opening=.5f-.5f*cos(2*PI3*u*p.cycles);float radius=.47f*min(p.aspect,1.0f)*opening*shape;float edge=max(.001f,p.softness*.02f);
   float phase=frac((a+PI3)/(2*PI3));float j=floor(phase*petals);
   f.b=bounce3(clock+j/petals*depth);f.weight=1-smoothstep(radius-edge,radius+edge,r);
   MAC_TILED_EDGE(f,frac(phase*petals),2*PI3*r*p.sampleH/petals,f.weight)
   break;
  }
  case 403:{
   float a=axisAngle3(v.y,v.x)+u*PI3,r=length(v),blades=max(3.0f,n),sector=2*PI3/blades;
   float local=frac((a+PI3)/sector)*sector-sector*.5f;
   float aperture=(.025f+.45f*(.5f-.5f*cos(2*PI3*u*p.cycles)))*min(p.aspect,1.0f)*cos(PI3/blades)/max(.001f,cos(local));
   float j=floor(frac((a+PI3)/(2*PI3))*blades);
   f.a=bounce3(clock-depth*j/blades);f.b=bounce3(clock+1);f.weight=1-smoothstep(aperture-.002f,aperture+.002f,r);
   MAC_TILED_EDGE(f,frac((a+PI3)/sector),sector*r*p.sampleH,1-f.weight)
   break;
  }
  case 404:{
   float best=1e9f,bestPhase=0;float head=frac(u*p.cycles);
#ifdef SHIREN_MAC42
   float lateral=0;
#endif
   for(int i=0;i<32;i++){
    float a0=2*PI3*i/32,a1=2*PI3*(i+1)/32;
    float2 a=center+float2(.34f*sin(a0),.22f*sin(2*a0));float2 b=center+float2(.34f*sin(a1),.22f*sin(2*a1));
    float2 segment=(b-a)*metric,point=(uv-a)*metric;float k=clamp(dot(point,segment)/max(dot(segment,segment),1e-7f),0.0f,1.0f);
    float2 delta=point-k*segment;
#ifdef SHIREN_MAC42
    float distance=dot(delta,delta);
#else
    float distance=length(delta);
#endif
    float phase=(i+k)/32;
    float trail=frac(head-phase+1);
    if(trail<.6f && distance<best){
     best=distance;bestPhase=trail;
#ifdef SHIREN_MAC42
     if(p.shadowStrength>0)lateral=dot(delta,float2(segment.y,-segment.x))>=0 ? 1.0f:-1.0f;
#endif
    }
   }
   float edge=max(.002f,p.softness*.04f);
#ifdef SHIREN_MAC42
   best=sqrt(best);
#endif
   f.weight=1-smoothstep(.035f-edge,.035f+edge,best);
   float q=bestPhase/.6f;if(p.pixel==0)q=floor(q*n)/(n-1);f.b=.15f+.85f*q;
   MAC_EDGE(f,clamp(.5f+best*lateral/.07f,0.0f,1.0f),.07f*p.sampleH,f.weight)
   break;
  }
#ifndef SHIREN_MAC42
  case 405:{float k=fbm3(uv*float2(5*p.aspect,5)+float2(u*2,-u));if(p.pixel==0)k=floor(k*n)/(n-1);float threshold=bounce3(clock);float edge=max(.015f,p.softness*.3f);f.a=.08f;f.b=.95f;f.weight=smoothstep(k-edge,k+edge,threshold);break;}
  case 406:{
   float index=floor(uv.x*n),bestZ=-1e9f;bool hit=false;
   for(int j=-1;j<=1;j++){
    float cell=index+j;if(cell<0||cell>=n)continue;float cx=(cell+.5f)/n;float local=(uv.x-cx)*2*n;
    float angle=(.5f-.5f*cos(2*PI3*u))*1.2f*(int(cell)%2==0 ? 1.0f:-1.0f);
    float co=cos(angle),si=sin(angle),perspective=.25f;
    float srcx=local/max(.001f,co+perspective*local*si);
    float srcy=.5f+(uv.y-.5f)*(1-perspective*srcx*si);float z=srcx*si;
    if(abs(srcx)<=1&&srcy>=0&&srcy<=1&&z>=bestZ){hit=true;bestZ=z;f.uvB=float2(cx+srcx/(2*n),srcy);f.b=bounce3(clock-cell/n*depth);f.weight=1;f.shade=.65f+.35f*abs(co);}
   }
   if(!hit)f.weight=0;break;
  }
#endif
 }
 return f;
}
/* 选择当前效果的时间场，并应用统一阴影逻辑。 */ Field evaluate3(float2 uv,TFParams p,float mapValue){
#ifdef SHIREN_MAC42
 if(p.design>=407)return creative42(uv,p);
#endif
 Coord c=coordinate3(uv,p,mapValue);
 if(c.coverage==0){float base=p.family==0 ? play3(p.u/max(.1f,p.build),p.playback):play3((p.family==1?1.0f:0.0f)+2*p.cycles*p.u,p.playback);return single3(uv,base);}
#ifdef SHIREN_MAC42
 if(p.family==3)return creative3(uv,c,p);
 Field f=p.family==0 ? frozen3(uv,c,p):(p.family==1 ? basic3(uv,c,p):wave3(uv,c,p));
 if(p.shadowStrength>0){
  float coverage=(p.family==0&&p.u<clamp(p.build,.1f,.9f)) ? f.weight:1.0f;
  if(coverage>0)f.light=sliceLight42(uv,c,p,coverage);
 }
 return f;
#else
 if(p.family==0)return frozen3(uv,c,p);
 if(p.family==1)return basic3(uv,c,p);
 if(p.family==2)return wave3(uv,c,p);
 return creative3(uv,c,p);
#endif
}
/* 应用源反转与入出点限制，得到实际取样时间。 */ float adjusted3(float n,TFParams p){
 n=clamp(n,0.0f,1.0f);if(p.sourceReverse>0)n=1-n;
 n=lerp(p.sourceStart,p.sourceEnd,n);
 return n;
}

#ifdef SHIREN_MAC42
// Integrate a pixel-sized tent over ideal, equal-width slices. The tent preserves
// subpixel edge positions when a low-resolution preview is enlarged.
struct StripeFootprint52 {
 float first,last,low,high,center,step,count,normalization;
};
/* 计算条形轴向在一个输出像素内的变化量。 */ float2 stripeGradient52(TFParams p){
 if(p.shape==0)return float2(1,0);
 if(p.shape==1)return float2(0,1);
 float a=p.angle*PI3/180;
 float2 axis=float2(cos(a),sin(a)),dim=float2(p.outputW,p.outputH);
 float span=max(1.0f,abs(dim.x*axis.x)+abs(dim.y*axis.y));
 return dim*axis/span;
}
/* 为横竖或斜条建立等距的一维几何坐标。 */ float stripeAxis52(float2 uv,TFParams p){
 float2 gradient=stripeGradient52(p);
 return clamp(dot(uv,gradient)-min(0.0f,gradient.x)-min(0.0f,gradient.y),0.0f,1.0f);
}
/* 计算帐篷核的积分以获得连续的亚像素覆盖。 */ float tentArea52(float x){
 x=clamp(x,-1.0f,1.0f);
 return x<=0 ? .5f*(x+1)*(x+1):1-.5f*(1-x)*(1-x);
}
/* 确定像素覆盖到的理想条形区间和归一化权重。 */ StripeFootprint52 stripeFootprint52(float2 uv,TFParams p){
 StripeFootprint52 f;
 float2 gradient=abs(stripeGradient52(p));
 float pixelStep=gradient.x/p.sampleW+gradient.y/p.sampleH;
 f.count=max(2.0f,p.slices)*(p.direction>=2 ? 2.0f:1.0f);
 f.center=stripeAxis52(uv,p)*f.count;
 f.step=f.count*pixelStep;
 f.low=max(0.0f,f.center-f.step);f.high=min(f.count,f.center+f.step);
 f.first=floor(f.low);f.last=min(f.count-1,ceil(f.high)-1);
 f.normalization=max(1e-8f,tentArea52((f.high-f.center)/f.step)-tentArea52((f.low-f.center)/f.step));
 return f;
}
/* 计算一个像素对当前切片单元的有效覆盖权重。 */ float stripeWeight52(float low,float high,StripeFootprint52 f){
 return max(0.0f,tentArea52((high-f.center)/f.step)-tentArea52((low-f.center)/f.step));
}
// The shadow feather is cubic. Integrating in local coordinates avoids the
// cancellation caused by subtracting nearly equal global antiderivatives.
/* 积分单个帐篷核区间内的阴影覆盖。 */ float shadowTentPart52(float low,float high,bool feathered,float solid,float feather,
                       float mid,float center,float step,float distance,float sign,float slope){
 if(high<=low)return 0;
 float m=(low+high)*.5f,r=(high-low)*.5f;
 float offset=mid-center+sign*(m-distance);
 float w0=max(0.0f,1+slope*offset/step)/step;
 if(!feathered)return 2*r*w0;
 float t=clamp((m-solid)/feather,0.0f,1.0f);
 float h0=1-t*t*(3-2*t);
 float h1=6*t*(t-1)/feather;
 float h2=(6*t-3)/(feather*feather);
 float h3=2/(feather*feather*feather);
 float w1=slope*sign/(step*step),r2=r*r;
 return max(0.0f,2*r*(w0*h0+(w0*h2+w1*h1)*r2/3+w1*h3*r2*r2/5));
}
/* 组合帐篷核单侧覆盖的阴影贡献。 */ float shadowTentSide52(float low,float high,float mid,float center,float step,
                      float distance,float sign,float slope,TFParams p){
 if(high<=low)return 0;
 float a=distance+sign*(low-mid),b=distance+sign*(high-mid);
 float lo=clamp(min(a,b),0.0f,1.0f),hi=clamp(max(a,b),0.0f,1.0f);
 float width=clamp(p.shadowWidth,.02f,.75f);
 float feather=width*max(.025f,p.shadowSoftness),solid=width-feather;
 return shadowTentPart52(lo,min(hi,solid),false,solid,feather,mid,center,step,distance,sign,slope)+
        shadowTentPart52(max(lo,solid),min(hi,width),true,solid,feather,mid,center,step,distance,sign,slope);
}
/* 为覆盖区间求解切片取样与阴影积分。 */ Field stripeSample52(float2 uv,TFParams p,StripeFootprint52 footprint,float low,float high,float weight){
 float mid=(low+high)*.5f,axis=mid/footprint.count;
 float2 gradient=stripeGradient52(p);
 uv=uv+gradient*((axis-stripeAxis52(uv,p))/max(1e-8f,dot(gradient,gradient)));
 // reserved0 is only an internal sampling marker, never a stored setting.
 p.reserved0=1;
 Field f=evaluate3(uv,p,0);
 if(p.shadowStrength<=0)return f;
 Coord c=coordinate3(uv,p,0);
 float phase=clamp(c.raw*max(2.0f,p.slices)-c.index,0.0f,1.0f);
 float sign=p.direction==1 ? -1.0f:1.0f;
 if(p.direction>=2)sign=(axis<.5f ? -1.0f:1.0f)*(p.direction==3 ? -1.0f:1.0f);
#ifdef SHIREN_MAC_NEXT
 // Shadow side follows geometry, independently of reveal/playback direction.
 if(sign<0)phase=1-phase;
 sign=1;
#endif
 float distance=p.shadowSide>0 ? phase:1-phase;
 if(p.shadowSide==0)sign=-sign;
 float mass=shadowTentSide52(low,min(high,footprint.center),mid,footprint.center,footprint.step,distance,sign,1,p)+
            shadowTentSide52(max(low,footprint.center),high,mid,footprint.center,footprint.step,distance,sign,-1,p);
 gradient=abs(gradient);
 float outputLength=1/max(1e-8f,gradient.x/p.outputW+gradient.y/p.outputH);
 float fade=smoothstep(1.0f,2.5f,outputLength/footprint.count);
 float coverage=p.u<clamp(p.build,.1f,.9f) ? f.weight:1.0f;
 f.light=1-p.shadowStrength*coverage*fade*clamp(mass/max(weight,1e-8f),0.0f,1.0f);
 return f;
}
#endif
