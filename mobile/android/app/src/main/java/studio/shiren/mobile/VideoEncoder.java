package studio.shiren.mobile;

import android.content.Context;
import android.net.Uri;
import java.io.File;
import java.nio.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** 格式、尺寸、帧率和码率分别探测，Main10失败时不走8位软件兜底。 */
public final class VideoEncoder implements AutoCloseable {
    private static final Map<String,Boolean> compatibility=new HashMap<>();
    private SystemVideoEncoder system;private CompatibleEncoder fallback;
    public final String label;
    public static boolean testCompatibilityOnly=false;
    /* 保留原有兼容输出接口。 */
    public VideoEncoder(Context c,Uri src,File out,int w,int h,int fps,boolean sound,AtomicBoolean stop)throws Exception{this(c,src,out,w,h,fps,sound,stop,0,"h264");}
    /* 手动码率接口保持兼容。 */
    public VideoEncoder(Context c,Uri src,File out,int w,int h,int fps,boolean sound,AtomicBoolean stop,int bits)throws Exception{this(c,src,out,w,h,fps,sound,stop,bits,"h264");}
    /* 用实际编码和解码检查格式，不能拿8位探测冒充Main10能力。 */
    public VideoEncoder(Context c,Uri src,File out,int w,int h,int fps,boolean sound,AtomicBoolean stop,int bits,String mode)throws Exception{
        boolean high=VideoColor.high(mode);String key=mode+"/"+w+"x"+h+"@"+fps+"/"+bits;Boolean soft=compatibility.get(key);
        if(testCompatibilityOnly)soft=true;
        if(soft==null){
            File probe=new File(c.getCacheDir(),"codec_check_"+UUID.randomUUID()+".mp4");ByteBuffer pattern=ByteBuffer.allocateDirect(w*h*4).order(ByteOrder.LITTLE_ENDIAN);
            for(int y=0;y<h;y++)for(int x=0;x<w;x++){
                if(high){int v=x*1023/Math.max(1,w-1);pattern.putInt((3<<30)|(v<<20)|(v<<10)|v);}
                else{int q=(x<w/2?0:1)+(y<h/2?0:2);pattern.put((byte)(q==0||q==3?220:24));pattern.put((byte)(q==1||q==3?180:32));pattern.put((byte)(q==2||q==3?150:40));pattern.put((byte)255);}
            }pattern.rewind();
            try{
                try(SystemVideoEncoder e=new SystemVideoEncoder(c,src,probe,w,h,fps,false,stop,bits,mode)){e.append(pattern,0);e.append(pattern,1);e.finish(2f/fps);}
                VideoValidator.check(c,probe,pattern,w,h,mode,stop);soft=false;
            }catch(Exception failure){VideoSource.check(stop);if(high)throw new Exception("设备未通过真正的HEVC Main10/P010编码核验："+failure.getMessage(),failure);soft=true;android.util.Log.w("ShirenEncoder","系统编码核验失败，使用兼容软件编码",failure);}
            finally{probe.delete();}compatibility.put(key,soft);
        }
        if(soft&&high)throw new Exception("当前设备没有可靠的10位编码通路，请选择H.264兼容格式。");
        if(soft&&bits>0)throw new Exception("系统编码无法可靠输出所选目标码率，请改为推荐或调整输出规格。");
        if(soft){fallback=new CompatibleEncoder(c,src,out,w,h,fps,sound,stop);label="兼容软件编码（较慢）";}
        else{system=new SystemVideoEncoder(c,src,out,w,h,fps,sound,stop,bits,mode);label="系统编码 · "+system.codecName+(high?" · Main10":"");}
    }
    /* 追加真实目标布局的帧，不再做RGB8中转。 */
    public void append(ByteBuffer rgb,int frame)throws Exception{if(system!=null)system.append(rgb,frame);else fallback.append(rgb,frame);}
    /* 完成封装与音频复制。 */
    public void finish(float seconds)throws Exception{if(system!=null)system.finish(seconds);else fallback.finish(seconds);}
    /* 关闭当前编码资源。 */
    public void close(){if(system!=null)system.close();if(fallback!=null)fallback.close();}
}
