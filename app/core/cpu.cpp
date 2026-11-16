#include "cpu_math.h"
#include "field_common.h"
#include "quantization.h"
#ifdef _WIN32
#define API extern "C" __declspec(dllexport)
#else
#define API extern "C" __attribute__((visibility("default")))
#endif
#ifdef SHIREN_MAC_NEXT
bool needsAA53(float2 uv,TFParams p,float mapValue);
#endif
// Each call owns an independent row block; ctypes releases the GIL for multicore calls.
/* 批量输出时间场诊断值，供渲染和一致性检查使用。 */ API void fields(const TFParams* params,int w,int h,int y0,int rows,const float* map,float* out){
 const TFParams p=*params;
 for(int y=y0;y<y0+rows;y++)for(int x=0;x<w;x++){
  float2 uv((x+.5f)/w,(y+.5f)/h);Field f=evaluate3(uv,p,map?map[y*w+x]:0);
  float* d=out+((y-y0)*w+x)*8;
  d[0]=adjusted3(f.a,p);d[1]=adjusted3(f.b,p);d[2]=clamp(f.weight,0.f,1.f);d[3]=f.shade;
#ifdef SHIREN_MAC_NEXT
  if((p.flags&256)!=0)d[3]=f.light;
  if((p.flags&512)!=0)d[3]=needsAA53(uv,p,map?map[y*w+x]:0)?1:0;
#endif
  d[4]=f.uvA.x;d[5]=f.uvA.y;d[6]=f.uvB.x;d[7]=f.uvB.y;
 }
}
/* 返回原生参数结构的字节数，核对跨语言布局。 */ API int params_size(){return sizeof(TFParams);}
#ifdef SHIREN_MAC42
/* 对固定空间像素做时间插值，保留原画面锐度。 */ static void rgb_at_pixel(const uint8_t* src,int w,int h,int frames,float duration,float n,int x,int y,float* color){
 float at=clamp(n*duration,0.f,float(frames-1));
 int lo=int(at),hi=std::min(lo+1,frames-1);
 const uint8_t* a=src+((uint64_t(lo)*h+y)*w+x)*4;
 const uint8_t* b=src+((uint64_t(hi)*h+y)*w+x)*4;
 for(int c=0;c<3;c++)color[c]=lerp(float(a[c]),float(b[c]),at-lo);
}
#else
/* 按时间及空间坐标插值读取一个颜色通道。 */ static float channel(const uint8_t* src,int w,int h,int frames,float duration,float n,float2 uv,int c){
 float at=clamp(n*(duration>0?duration:frames),0.f,float(frames-1));int lo=int(at),hi=min(float(frames-1),float(lo+1));float ta=at-lo;
 float xx=clamp(uv.x*w-.5f,0.f,float(w-1)),yy=clamp(uv.y*h-.5f,0.f,float(h-1));int x=int(xx),y=int(yy),x1=std::min(x+1,w-1),y1=std::min(y+1,h-1);float fx=xx-x,fy=yy-y;
 auto v=[&](int t,int a,int b){return float(src[((uint64_t(t)*h+b)*w+a)*4+c]);};
 auto bilinear=[&](int t){return lerp(lerp(v(t,x,y),v(t,x1,y),fx),lerp(v(t,x,y1),v(t,x1,y1),fx),fy);};
 return lerp(bilinear(lo),bilinear(hi),ta);
}
#endif
#ifdef SHIREN_MAC42
/* 积分条形覆盖及阴影后读取相应的源画面颜色。 */ static void filtered_stripe_rgb52(const TFParams& p,float2 uv,const uint8_t* source,int w,int h,int x,int y,float* color){
 StripeFootprint52 footprint=stripeFootprint52(uv,p);
 color[0]=color[1]=color[2]=0;
 for(int cell=int(footprint.first);cell<=int(footprint.last);cell++){
  float low=max(footprint.low,float(cell)),high=min(footprint.high,float(cell+1));
  float weight=stripeWeight52(low,high,footprint);
  if(weight<=1e-8f)continue;
  Field f=stripeSample52(uv,p,footprint,low,high,weight);
  float sample[3],blend=clamp(f.weight,0.f,1.f);
  if(p.viewMode==2){
   float t=adjusted3(lerp(clamp(f.a,0.f,1.f),clamp(f.b,0.f,1.f),blend),p)*255;
   sample[0]=sample[1]=sample[2]=t;
  }else{
   rgb_at_pixel(source,w,h,p.frames,p.sourceDuration,adjusted3(blend==1 ? f.b:f.a,p),x,y,sample);
   if(blend==1){for(float& c:sample)c*=f.shade;}
   else if(blend>0){
    float b[3];rgb_at_pixel(source,w,h,p.frames,p.sourceDuration,adjusted3(f.b,p),x,y,b);
    for(int c=0;c<3;c++)sample[c]=lerp(sample[c],b[c]*f.shade,blend);
   }
   for(float& c:sample)c*=f.light;
  }
  for(int c=0;c<3;c++)color[c]+=sample[c]*weight/footprint.normalization;
 }
}
#endif
#ifdef SHIREN_MAC_NEXT
#include "antialias.h"
#define SHIREN_GRADE_CPU 1
#define GRADE(i) gradedata[int(i)]
#include "grade.h"
#undef GRADE
/* 对轻量源纹理做双线性与时间插值，并按源时刻调色。 */ static Color53 source53(const uint8_t* src,int sw,int sh,int frames,float duration,float n,float2 uv,const float* grade){
 float at=clamp(n*duration,0.f,float(frames-1));int a=int(at),b=std::min(a+1,frames-1);
 float xx=clamp(uv.x*sw-.5f,0.f,float(sw-1)),yy=clamp(uv.y*sh-.5f,0.f,float(sh-1));
 int x=int(xx),y=int(yy),x1=std::min(x+1,sw-1),y1=std::min(y+1,sh-1);float fx=xx-x,fy=yy-y;
 auto frame=[&](int i){
  float c[3];for(int k=0;k<3;k++){
   auto v=[&](int x,int y){return src[((uint64_t(i)*sh+y)*sw+x)*4+k]/255.f;};
   c[k]=lerp(lerp(v(x,y),v(x1,y),fx),lerp(v(x,y1),v(x1,y1),fx),fy);
  }
  Color53 out=color53(c[0],c[1],c[2]);return grade ? grade53(out,i,grade):out;
 };
 Color53 ca=frame(a),cb=frame(b);return color53(lerp(ca.r,cb.r,at-a),lerp(ca.g,cb.g,at-a),lerp(ca.b,cb.b,at-a));
}
/* 按时间场混合源帧，再应用切片遮光与阴影。 */ static Color53 fieldColor53(Field f,TFParams p,const uint8_t* src,int sw,int sh,float2 uv,const float* grade){
 float t=clamp(f.weight,0.f,1.f);
 if(p.viewMode==2){float v=adjusted3(lerp(clamp(f.a,0.f,1.f),clamp(f.b,0.f,1.f),t),p);return color53(v,v,v);}
 Color53 a=source53(src,sw,sh,p.frames,p.sourceDuration,adjusted3(t==1?f.b:f.a,p),uv,grade);
 if(t==1){a.r*=f.shade;a.g*=f.shade;a.b*=f.shade;}
 else if(t>0){Color53 b=source53(src,sw,sh,p.frames,p.sourceDuration,adjusted3(f.b,p),uv,grade);a=color53(lerp(a.r,b.r*f.shade,t),lerp(a.g,b.g*f.shade,t),lerp(a.b,b.b*f.shade,t));}
 return color53(a.r*f.light,a.g*f.light,a.b*f.light);
}
/* 为一个输出像素选择解析覆盖或边缘面积采样路径。 */ static Color53 pixel53(TFParams p,float2 uv,const uint8_t* src,int sw,int sh,float map,const float* grade){
 if(p.viewMode==1)return source53(src,sw,sh,p.frames,p.sourceDuration,adjusted3((p.flags&1024)!=0 ? p.u/max(.1f,p.build):p.u,p),uv,grade);
 Color53 result=color53(0,0,0);
 if(filteredFreeze52(p)){
  StripeFootprint52 foot=stripeFootprint52(uv,p);
  for(int cell=int(foot.first);cell<=int(foot.last);cell++){
   float low=max(foot.low,float(cell)),high=min(foot.high,float(cell+1)),weight=stripeWeight52(low,high,foot);
   if(weight<=1e-8f)continue;Field f=stripeSample52(uv,p,foot,low,high,weight);
   Color53 c=fieldColor53(f,p,src,sw,sh,uv,grade);float w=weight/foot.normalization;result.r+=c.r*w;result.g+=c.g*w;result.b+=c.b*w;
  }
  return result;
 }
 if(!needsAA53(uv,p,map))return fieldColor53(evaluate3(uv,p,map),p,src,sw,sh,uv,grade);
 TFParams q=p;q.reserved0=.25f;
 for(int y=0;y<4;y++)for(int x=0;x<4;x++){
  float2 point=uv+float2((x+.5f)/4-.5f,(y+.5f)/4-.5f)/float2(p.sampleW,p.sampleH);
  Color53 c=fieldColor53(evaluate3(point,q,map),p,src,sw,sh,uv,grade);result.r+=c.r/16;result.g+=c.g/16;result.b+=c.b/16;
 }
 return result;
}
/* 按目标视口绘制几何，并允许源纹理与输出尺寸不同。 */ API void render_preview(const TFParams* params,int w,int h,int y0,int rows,const float* map,const uint8_t* source,int sw,int sh,const float* grade,uint8_t* out){
 TFParams p=*params;
 for(int y=y0;y<y0+rows;y++)for(int x=0;x<w;x++){
  Color53 c=pixel53(p,float2((x+.5f)/w,(y+.5f)/h),source,sw,sh,map?map[y*w+x]:0,grade);
  uint8_t* d=out+((y-y0)*w+x)*4;d[0]=uint8_t(quantizeColor105(c.r,x,y,p.flags));d[1]=uint8_t(quantizeColor105(c.g,x,y,p.flags));d[2]=uint8_t(quantizeColor105(c.b,x,y,p.flags));d[3]=255;
 }
}
#endif
/* 通过多线程行块合成 CPU 输出画面。 */ API void render_cpu(const TFParams* params,int w,int h,int y0,int rows,const float* map,const uint8_t* source,uint8_t* out){
#ifdef SHIREN_MAC_NEXT
 render_preview(params,w,h,y0,rows,map,source,w,h,nullptr,out);return;
#endif
 const TFParams p=*params;
 for(int y=y0;y<y0+rows;y++)for(int x=0;x<w;x++){
  float2 uv((x+.5f)/w,(y+.5f)/h);
  Field f=p.viewMode==1 ? single3(uv,p.u):evaluate3(uv,p,map?map[y*w+x]:0);
  uint8_t* d=out+((y-y0)*w+x)*4;
#ifdef SHIREN_MAC42
  if(filteredFreeze52(p) && p.viewMode!=1){
   float color[3];filtered_stripe_rgb52(p,uv,source,w,h,x,y,color);
   for(int c=0;c<3;c++)d[c]=uint8_t(round(clamp(color[c],0.f,255.f)));
   d[3]=255;continue;
  }
#endif
  if(p.viewMode==2){float v=adjusted3(lerp(clamp(f.a,0.f,1.f),clamp(f.b,0.f,1.f),clamp(f.weight,0.f,1.f)),p);d[0]=d[1]=d[2]=uint8_t(round(clamp(v,0.f,1.f)*255));}
#ifdef SHIREN_MAC42
  else{
   float color[3],weight=clamp(f.weight,0.f,1.f);
   float t=adjusted3(weight==1 ? f.b:f.a,p);
   rgb_at_pixel(source,w,h,p.frames,p.sourceDuration,t,x,y,color);
   if(weight==1){
    for(float& c:color)c*=f.shade;
   }else if(weight>0){
    float b[3];
    rgb_at_pixel(source,w,h,p.frames,p.sourceDuration,adjusted3(f.b,p),x,y,b);
    for(int c=0;c<3;c++)color[c]=lerp(color[c],b[c]*f.shade,weight);
   }
   for(int c=0;c<3;c++)d[c]=uint8_t(round(clamp(color[c]*f.light,0.f,255.f)));
  }
#else
  else for(int c=0;c<3;c++){
   float a=channel(source,w,h,p.frames,p.sourceDuration,adjusted3(f.a,p),f.uvA,c),b=channel(source,w,h,p.frames,p.sourceDuration,adjusted3(f.b,p),f.uvB,c)*f.shade;
   d[c]=uint8_t(round(clamp(lerp(a,b,clamp(f.weight,0.f,1.f)),0.f,255.f)));
  }
#endif
  d[3]=255;
 }
}
struct Layer {float time,active,rotation,scale,posX,posY,anchorX,anchorY;};
/* 把遮罩局部坐标映射到当前图层并计算透明度。 */ static float alpha_at(const uint8_t* m,int mw,int mh,float2 uv,Layer l,float2 dim){
 float2 point=rot3((uv-float2(l.posX,l.posY))*dim,l.rotation*PI3/180.f)/max(l.scale,.0001f);
 float xx=point.x+l.anchorX*mw-.5f,yy=point.y+l.anchorY*mh-.5f;
 int x=int(floor(xx)),y=int(floor(yy));float fx=xx-x,fy=yy-y;
 auto at=[&](int a,int b){return a<0||b<0||a>=mw||b>=mh?0.f:m[b*mw+a]/255.f;};
 return lerp(lerp(at(x,y),at(x+1,y),fx),lerp(at(x,y+1),at(x+1,y+1),fx),fy)*l.active;
}
/* 复现原 PR 图层时间与遮罩，作为旧流程对照。 */ API void reference_cpu(const Layer* ls,const uint8_t* src,int w,int h,int frames,int y0,int rows,const uint8_t* mask,uint8_t* out,const void* options,int mw,int mh,float base,float kindf,float timeScale){
 bool gray=kindf>=100;int kind=int(kindf)%100;float aspect=float(w)/h;float2 dim=aspect>=1?float2(3840,3840/aspect):float2(3840*aspect,3840);
#ifdef SHIREN_MAC42
 const auto* shadow=gray ? nullptr:static_cast<const TFParams*>(options);
 auto light=[&](float phase,float span){return shadow ? edgeLight42(phase,span,1,*shadow):1.f;};
#endif
 for(int y=y0;y<y0+rows;y++)for(int x=0;x<w;x++){
  float2 uv((x+.5f)/w,(y+.5f)/h);float color[3]={0,0,0};
#ifdef SHIREN_MAC42
  auto sample=[&](float t,float* rgb){
   if(gray)rgb[0]=rgb[1]=rgb[2]=clamp(t,0.f,1.f)*255;
   else rgb_at_pixel(src,w,h,frames,timeScale,t,x,y,rgb);
  };
  auto assign=[&](float t,float shade=1.f){sample(t,color);for(float& c:color)c*=shade;};
  auto overlay=[&](int i,float shade=1.f){
   float alpha=alpha_at(mask,mw,mh,uv,ls[i],dim);
   if(alpha<=0)return;
   float rgb[3];sample(ls[i].time,rgb);
   for(int c=0;c<3;c++)color[c]=lerp(color[c],rgb[c]*shade,alpha);
  };
  if(kind==4){
   int index=int(rasterStripeIndex42(float(x),float(w),100.f));
   assign(ls[index].time,shadow ? stripeLight42(uv.x,float(index),float(w),100.f,false,1,*shadow):1.f);
  }
  else if(kind==1){
   float2 p=(uv-.5f)*dim;
   float angle=atan2(p.x,-p.y)*180/PI3;
   if(angle<0)angle+=360;
   float band=angle/1.5f,radius=length(p);
   int k=int(floor(band));
   float span=radius*(1.5f*PI3/180)*w/dim.x;
   bool pivot=radius<8;
   assign(ls[0].time,k==0 ? light(frac(band),span):1.f);
   for(int j=pivot?1:std::max(1,k-1);j<=(pivot?239:std::min(239,k+1));j++)
    overlay(j,light(clamp(band-j,0.f,1.f),span));
   if(k==0&&!pivot)overlay(239,light(1,span));
  }else if(kind==2){
   assign(base);
   float2 p=(uv-float2(.5f,1))*dim;
   float band=atan2(-p.y,-p.x)*60/PI3,radius=length(p);
   int k=int(floor(band));bool pivot=radius<240;
   float span=radius*(PI3/60)*w/dim.x;
   for(int j=pivot?0:std::max(0,k-1);j<=(pivot?60:std::min(60,k+1));j++)
    overlay(j,light(clamp(band-j,0.f,1.f),span));
  }else{
   float2 p=rot3((uv-.5f)*dim,ls[0].rotation*PI3/180.f);
   float radius=abs(p.x)/(mw*.5f)+abs(p.y)/(mh*.5f);
   int k=int(clamp(floor((ls[0].scale-radius)/.02f),0.f,100.f));
   float span=.01f*min(float(mw),float(mh))*.707107f*w/dim.x;
   for(int j=std::max(0,k-2);j<=std::min(100,k+2);j++)
    overlay(j,light(1-clamp((ls[j].scale-radius)/.02f,0.f,1.f),span));
  }
#else
  auto assign=[&](float t){for(int c=0;c<3;c++)color[c]=gray?clamp(t,0.f,1.f)*255:channel(src,w,h,frames,timeScale,t,uv,c);};
  auto overlay=[&](int i){float alpha=alpha_at(mask,mw,mh,uv,ls[i],dim);if(alpha>0)for(int c=0;c<3;c++)color[c]=lerp(color[c],gray?clamp(ls[i].time,0.f,1.f)*255:channel(src,w,h,frames,timeScale,ls[i].time,uv,c),alpha);};
  if(kind==4)assign(ls[std::min(int(uv.x*100),99)].time);
  else if(kind==1){
   float2 p=(uv-.5f)*dim;float angle=atan2(p.x,-p.y)*180/PI3;if(angle<0)angle+=360;int k=int(floor(angle/1.5f));assign(ls[0].time);bool pivot=length(p)<8;
   for(int j=pivot?1:std::max(1,k-1);j<=(pivot?239:std::min(239,k+1));j++)overlay(j);
   if(k==0&&!pivot)overlay(239);
  }else if(kind==2){
   assign(base);float2 p=(uv-float2(.5f,1))*dim;float a=atan2(-p.y,-p.x)*180/PI3;int k=int(floor(a/3));bool pivot=length(p)<240;
   for(int j=pivot?0:std::max(0,k-1);j<=(pivot?60:std::min(60,k+1));j++)overlay(j);
  }else{
   float2 p=rot3((uv-.5f)*dim,ls[0].rotation*PI3/180.f);float radius=abs(p.x)/(mw*.5f)+abs(p.y)/(mh*.5f);int k=int(clamp(floor((ls[0].scale-radius)/.02f),0.f,100.f));
   for(int j=std::max(0,k-2);j<=std::min(100,k+2);j++)overlay(j);
  }
#endif
  auto d=out+((y-y0)*w+x)*4;for(int c=0;c<3;c++)d[c]=uint8_t(round(clamp(color[c],0.f,255.f)));d[3]=255;
 }
}
