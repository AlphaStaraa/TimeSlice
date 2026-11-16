package studio.shiren.mobile;
import java.nio.*;
public final class NativeCore {
/* 直接把解码器YUV8/P010平面转成RGB10，支持裁切、旋转和目标尺寸。 */
public static native int yuvToRGB10(ByteBuffer y,int yr,int yp,ByteBuffer u,int ur,int up,ByteBuffer v,int vr,int vp,int sw,int sh,int left,int top,int cw,int ch,int bits,int range,int standard,int rotation,ByteBuffer output,int dw,int dh);
/* 写入真正的P010编码平面，保留10位分量。 */
public static native boolean rgb10ToP010(ByteBuffer rgb,int w,int h,ByteBuffer y,int yr,int yp,ByteBuffer u,int ur,int up,ByteBuffer v,int vr,int vp,boolean wide);
/* 高精度稳定/去闪与分析代理共用，正式像素不经过8位缓存。 */
public static native boolean transformPrecision(ByteBuffer source,int sw,int sh,ByteBuffer output,int dw,int dh,float[] inverse,float[] gains,int flags,float peak,boolean preserve);
/* 保留浮点自定义时间图的灰度精度，和桌面使用相同参数。 */ public static native void renderMapped(ByteBuffer p,int w,int h,int y,int rows,ByteBuffer source,ByteBuffer output,ByteBuffer grade,ByteBuffer mapping);

/* 共用桌面调色方程，按源时间实时合成，不重复处理整段素材。 */ public static native void renderGraded(ByteBuffer p,int w,int h,int y,int rows,ByteBuffer source,ByteBuffer output,ByteBuffer grade);
/* 把 GPU 时间场与实时调色、边缘面积积分合成为输出。 */ public static native void composeGraded(ByteBuffer p,int w,int h,int y,int rows,ByteBuffer field,ByteBuffer source,ByteBuffer output,ByteBuffer grade);
/* 转换 RGBA 帧为编码器要求的 YUV 平面。 */ public static native boolean rgbaToYuv(ByteBuffer input,int w,int h,ByteBuffer y,int yr,int yp,ByteBuffer u,int ur,int up,ByteBuffer v,int vr,int vp);static{System.loadLibrary("shiren");}/* 执行当前渲染步骤并生成目标图像或资源。 */ public static native void render(ByteBuffer p,int w,int h,int y,int rows,ByteBuffer source,ByteBuffer output);/* 用时间场从原始源帧合成输出。 */ public static native void compose(ByteBuffer p,int w,int h,int y,int rows,ByteBuffer field,ByteBuffer source,ByteBuffer output);/* 把 Android 像素排列转换为渲染器的 RGBA 数据。 */ public static native void fromARGB(int[] pixels,ByteBuffer target,int byteOffset);/* 把渲染结果转换回 Android 位图通道排列。 */ public static native void toARGB(ByteBuffer source,int[] pixels);}
