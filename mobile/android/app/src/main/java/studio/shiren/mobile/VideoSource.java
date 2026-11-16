package studio.shiren.mobile;
import android.content.*;import android.os.Build;import java.util.*;import android.net.Uri;import android.media.*;import android.graphics.*;import java.nio.*;import java.util.concurrent.atomic.AtomicBoolean;
public class VideoSource {
 public final Uri uri;public int width,height,rotation,standard=1,transfer=3,range=2,bits=8;public boolean hdr=false;public float peak=203;public long durationUs;public float fps=30;protected final Context context;
 public interface Progress{/* 更新当前任务状态并把进度通知上层。 */ void update(float p,String text);}
 /* 读取真实色彩描述；HDR不再提前转成8位Bitmap。 */
 public VideoSource(Context c,Uri u)throws Exception{
  context=c;uri=u;
  try(MediaMetadataRetriever r=new MediaMetadataRetriever()){
   r.setDataSource(c,u);width=Integer.parseInt(r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH));height=Integer.parseInt(r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT));durationUs=Long.parseLong(r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION))*1000;
   String angle=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);rotation=angle==null?0:Integer.parseInt(angle);if(rotation==90||rotation==270){int tmp=width;width=height;height=tmp;}
   String tr=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_TRANSFER),cs=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_STANDARD),cr=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_RANGE);
   if(tr!=null)transfer=Integer.parseInt(tr);if(cs!=null)standard=Integer.parseInt(cs);if(cr!=null)range=Integer.parseInt(cr);
   String rate=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE),count=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT);if(rate!=null)fps=Float.parseFloat(rate);else if(count!=null&&durationUs>0)fps=(float)(Long.parseLong(count)*1e6/durationUs);else fps=Float.NaN;
  }
  MediaExtractor e=new MediaExtractor();try{e.setDataSource(c,u,null);for(int i=0;i<e.getTrackCount();i++){
   MediaFormat f=e.getTrackFormat(i);String mime=f.getString(MediaFormat.KEY_MIME);if(mime==null||!mime.startsWith("video/"))continue;
   if(f.containsKey(MediaFormat.KEY_COLOR_STANDARD))standard=f.getInteger(MediaFormat.KEY_COLOR_STANDARD);if(f.containsKey(MediaFormat.KEY_COLOR_TRANSFER))transfer=f.getInteger(MediaFormat.KEY_COLOR_TRANSFER);if(f.containsKey(MediaFormat.KEY_COLOR_RANGE))range=f.getInteger(MediaFormat.KEY_COLOR_RANGE);
   if(f.containsKey(MediaFormat.KEY_FRAME_RATE)&&!Float.isFinite(fps))fps=f.getInteger(MediaFormat.KEY_FRAME_RATE);
   if("video/hevc".equals(mime)&&f.getByteBuffer("csd-0")!=null)try{bits=HevcSps.depth(f.getByteBuffer("csd-0"));}catch(IllegalArgumentException error){if(f.containsKey(MediaFormat.KEY_PROFILE)&&f.getInteger(MediaFormat.KEY_PROFILE)!=MediaCodecInfo.CodecProfileLevel.HEVCProfileMain)bits=10;}
   if(f.containsKey(MediaFormat.KEY_HDR_STATIC_INFO)){ByteBuffer h=f.getByteBuffer(MediaFormat.KEY_HDR_STATIC_INFO).duplicate().order(ByteOrder.LITTLE_ENDIAN);if(h.remaining()>=25){int base=h.position();int cll=h.getShort(base+21)&65535,master=h.getShort(base+17)&65535;peak=Math.max(203,cll>0?cll:master>0?master:1000);}}
   break;
  }}finally{e.release();}
  if(!Float.isFinite(fps)||fps<=0)fps=30;hdr=transfer==6||transfer==7;if(hdr){bits=Math.max(10,bits);peak=Math.max(1000,peak);}
  if(durationUs<=0||width<2||height<2)throw new Exception("没有读到有效视频。");
 }
 /* 依据原始尺寸与目标边长计算有效输出大小。 */ public int[] size(int edge){float scale=edge<=0?1:Math.min(1,(float)edge/Math.max(width,height));return new int[]{Math.max(2,(int)(width*scale)/2*2),Math.max(2,(int)(height*scale)/2*2)};}
 public static final class Cache implements AutoCloseable {
 public int w,h,frames,colorFlags;public boolean precision;public float sourcePeak=1000;public ByteBuffer bytes,grade;public double[] brightness;public double[][] chroma;public java.io.File backing;
 /* 取得单帧的独立视图，保持全局缓存读写位置不变。 */ public ByteBuffer frame(int i){ByteBuffer b=bytes.duplicate().order(ByteOrder.nativeOrder());int size=w*h*4;b.position(i*size);b.limit((i+1)*size);return b.slice().order(ByteOrder.nativeOrder());}
 /* 关闭缓存身份并删除可重建的磁盘文件，不修改输入视频。 */ public void close(){bytes=null;grade=null;if(backing!=null)backing.delete();}
}
/* 正式源缓存使用磁盘映射，避免4K时间样本全部占用Java堆。 */ public static Cache allocate(Context c,int w,int h,int count)throws Exception{
 long needed=(long)w*h*4*count;if(needed>Integer.MAX_VALUE-8)throw new Exception("时间缓存超过单块2GB，请减少时间样本；不会降低所选输出分辨率。");
 Cache out=new Cache();out.w=w;out.h=h;out.frames=count;
 if(needed>32L*1024*1024){
  if(c.getCacheDir().getUsableSpace()<needed+256L*1024*1024)throw new Exception("可用空间不足，准备素材需要约 "+needed/1024/1024+" MB。");
  out.backing=java.io.File.createTempFile("source-",".rgba",c.getCacheDir());
  try(java.io.RandomAccessFile file=new java.io.RandomAccessFile(out.backing,"rw")){file.setLength(needed);out.bytes=file.getChannel().map(java.nio.channels.FileChannel.MapMode.READ_WRITE,0,needed).order(ByteOrder.nativeOrder());}
 }else out.bytes=ByteBuffer.allocateDirect((int)needed).order(ByteOrder.nativeOrder());return out;
}
 /* 读取输入或资源并返回后续处理需要的数据。 */ /* 普通SDR沿用快速读取；HDR必须保留精度再做显示映射。 */
 public Cache read(int edge,int samples,AtomicBoolean cancel,Progress progress)throws Exception{return read(edge,samples,cancel,progress,hdr);}
 /* 导出格式需要高精度时，不经过ARGB8888中间帧。 */
 public Cache read(int edge,int samples,AtomicBoolean cancel,Progress progress,boolean precision)throws Exception{return precision||hdr?PrecisionDecoder.read(this,edge,samples,cancel,progress):read8(edge,samples,cancel,progress);}
 public Cache read8(int edge,int samples,AtomicBoolean cancel,Progress progress)throws Exception{
  int[] wh=size(edge);int count=Math.max(2,Math.min(samples<=0?Integer.MAX_VALUE:samples,(int)Math.ceil(durationUs/1e6*fps)));long needed=(long)wh[0]*wh[1]*4*count;
  Cache cache=allocate(context,wh[0],wh[1],count);int[] pixels=new int[cache.w*cache.h];
  try(MediaMetadataRetriever r=new MediaMetadataRetriever()){r.setDataSource(context,uri);MediaMetadataRetriever.BitmapParams bitmapParams=new MediaMetadataRetriever.BitmapParams();bitmapParams.setPreferredConfig(Bitmap.Config.ARGB_8888);ArrayList<Long> stamps=Build.VERSION.SDK_INT<30?timestamps():null;int frameCount=0;if(stamps!=null){String value=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT);if(value!=null)frameCount=Integer.parseInt(value);if(frameCount<1||stamps.isEmpty())throw new Exception("Android 10无法精确读取这段视频，请先转为标准H.264 MP4。");}for(int i=0;i<count;i++){ExportSafety.pace(context,cancel);long t=(long)(Math.max(0,durationUs-1e6/fps)*i/(count-1));Bitmap b;if(Build.VERSION.SDK_INT>=30)b=r.getScaledFrameAtTime(t,MediaMetadataRetriever.OPTION_CLOSEST,Math.max(cache.w,cache.h),Math.max(cache.w,cache.h),bitmapParams);else{int index=Collections.binarySearch(stamps,t);if(index<0)index=-index-1;if(index>=stamps.size())index=stamps.size()-1;if(index>0&&Math.abs(stamps.get(index-1)-t)<Math.abs(stamps.get(index)-t))index--;b=r.getFrameAtIndex(Math.min(frameCount-1,index),bitmapParams);}if(b==null)throw new Exception("读取第 "+(i+1)+" 个时间画面失败。");if(Math.abs((float)b.getWidth()/b.getHeight()-(float)cache.w/cache.h)>Math.abs((float)b.getHeight()/b.getWidth()-(float)cache.w/cache.h)){Matrix m=new Matrix();String a=r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);m.postRotate(a==null?90:Integer.parseInt(a));Bitmap rotated=Bitmap.createBitmap(b,0,0,b.getWidth(),b.getHeight(),m,true);b.recycle();b=rotated;}Bitmap sized=Bitmap.createScaledBitmap(b,cache.w,cache.h,true);if(sized!=b)b.recycle();sized.getPixels(pixels,0,cache.w,0,0,cache.w,cache.h);NativeCore.fromARGB(pixels,cache.bytes,i*cache.w*cache.h*4);sized.recycle();progress.update((i+1f)/count,"读取时间画面 "+(i+1)+"/"+count);}}
  catch(Exception error){cache.close();throw error;}
  return cache;
 }
 /* 生成与视频采样和输出帧率一致的时间戳。 */ private ArrayList<Long> timestamps()throws Exception{ArrayList<Long> times=new ArrayList<>();MediaExtractor e=new MediaExtractor();try{e.setDataSource(context,uri,null);int track=-1;for(int i=0;i<e.getTrackCount();i++){String m=e.getTrackFormat(i).getString(MediaFormat.KEY_MIME);if(m!=null&&m.startsWith("video/")){track=i;break;}}if(track<0)return times;e.selectTrack(track);while(e.getSampleTime()>=0){times.add(e.getSampleTime());if(times.size()>1000000)throw new Exception("素材过长，请先裁剪要处理的片段。");if(!e.advance())break;}}finally{e.release();}Collections.sort(times);return times;}
 /* 检查取消标志或输入约束，必要时中止当前任务。 */ public static void check(AtomicBoolean c)throws Exception{if(c.get())throw new Exception("已取消，已经导出的视频保留。");}
}
