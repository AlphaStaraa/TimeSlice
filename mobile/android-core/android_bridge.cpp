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
  pixel[0]=uint8_t(round(clamp(color.r*255,0.f,255.f)));
  pixel[1]=uint8_t(round(clamp(color.g*255,0.f,255.f)));
  pixel[2]=uint8_t(round(clamp(color.b*255,0.f,255.f)));pixel[3]=255;
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
