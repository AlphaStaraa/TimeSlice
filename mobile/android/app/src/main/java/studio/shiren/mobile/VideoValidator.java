package studio.shiren.mobile;
import android.graphics.*;import android.media.*;import java.io.*;import java.nio.*;
/** Verifies actual decoded pixels before publishing a new movie to the gallery. */
final class VideoValidator {
 /* 检查取消标志或输入约束，必要时中止当前任务。 */ static void check(File file,ByteBuffer expected,int w,int h)throws Exception{
  try(MediaMetadataRetriever r=new MediaMetadataRetriever()){r.setDataSource(file.getAbsolutePath());MediaMetadataRetriever.BitmapParams params=new MediaMetadataRetriever.BitmapParams();params.setPreferredConfig(Bitmap.Config.ARGB_8888);Bitmap image=null;try{image=r.getFrameAtIndex(0,params);}catch(Exception ignored){}if(image==null)image=r.getFrameAtTime(0,MediaMetadataRetriever.OPTION_CLOSEST_SYNC);if(image==null||image.getWidth()!=w||image.getHeight()!=h){if(image!=null)image.recycle();throw new Exception("成片尺寸或画面读取没有通过核验。");}int[] pixels=new int[w*h];image.getPixels(pixels,0,w,0,0,w,h);image.recycle();long color=0,luma=0;for(int i=0;i<pixels.length;i++){int a=expected.get(i*4)&255,b=expected.get(i*4+1)&255,c=expected.get(i*4+2)&255;int x=(pixels[i]>>16)&255,y=(pixels[i]>>8)&255,z=pixels[i]&255;color+=Math.abs(a-x)+Math.abs(b-y)+Math.abs(c-z);luma+=Math.abs(((54*a+183*b+19*c)>>8)-((54*x+183*y+19*z)>>8));}double c=(double)color/(pixels.length*3),l=(double)luma/pixels.length;android.util.Log.i("ShirenEncoder","verified RGB="+c+" luma="+l);if(c>32||l>18)throw new Exception("系统编码器写出的画面没有通过核验，当前视频不会保存。请降低输出尺寸或帧率后重试。");}
 }
 /* 在保存Main10前核对实际SPS、色彩和解码像素，不使用会自动降8位的Bitmap。 */
 static void check(android.content.Context context,File file,ByteBuffer expected,int w,int h,String mode,java.util.concurrent.atomic.AtomicBoolean stop)throws Exception{
  if(!VideoColor.high(mode)){check(file,expected,w,h);return;}
  VideoColor.requirePrecision();MediaExtractor e=new MediaExtractor();MediaFormat actual=null;
  try{e.setDataSource(file.getAbsolutePath());for(int i=0;i<e.getTrackCount();i++){MediaFormat f=e.getTrackFormat(i);if("video/hevc".equals(f.getString(MediaFormat.KEY_MIME))){actual=f;break;}}
   if(actual==null||actual.getByteBuffer("csd-0")==null||HevcSps.depth(actual.getByteBuffer("csd-0"))!=10)throw new Exception("成片不是实际10位HEVC，已停止保存。");
   MediaFormat target=VideoColor.format(w,h,30,0,mode);
   for(String key:new String[]{MediaFormat.KEY_COLOR_STANDARD,MediaFormat.KEY_COLOR_TRANSFER,MediaFormat.KEY_COLOR_RANGE})if(!actual.containsKey(key)||actual.getInteger(key)!=target.getInteger(key))throw new Exception("成片色彩信息与目标不一致，已停止保存。");
  }finally{e.release();}
  VideoSource source=new VideoSource(context,android.net.Uri.fromFile(file));
  try(VideoSource.Cache decoded=PrecisionDecoder.first(source,stop)){
   if(decoded.w!=w||decoded.h!=h)throw new Exception("10位成片尺寸不正确");ByteBuffer pixels=decoded.frame(0).order(ByteOrder.LITTLE_ENDIAN),reference=expected.duplicate().order(ByteOrder.LITTLE_ENDIAN);long error=0;
   for(int i=0;i<w*h;i++){int a=pixels.getInt(i*4),b=reference.getInt(i*4);error+=Math.abs(((a>>>20)&1023)-((b>>>20)&1023))+Math.abs(((a>>>10)&1023)-((b>>>10)&1023))+Math.abs((a&1023)-(b&1023));}
   double mean=error/(w*(double)h*3);if(mean>96)throw new Exception("10位成片解码像素偏差过大，已停止保存。");
  }
 }
}
