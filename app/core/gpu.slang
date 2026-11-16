#define atan2 atan2
#include "field_common.h"
#include "quantization.h"
[[vk::binding(0,0)]] ConstantBuffer<TFParams> param;
// tile x/y/width/height; full W/H, source frames, first output frame;
// batch length, output frame count, mode, reserved
[[vk::binding(1,0)]] StructuredBuffer<uint> cfg;
[[vk::binding(2,0)]] StructuredBuffer<uint> source;
[[vk::binding(3,0)]] StructuredBuffer<float> timeMap;
[[vk::binding(4,0)]] RWStructuredBuffer<uint> output;
/* 把紧凑整数像素解码为归一化 RGBA 颜色。 */ float4 unpack(uint v){return float4(v&255,(v>>8)&255,(v>>16)&255,(v>>24)&255)/255.0f;}
/* 把归一化颜色夹到有效范围并编码为整数像素。 */ uint pack(float4 c){uint4 v=uint4(round(clamp(c,0.0f,1.0f)*255));return v.x|(v.y<<8)|(v.z<<16)|(255u<<24);}
#ifdef SHIREN_MAC_NEXT
[[vk::binding(6,0)]] StructuredBuffer<float> gradeData;
#define GRADE(i) gradeData[int(i)]
#include "grade.h"
#undef GRADE
#include "antialias.h"
/* 读取源帧并应用可选的空间缩放与实时调色。 */ float4 sourceFrame53(uint frame,uint pixel,TFParams p){
 float4 c;
 if((p.flags&64)!=0){
  uint x=pixel%cfg[2]+cfg[0],y=pixel/cfg[2]+cfg[1];
  float2 point=clamp((float2(x,y)+.5f)/float2(cfg[4],cfg[5])*float2(cfg[10],cfg[11])-.5f,0.0f,float2(cfg[10]-1,cfg[11]-1));
  uint2 lo=uint2(floor(point)),hi=min(lo+1,uint2(cfg[10]-1,cfg[11]-1));float2 t=frac(point);
  uint base=frame*cfg[14]*cfg[15];
  uint xa=lo.x-cfg[12],xb=hi.x-cfg[12],ya=lo.y-cfg[13],yb=hi.y-cfg[13];
  c=lerp(lerp(unpack(source[base+ya*cfg[14]+xa]),unpack(source[base+ya*cfg[14]+xb]),t.x),lerp(unpack(source[base+yb*cfg[14]+xa]),unpack(source[base+yb*cfg[14]+xb]),t.x),t.y);
 }else c=unpack(source[frame*cfg[2]*cfg[3]+pixel]);
 if((p.flags&128)!=0){Color53 rgb=grade53(color53(c.r,c.g,c.b),int(frame));c=float4(rgb.r,rgb.g,rgb.b,1);}
 return c;
}
#endif
/* 在当前源时间读取两个相邻帧并插值。 */ float4 sampleSource(float n,uint pixel,TFParams p){
 n=adjusted3(n,p);float f=clamp(n*p.sourceDuration,0.f,float(cfg[6]-1));
 uint a=uint(floor(f)),b=min(a+1,cfg[6]-1);
#ifdef SHIREN_MAC_NEXT
 return lerp(sourceFrame53(a,pixel,p),sourceFrame53(b,pixel,p),f-float(a));
#else
 uint area=cfg[2]*cfg[3];return lerp(unpack(source[a*area+pixel]),unpack(source[b*area+pixel]),f-float(a));
#endif
}
#ifdef SHIREN_MAC42
/* 按时间场混合源帧，再应用切片遮光与阴影。 */ float4 fieldColor53(Field f,uint local,TFParams p){
 float weight=clamp(f.weight,0.f,1.f);
 if(p.viewMode==2){float n=adjusted3(lerp(clamp(f.a,0.f,1.f),clamp(f.b,0.f,1.f),weight),p);return float4(n,n,n,1);}
 float4 color=sampleSource(weight==1?f.b:f.a,local,p);
 if(weight==1)color*=f.shade;
 else if(weight>0)color=lerp(color,sampleSource(f.b,local,p)*f.shade,weight);
 color.rgb*=f.light;return color;
}
#endif
#ifdef SHIREN_MAC42
/* 按理想直条覆盖积分混合源颜色和阴影。 */ float4 filteredStripeColor52(float2 uv,uint local,TFParams p){
 StripeFootprint52 footprint=stripeFootprint52(uv,p);
 float4 result=0;
 for(int cell=int(footprint.first);cell<=int(footprint.last);cell++){
  float low=max(footprint.low,float(cell)),high=min(footprint.high,float(cell+1));
  float weight=stripeWeight52(low,high,footprint);
  if(weight<=1e-8f)continue;
  Field f=stripeSample52(uv,p,footprint,low,high,weight);
  float blend=clamp(f.weight,0.0f,1.0f);
  float4 color;
  if(p.viewMode==2){float t=adjusted3(lerp(clamp(f.a,0.0f,1.0f),clamp(f.b,0.0f,1.0f),blend),p);color=float4(t,t,t,1);}
  else{
   if(blend==1)color=sampleSource(f.b,local,p)*f.shade;
   else{color=sampleSource(f.a,local,p);if(blend>0)color=lerp(color,sampleSource(f.b,local,p)*f.shade,blend);}
   color.rgb*=f.light;
  }
  result+=color*weight/footprint.normalization;
 }
 return result;
}
#endif
[numthreads(8,8,1)]
/* 执行当前渲染步骤并生成目标图像或资源。 */ void render(uint3 id:SV_DispatchThreadID){
 if(id.x>=cfg[2]||id.y>=cfg[3]||id.z>=cfg[8])return;
 uint local=id.y*cfg[2]+id.x;float2 uv=(float2(id.xy+uint2(cfg[0],cfg[1]))+.5f)/float2(cfg[4],cfg[5]);
 TFParams p=param;p.u=float(cfg[7]+id.z)/float(max(1u,cfg[9]));p.outTime=p.u;
#ifdef SHIREN_MAC_NEXT
 // 昼夜模式把全部输出时长交给冻结展开，结束时不进入后续流动。
 if((p.flags&1024)!=0){float build=clamp(p.build,.1f,.9f);p.u=clamp(p.u*build,0.0f,build);}
#endif
 float4 color;
#ifdef SHIREN_MAC42
 if(p.viewMode==1){
#ifdef SHIREN_MAC_NEXT
 color=sampleSource((p.flags&1024)!=0 ? p.u/max(.1f,p.build):p.u,local,p);
#else
 color=sampleSource(p.u,local,p);
#endif
 }
 else if(filteredFreeze52(p))color=filteredStripeColor52(uv,local,p);
 else {
#ifdef SHIREN_MAC_NEXT
  float map=p.customMap!=0 ? timeMap[local]:0;
  if(needsAA53(uv,p,map)){
   TFParams q=p;q.reserved0=.25f;color=0;
   for(int yy=0;yy<4;yy++)for(int xx=0;xx<4;xx++){
    float2 point=uv+float2((xx+.5f)/4-.5f,(yy+.5f)/4-.5f)/float2(p.sampleW,p.sampleH);
    color+=fieldColor53(evaluate3(point,q,map),local,p)/16;
   }
  }else color=fieldColor53(evaluate3(uv,p,map),local,p);
#else
  color=fieldColor53(evaluate3(uv,p,p.customMap!=0 ? timeMap[local]:0),local,p);
#endif
 }
#else
 Field f=evaluate3(uv,p,timeMap[local]);
 if(p.viewMode==1)color=sampleSource(p.u,local,p);
 else if(p.viewMode==2){float n=adjusted3(lerp(clamp(f.a,0.f,1.f),clamp(f.b,0.f,1.f),clamp(f.weight,0.f,1.f)),p);color=float4(n,n,n,1);}
 else {float4 a=sampleSource(f.a,local,p),b=sampleSource(f.b,local,p);b.rgb*=f.shade;color=float4(lerp(a.rgb,b.rgb,clamp(f.weight,0.f,1.f)),1);}
#endif
 if((p.flags&4096u)!=0){float noise=gradientOffset105(id.x+cfg[0],id.y+cfg[1])/255.f;color.rgb=clamp(color.rgb,0.f,1.f)+noise;}
 output[(id.z*cfg[3]+id.y)*cfg[2]+id.x]=pack(color);
}
// Diagnostic field, used for CPU/GPU equivalence and warped fold sampling.
[[vk::binding(5,0)]] RWStructuredBuffer<float4> diagnostics;
[numthreads(8,8,1)]
/* 批量输出时间场诊断值，供渲染和一致性检查使用。 */ void fields(uint3 id:SV_DispatchThreadID){
 if(id.x>=cfg[2]||id.y>=cfg[3])return;
 uint local=id.y*cfg[2]+id.x;float2 uv=(float2(id.xy+uint2(cfg[0],cfg[1]))+.5f)/float2(cfg[4],cfg[5]);
 Field f=evaluate3(uv,param,timeMap[local]);
 float shade=f.shade;
#ifdef SHIREN_MAC_NEXT
 if((param.flags&256)!=0)shade=f.light;
 if((param.flags&512)!=0)shade=needsAA53(uv,param,timeMap[local])?1:0;
#endif
 diagnostics[local*2]=float4(adjusted3(f.a,param),adjusted3(f.b,param),clamp(f.weight,0.f,1.f),shade);
 diagnostics[local*2+1]=float4(f.uvA,f.uvB);
}
