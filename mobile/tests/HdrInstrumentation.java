package studio.shiren.mobile;

import android.app.*;
import android.content.*;
import android.media.*;
import android.net.Uri;
import android.os.*;
import android.provider.MediaStore;
import java.io.*;
import java.nio.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.*;

/** 只在验证助手内运行：检查真实RGB10缓存、Main10编码和PQ/HLG像素。 */
public final class HdrInstrumentation extends Instrumentation {
    final JSONObject report=new JSONObject();final JSONArray outputs=new JSONArray();
    final AtomicBoolean stop=new AtomicBoolean();File folder;Activity activity;
    /* 显式启动验证，不加入正式应用后台流程。 */
    @Override public void onCreate(Bundle args){super.onCreate(args);start();}
    /* 证据只写本轮下载子目录。 */
    void publish(File file)throws Exception{
        ContentValues values=new ContentValues();values.put(MediaStore.MediaColumns.DISPLAY_NAME,file.getName());values.put(MediaStore.MediaColumns.RELATIVE_PATH,"Download/TimeSliceHDR106");values.put(MediaStore.MediaColumns.MIME_TYPE,file.getName().endsWith(".mp4")?"video/mp4":"application/json");values.put(MediaStore.MediaColumns.IS_PENDING,1);
        Uri uri=getTargetContext().getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,values);
        try(InputStream in=new FileInputStream(file);OutputStream out=getTargetContext().getContentResolver().openOutputStream(uri)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}
        values.clear();values.put(MediaStore.MediaColumns.IS_PENDING,0);getTargetContext().getContentResolver().update(uri,values,null,null);
    }
    /* 从测试APK取标准源，不访问用户的相册。 */
    File fixture(String name)throws Exception{File file=new File(folder,name);try(InputStream in=getContext().getAssets().open("validation/"+name);OutputStream out=new FileOutputStream(file)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}return file;}
    /* 统计真实10位像素级数，RGBA8升格只会剩至多256级。 */
    int levels(ByteBuffer data,int width,int height){boolean[] seen=new boolean[1024];ByteBuffer b=data.duplicate().order(ByteOrder.LITTLE_ENDIAN);for(int y=0;y<height;y++)for(int x=0;x<width;x++)seen[(b.getInt((y*width+x)*4)>>>20)&1023]=true;int count=0;for(boolean value:seen)if(value)count++;return count;}
    /* 记录设备宣称的P010能力，实际输出仍要单独通过SPS和解码核验。 */
    JSONArray capabilities()throws Exception{JSONArray list=new JSONArray();for(MediaCodecInfo c:new MediaCodecList(MediaCodecList.REGULAR_CODECS).getCodecInfos()){if(!c.isEncoder())continue;for(String type:c.getSupportedTypes())if(type.equals("video/hevc")){MediaCodecInfo.CodecCapabilities caps=c.getCapabilitiesForType(type);JSONArray colors=new JSONArray(),profiles=new JSONArray();for(int f:caps.colorFormats)colors.put(f);for(MediaCodecInfo.CodecProfileLevel p:caps.profileLevels)profiles.put(p.profile);list.put(new JSONObject().put("name",c.getName()).put("colors",colors).put("profiles",profiles));}}return list;}
    /* 读取真实10位源并经过正式渲染器、编码器与核验器。 */
    void exportCase(String name,String mode,boolean processing)throws Exception{
        Context context=getTargetContext();VideoSource source=new VideoSource(context,Uri.fromFile(fixture(name)));
        try(VideoSource.Cache base=source.read(1024,4,stop,(p,t)->{},true);Renderer renderer=new Renderer(context,"gpu")){
            int sourceLevels=levels(base.frame(0),base.w,base.h);if(sourceLevels<=400)throw new Exception("Decoded cache lost precision: "+sourceLevels);
            VideoSource.Cache cache=base;SourceProcessor.Result processed=null;
            try{
                if(processing){SourceOptions options=new SourceOptions();options.deflicker="light";processed=SourceProcessor.process(context,base,options,stop,(p,t)->{});cache=processed.cache;if(!cache.precision||levels(cache.frame(0),cache.w,cache.h)<=400)throw new Exception("Processing dropped precision");}
                Effect effect=null;for(Effect e:Effect.load(context))if(e.id==100)effect=e;
                Effect.Settings settings=effect.defaults();settings.playback=0;settings.exportFormat=mode;settings.exportDither=true;
                ByteBuffer first=renderer.frame(cache,effect,settings,0,1);
                int composed=levels(first,cache.w,cache.h);if(composed<=400)throw new Exception("Compositor lost precision: "+composed);
                File video=new File(folder,name+"-"+mode+(processing?"-processed":"")+".mp4");String encoder;
                try(VideoEncoder writer=new VideoEncoder(context,source.uri,video,cache.w,cache.h,12,false,stop,60000000,mode)){
                    encoder=writer.label;for(int i=0;i<4;i++)writer.append(renderer.frame(cache,effect,settings,i/3f,1),i);writer.finish(1/3f);
                }
                VideoValidator.check(context,video,first,cache.w,cache.h,mode,stop);
                outputs.put(new JSONObject().put("source",name).put("format",mode).put("sourceBits",source.bits).put("cacheLevels",sourceLevels).put("composedLevels",composed).put("sourceHDR",source.hdr).put("processing",processing).put("encoder",encoder).put("frames",4).put("file",video.getName()));publish(video);
            }finally{if(cache!=base)cache.close();}
        }
    }
    /* 真实上海20秒源的4K60短片，验证实际分辨率下的P010链路。 */
    void realCase(String mode)throws Exception{
        VideoSource source=new VideoSource(getTargetContext(),Uri.fromFile(fixture("stress.mov")));
        try(VideoSource.Cache cache=source.read(3840,24,stop,(p,t)->{},true);Renderer renderer=new Renderer(getTargetContext(),"gpu")){
            Effect effect=null;for(Effect e:Effect.load(getTargetContext()))if(e.id==100)effect=e;
            Effect.Settings settings=effect.defaults();settings.exportFormat=mode;settings.exportDither=true;
            File output=new File(folder,"real-4k60-"+mode+".mp4");ByteBuffer first=null;int count=12;long began=SystemClock.elapsedRealtime();String backend;
            try(VideoEncoder encoder=new VideoEncoder(getTargetContext(),source.uri,output,cache.w,cache.h,60,false,stop,100000000,mode)){
                backend=encoder.label;for(int i=0;i<count;i++){ByteBuffer frame=renderer.frame(cache,effect,settings,i/(float)(count-1),0);if(i==0)first=frame;encoder.append(frame,i);}encoder.finish(count/60f);
            }
            VideoValidator.check(getTargetContext(),output,first,cache.w,cache.h,mode,stop);
            outputs.put(new JSONObject().put("source","Shanghai20.mov").put("sourceSeconds",source.durationUs/1e6).put("sourceSamples",24).put("format",mode).put("width",cache.w).put("height",cache.h).put("fps",60).put("frames",count).put("encoder",backend).put("engine",renderer.label).put("seconds",(SystemClock.elapsedRealtime()-began)/1000.).put("file",output.getName()));publish(output);
        }
    }

    /* 前台验证，结果与异常均导出；不改变设备安全和热状态。 */
    @Override public void onStart(){
        folder=new File(getTargetContext().getCacheDir(),"validation_hdr106");folder.mkdirs();
        try{
            report.put("capabilities",capabilities());
            ActivityMonitor monitor=addMonitor("studio.shiren.mobile.MainActivity",null,false);try{try(ParcelFileDescriptor fd=getUiAutomation().executeShellCommand("am start -n studio.shiren.mobile/.MainActivity");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(fd)){while(in.read()!=-1){}}activity=waitForMonitorWithTimeout(monitor,30000);}finally{removeMonitor(monitor);}
            exportCase("sdr10.mp4","hevc10",false);
            exportCase("hdr-pq.mp4","hdr_pq",false);
            exportCase("hdr-hlg.mp4","hdr_hlg",false);
            exportCase("hdr-pq.mp4","hdr_pq",true);
            realCase("hevc10");
            realCase("hdr_pq");
            report.put("passed",true);
        }catch(Throwable error){try{report.put("passed",false).put("error",android.util.Log.getStackTraceString(error));}catch(Exception ignored){}}
        finally{try{report.put("outputs",outputs);File file=new File(folder,"hdr-report.json");try(OutputStream out=new FileOutputStream(file)){out.write(report.toString(2).getBytes("UTF-8"));}publish(file);}catch(Exception ignored){}Bundle result=new Bundle();result.putString("report",report.toString());finish(0,result);}
    }
}
