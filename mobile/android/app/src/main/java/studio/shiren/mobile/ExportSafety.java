package studio.shiren.mobile;

import android.content.Context;
import android.media.*;
import android.os.PowerManager;
import java.util.concurrent.atomic.AtomicBoolean;

/** 导出能力与热状态预检；提醒不擅自改变用户的输出质量。 */
public final class ExportSafety {
    public static final class Assessment {
        public boolean highLoad,hardwareSupported;
        public String encoder="";
        public long targetBytes,cacheBytes;
    }

    /* 分开检查尺寸、帧率和目标码率，不能只看手机能否播放4K。 */
    public static Assessment inspect(int w,int h,int fps,int bitrate,int samples,float seconds){
        Assessment result=new Assessment();int bits=bitrate>0?bitrate:Math.max(2000000,(int)(w*(long)h*fps*.15));
        result.highLoad=Math.max(w,h)>=2560||fps>=50||bits>=35000000;
        result.targetBytes=(long)(bits/8.*seconds);result.cacheBytes=(long)w*h*4*samples;
        for(MediaCodecInfo codec:new MediaCodecList(MediaCodecList.REGULAR_CODECS).getCodecInfos()){
            if(!codec.isEncoder())continue;
            try{
                MediaCodecInfo.CodecCapabilities caps=codec.getCapabilitiesForType("video/avc");
                MediaCodecInfo.VideoCapabilities video=caps.getVideoCapabilities();
                if(video!=null&&video.areSizeAndRateSupported(w,h,fps)&&video.getBitrateRange().contains(bits)){
                    result.encoder=codec.getName();if(codec.isHardwareAccelerated()){result.hardwareSupported=true;break;}
                }
            }catch(IllegalArgumentException ignored){/* 该编码器不支持AVC，继续核查其他编码器。 */}
        }
        return result;
    }

    /* 用系统热状态提示减速；临界高温安全取消当前片段并保留已完成输出。 */
    public static int pace(Context context,AtomicBoolean stop)throws Exception{
        VideoSource.check(stop);PowerManager power=(PowerManager)context.getSystemService(Context.POWER_SERVICE);
        int status=power==null?PowerManager.THERMAL_STATUS_NONE:power.getCurrentThermalStatus();
        if(status>=PowerManager.THERMAL_STATUS_CRITICAL)throw new Exception("设备温度过高，当前导出已安全停止，已完成视频保留。请等待降温后继续。");
        if(status>=PowerManager.THERMAL_STATUS_SEVERE)Thread.sleep(120);
        else if(status>=PowerManager.THERMAL_STATUS_MODERATE)Thread.sleep(35);
        return status;
    }
}
