#ifdef SHIREN_GRADE_CPU
/* HDR调色在线性亮度域完成，曝光与白平衡不得归一化掉超白高光。 */
Color53 gradeLinear106(Color53 rgb,int frame,TFParams p,const float* gradedata){
#else
/* C++和Slang共用同一套HDR首尾曲线与HSL方程。 */
Color53 gradeLinear106(Color53 rgb,int frame,TFParams p){
#endif
 if(GRADE(0)<.5f)return rgb;
 int count=int(GRADE(1));float t=GRADE(16+min(float(frame),float(count-1)));
 float temperature=lerp(GRADE(2),GRADE(7),t),tint=lerp(GRADE(3),GRADE(8),t);
 float sat=lerp(GRADE(4),GRADE(9),t),ev=lerp(GRADE(5),GRADE(10),t),contrast=lerp(GRADE(6),GRADE(11),t);
 bool wide=(p.flags&(OUT_PQ106|OUT_HLG106))!=0;
 float wr=wide?.2627f:.2126f,wg=wide?.6780f:.7152f,wb=wide?.0593f:.0722f;
 float gr=exp2(temperature*.006f+tint*.002f),gg=exp2(-tint*.004f),gb=exp2(-temperature*.006f+tint*.002f),norm=gr*wr+gg*wg+gb*wb;
 float r=rgb.r*gr/norm,g=rgb.g*gg/norm,b=rgb.b*gb/norm;
 float y=max(.0001f,r*wr+g*wg+b*wb),scale=pow(y/.18f,contrast-1.f);
 r*=scale;g*=scale;b*=scale;y=r*wr+g*wg+b*wb;
 float gain=exp2(ev);r=max(0.f,(y+sat*(r-y))*gain);g=max(0.f,(y+sat*(g-y))*gain);b=max(0.f,(y+sat*(b-y))*gain);
 if(GRADE(12)>.5f){
  float peak=max(1.f,max(r,max(g,b)));r=clamp(srgb53(r/peak),0.f,1.f);g=clamp(srgb53(g/peak),0.f,1.f);b=clamp(srgb53(b/peak),0.f,1.f);
  float high=max(r,max(g,b)),low=min(r,min(g,b)),d=high-low,l=(high+low)*.5f;
  if(d>1e-7f){
   float saturation=d/max(1e-7f,1-abs(2*l-1));float h=(high==r?(g-b)/d:high==g?(b-r)/d+2:(r-g)/d+4)/6;h=frac(h);
   float pos=h*1024;int i=int(floor(pos));float f=frac(pos);int offset=16+count,a=offset+(i%1024)*3,bb=offset+((i+1)%1024)*3;
   float chroma=clamp(saturation/.12f,0.f,1.f);h=frac(h+lerp(GRADE(a),GRADE(bb),f)*chroma/360);
   saturation=clamp(saturation*(1+lerp(GRADE(a+1),GRADE(bb+1),f)*chroma),0.f,1.f);
   float dl=lerp(GRADE(a+2),GRADE(bb+2),f)*chroma;l+=dl>=0?(1-l)*dl:l*dl;
   float q=l<.5f?l*(1+saturation):l+saturation-l*saturation,pp=2*l-q;r=hue53(pp,q,h+1.f/3);g=hue53(pp,q,h);b=hue53(pp,q,h-1.f/3);
  }
  r=linear53(r)*peak;g=linear53(g)*peak;b=linear53(b)*peak;
 }
 return color53(r,g,b);
}
