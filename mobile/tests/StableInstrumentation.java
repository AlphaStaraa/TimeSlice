package studio.shiren.mobile;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.graphics.*;
import android.view.*;
import java.io.*;
import java.nio.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.*;
import org.opencv.core.*;
import org.opencv.core.Point;
import org.opencv.imgproc.Imgproc;

/** 仅测试APK使用：在正式应用进程验证渲染、素材处理、实时调色及导出。 */
public final class StableInstrumentation extends Instrumentation {
    MainActivity app;File dir;JSONObject report=new JSONObject();boolean physical=false;String session="";
    interface Condition{/* 返回界面是否已到达待验证状态。 */boolean ready();}
    /* 启动隔离的仪器化测试，不向正式APK增加调试入口。 */
    @Override public void onCreate(Bundle args){super.onCreate(args);if(args!=null){physical=Boolean.parseBoolean(String.valueOf(args.get("physical")));session=args.getString("session","").replaceAll("[^a-zA-Z0-9_-]","_");}start();}
    /* 等待界面线程条件成立，并在失败时带出可见错误。 */
    void waitFor(Condition condition,long timeout)throws Exception{long end=System.currentTimeMillis()+timeout;while(System.currentTimeMillis()<end){boolean[] ready={false};runOnMainSync(()->ready[0]=condition.ready());if(ready[0])return;Thread.sleep(30);}throw new Exception("Timeout: "+app.status.getText()+" / "+app.prepareStatus.getText());}
    /* 保存真正布局后的手机工作台画面。 */
    void capture(String name)throws Exception{runOnMainSync(()->{try{android.view.View view=app.getWindow().getDecorView();Bitmap bitmap=Bitmap.createBitmap(view.getWidth(),view.getHeight(),Bitmap.Config.ARGB_8888);view.draw(new Canvas(bitmap));try(FileOutputStream out=new FileOutputStream(new File(dir,name))){bitmap.compress(Bitmap.CompressFormat.PNG,100,out);}bitmap.recycle();}catch(Exception error){throw new RuntimeException(error);}});}
    /* 将已保存的真实输出复制到测试目录，交由宿主完整解码。 */
    void copy(Uri uri,String name)throws Exception{try(InputStream in=getTargetContext().getContentResolver().openInputStream(uri);OutputStream out=new FileOutputStream(new File(dir,name))){if(in==null)throw new Exception("Missing exported video");byte[] block=new byte[65536];int n;while((n=in.read(block))>=0)out.write(block,0,n);}}
    /* 检查非近似数据，避免把CPU回退误报成GPU验证。 */
    void rendererCases()throws Exception{
        Context context=getTargetContext();VideoSource.Cache cache=new VideoSource.Cache();cache.w=160;cache.h=90;cache.frames=101;cache.bytes=ByteBuffer.allocateDirect(cache.w*cache.h*4*cache.frames);
        for(int frame=0;frame<cache.frames;frame++)for(int i=0;i<cache.w*cache.h;i++){int p=(frame*cache.w*cache.h+i)*4;cache.bytes.put(p,(byte)Math.round(frame*2.55));cache.bytes.put(p+1,(byte)(i%160));cache.bytes.put(p+2,(byte)150);cache.bytes.put(p+3,(byte)255);}
        double worst=0;int max=0,cases=0;String device;
        try(Renderer cpu=new Renderer(context,"cpu");Renderer gpu=new Renderer(context,"gpu")){
            device=gpu.label;if(!device.startsWith("GPU"))throw new Exception("GPU was not active");
            for(Effect effect:Effect.load(context))for(boolean split:new boolean[]{false,true}){
                if(split&&effect.family!=0)continue;
                for(float at:new float[]{.23f,.51f,.81f,1f}){
                    Effect.Settings s=effect.defaults();s.dayNightSplit=split;
                    ByteBuffer a=cpu.frame(cache,effect,s,at,0),b=gpu.frame(cache,effect,s,at,0);long error=0;int peak=0;
                    for(int i=0;i<a.capacity();i++){int d=Math.abs((a.get(i)&255)-(b.get(i)&255));error+=d;peak=Math.max(peak,d);}
                    double mean=error/(double)a.capacity();if(mean>.12||peak>3)throw new Exception(effect.key+" CPU/GPU: "+mean+" / "+peak);worst=Math.max(worst,mean);max=Math.max(max,peak);cases++;
                }
                Effect.Settings s=effect.defaults();s.dayNightSplit=split;
                ByteBuffer params=effect.params(s,160,90,101,.51f,0);byte[] data=new byte[params.capacity()];params.get(data);
                try(FileOutputStream out=new FileOutputStream(new File(dir,"params-"+effect.id+"-"+split+".bin"))){out.write(data);}
            }
            SourceOptions grade=new SourceOptions();grade.grade=true;grade.hsl[5][0]=-20;cache.grade=grade.buffer(cache.frames,null);
            Effect e=app.effectById(100);Effect.Settings s=e.defaults();s.dayNightSplit=true;ByteBuffer a=cpu.frame(cache,e,s,.51f,0),b=gpu.frame(cache,e,s,.51f,0);long sum=0;for(int i=0;i<a.capacity();i++)sum+=Math.abs((a.get(i)&255)-(b.get(i)&255));if(sum/(double)a.capacity()>.2)throw new Exception("Live grade CPU/GPU mismatch");
        }finally{cache.close();}
        report.put("renderCases",cases).put("cpuGpuMeanMax",worst).put("cpuGpuPixelMax",max).put("gpuDevice",device).put("liveGradeHsl",true);
    }
    /* 验证三级去闪都改善曝光跳变，并保持全部输入帧。 */
    void deflickerCases()throws Exception{
        Context c=getTargetContext();VideoSource.Cache base=VideoSource.allocate(c,192,128,40);
        for(int frame=0;frame<40;frame++)for(int y=0;y<128;y++)for(int x=0;x<192;x++){
            int p=(frame*128*192+y*192+x)*4;double gain=Math.pow(2,(frame%2==0?.11:-.11)-.4*frame/39);int value=(int)Math.round((80+x*.4+y*.2)*gain);for(int k=0;k<3;k++)base.bytes.put(p+k,(byte)value);base.bytes.put(p+3,(byte)255);
        }
        JSONArray levels=new JSONArray();try{for(String level:new String[]{"light","standard","extreme"}){SourceOptions s=new SourceOptions();s.deflicker=level;SourceProcessor.Result result=SourceProcessor.process(c,base,s,new AtomicBoolean(),(p,t)->{});try{if(result.cache.frames!=40||result.afterFlicker>=result.beforeFlicker*.6)throw new Exception("Deflicker did not improve: "+level);levels.put(new JSONObject().put("level",level).put("before",result.beforeFlicker).put("after",result.afterFlicker));}finally{result.cache.close();}}}finally{base.close();}report.put("deflickerLevels",levels);
    }
    /* 以独立相位相关核查固定机位锁定结果，测试输入具有已知位移和微小旋转。 */
    double drift95(VideoSource.Cache cache){
        Mat reference=new Mat(),frame=new Mat(),raw=new Mat(cache.h,cache.w,CvType.CV_8UC4,cache.frame(0));
        Imgproc.cvtColor(raw,reference,Imgproc.COLOR_RGBA2GRAY);raw.release();reference.convertTo(reference,CvType.CV_32F);
        double[] shifts=new double[cache.frames-1];
        try{for(int i=1;i<cache.frames;i++){raw=new Mat(cache.h,cache.w,CvType.CV_8UC4,cache.frame(i));Imgproc.cvtColor(raw,frame,Imgproc.COLOR_RGBA2GRAY);raw.release();frame.convertTo(frame,CvType.CV_32F);Point delta=Imgproc.phaseCorrelate(reference,frame);shifts[i-1]=Math.hypot(delta.x,delta.y);}Arrays.sort(shifts);return shifts[(int)((shifts.length-1)*.95)];}
        finally{reference.release();frame.release();}
    }
    /* 普通和极致锁定都必须降低已知抖动，并保持每一个输入时刻。 */
    void stabilizationCases()throws Exception{
        Context c=getTargetContext();VideoSource.Cache base=VideoSource.allocate(c,360,240,20);
        try(InputStream input=new FileInputStream(new File(dir,"jitter.rgba"))){byte[] chunk=new byte[65536];int n;while((n=input.read(chunk))>=0)base.bytes.put(chunk,0,n);base.bytes.rewind();}
        double before=drift95(base);JSONArray cases=new JSONArray();
        try{for(String mode:new String[]{"lock","extreme"}){SourceOptions opts=new SourceOptions();opts.stabilize=mode;SourceProcessor.Result result=SourceProcessor.process(c,base,opts,new AtomicBoolean(),(p,t)->{});try{double after=drift95(result.cache);if(after>=before*.45||after>.7||result.cache.frames!=20)throw new Exception("Lock failed: "+mode+" "+before+" -> "+after);cases.put(new JSONObject().put("mode",mode).put("beforeP95",before).put("afterP95",after).put("crop",result.crop).put("algorithm",result.algorithm));}finally{result.cache.close();}}}finally{base.close();}
        report.put("stabilization",cases);
    }
    /* 16位时间图必须保留浮点细节，并进入实际CPU/GPU合成。 */
    void mapCases()throws Exception{
        Context c=getTargetContext();TimeMap map=TimeMap.load(c,Uri.fromFile(new File(dir,"map16.png")));if(map.bits!=16)throw new Exception("16-bit map lost precision");ByteBuffer values=map.buffer(3840,32,false);Set<Float> distinct=new HashSet<>();for(int x=0;x<3840;x++)distinct.add(values.getFloat(x*4));if(distinct.size()!=3840)throw new Exception("Pixel map samples collapsed");
        VideoSource.Cache cache=VideoSource.allocate(c,160,90,2);for(int i=0;i<cache.w*cache.h;i++){cache.bytes.put(i*4+3,(byte)255);for(int k=0;k<4;k++)cache.bytes.put((cache.w*cache.h+i)*4+k,(byte)255);}
        try(Renderer cpu=new Renderer(c,"cpu");Renderer gpu=new Renderer(c,"gpu")){
            Effect effect=app.effectById(2);Effect.Settings s=effect.defaults();s.timeMap=map;s.countMode=2;
            ByteBuffer a=cpu.frame(cache,effect,s,.37f,0),b=gpu.frame(cache,effect,s,.37f,0);int max=0;for(int i=0;i<a.capacity();i++)max=Math.max(max,Math.abs((a.get(i)&255)-(b.get(i)&255)));if(max>1)throw new Exception("Mapped CPU/GPU mismatch "+max);
        }finally{cache.close();}report.put("map16Bit",true).put("distinctPixelSamples",3840);
    }
    /* 用真实触摸长按和移动事件验证拖拽，而不是只调用排序函数。 */
    void dragQueue(int from,int to)throws Exception{
        int[] a=new int[2],b=new int[2];
        runOnMainSync(()->{View first=app.queueCards.getChildAt(from),target=app.queueCards.getChildAt(to);first.getLocationOnScreen(a);target.getLocationOnScreen(b);a[0]+=first.getWidth()/2;a[1]+=first.getHeight()/2;b[0]+=target.getWidth()/2;b[1]+=target.getHeight()/2;});
        long down=SystemClock.uptimeMillis();MotionEvent event=MotionEvent.obtain(down,down,MotionEvent.ACTION_DOWN,a[0],a[1],0);event.setSource(InputDevice.SOURCE_TOUCHSCREEN);if(!getUiAutomation().injectInputEvent(event,true))throw new Exception("Touch injection failed");event.recycle();Thread.sleep(ViewConfiguration.getLongPressTimeout()+150);
        for(int i=1;i<=12;i++){float fraction=i/12f;event=MotionEvent.obtain(down,SystemClock.uptimeMillis(),MotionEvent.ACTION_MOVE,a[0]+(b[0]-a[0])*fraction,a[1]+(b[1]-a[1])*fraction,0);event.setSource(InputDevice.SOURCE_TOUCHSCREEN);if(!getUiAutomation().injectInputEvent(event,true))throw new Exception("Touch injection failed");event.recycle();Thread.sleep(25);}
        event=MotionEvent.obtain(down,SystemClock.uptimeMillis(),MotionEvent.ACTION_UP,b[0],b[1],0);event.setSource(InputDevice.SOURCE_TOUCHSCREEN);if(!getUiAutomation().injectInputEvent(event,true))throw new Exception("Touch injection failed");event.recycle();Thread.sleep(250);
    }
    /* 原地放手不崩溃，向右一位和跨卡片移动均保留全部选择。 */
    void queueDragCases()throws Exception{
        runOnMainSync(()->{app.selected.clear();app.selected.add(100);app.selected.add(101);app.selected.add(102);app.refreshSelection();});Thread.sleep(150);
        dragQueue(0,0);if(!new ArrayList<>(app.selected).equals(Arrays.asList(100,101,102)))throw new Exception("Self drop changed selection");
        dragQueue(0,1);if(!new ArrayList<>(app.selected).equals(Arrays.asList(101,100,102)))throw new Exception("Adjacent drag failed: "+app.selected);
        dragQueue(0,2);if(!new ArrayList<>(app.selected).equals(Arrays.asList(100,102,101)))throw new Exception("Queue drag failed: "+app.selected);
        report.put("realTouchQueueDrag",true).put("selfDropSafe",true).put("adjacentMoveWorks",true);
    }
    /* 只在隔离模拟器内注入热状态，核查减速与临界停止后恢复系统状态。 */
    void thermalCases()throws Exception{
        // 实体设备只读取真实热状态，不注入模拟器的系统热覆盖值。
        if(physical){PowerManager power=(PowerManager)getTargetContext().getSystemService(Context.POWER_SERVICE);Intent battery=getTargetContext().registerReceiver(null,new IntentFilter(Intent.ACTION_BATTERY_CHANGED));report.put("thermalSimulationRun",false).put("realThermalStatus",power.getCurrentThermalStatus());if(battery!=null)report.put("batteryTemperatureC",battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE,0)/10.0);return;}
        try{
            try(ParcelFileDescriptor command=getUiAutomation().executeShellCommand("cmd thermalservice override-status 3");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(command)){while(in.read()!=-1){}}
            Thread.sleep(150);long start=System.nanoTime();int state=ExportSafety.pace(getTargetContext(),new AtomicBoolean());long elapsed=(System.nanoTime()-start)/1000000;
            if(state<PowerManager.THERMAL_STATUS_SEVERE||elapsed<100)throw new Exception("Thermal pacing did not activate");
            try(ParcelFileDescriptor command=getUiAutomation().executeShellCommand("cmd thermalservice override-status 4");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(command)){while(in.read()!=-1){}}
            Thread.sleep(150);boolean stopped=false;try{ExportSafety.pace(getTargetContext(),new AtomicBoolean());}catch(Exception expected){stopped=true;}if(!stopped)throw new Exception("Critical thermal stop missing");
            report.put("thermalPacingMs",elapsed).put("criticalThermalStop",true);
        }finally{try(ParcelFileDescriptor command=getUiAutomation().executeShellCommand("cmd thermalservice reset");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(command)){while(in.read()!=-1){}}Thread.sleep(150);}
    }
    /* 正式应用导入、立即准备、调色不重建源缓存、结束停住和高负载提示。 */
    @Override public void onStart(){
        try{
            android.util.Log.i("TimeSliceValidation","Starting; physical="+physical+" session="+session);
            Context c=getTargetContext();dir=physical?new File(c.getCacheDir(),"validation_"+session):c.getExternalFilesDir(null);if(!dir.exists()&&!dir.mkdirs())throw new Exception("Cannot create test directory");
            if(physical){for(String name:getContext().getAssets().list("validation")){try(InputStream in=getContext().getAssets().open("validation/"+name);OutputStream out=new FileOutputStream(new File(dir,name))){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}}}
            File input=new File(dir,"source.mp4");
            android.util.Log.i("TimeSliceValidation","Launching activity; dir="+dir.getAbsolutePath()+" source="+input.isFile());
            if(physical){ActivityMonitor monitor=addMonitor("studio.shiren.mobile.MainActivity",null,false);try{try(ParcelFileDescriptor command=getUiAutomation().executeShellCommand("am start -n studio.shiren.mobile/.MainActivity");InputStream stream=new ParcelFileDescriptor.AutoCloseInputStream(command)){while(stream.read()!=-1){}}app=(MainActivity)waitForMonitorWithTimeout(monitor,30000);if(app==null)throw new Exception("Foreground activity did not reach monitor");}finally{removeMonitor(monitor);}}
            else{Intent intent=new Intent().setClassName(c,"studio.shiren.mobile.MainActivity").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);app=(MainActivity)startActivitySync(intent);}
            android.util.Log.i("TimeSliceValidation","Activity ready");runOnMainSync(()->app.importVideo(Uri.fromFile(input)));waitFor(()->app.preview!=null&&!app.preparing&&app.renderer!=null&&app.lastPreview!=null&&!app.pending.get(),120000);capture("phone-zh.png");
            queueDragCases();rendererCases();deflickerCases();stabilizationCases();mapCases();
            final String key=app.preparedKey;final VideoSource.Cache full=app.preparedCache;
            runOnMainSync(()->{app.sourceOptions.grade=true;app.sourceOptions.hsl[5][0]=-20;app.updateGrade();app.setFreezeSplit(true);app.selectVariant(102);});
            waitFor(()->!app.pending.get(),10000);if(app.preparedCache!=full||!key.equals(app.preparedKey)||app.preparing)throw new Exception("Color edit rebuilt source cache");
            runOnMainSync(()->{app.english=true;app.buildUI();app.requestPreview();});waitFor(()->!app.pending.get(),10000);capture("phone-en.png");
            runOnMainSync(()->{app.edge=320;app.samples=24;app.prepareSource();});waitFor(()->!app.preparing&&app.preparedCache!=null,90000);
            runOnMainSync(()->{app.english=false;app.buildUI();app.selected.clear();app.selected.add(101);app.selected.add(100);for(int id:app.selected)app.settings.get(id).seconds=.5f;app.fps=12;app.startExport();});waitFor(()->!app.busy&&app.lastOutput!=null,120000);copy(app.lastOutput,"queue-last.mp4");report.put("gallerySaved",true).put("separateOrder",new JSONArray(Arrays.asList(101,100)));
            runOnMainSync(()->{app.fps=60;app.startExport();});waitFor(()->app.riskDialog!=null&&app.riskDialog.isShowing(),10000);if(app.busy)throw new Exception("High-load export started without confirmation");
            runOnMainSync(()->app.riskDialog.getButton(DialogInterface.BUTTON_NEGATIVE).performClick());report.put("highLoadWarningBeforeExport",true).put("sourceCacheReusedAfterColor",true);
            runOnMainSync(()->{if(app.inspectorDialog!=null)app.inspectorDialog.dismiss();app.selected.clear();app.selected.add(100);app.settings.get(100).seconds=30;app.fps=12;app.beginExport();});waitFor(()->app.busy&&app.exportBar.getProgress()>10,60000);runOnMainSync(()->app.startExport());waitFor(()->!app.busy,30000);
            String[] partial=getTargetContext().getCacheDir().list((folder,name)->name.startsWith("render_")||name.startsWith("codec_check_"));if(partial!=null&&partial.length>0)throw new Exception("Partial videos remained after cancel");report.put("cancelCleanup",true);
            thermalCases();report.put("passed",true);
        }catch(Throwable error){try{report.put("passed",false).put("error",android.util.Log.getStackTraceString(error));}catch(Exception ignored){}}
        finally{
            try{if(dir==null)dir=getTargetContext().getExternalFilesDir(null);try(FileOutputStream output=new FileOutputStream(new File(dir,"stable-report.json"))){output.write(report.toString(2).getBytes("UTF-8"));}}catch(Exception ignored){}
            Bundle result=new Bundle();result.putString("report",report.toString());finish(0,result);
        }
    }
}
