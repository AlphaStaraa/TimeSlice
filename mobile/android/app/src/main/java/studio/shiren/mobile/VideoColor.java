package studio.shiren.mobile;

import android.media.MediaFormat;
import android.os.Build;
import java.nio.ByteBuffer;

/** 共用色彩枚举和内核标志，10位能力必须由真实P010和SPS确认。 */
public final class VideoColor {
    public static final String[] FORMATS={"h264","hevc10","hdr_pq","hdr_hlg"};
    public static final int SOURCE10=8192,OUTPUT10=16384,SOURCE_PQ=32768,SOURCE_HLG=65536,
        OUTPUT_PQ=131072,OUTPUT_HLG=262144,SOURCE2020=524288;
    private VideoColor() {}

    /* 严格校验输出枚举，未知格式不降为兼容模式。 */
    public static boolean high(String mode){for(String value:FORMATS)if(value.equals(mode))return !mode.equals("h264");throw new IllegalArgumentException("不支持的输出格式");}
    /* HDR输入以及10位输出从源解码开始采用RGB10缓存。 */
    public static boolean precision(VideoSource source,String mode){return high(mode)||source.hdr;}
    /* 从源媒体描述建立共用标志，不在这里改变视频代码值。 */
    public static int sourceFlags(int standard,int transfer){return (standard==MediaFormat.COLOR_STANDARD_BT2020?SOURCE2020:0)|(transfer==MediaFormat.COLOR_TRANSFER_ST2084?SOURCE_PQ:transfer==MediaFormat.COLOR_TRANSFER_HLG?SOURCE_HLG:0);}
    /* 帧快照明确选择真实输出布局；普通主预览使用SDR RGBA8。 */
    public static int flags(VideoSource.Cache cache,String mode){return cache.colorFlags|(cache.precision?SOURCE10:0)|(high(mode)?OUTPUT10:0)|(mode.equals("hdr_pq")?OUTPUT_PQ:mode.equals("hdr_hlg")?OUTPUT_HLG:0);}
    /* 10位P010直读路径要求Android13以上，旧设备仍可用8位兼容格式。 */
    public static void requirePrecision(){if(Build.VERSION.SDK_INT<33)throw new IllegalArgumentException("10位/HDR需要Android13以上的P010编解码支持，请选择H.264兼容格式。");}
    /* 建立符合目标色域、传递函数和有限范围的编码格式。 */
    public static MediaFormat format(int w,int h,int fps,int bitrate,String mode){
        boolean high=high(mode),hdr=mode.equals("hdr_pq")||mode.equals("hdr_hlg");
        if(high)requirePrecision();
        MediaFormat f=MediaFormat.createVideoFormat(high?"video/hevc":"video/avc",w,h);
        f.setInteger(MediaFormat.KEY_COLOR_FORMAT,high?54:android.media.MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible);
        if(high)f.setInteger(MediaFormat.KEY_PROFILE,android.media.MediaCodecInfo.CodecProfileLevel.HEVCProfileMain10);
        f.setInteger(MediaFormat.KEY_BIT_RATE,ExportQuality.resolve(w,h,fps,bitrate));
        f.setInteger(MediaFormat.KEY_FRAME_RATE,fps);f.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL,1);
        f.setInteger(MediaFormat.KEY_COLOR_STANDARD,hdr?MediaFormat.COLOR_STANDARD_BT2020:MediaFormat.COLOR_STANDARD_BT709);
        f.setInteger(MediaFormat.KEY_COLOR_TRANSFER,mode.equals("hdr_pq")?MediaFormat.COLOR_TRANSFER_ST2084:mode.equals("hdr_hlg")?MediaFormat.COLOR_TRANSFER_HLG:MediaFormat.COLOR_TRANSFER_SDR_VIDEO);
        f.setInteger(MediaFormat.KEY_COLOR_RANGE,MediaFormat.COLOR_RANGE_LIMITED);
        return f;
    }
    /* 将源峰值代码转换成亮度，用于HDR到SDR/HLG的高光映射。 */
    public static float observedPeak(int code,int transfer){
        double v=code/1023.;if(transfer==MediaFormat.COLOR_TRANSFER_ST2084){double p=Math.pow(v,32./2523);return(float)(10000*Math.pow(Math.max(p-3424./4096,0)/Math.max(2413./128-2392./128*p,1e-9),16384./2610));}
        if(transfer==MediaFormat.COLOR_TRANSFER_HLG){double scene=v<=.5?v*v/3:(Math.exp((v-.55991073)/.17883277)+.28466892)/12;return(float)(1000*Math.pow(scene,1.2));}
        return 203;
    }
    /* 复制缓存色彩身份，防止预览缩小或源处理丢失位深描述。 */
    public static void copy(VideoSource.Cache source,VideoSource.Cache target){target.precision=source.precision;target.colorFlags=source.colorFlags;target.sourcePeak=source.sourcePeak;}
}
