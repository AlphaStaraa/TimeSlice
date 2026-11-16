package studio.shiren.mobile;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.net.Uri;
import android.os.*;
import android.provider.MediaStore;
import android.view.*;
import android.widget.*;
import java.io.*;
import org.json.*;

/** 仅测试APK使用：真实上海素材下复查浅深主题、面板、关于、许可与导出。 */
public final class UiReviewInstrumentation extends Instrumentation {
    MainActivity app;
    File directory;
    final JSONObject report=new JSONObject();
    final JSONArray shots=new JSONArray();
    int oldAppearance;boolean oldEnglish;
    interface Condition { boolean ready(); }
    /** 启动本轮物理设备界面验收。 */
    @Override public void onCreate(Bundle args){super.onCreate(args);start();}
    /** 等待UI线程真实状态，超时保留错误。 */
    void waitFor(Condition condition,long timeout)throws Exception{
        long until=SystemClock.elapsedRealtime()+timeout;
        while(SystemClock.elapsedRealtime()<until){boolean[] ready={false};runOnMainSync(()->ready[0]=condition.ready());if(ready[0])return;Thread.sleep(40);}
        throw new Exception("UI state timed out");
    }
    /** 只导出本次测试文件，保留相册和其他应用数据。 */
    void publish(File file,String mime)throws Exception{
        ContentValues values=new ContentValues();values.put(MediaStore.MediaColumns.DISPLAY_NAME,file.getName());
        values.put(MediaStore.MediaColumns.MIME_TYPE,mime);values.put(MediaStore.MediaColumns.RELATIVE_PATH,"Download/TimeSliceVisual103");values.put(MediaStore.MediaColumns.IS_PENDING,1);
        Uri uri=getTargetContext().getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,values);
        try(InputStream in=new FileInputStream(file);OutputStream out=getTargetContext().getContentResolver().openOutputStream(uri)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}
        values.clear();values.put(MediaStore.MediaColumns.IS_PENDING,0);getTargetContext().getContentResolver().update(uri,values,null,null);
    }
    /** 使用真实屏幕合成截图，玻璃和系统圆角也必须进入验收。 */
    void capture(String name)throws Exception{
        waitForIdleSync();Thread.sleep(180);
        android.view.accessibility.AccessibilityNodeInfo active=getUiAutomation().getRootInActiveWindow();
        if(active!=null&&(!active.findAccessibilityNodeInfosByText("这一步没有完成").isEmpty()||!active.findAccessibilityNodeInfosByText("Could not finish").isEmpty()))
            throw new Exception("Unexpected error dialog: "+name);
        Bitmap bitmap=getUiAutomation().takeScreenshot();
        if(bitmap==null)throw new Exception("Screenshot unavailable");File file=new File(directory,name+".png");
        try(OutputStream out=new FileOutputStream(file)){bitmap.compress(Bitmap.CompressFormat.PNG,100,out);}bitmap.recycle();publish(file,"image/png");shots.put(file.getName());
    }
    /** 仅在本应用窗口查找操作按钮。 */
    View find(View node,String text){
        if(node instanceof TextView&&text.contentEquals(((TextView)node).getText()))return node;
        if(node instanceof ViewGroup){ViewGroup group=(ViewGroup)node;for(int i=0;i<group.getChildCount();i++){View found=find(group.getChildAt(i),text);if(found!=null)return found;}}
        return null;
    }
    /** 按可访问名称寻找真实控件，验证用户可直接修改目标码率。 */
    View described(View node,String name){
        if(name.contentEquals(node.getContentDescription()==null?"":node.getContentDescription()))return node;
        if(node instanceof ViewGroup){ViewGroup group=(ViewGroup)node;for(int i=0;i<group.getChildCount();i++){View match=described(group.getChildAt(i),name);if(match!=null)return match;}}
        return null;
    }
    /** 用真实控件切换推荐和自定义，码率修改不得重建源缓存。 */
    void verifyBitrate()throws Exception{
        Object cache=app.preparedCache;
        runOnMainSync(()->{app.bitrate=0;app.panels.showExport();Spinner mode=(Spinner)described(app.inspectorDialog.getWindow().getDecorView(),app.t("码率","Bitrate"));if(mode==null)throw new AssertionError("Bitrate mode missing");mode.setSelection(1);});
        waitFor(()->app.bitrate>0,5000);
        runOnMainSync(()->{EditText input=(EditText)described(app.inspectorDialog.getWindow().getDecorView(),app.t("目标码率（Mbps）","Target bitrate (Mbps)"));if(input==null)throw new AssertionError("Custom bitrate missing");input.requestFocus();input.setText("37.5");input.clearFocus();});
        waitFor(()->app.bitrate==37500000,5000);
        if(app.preparedCache!=cache)throw new Exception("Bitrate change rebuilt source");
    }

    /** 使用标准返回键关闭当前产品弹窗。 */
    void back()throws Exception{try(ParcelFileDescriptor fd=getUiAutomation().executeShellCommand("input keyevent 4");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(fd)){while(in.read()!=-1){}}Thread.sleep(120);}
    /** 前台启动避免设备冻结后台仪器化。 */
    void launch()throws Exception{
        ActivityMonitor monitor=addMonitor("studio.shiren.mobile.MainActivity",null,false);
        try{
            try(ParcelFileDescriptor fd=getUiAutomation().executeShellCommand("am start -n studio.shiren.mobile/.MainActivity");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(fd)){while(in.read()!=-1){}}
            app=(MainActivity)waitForMonitorWithTimeout(monitor,30000);if(app==null)throw new Exception("Activity not foreground");
        }finally{removeMonitor(monitor);}
    }
    /** 在同一真实素材上逐一打开产品页面，最后执行实际导出。 */
    @Override public void onStart(){
        try{
            for(String removed:new String[]{"studio.shiren.mobile.PhotoSequence","studio.shiren.mobile.RawDecoder"}){
                boolean absent=false;try{Class.forName(removed);}catch(ClassNotFoundException expected){absent=true;}
                if(!absent)throw new Exception("Removed photo class still shipped: "+removed);
            }
            boolean oneTapMissing=false;try{MainActivity.class.getDeclaredMethod("oneTap");}catch(NoSuchMethodException expected){oneTapMissing=true;}
            if(!oneTapMissing)throw new Exception("Removed one-tap entry still shipped");
            launch();oldAppearance=app.getPreferences(0).getInt("appearance",0);oldEnglish=app.english;
            directory=new File(getTargetContext().getCacheDir(),"validation_visual103");directory.mkdirs();
            File source=new File(directory,"Shanghai20.mov");
            try(InputStream in=getContext().getAssets().open("validation/stress.mov");OutputStream out=new FileOutputStream(source)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}
            runOnMainSync(()->{app.edge=1280;app.samples=24;app.importVideo(Uri.fromFile(source));});
            waitFor(()->app.lastPreview!=null&&!app.preparing&&!app.pending.get(),120000);
            for(int appearance:new int[]{1,2}){
                final int theme=appearance;String tone=appearance==1?"light":"dark";
                for(boolean english:new boolean[]{false,true}){
                    final boolean language=english;String locale=english?"en":"zh";
                    runOnMainSync(()->{app.getPreferences(0).edit().putInt("appearance",theme).apply();app.english=language;app.buildUI();app.playing=false;app.u=.63f;app.version++;app.requestPreview();});
                    waitFor(()->!app.pending.get(),10000);capture(tone+"-"+locale+"-workspace");
                    runOnMainSync(()->app.showInspector(1));capture(tone+"-"+locale+"-effect");runOnMainSync(()->app.inspectorDialog.dismiss());
                    runOnMainSync(()->app.showInspector(2));capture(tone+"-"+locale+"-shadow");runOnMainSync(()->app.inspectorDialog.dismiss());
                    runOnMainSync(()->{app.panels.sourcePage=0;app.showInspector(0);});capture(tone+"-"+locale+"-source");runOnMainSync(()->app.inspectorDialog.dismiss());
                    verifyBitrate();capture(tone+"-"+locale+"-export");runOnMainSync(()->app.inspectorDialog.dismiss());
                    final Dialog[] about={null};runOnMainSync(()->about[0]=PhoneAbout.show(app));capture(tone+"-"+locale+"-about");
                    View license=find(about[0].getWindow().getDecorView(),app.t("开源许可与声明","License & notices"));if(license==null)throw new Exception("License action missing");
                    runOnMainSync(license::performClick);capture(tone+"-"+locale+"-license");
                    if(getUiAutomation().getRootInActiveWindow().findAccessibilityNodeInfosByText("GNU AFFERO GENERAL PUBLIC LICENSE").isEmpty())throw new Exception("License text not displayed");
                    try(ParcelFileDescriptor fd=getUiAutomation().executeShellCommand("input keyevent 4");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(fd)){while(in.read()!=-1){}}
                    View third=find(about[0].getWindow().getDecorView(),app.t("第三方组件许可","Third-party licenses"));if(third==null)throw new Exception("Third-party action missing");
                    runOnMainSync(third::performClick);capture(tone+"-"+locale+"-third-party");
                    if(getUiAutomation().getRootInActiveWindow().findAccessibilityNodeInfosByText("OpenCV").isEmpty())throw new Exception("Third-party notices not displayed");
                    try(ParcelFileDescriptor fd=getUiAutomation().executeShellCommand("input keyevent 4");InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(fd)){while(in.read()!=-1){}}
                    runOnMainSync(()->about[0].dismiss());
                }
            }
            for(int theme:new int[]{1,2}){
                final int chosenTheme=theme;String tone=theme==1?"light-zh":"dark-en";
                runOnMainSync(()->{app.getPreferences(0).edit().putInt("appearance",chosenTheme).apply();app.english=chosenTheme==2;app.buildUI();app.panels.more();});capture(tone+"-more");back();
                runOnMainSync(()->{app.panels.sourcePage=1;app.sourceOptions.grade=true;app.updateGrade();app.showInspector(0);});waitFor(()->!app.pending.get(),10000);capture(tone+"-color");
                final View[] disclosure={null};runOnMainSync(()->{View node=find(app.inspectorDialog.getWindow().getDecorView(),"HSL");while(node!=null&&!node.isClickable())node=node.getParent() instanceof View?(View)node.getParent():null;disclosure[0]=node;});
                if(disclosure[0]==null)throw new Exception("HSL disclosure missing");if(!app.panels.expanded.contains("color.hsl"))runOnMainSync(disclosure[0]::performClick);capture(tone+"-hsl");runOnMainSync(()->app.inspectorDialog.dismiss());
            }
            for(String key:new String[]{"base_fan","wave_fan"}){
                Effect target=null;for(Effect effect:app.effects)if(effect.key.equals(key))target=effect;
                final Effect effect=target;if(effect==null)throw new Exception("Fan variant missing");
                runOnMainSync(()->{app.selectVariant(effect.id);app.playing=false;app.u=.63f;app.version++;app.requestPreview();});waitFor(()->!app.pending.get(),10000);capture(key+"-real-preview");
            }
            runOnMainSync(()->{app.english=false;app.selected.clear();app.selected.add(100);app.settings.get(100).seconds=.5f;app.fps=24;app.bitrate=8000000;app.beginExport();});
            waitFor(()->!app.busy&&app.lastOutput!=null,120000);
            File output=new File(directory,"real-UI-export.mp4");
            try(InputStream in=getTargetContext().getContentResolver().openInputStream(app.lastOutput);OutputStream out=new FileOutputStream(output)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}publish(output,"video/mp4");
            report.put("passed",true).put("originalSource","Shanghai20.mov").put("sourceResolution",app.source.width+"x"+app.source.height).put("sourceSeconds",app.source.durationUs/1e6).put("sourceSamples",24).put("realExport",true).put("customBitrateMbps",8).put("manualInputMbps",37.5).put("gradientDither",true).put("themes",2).put("languages",2).put("licenseTextDisplayed",true).put("thirdPartyNoticesDisplayed",true).put("noErrorDialogs",true).put("videoOnly",true).put("photoClassesAbsent",true).put("oneTapRemoved",true);
        }catch(Throwable error){try{report.put("passed",false).put("error",android.util.Log.getStackTraceString(error));}catch(Exception ignored){}}
        finally{
            if(app!=null)runOnMainSync(()->{app.getPreferences(0).edit().putInt("appearance",oldAppearance).apply();app.english=oldEnglish;app.buildUI();});
            try{report.put("screenshots",shots);File file=new File(directory,"ui-review.json");try(OutputStream out=new FileOutputStream(file)){out.write(report.toString(2).getBytes("UTF-8"));}publish(file,"application/json");}catch(Exception ignored){}
            Bundle result=new Bundle();result.putString("report",report.toString());finish(0,result);
        }
    }
}
