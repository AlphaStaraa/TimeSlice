package studio.shiren.mobile;

import android.content.Context;
import android.graphics.Rect;
import android.media.*;
import android.net.Uri;
import android.os.Build;
import java.io.File;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;

/** 系统编码器：RGBA8到AVC，真实RGB10到HEVC P010。 */
public final class SystemVideoEncoder implements AutoCloseable {
    private MediaCodec codec;
    private MediaMuxer muxer;
    private MediaExtractor audio;
    private MediaFormat audioFormat,configured;
    private int track=-1,audioTrack=-1,colorFormat,stride,sliceHeight;
    private boolean started;
    private ByteBuffer staging;
    private final int width,height,fps;
    private final AtomicBoolean cancel;
    private final String mode,mime;
    private final boolean high;
    public String codecName;

    /* 保留现有兼容接口。 */
    public SystemVideoEncoder(Context c,Uri source,File file,int w,int h,int rate,boolean sound,AtomicBoolean stop)throws Exception{this(c,source,file,w,h,rate,sound,stop,0,"h264");}
    /* 手动码率沿用H.264，格式由新重载明确指定。 */
    public SystemVideoEncoder(Context c,Uri source,File file,int w,int h,int rate,boolean sound,AtomicBoolean stop,int bits)throws Exception{this(c,source,file,w,h,rate,sound,stop,bits,"h264");}
    /* 按所选格式配置，不把不支持的Main10转换为8位。 */
    public SystemVideoEncoder(Context context,Uri source,File file,int w,int h,int rate,boolean sound,AtomicBoolean stop,int bits,String format)throws Exception{
        width=w;height=h;fps=rate;cancel=stop;mode=format;high=VideoColor.high(mode);mime=high?"video/hevc":"video/avc";
        try{
            if(sound){audio=new MediaExtractor();audio.setDataSource(context,source,null);for(int i=0;i<audio.getTrackCount();i++){MediaFormat f=audio.getTrackFormat(i);String type=f.getString(MediaFormat.KEY_MIME);if(type!=null&&type.startsWith("audio/")){if(!type.equals("audio/mp4a-latm"))throw new Exception("原声目前支持AAC，请关闭保留原声后导出。");audio.selectTrack(i);audio.seekTo(0,MediaExtractor.SEEK_TO_NEXT_SYNC);if(audio.getSampleTime()>=0)audioFormat=f;break;}}}
            configured=VideoColor.format(w,h,rate,bits,mode);
            String name=new MediaCodecList(MediaCodecList.REGULAR_CODECS).findEncoderForFormat(configured);
            if(name==null)throw new Exception(high?"设备不支持所选尺寸/帧率的HEVC Main10 P010编码，请调整规格或选择H.264。":"当前手机无法编码所选尺寸和帧率。");
            if(!high&&Build.VERSION.SDK_INT<=29&&name.startsWith("c2.android."))for(MediaCodecInfo item:new MediaCodecList(MediaCodecList.REGULAR_CODECS).getCodecInfos())if(item.isEncoder()&&item.getName().startsWith("OMX.google."))for(String type:item.getSupportedTypes())if(type.equals(mime)&&item.getCapabilitiesForType(type).isFormatSupported(configured)){name=item.getName();break;}
            codec=MediaCodec.createByCodecName(name);codecName=name;
            MediaCodecInfo.CodecCapabilities caps=codec.getCodecInfo().getCapabilitiesForType(mime);
            colorFormat=high?54:MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible;
            if(high){boolean found=false;for(int value:caps.colorFormats)if(value==54)found=true;if(!found)throw new Exception("此HEVC编码器没有可直接写入的10位P010平面，已停止以避免位深降级。");}
            else{for(int value:caps.colorFormats)if(value==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar){colorFormat=value;break;}if(colorFormat==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)for(int value:caps.colorFormats)if(value==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar){colorFormat=value;break;}}
            configured.setInteger(MediaFormat.KEY_COLOR_FORMAT,colorFormat);
            if(caps.getEncoderCapabilities().isBitrateModeSupported(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR))configured.setInteger(MediaFormat.KEY_BITRATE_MODE,MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR);
            configured.setInteger(MediaFormat.KEY_STRIDE,w);configured.setInteger(MediaFormat.KEY_SLICE_HEIGHT,h);
            codec.configure(configured,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE);codec.start();
            MediaFormat accepted=codec.getInputFormat();stride=Math.max(w,accepted.containsKey(MediaFormat.KEY_STRIDE)?accepted.getInteger(MediaFormat.KEY_STRIDE):w);sliceHeight=Math.max(h,accepted.containsKey(MediaFormat.KEY_SLICE_HEIGHT)?accepted.getInteger(MediaFormat.KEY_SLICE_HEIGHT):h);
            android.util.Log.i("ShirenEncoder","format="+accepted+" requested="+mode);
            muxer=new MediaMuxer(file.getAbsolutePath(),MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        }catch(Exception error){close();throw error;}
    }

    /* 等待可写输入，同时排空编码输出并响应取消。 */
    private int input()throws Exception{for(int n=0;n<1500;n++){VideoSource.check(cancel);int index=codec.dequeueInputBuffer(10000);if(index>=0)return index;drain(false);}throw new Exception("编码器没有响应，请调整输出规格。");}
    /* 取得独立的平面区间，不改变缓冲区全局位置。 */
    private ByteBuffer region(ByteBuffer b,int start,int size){ByteBuffer view=b.duplicate();view.position(start);view.limit(start+size);return view.slice();}
    /* 按裁切起点定位图像平面。 */
    private ByteBuffer plane(Image.Plane p,int x,int y){ByteBuffer b=p.getBuffer().duplicate();b.position(b.position()+y*p.getRowStride()+x*p.getPixelStride());return b.slice();}

    /* 对每一帧选用真正的8位或10位平面写入器。 */
    public void append(ByteBuffer rgba,int frame)throws Exception{
        VideoSource.check(cancel);int index=input();ByteBuffer target=codec.getInputBuffer(index);if(target==null)throw new Exception("编码输入不可用");int bytes=target.capacity();
        if(high){
            Image image=codec.getInputImage(index);
            if(image!=null){
                Image.Plane[] p=image.getPlanes();Rect crop=image.getCropRect();
                if(image.getFormat()!=54||p.length<2||crop.width()<width||crop.height()<height)throw new Exception("编码器未提供正确的P010图像布局。");
                ByteBuffer y=plane(p[0],crop.left,crop.top),u=plane(p[1],crop.left/2,crop.top/2),v;int up=p[1].getPixelStride(),ur=p[1].getRowStride(),vp,vr;
                if(p.length>=3){v=plane(p[2],crop.left/2,crop.top/2);vp=p[2].getPixelStride();vr=p[2].getRowStride();}else{ByteBuffer b=u.duplicate();b.position(2);v=b.slice();up=vp=4;vr=ur;}
                if(!NativeCore.rgb10ToP010(rgba,width,height,y,p[0].getRowStride(),p[0].getPixelStride(),u,ur,up,v,vr,vp,mode.startsWith("hdr_")))throw new Exception("P010平面容量没有通过检查。");
            }else{
                int row=stride*2,ys=row*sliceHeight,uv=row*((sliceHeight+1)/2),total=ys+uv;
                if(total>bytes&&stride>=width*2){row=stride;ys=row*sliceHeight;uv=row*((sliceHeight+1)/2);total=ys+uv;}
                if(total>bytes)throw new Exception("编码器P010缓冲区不足。");if(staging==null||staging.capacity()<total)staging=ByteBuffer.allocateDirect(total);
                if(!NativeCore.rgb10ToP010(rgba,width,height,region(staging,0,ys),row,2,region(staging,ys,uv),row,4,region(staging,ys+2,uv-2),row,4,mode.startsWith("hdr_")))throw new Exception("P010像素写入失败。");
                staging.position(0);staging.limit(total);target.clear();target.put(staging);bytes=total;
            }
        }else if(colorFormat!=MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible){
            int ys=stride*sliceHeight,uvStride=colorFormat==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar?(stride+1)/2:stride,uvSize=uvStride*((sliceHeight+1)/2),total=colorFormat==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar?ys+uvSize*2:ys+uvSize;
            if(total>bytes)throw new Exception("编码缓冲不足");if(staging==null||staging.capacity()<total)staging=ByteBuffer.allocateDirect(total);int pixel=colorFormat==MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar?1:2;
            if(!NativeCore.rgbaToYuv(rgba,width,height,region(staging,0,ys),stride,1,region(staging,ys,uvSize),uvStride,pixel,region(staging,pixel==1?ys+uvSize:ys+1,pixel==1?uvSize:uvSize-1),uvStride,pixel))throw new Exception("编码像素写入失败");
            staging.position(0);staging.limit(total);target.clear();target.put(staging);bytes=total;
        }else{
            Image image=codec.getInputImage(index);if(image==null)throw new Exception("编码器不支持可写YUV图像");Image.Plane[] p=image.getPlanes();Rect crop=image.getCropRect();if(p.length!=3||crop.width()<width||crop.height()<height)throw new Exception("编码图像尺寸不正确");
            if(!NativeCore.rgbaToYuv(rgba,width,height,plane(p[0],crop.left,crop.top),p[0].getRowStride(),p[0].getPixelStride(),plane(p[1],crop.left/2,crop.top/2),p[1].getRowStride(),p[1].getPixelStride(),plane(p[2],crop.left/2,crop.top/2),p[2].getRowStride(),p[2].getPixelStride()))throw new Exception("编码图像缓冲不完整");
        }
        codec.queueInputBuffer(index,0,bytes,frame*1000000L/fps,0);drain(false);
    }

    /* 编码器产生轨道信息时检查实际SPS和色彩参数，再交给封装器。 */
    private void drain(boolean end)throws Exception{
        MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();int waits=0;
        while(true){VideoSource.check(cancel);int index=codec.dequeueOutputBuffer(info,end?10000:0);
            if(index==MediaCodec.INFO_TRY_AGAIN_LATER){if(!end)return;if(++waits>1500)throw new Exception("视频编码超时");}
            else if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){
                MediaFormat actual=codec.getOutputFormat();
                if(high){if(actual.getByteBuffer("csd-0")==null||HevcSps.depth(actual.getByteBuffer("csd-0"))!=10)throw new Exception("编码器实际输出不是10位，视频不会保存。");for(String key:new String[]{MediaFormat.KEY_COLOR_STANDARD,MediaFormat.KEY_COLOR_TRANSFER,MediaFormat.KEY_COLOR_RANGE})if(!actual.containsKey(key)||actual.getInteger(key)!=configured.getInteger(key))throw new Exception("编码器实际色彩标记与目标不一致，视频不会保存。");}
                track=muxer.addTrack(actual);if(audioFormat!=null)audioTrack=muxer.addTrack(audioFormat);muxer.start();started=true;
            }else if(index>=0){
                ByteBuffer data=codec.getOutputBuffer(index);if((info.flags&MediaCodec.BUFFER_FLAG_CODEC_CONFIG)!=0)info.size=0;
                if(info.size>0){if(!started)throw new Exception("编码轨道尚未就绪");data.position(info.offset);data.limit(info.offset+info.size);ByteBuffer copy=ByteBuffer.allocate(info.size);copy.put(data);copy.flip();MediaCodec.BufferInfo owned=new MediaCodec.BufferInfo();owned.set(0,info.size,info.presentationTimeUs,info.flags);muxer.writeSampleData(track,copy,owned);}
                boolean eos=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;codec.releaseOutputBuffer(index,false);if(eos)return;
            }
        }
    }
    /* 完成视频，再原样复制受支持的AAC音轨。 */
    public void finish(float seconds)throws Exception{int i=input();codec.queueInputBuffer(i,0,0,(long)(seconds*1000000),MediaCodec.BUFFER_FLAG_END_OF_STREAM);drain(true);if(audioTrack>=0){ByteBuffer bytes=ByteBuffer.allocateDirect(1024*1024);MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();long first=audio.getSampleTime();while(audio.getSampleTime()>=0&&audio.getSampleTime()-first<(long)(seconds*1e6)){VideoSource.check(cancel);bytes.clear();int n=audio.readSampleData(bytes,0);if(n<0)break;info.set(0,n,audio.getSampleTime()-first,audio.getSampleFlags());muxer.writeSampleData(audioTrack,bytes,info);audio.advance();}}muxer.stop();started=false;}
    /* 任何失败都释放资源，半成品由上层删除。 */
    public void close(){if(codec!=null){try{codec.stop();}catch(Exception ignored){}codec.release();codec=null;}if(muxer!=null){if(started)try{muxer.stop();}catch(Exception ignored){}muxer.release();muxer=null;}if(audio!=null){audio.release();audio=null;}}
}
