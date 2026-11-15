package studio.shiren.mobile;
import android.content.Context;import android.net.Uri;import java.io.*;import java.nio.*;import java.util.*;import java.util.concurrent.atomic.AtomicBoolean;
public final class VideoEncoder implements AutoCloseable {
 private static final Map<String,Boolean> compatibility=new HashMap<>();private SystemVideoEncoder system;private CompatibleEncoder fallback;public final String label;
 public static boolean testCompatibilityOnly=false;
 /* 初始化视频编码与封装状态。 */ public VideoEncoder(Context c,Uri source,File output,int w,int h,int fps,boolean sound,AtomicBoolean stop)throws Exception{
  this(c,source,output,w,h,fps,sound,stop,0);
 }
 /* 为目标码率单独做编码画面自检，不能把自动码率的结果冒充为手动参数。 */ public VideoEncoder(Context c,Uri source,File output,int w,int h,int fps,boolean sound,AtomicBoolean stop,int bitrate)throws Exception{
  String key=w+"x"+h+"@"+fps+"/"+bitrate;Boolean soft=compatibility.get(key);
  if(testCompatibilityOnly)soft=true;
  if(soft==null){File probe=new File(c.getCacheDir(),"codec_check_"+UUID.randomUUID()+".mp4");ByteBuffer pattern=ByteBuffer.allocateDirect(w*h*4);for(int y=0;y<h;y++)for(int x=0;x<w;x++){int q=(x<w/2?0:1)+(y<h/2?0:2);pattern.put((byte)(q==0||q==3?220:24));pattern.put((byte)(q==1||q==3?180:32));pattern.put((byte)(q==2||q==3?150:40));pattern.put((byte)255);}pattern.rewind();try{try(SystemVideoEncoder e=new SystemVideoEncoder(c,source,probe,w,h,fps,false,stop,bitrate)){e.append(pattern,0);e.append(pattern,1);e.finish(2f/fps);}VideoValidator.check(probe,pattern,w,h);soft=false;}catch(Exception failure){VideoSource.check(stop);soft=true;android.util.Log.w("ShirenEncoder","系统编码自检未通过，使用兼容软件编码",failure);}finally{probe.delete();}compatibility.put(key,soft);}
  if(soft&&bitrate>0)throw new Exception("系统编码无法可靠输出所选目标码率，请改为自动码率或调整分辨率、帧率。");
  if(soft){fallback=new CompatibleEncoder(c,source,output,w,h,fps,sound,stop);label="兼容软件编码（较慢）";}else{system=new SystemVideoEncoder(c,source,output,w,h,fps,sound,stop,bitrate);label="系统编码 · "+system.codecName;}
 }
 /* 追加当前视频帧或音轨数据并维护时间戳。 */ public void append(ByteBuffer rgba,int frame)throws Exception{if(system!=null)system.append(rgba,frame);else fallback.append(rgba,frame);}
 /* 完成当前任务并释放编码或缓存资源。 */ public void finish(float seconds)throws Exception{if(system!=null)system.finish(seconds);else fallback.finish(seconds);}
 /* 关闭当前对象持有的资源，避免重复占用文件、线程或设备。 */ public void close(){if(system!=null)system.close();if(fallback!=null)fallback.close();}
}
