// Same scalar grading equations for C++ and Slang. GRADE reads the tiny live configuration.
struct Color53 {float r,g,b;};
/* 建立可供 C++ 与 Slang 共用的标量 RGB 颜色。 */ Color53 color53(float r,float g,float b){Color53 c;c.r=r;c.g=g;c.b=b;return c;}
/* 把一个 sRGB 通道还原为线性亮度。 */ float linear53(float c){return c<=.04045f ? c/12.92f:pow((c+.055f)/1.055f,2.4f);}
/* 把线性颜色通道重新编码为显示值。 */ float srgb53(float c){c=max(c,0.0f);return c<=.0031308f ? 12.92f*c:1.055f*pow(c,1.0f/2.4f)-.055f;}
/* 在 HSL 转 RGB 时插值指定色相通道。 */ float hue53(float p,float q,float t){t=frac(t);if(t<1.0f/6)return p+(q-p)*6*t;if(t<.5f)return q;if(t<2.0f/3)return p+(q-p)*(2.0f/3-t)*6;return p;}
#ifdef SHIREN_GRADE_CPU
Color53 grade53(Color53 rgb,int frame,const float* gradedata){
#else
/* 按源帧的时间曲线应用首尾调色与连续八色 HSL。 */ Color53 grade53(Color53 rgb,int frame){
#endif
 if(GRADE(0)<.5f)return rgb;
 int count=int(GRADE(1));float t=GRADE(16+min(float(frame),float(count-1)));
 float temperature=lerp(GRADE(2),GRADE(7),t),tint=lerp(GRADE(3),GRADE(8),t);
 float sat=lerp(GRADE(4),GRADE(9),t),ev=lerp(GRADE(5),GRADE(10),t),contrast=lerp(GRADE(6),GRADE(11),t);
 float r=linear53(rgb.r),g=linear53(rgb.g),b=linear53(rgb.b);
 float gr=exp2(temperature*.006f+tint*.002f),gg=exp2(-tint*.004f),gb=exp2(-temperature*.006f+tint*.002f);
 float norm=gr*.2126f+gg*.7152f+gb*.0722f;
 r*=gr/norm;g*=gg/norm;b*=gb/norm;
 float y=max(.0001f,r*.2126f+g*.7152f+b*.0722f),scale=pow(y/.18f,contrast-1);
 r*=scale;g*=scale;b*=scale;y=r*.2126f+g*.7152f+b*.0722f;
 r=(y+sat*(r-y))*exp2(ev);g=(y+sat*(g-y))*exp2(ev);b=(y+sat*(b-y))*exp2(ev);
 scale=max(1.0f,max(r,max(g,b)));r=clamp(srgb53(r/scale),0.0f,1.0f);g=clamp(srgb53(g/scale),0.0f,1.0f);b=clamp(srgb53(b/scale),0.0f,1.0f);
 if(GRADE(12)>.5f){
  float high=max(r,max(g,b)),low=min(r,min(g,b)),d=high-low,l=(high+low)*.5f;
  if(d>1e-7f){
   float saturation=d/max(1e-7f,1-abs(2*l-1));
   float h=(high==r ? (g-b)/d:high==g ? (b-r)/d+2:(r-g)/d+4)/6;
   h=frac(h);float position=h*1024;int i=int(floor(position));float f=frac(position);
   int offset=16+count;int a=offset+(i%1024)*3,bb=offset+((i+1)%1024)*3;
   float chroma=clamp(saturation/.12f,0.0f,1.0f);
   h=frac(h+lerp(GRADE(a),GRADE(bb),f)*chroma/360);
   saturation=clamp(saturation*(1+lerp(GRADE(a+1),GRADE(bb+1),f)*chroma),0.0f,1.0f);
   float dl=lerp(GRADE(a+2),GRADE(bb+2),f)*chroma;l+=dl>=0 ? (1-l)*dl:l*dl;
   float q=l<.5f ? l*(1+saturation):l+saturation-l*saturation,p=2*l-q;
   r=hue53(p,q,h+1.0f/3);g=hue53(p,q,h);b=hue53(p,q,h-1.0f/3);
  }
 }
 return color53(r,g,b);
}
