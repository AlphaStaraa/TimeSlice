#include <jni.h>
#include "../../app/core/cpu.cpp"

/* 用浮点时间图驱动与桌面一致的内置、绝对和相对取样。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_renderMapped(
 JNIEnv* env,jclass,jobject params,jint w,jint h,jint y,jint rows,jobject source,jobject output,jobject grading,jobject mapping){
 auto p=(TFParams*)env->GetDirectBufferAddress(params);auto src=(uint8_t*)env->GetDirectBufferAddress(source);
 auto out=(uint8_t*)env->GetDirectBufferAddress(output);auto grade=grading?(float*)env->GetDirectBufferAddress(grading):nullptr;
 auto map=mapping?(float*)env->GetDirectBufferAddress(mapping):nullptr;if(!p||!src||!out)return;
 render_preview(p,w,h,y,rows,map,src,w,h,grade,out+y*w*4);
}

/* 直接使用桌面 CPU 方程，手机预览和导出只改变目标画布尺寸。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_renderGraded(
 JNIEnv* env,jclass,jobject params,jint w,jint h,jint y,jint rows,jobject source,jobject output,jobject grading){
 auto p=(TFParams*)env->GetDirectBufferAddress(params);
 auto src=(uint8_t*)env->GetDirectBufferAddress(source);
 auto out=(uint8_t*)env->GetDirectBufferAddress(output);
 auto grade=grading ? (float*)env->GetDirectBufferAddress(grading):nullptr;
 if(!p||!src||!out)return;
 render_preview(p,w,h,y,rows,nullptr,src,w,h,grade,out+y*w*4);
}

/* 合成 GPU 时间场；几何边缘仍复用桌面面积积分，避免斜切锯齿。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_composeGraded(
 JNIEnv* env,jclass,jobject params,jint w,jint h,jint y0,jint rows,jobject field,jobject source,jobject output,jobject grading){
 auto p=(TFParams*)env->GetDirectBufferAddress(params);
 auto src=(uint8_t*)env->GetDirectBufferAddress(source);
 auto out=(uint8_t*)env->GetDirectBufferAddress(output);
 auto data=(float*)env->GetDirectBufferAddress(field);
 auto grade=grading ? (float*)env->GetDirectBufferAddress(grading):nullptr;
 if(!p||!src||!out||!data)return;
 for(int y=y0;y<y0+rows;y++)for(int x=0;x<w;x++){
  float2 uv((x+.5f)/w,(y+.5f)/h);Color53 color;
  if(filteredFreeze52(*p)||needsAA53(uv,*p,0))color=pixel53(*p,uv,src,w,h,0,grade);
  else{
   const float* sample=data+((y-y0)*w+x)*8;
   Field f=single3(uv,0);f.a=sample[0];f.b=sample[1];f.weight=sample[2];f.shade=sample[3];f.light=sample[4];
   // GPU 时间场已完成素材入出点和反转，合成时不能再应用一次。
   TFParams q=*p;q.sourceStart=0;q.sourceEnd=1;q.sourceReverse=0;
   color=fieldColor53(f,q,src,w,h,uv,grade);
  }
  auto pixel=out+(y*w+x)*4;
  uint value=packColor106(color,x,y,*p);std::memcpy(pixel,&value,4);
 }
}

/* 保留无调色的移动端接口，供自检和兼容入口使用。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_render(
 JNIEnv* env,jclass c,jobject p,jint w,jint h,jint y,jint rows,jobject source,jobject output){
 Java_studio_shiren_mobile_NativeCore_renderGraded(env,c,p,w,h,y,rows,source,output,nullptr);
}

/* 保留 GPU 混合接口，所有入口共享同一条合成路径。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_compose(
 JNIEnv* env,jclass c,jobject p,jint w,jint h,jint y,jint rows,jobject field,jobject source,jobject output){
 Java_studio_shiren_mobile_NativeCore_composeGraded(env,c,p,w,h,y,rows,field,source,output,nullptr);
}

/* 将 Android ARGB 位图转换为统一的 RGBA 帧。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_fromARGB(
 JNIEnv* env,jclass,jintArray array,jobject target,jint offset){
 auto a=env->GetIntArrayElements(array,nullptr);auto p=(uint8_t*)env->GetDirectBufferAddress(target)+offset;
 int n=env->GetArrayLength(array);for(int i=0;i<n;i++){unsigned v=a[i];p[i*4]=(v>>16)&255;p[i*4+1]=(v>>8)&255;p[i*4+2]=v&255;p[i*4+3]=255;}
 env->ReleaseIntArrayElements(array,a,JNI_ABORT);
}

/* 将渲染结果转换为系统 ImageView 所需的 ARGB 通道。 */
extern "C" JNIEXPORT void JNICALL Java_studio_shiren_mobile_NativeCore_toARGB(
 JNIEnv* env,jclass,jobject source,jintArray array){
 auto a=env->GetIntArrayElements(array,nullptr);auto p=(uint8_t*)env->GetDirectBufferAddress(source);
 int n=env->GetArrayLength(array);for(int i=0;i<n;i++)a[i]=(255u<<24)|(p[i*4]<<16)|(p[i*4+1]<<8)|p[i*4+2];
 env->ReleaseIntArrayElements(array,a,0);
}

/* 把计算结果限制到有效的八位视频范围。 */
static uint8_t byte_clip(int v){return uint8_t(v<0?0:(v>255?255:v));}

/* 为系统硬件编码器写入 Rec.709 有限范围的 I420/NV12 色度平面。 */
extern "C" JNIEXPORT jboolean JNICALL Java_studio_shiren_mobile_NativeCore_rgbaToYuv(
 JNIEnv* env,jclass,jobject input,jint w,jint h,jobject yBuffer,jint yr,jint yp,jobject uBuffer,jint ur,jint up,jobject vBuffer,jint vr,jint vp){
 auto src=(uint8_t*)env->GetDirectBufferAddress(input);auto y=(uint8_t*)env->GetDirectBufferAddress(yBuffer);
 auto u=(uint8_t*)env->GetDirectBufferAddress(uBuffer);auto v=(uint8_t*)env->GetDirectBufferAddress(vBuffer);
 if(!src||!y||!u||!v||w<2||h<2)return JNI_FALSE;
 if(env->GetDirectBufferCapacity(input)<jlong(w)*h*4||env->GetDirectBufferCapacity(yBuffer)<jlong(h-1)*yr+(w-1)*yp+1||
    env->GetDirectBufferCapacity(uBuffer)<jlong(h/2-1)*ur+(w/2-1)*up+1||env->GetDirectBufferCapacity(vBuffer)<jlong(h/2-1)*vr+(w/2-1)*vp+1)return JNI_FALSE;
 for(int row=0;row<h;row++)for(int x=0;x<w;x++){auto p=src+(row*w+x)*4;y[row*yr+x*yp]=byte_clip(((2991*p[0]+10064*p[1]+1016*p[2]+8192)>>14)+16);}
 for(int row=0;row<h;row+=2)for(int x=0;x<w;x+=2){int r=0,g=0,b=0;for(int dy=0;dy<2;dy++)for(int dx=0;dx<2;dx++){auto p=src+((row+dy)*w+x+dx)*4;r+=p[0];g+=p[1];b+=p[2];}
  u[(row/2)*ur+(x/2)*up]=byte_clip(((-1649*r-5547*g+7196*b+32768)>>16)+128);
  v[(row/2)*vr+(x/2)*vp]=byte_clip(((7196*r-6536*g-660*b+32768)>>16)+128);}
 return JNI_TRUE;
}

/* 读取P010小端高十位或普通YUV8分量。 */
static float planeValue106(const uint8_t* p,int row,int pixel,int x,int y,int bits){const uint8_t* q=p+uint64_t(y)*row+uint64_t(x)*pixel;return bits==10?float((uint(q[0])|(uint(q[1])<<8))>>6):float(q[0]);}
/* 在合法源平面范围内做高精度双线性采样。 */
static float planeSample106(const uint8_t* p,int row,int pixel,float x,float y,int w,int h,int bits){x=clamp(x,0.f,float(w-1));y=clamp(y,0.f,float(h-1));int ix=int(x),iy=int(y),xx=std::min(ix+1,w-1),yy=std::min(iy+1,h-1);return lerp(lerp(planeValue106(p,row,pixel,ix,iy,bits),planeValue106(p,row,pixel,xx,iy,bits),x-ix),lerp(planeValue106(p,row,pixel,ix,yy,bits),planeValue106(p,row,pixel,xx,yy,bits),x-ix),y-iy);}
/* 验证平面容量和步长，避免厂商布局不兼容时越界读取。 */
static bool planeFits106(JNIEnv* env,jobject plane,int row,int pixel,int w,int h,int bytes){return plane&&row>0&&pixel>=bytes&&w>0&&h>0&&env->GetDirectBufferAddress(plane)&&env->GetDirectBufferCapacity(plane)>=jlong(h-1)*row+jlong(w-1)*pixel+bytes;}
/* 在YUV8或P010源上完成缩放、旋转和颜色矩阵转换，直接保存RGB10。 */
extern "C" JNIEXPORT jint JNICALL Java_studio_shiren_mobile_NativeCore_yuvToRGB10(
 JNIEnv* env,jclass,jobject yy,jint yr,jint yp,jobject uu,jint ur,jint up,jobject vv,jint vr,jint vp,jint sw,jint sh,jint left,jint top,jint cw,jint ch,jint bits,jint range,jint standard,jint rotation,jobject target,jint dw,jint dh){
 int bytes=bits==10?2:1;
 if(sw<2||sh<2||cw<1||ch<1||left<0||top<0||left+cw>sw||top+ch>sh||dw<2||dh<2||
    !planeFits106(env,yy,yr,yp,sw,sh,bytes)||!planeFits106(env,uu,ur,up,(sw+1)/2,(sh+1)/2,bytes)||!planeFits106(env,vv,vr,vp,(sw+1)/2,(sh+1)/2,bytes)||env->GetDirectBufferCapacity(target)<jlong(dw)*dh*4)return -1;
 auto y=(const uint8_t*)env->GetDirectBufferAddress(yy);auto u=(const uint8_t*)env->GetDirectBufferAddress(uu);auto v=(const uint8_t*)env->GetDirectBufferAddress(vv);auto out=(uint8_t*)env->GetDirectBufferAddress(target);if(!out)return -1;
 float kr=standard==6?.2627f:standard==2||standard==4?.299f:.2126f,kb=standard==6?.0593f:standard==2||standard==4?.114f:.0722f,kg=1-kr-kb;
 float maxCode=bits==10?1023.f:255.f,yOffset=range==1?0.f:bits==10?64.f:16.f,yRange=range==1?maxCode:bits==10?876.f:219.f,cRange=range==1?maxCode:bits==10?896.f:224.f,center=bits==10?512.f:128.f;
 int maximum=0;
 for(int row=0;row<dh;row++)for(int x=0;x<dw;x++){
  float nx=(x+.5f)/dw,ny=(row+.5f)/dh,px=nx,py=ny;
  if(rotation==90){px=ny;py=1-nx;}else if(rotation==270){px=1-ny;py=nx;}else if(rotation==180){px=1-nx;py=1-ny;}
  float sx=left+px*cw-.5f,sy=top+py*ch-.5f;
  float l=(planeSample106(y,yr,yp,sx,sy,sw,sh,bits)-yOffset)/yRange;
  float cb=(planeSample106(u,ur,up,(sx-.5f)/2,(sy-.5f)/2,(sw+1)/2,(sh+1)/2,bits)-center)/cRange;
  float cr=(planeSample106(v,vr,vp,(sx-.5f)/2,(sy-.5f)/2,(sw+1)/2,(sh+1)/2,bits)-center)/cRange;
  float r=l+2*(1-kr)*cr,b=l+2*(1-kb)*cb,g=(l-kr*r-kb*b)/kg;
  uint rr=uint(round(clamp(r,0.f,1.f)*1023.f)),gg=uint(round(clamp(g,0.f,1.f)*1023.f)),bb=uint(round(clamp(b,0.f,1.f)*1023.f));maximum=std::max(maximum,int(std::max(rr,std::max(gg,bb))));uint packed=(3u<<30)|(rr<<20)|(gg<<10)|bb;std::memcpy(out+(uint64_t(row)*dw+x)*4,&packed,4);
 }
 return maximum;
}
/* 为HEVC Main10写P010，16位样本的低六位必须为零。 */
extern "C" JNIEXPORT jboolean JNICALL Java_studio_shiren_mobile_NativeCore_rgb10ToP010(
 JNIEnv* env,jclass,jobject input,jint w,jint h,jobject yy,jint yr,jint yp,jobject uu,jint ur,jint up,jobject vv,jint vr,jint vp,jboolean wide){
 if(w<2||h<2||w%2||h%2||!planeFits106(env,yy,yr,yp,w,h,2)||!planeFits106(env,uu,ur,up,w/2,h/2,2)||!planeFits106(env,vv,vr,vp,w/2,h/2,2)||env->GetDirectBufferCapacity(input)<jlong(w)*h*4)return JNI_FALSE;
 auto src=(const uint8_t*)env->GetDirectBufferAddress(input);auto y=(uint8_t*)env->GetDirectBufferAddress(yy);auto u=(uint8_t*)env->GetDirectBufferAddress(uu);auto v=(uint8_t*)env->GetDirectBufferAddress(vv);if(!src)return JNI_FALSE;
 float kr=wide?.2627f:.2126f,kb=wide?.0593f:.0722f,kg=1-kr-kb;
 auto sample=[&](int x,int row){uint value;std::memcpy(&value,src+(uint64_t(row)*w+x)*4,4);return color53(float((value>>20)&1023u)/1023.f,float((value>>10)&1023u)/1023.f,float(value&1023u)/1023.f);};
 auto write=[](uint8_t* p,int code){uint value=uint(std::max(0,std::min(1023,code)))<<6;p[0]=uint8_t(value);p[1]=uint8_t(value>>8);};
 for(int row=0;row<h;row++)for(int x=0;x<w;x++){Color53 c=sample(x,row);write(y+uint64_t(row)*yr+x*yp,int(round(64+876*(kr*c.r+kg*c.g+kb*c.b))));}
 for(int row=0;row<h;row+=2)for(int x=0;x<w;x+=2){Color53 c=color53(0,0,0);for(int dy=0;dy<2;dy++)for(int dx=0;dx<2;dx++){Color53 a=sample(x+dx,row+dy);c.r+=a.r*.25f;c.g+=a.g*.25f;c.b+=a.b*.25f;}float l=kr*c.r+kg*c.g+kb*c.b;write(u+uint64_t(row/2)*ur+(x/2)*up,int(round(512+896*(c.b-l)/(2*(1-kb)))));write(v+uint64_t(row/2)*vr+(x/2)*vp,int(round(512+896*(c.r-l)/(2*(1-kr)))));}
 return JNI_TRUE;
}
/* 共用桌面高精度重采样，输出可以是源RGB10或仅用于分析的SDR代理。 */
extern "C" JNIEXPORT jboolean JNICALL Java_studio_shiren_mobile_NativeCore_transformPrecision(
 JNIEnv* env,jclass,jobject source,jint sw,jint sh,jobject output,jint dw,jint dh,jfloatArray matrix,jfloatArray gains,jint flags,jfloat peak,jboolean preserve){
 auto src=(const uint8_t*)env->GetDirectBufferAddress(source);auto out=(uint8_t*)env->GetDirectBufferAddress(output);
 if(!src||!out||sw<2||sh<2||dw<2||dh<2||env->GetDirectBufferCapacity(source)<jlong(sw)*sh*4||env->GetDirectBufferCapacity(output)<jlong(dw)*dh*4||env->GetArrayLength(matrix)!=6||env->GetArrayLength(gains)!=3)return JNI_FALSE;
 float m[6],g[3];env->GetFloatArrayRegion(matrix,0,6,m);env->GetFloatArrayRegion(gains,0,3,g);TFParams p={};p.flags=uint(flags)|8192u;p.sourcePeak=peak;p.paperWhite=203;p.displayPeak=1000;
 transform_precision(&p,sw,sh,dw,dh,0,dh,m,g,src,out,preserve?1:0);return JNI_TRUE;
}
