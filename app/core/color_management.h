#ifndef TIMESLICE_COLOR_106
#define TIMESLICE_COLOR_106
static const uint SRC10_106=8192u,OUT10_106=16384u,SRC_PQ106=32768u,SRC_HLG106=65536u;
static const uint OUT_PQ106=131072u,OUT_HLG106=262144u,SRC2020_106=524288u,SRC_SRGB106=1048576u;
/* PQ使用绝对亮度；工作空间以203nit参考白归一，保留大于1的高光。 */
float pqLinear106(float v){float q=pow(max(v,0.f),32.f/2523.f);return 10000.f*pow(max(q-3424.f/4096.f,0.f)/max(2413.f/128.f-2392.f/128.f*q,1e-9f),16384.f/2610.f)/203.f;}
/* 将真实线性亮度编码为PQ，而不是仅给SDR像素加标签。 */
float pqSignal106(float v){float q=pow(max(v,0.f)*203.f/10000.f,2610.f/16384.f);return pow((3424.f/4096.f+2413.f/128.f*q)/(1.f+2392.f/128.f*q),2523.f/32.f);}
/* BT.709的光电转换对，用于SDR与HDR工作域转换。 */
float btLinear106(float v){return v<=.081f?v/4.5f:pow((v+.099f)/1.099f,1.f/.45f);}
/* 将线性SDR亮度重新编码为BT.709。 */
float btSignal106(float v){v=max(v,0.f);return v<.018f?v*4.5f:1.099f*pow(v,.45f)-.099f;}
/* HLG场景编码/解码，显示OOTF在RGB亮度域整体应用以避免色相偏移。 */
float hlgScene106(float v){return v<=.5f?v*v/3.f:(exp((v-.55991073f)/.17883277f)+.28466892f)/12.f;}
/* 将HLG场景线性信号编码为视频代码值。 */
float hlgSignal106(float v){v=max(v,0.f);return v<=1.f/12.f?sqrt(3.f*v):.17883277f*log(max(12.f*v-.28466892f,1e-9f))+.55991073f;}
#ifdef SHIREN_GRADE_CPU
/* 10位源只有1024种通道代码，精确查表代替每个采样点重复求幂。 */
struct TransferTable106 {
 float value[4][1024];
 TransferTable106(){for(int i=0;i<1024;i++){float v=float(i)/1023.f;value[0][i]=pqLinear106(v);value[1][i]=hlgScene106(v);value[2][i]=linear53(v);value[3][i]=btLinear106(v);}}
};
#endif
/* CPU的代码值查表不降低精度；GPU保留原生浮点传递函数。 */
float sourceTransfer106(float v,uint flags){
#ifdef SHIREN_GRADE_CPU
 if((flags&SRC10_106)!=0){static const TransferTable106 table;int mode=(flags&SRC_PQ106)!=0?0:(flags&SRC_HLG106)!=0?1:(flags&SRC_SRGB106)!=0?2:3;int index=int(round(clamp(v,0.f,1.f)*1023.f));return table.value[mode][index];}
#endif
 return (flags&SRC_PQ106)!=0?pqLinear106(v):(flags&SRC_HLG106)!=0?hlgScene106(v):(flags&SRC_SRGB106)!=0?linear53(v):btLinear106(v);
}
/* 根据源传递函数还原线性亮度，绝不在这里把HDR高光截到SDR白点。 */
Color53 sourceLinear106(Color53 c,TFParams p){
 if((p.flags&SRC_PQ106)!=0)return color53(sourceTransfer106(c.r,p.flags),sourceTransfer106(c.g,p.flags),sourceTransfer106(c.b,p.flags));
 if((p.flags&SRC_HLG106)!=0){c=color53(sourceTransfer106(c.r,p.flags),sourceTransfer106(c.g,p.flags),sourceTransfer106(c.b,p.flags));float gain=pow(max(c.r*.2627f+c.g*.6780f+c.b*.0593f,1e-12f),.2f)*1000.f/203.f;return color53(c.r*gain,c.g*gain,c.b*gain);}
 return color53(sourceTransfer106(c.r,p.flags),sourceTransfer106(c.g,p.flags),sourceTransfer106(c.b,p.flags));
}
/* 将线性颜色写回原缓存的编码空间，用于高精度稳定和去闪。 */
Color53 sourceSignal106(Color53 c,TFParams p){
 if((p.flags&SRC_PQ106)!=0)return color53(pqSignal106(c.r),pqSignal106(c.g),pqSignal106(c.b));
 if((p.flags&SRC_HLG106)!=0){float gain=pow(max((c.r*.2627f+c.g*.6780f+c.b*.0593f)*203.f/1000.f,1e-12f),-1.f/6.f)*203.f/1000.f;return color53(hlgSignal106(c.r*gain),hlgSignal106(c.g*gain),hlgSignal106(c.b*gain));}
 if((p.flags&SRC_SRGB106)!=0)return color53(srgb53(c.r),srgb53(c.g),srgb53(c.b));
 return color53(btSignal106(c.r),btSignal106(c.g),btSignal106(c.b));
}
/* Rec.709与Rec.2020在线性RGB域转换，处理真实色域而非改写标记。 */
Color53 to2020_106(Color53 c){return color53(.627404f*c.r+.329282f*c.g+.0433136f*c.b,.069097f*c.r+.919540f*c.g+.0113612f*c.b,.0163916f*c.r+.0880132f*c.g+.895595f*c.b);}
/* 宽色域转换回Rec.709，超出目标色域的颜色在最终阶段压缩。 */
Color53 to709_106(Color53 c){return color53(1.660491f*c.r-.587641f*c.g-.072850f*c.b,-.124550f*c.r+1.132900f*c.g-.008350f*c.b,-.018151f*c.r-.100579f*c.g+1.118730f*c.b);}
/* 只有需要色彩转换时进入线性域；普通8位SDR的既有效果保持原方程。 */
bool linearColor106(TFParams p){return (p.flags&(SRC_PQ106|SRC_HLG106|SRC2020_106|SRC_SRGB106|OUT_PQ106|OUT_HLG106))!=0;}
/* 把源代码值转换为本次目标的工作色域。 */
Color53 inputColor106(Color53 c,TFParams p){
 if(!linearColor106(p))return c;c=sourceLinear106(c,p);
 bool wide=(p.flags&(OUT_PQ106|OUT_HLG106))!=0,srcWide=(p.flags&SRC2020_106)!=0;
 return wide&&!srcWide?to2020_106(c):!wide&&srcWide?to709_106(c):c;
}
/* Mobius高光压缩保留低亮度，在实际需要降低动态范围时才启用。 */
float mobius106(float x,float peak){
 if(peak<=1.00001f||x<=.3f)return x;float j=.3f;
 float a=-j*j*(peak-1.f)/(j*j-2.f*j+peak),b=(j*j-2.f*j*peak+peak)/(peak-1.f);
 return (b+j)*(b+j)/(b-a)*(x+a)/max(x+b,1e-9f);
}
/* 保持中性色亮度，将目标Rec.709以外的色度压入可表示范围。 */
Color53 gamut709_106(Color53 c){
 float y=clamp(c.r*.2126f+c.g*.7152f+c.b*.0722f,0.f,1.f),low=min(c.r,min(c.g,c.b));
 float k=low<0?min(1.f,y/max(y-low,1e-9f)):1.f;c=color53(y+(c.r-y)*k,y+(c.g-y)*k,y+(c.b-y)*k);
 float high=max(c.r,max(c.g,c.b));k=high>1?min(1.f,(1-y)/max(high-y,1e-9f)):1.f;
 return color53(clamp(y+(c.r-y)*k,0.f,1.f),clamp(y+(c.g-y)*k,0.f,1.f),clamp(y+(c.b-y)*k,0.f,1.f));
}
/* 编码目标传递函数：原生PQ/HLG保留高光，HDR转SDR显式压缩亮度。 */
Color53 outputColor106(Color53 c,TFParams p){
 if(!linearColor106(p))return c;
 if((p.flags&OUT_PQ106)!=0)return color53(pqSignal106(c.r),pqSignal106(c.g),pqSignal106(c.b));
 if((p.flags&OUT_HLG106)!=0){
  float level=max(c.r,max(c.g,c.b))*203.f/1000.f,peak=max(1000.f,p.sourcePeak)/1000.f;
  float gain=level>1e-9f?mobius106(level,peak)/level:1.f;c=color53(c.r*gain,c.g*gain,c.b*gain);
  gain=pow(max((c.r*.2627f+c.g*.6780f+c.b*.0593f)*203.f/1000.f,1e-12f),-1.f/6.f)*203.f/1000.f;
  return color53(hlgSignal106(c.r*gain),hlgSignal106(c.g*gain),hlgSignal106(c.b*gain));
 }
 if((p.flags&(SRC_PQ106|SRC_HLG106))!=0){float level=max(c.r,max(c.g,c.b)),gain=level>1e-9f?mobius106(level,max(203.f,p.sourcePeak)/203.f)/level:1.f;c=color53(c.r*gain,c.g*gain,c.b*gain);}
 c=gamut709_106(c);return color53(btSignal106(c.r),btSignal106(c.g),btSignal106(c.b));
}
/* 解包10位RGB缓存，RGB8兼容路径不改变通道顺序。 */
Color53 rawColor106(uint v,TFParams p){return (p.flags&SRC10_106)!=0?color53(float((v>>20)&1023u)/1023.f,float((v>>10)&1023u)/1023.f,float(v&1023u)/1023.f):color53(float(v&255u)/255.f,float((v>>8)&255u)/255.f,float((v>>16)&255u)/255.f);}
/* 最终输出打包：真实10位保留1024级，兼容模式仍为RGBA8。 */
uint packColor106(Color53 c,uint x,uint y,TFParams p){
 if(p.viewMode!=2)c=outputColor106(c,p);float noise=(p.flags&4096u)!=0?gradientOffset105(x,y):0.f;
 if((p.flags&OUT10_106)!=0){uint r=uint(round(clamp(c.r,0.f,1.f)*1023.f+noise)),g=uint(round(clamp(c.g,0.f,1.f)*1023.f+noise)),b=uint(round(clamp(c.b,0.f,1.f)*1023.f+noise));return (3u<<30)|(r<<20)|(g<<10)|b;}
 return uint(quantizeColor105(c.r,x,y,p.flags))|(uint(quantizeColor105(c.g,x,y,p.flags))<<8)|(uint(quantizeColor105(c.b,x,y,p.flags))<<16)|(255u<<24);
}
#endif
