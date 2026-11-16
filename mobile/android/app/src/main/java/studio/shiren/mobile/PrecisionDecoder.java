package studio.shiren.mobile;

import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.media.*;
import java.nio.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** 直接读取解码器YUV/P010平面，禁止HDR/10位经过ARGB8888 Bitmap。 */
final class PrecisionDecoder {
    /* 顺序硬件解码并按时间采样，正式缓存保存RGB10而非8位截图。 */
    static VideoSource.Cache read(VideoSource source,int edge,int samples,AtomicBoolean stop,VideoSource.Progress progress)throws Exception{return read(source,edge,samples,stop,progress,false);}
    /* 成片核验只读第一帧，不为验证而重放整部影片。 */
    static VideoSource.Cache first(VideoSource source,AtomicBoolean stop)throws Exception{return read(source,0,2,stop,(p,t)->{},true);}
    /* 是否仅读首帧只影响验证缓存，正常源读取仍遍历采样时间。 */
    private static VideoSource.Cache read(VideoSource source,int edge,int samples,AtomicBoolean stop,VideoSource.Progress progress,boolean firstOnly)throws Exception{
        VideoColor.requirePrecision();
        int[] size=source.size(edge);int count=samples>0?Math.max(2,samples):Math.max(2,(int)Math.ceil(source.durationUs/1e6*source.fps));
        VideoSource.Cache cache=VideoSource.allocate(source.context,size[0],size[1],count);cache.precision=true;cache.colorFlags=VideoColor.sourceFlags(source.standard,source.transfer);cache.sourcePeak=source.peak;
        MediaExtractor input=new MediaExtractor();MediaCodec codec=null;boolean started=false;
        try{
            input.setDataSource(source.context,source.uri,null);int track=-1;MediaFormat format=null;
            for(int i=0;i<input.getTrackCount();i++){MediaFormat f=input.getTrackFormat(i);if(f.getString(MediaFormat.KEY_MIME).startsWith("video/")){track=i;format=f;break;}}
            if(track<0)throw new Exception("没有找到视频轨");input.selectTrack(track);
            format.setInteger(MediaFormat.KEY_COLOR_FORMAT,source.bits>8?54:MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible);
            format.setInteger(MediaFormat.KEY_ROTATION,0);format.setInteger(MediaFormat.KEY_COLOR_STANDARD,source.standard);format.setInteger(MediaFormat.KEY_COLOR_TRANSFER,source.transfer);format.setInteger(MediaFormat.KEY_COLOR_RANGE,source.range);
            codec=MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME));codec.configure(format,null,null,0);codec.start();started=true;
            MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();boolean inputEnd=false,outputEnd=false;int selected=0,maximum=0,idle=0;
            while(!outputEnd&&selected<count){
                VideoSource.check(stop);
                if(!inputEnd){int index=codec.dequeueInputBuffer(10000);if(index>=0){ByteBuffer b=codec.getInputBuffer(index);int n=input.readSampleData(b,0);if(n<0){codec.queueInputBuffer(index,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{codec.queueInputBuffer(index,0,n,input.getSampleTime(),input.getSampleFlags());input.advance();}}}
                int index=codec.dequeueOutputBuffer(info,10000);
                if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){MediaFormat actual=codec.getOutputFormat();if(source.hdr&&(!actual.containsKey(MediaFormat.KEY_COLOR_TRANSFER)||actual.getInteger(MediaFormat.KEY_COLOR_TRANSFER)!=source.transfer))throw new Exception("解码器没有保留源HDR传递函数，已停止处理。");idle=0;continue;}
                if(index<0){if(++idle>3000)throw new Exception("10位解码等待超时");continue;}idle=0;
                try{
                    outputEnd=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;
                    long wanted=(long)(Math.max(0,source.durationUs-1e6/source.fps)*selected/(count-1));
                    if(info.size>0&&info.presentationTimeUs+500000/source.fps>=wanted){
                        try(Image image=codec.getOutputImage(index)){
                            if(image==null)throw new Exception("此解码器不支持直接读取高精度图像平面");
                            boolean ten=image.getFormat()==ImageFormat.YCBCR_P010;if(source.bits>8&&!ten)throw new Exception("解码器将10位素材降为8位，已停止处理");
                            Image.Plane[] planes=image.getPlanes();if(planes.length<2)throw new Exception("解码平面格式不支持");
                            ByteBuffer y=planes[0].getBuffer().duplicate().slice(),u=planes[1].getBuffer().duplicate().slice(),v;
                            int up=planes[1].getPixelStride(),ur=planes[1].getRowStride(),vp,vr;
                            if(planes.length>=3){v=planes[2].getBuffer().duplicate().slice();vp=planes[2].getPixelStride();vr=planes[2].getRowStride();}
                            else{ByteBuffer copy=u.duplicate();copy.position(ten?2:1);v=copy.slice();vp=up=ten?4:2;vr=ur;}
                            Rect crop=image.getCropRect();int peak=NativeCore.yuvToRGB10(y,planes[0].getRowStride(),planes[0].getPixelStride(),u,ur,up,v,vr,vp,image.getWidth(),image.getHeight(),crop.left,crop.top,crop.width(),crop.height(),ten?10:8,source.range,source.standard,source.rotation,cache.frame(selected),cache.w,cache.h);
                            if(peak<0)throw new Exception("高精度解码平面尺寸没有通过检查");maximum=Math.max(maximum,peak);selected++;if(firstOnly)outputEnd=true;progress.update(selected/(float)count,"读取高精度画面 "+selected+"/"+count);
                        }
                    }
                }finally{codec.releaseOutputBuffer(index,false);}
            }
            if(selected==0)throw new Exception("没有读取到高精度画面");
            if(selected<count){ByteBuffer last=cache.frame(selected-1);byte[] copy=new byte[last.remaining()];last.get(copy);while(selected<count)cache.frame(selected++).put(copy);}
            if(source.hdr)cache.sourcePeak=Math.max(cache.sourcePeak,Math.min(10000,VideoColor.observedPeak(maximum,source.transfer)));
            return cache;
        }catch(Exception error){cache.close();throw error;}
        finally{if(codec!=null){if(started)try{codec.stop();}catch(Exception ignored){}codec.release();}input.release();}
    }
}
