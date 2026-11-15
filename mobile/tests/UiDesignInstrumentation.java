package studio.shiren.mobile;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.net.Uri;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.util.*;
import org.json.*;

/** 只在测试包中验证手机交互层级、面板和用户可见的真实导出。 */
public final class UiDesignInstrumentation extends Instrumentation {
    MainActivity app;File dir;JSONObject report=new JSONObject();
    interface Condition{/* 返回当前异步步骤是否完成。 */boolean ready();}

    /* 启动本轮界面仪器化，不向产品增加调试入口。 */
    @Override public void onCreate(Bundle args){super.onCreate(args);start();}

    /* 等待界面状态成立，同时检查当前活动是否发生异常销毁。 */
    void waitFor(Condition condition,long timeout)throws Exception{
        long end=System.currentTimeMillis()+timeout;while(System.currentTimeMillis()<end){boolean[] done={false};runOnMainSync(()->done[0]=condition.ready());if(done[0])return;Thread.sleep(30);}throw new Exception("Timeout: "+app.status.getText()+" / "+app.prepareStatus.getText());
    }

    /* ATD不提供可用合成截图，按真实布局渲染本应用视图及面板用于检查。 */
    void capture(String name)throws Exception{
        waitForIdleSync();Thread.sleep(150);final Bitmap[] result={null};
        runOnMainSync(()->{View root=app.getWindow().getDecorView();Bitmap image=Bitmap.createBitmap(root.getWidth(),root.getHeight(),Bitmap.Config.ARGB_8888);Canvas canvas=new Canvas(image);root.draw(canvas);
            if(app.inspectorDialog!=null&&app.inspectorDialog.isShowing()){Window window=app.inspectorDialog.getWindow();View panel=window.getDecorView();int[] location=new int[2];panel.getLocationOnScreen(location);Paint dim=new Paint();dim.setColor(Color.argb(Math.round(window.getAttributes().dimAmount*255),0,0,0));canvas.drawRect(0,0,image.getWidth(),image.getHeight(),dim);int saved=canvas.save();canvas.translate(location[0],location[1]);panel.draw(canvas);canvas.restoreToCount(saved);}result[0]=image;
        });
        Bitmap image=result[0];Set<Integer> colors=new HashSet<>();for(int y=0;y<image.getHeight();y+=16)for(int x=0;x<image.getWidth();x+=16)colors.add(image.getPixel(x,y));if(image.getWidth()<300||colors.size()<8)throw new Exception("Invalid or blank UI preview");try(FileOutputStream output=new FileOutputStream(new File(dir,name))){image.compress(Bitmap.CompressFormat.PNG,100,output);}image.recycle();
    }

    /* 遍历本应用视图树，按可读标签定位真实交互控件。 */
    View find(View root,String label){if(root instanceof TextView&&label.equals(((TextView)root).getText().toString()))return root;if(root instanceof ViewGroup){ViewGroup group=(ViewGroup)root;for(int i=0;i<group.getChildCount();i++){View result=find(group.getChildAt(i),label);if(result!=null)return result;}}return null;}

    /* 使用无障碍名称找到面板里的真实选择控件。 */
    View described(View root,String label){if(label.contentEquals(root.getContentDescription()==null?"":root.getContentDescription()))return root;if(root instanceof ViewGroup){ViewGroup group=(ViewGroup)root;for(int i=0;i<group.getChildCount();i++){View result=described(group.getChildAt(i),label);if(result!=null)return result;}}return null;}

    /* 在当前可见面板中点击指定文本，不绕过它的事件绑定。 */
    void clickText(String label)throws Exception{boolean[] found={false};runOnMainSync(()->{View root=app.inspectorDialog==null?app.getWindow().getDecorView():app.inspectorDialog.getWindow().getDecorView();View view=find(root,label);if(view!=null){found[0]=true;if(!view.performClick()&&view.getParent() instanceof View)((View)view.getParent()).performClick();}});if(!found[0])throw new Exception("Missing UI action: "+label);Thread.sleep(100);}

    /* 通过正式素材和页面控件检查单个、批量、折叠参数及导出。 */
    @Override public void onStart(){
        try{
            Context context=getTargetContext();dir=context.getExternalFilesDir(null);Intent launch=new Intent().setClassName(context,"studio.shiren.mobile.MainActivity").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);app=(MainActivity)startActivitySync(launch);waitFor(()->app.workspace!=null&&app.renderer!=null,30000);capture("ui101-empty.png");
            runOnMainSync(()->app.importVideo(Uri.fromFile(new File(dir,"source.mp4"))));waitFor(()->app.preview!=null&&!app.preparing&&app.lastPreview!=null&&!app.pending.get(),120000);
            if(app.queueScroll.isShown())throw new Exception("Single mode showed batch queue");
            runOnMainSync(()->{app.settings.get(101).seconds=.35f;app.cards.getChildAt(1).performClick();});waitFor(()->!app.pending.get(),10000);if(!app.playing)throw new Exception("Selected effect did not start preview");if(app.active.id!=101||!app.selected.equals(new LinkedHashSet<>(Arrays.asList(101))))throw new Exception("Single tap did not select one effect");waitFor(()->!app.playing&&app.u==1,10000);runOnMainSync(()->app.settings.get(101).seconds=0);
            runOnMainSync(()->{app.onLibraryTap(100);app.setFreezeSplit(true);app.playing=false;app.previewOnce=false;app.ui.removeCallbacks(app.tick);app.workspace.updatePlay();app.u=.64f;app.version++;app.requestPreview();});waitFor(()->!app.pending.get(),10000);if(Math.abs(app.timeline.getProgress()-640)>1)throw new Exception("Preview time and scrubber differ");capture("ui101-home-zh.png");
            runOnMainSync(()->{app.workspace.batchButton.performClick();app.onLibraryTap(101);app.onLibraryTap(102);app.playing=false;app.previewOnce=false;app.ui.removeCallbacks(app.tick);app.workspace.updatePlay();});if(app.selected.size()!=3||!app.queueScroll.isShown())throw new Exception("Multi mode not visible");capture("ui101-batch.png");
            runOnMainSync(()->app.showInspector(1));capture("ui101-effect.png");if(app.panels.expanded.contains("effect.advanced"))throw new Exception("Advanced effect options opened by default");
            runOnMainSync(()->app.showInspector(2));capture("ui101-shadow.png");
            runOnMainSync(()->{app.panels.sourcePage=0;app.showInspector(0);Spinner choice=(Spinner)described(app.inspectorDialog.getWindow().getDecorView(),"去闪");choice.setSelection(2);});waitFor(()->app.preparing,10000);if(app.panels.processingBar==null||!app.panels.processingBar.isShown())throw new Exception("Source progress hidden behind sheet");capture("ui101-processing.png");waitFor(()->!app.preparing&&app.preparedCache!=null,90000);if(app.panels.processingBar.isShown())throw new Exception("Finished progress stayed visible");
            runOnMainSync(()->{app.panels.sourcePage=1;app.showInspector(0);});capture("ui101-color-off.png");
            final String key=app.preparedKey;final VideoSource.Cache full=app.preparedCache;
            clickText("风格调色");waitFor(()->!app.pending.get(),10000);if(!app.sourceOptions.grade||!app.preparedKey.equals(key)||app.preparedCache!=full)throw new Exception("Color toggle rebuilt cache");capture("ui101-color.png");
            clickText("HSL");capture("ui101-hsl.png");if(!app.panels.expanded.contains("color.hsl"))throw new Exception("HSL disclosure did not open");
            runOnMainSync(()->{app.inspectorDialog.dismiss();app.english=true;app.buildUI();app.requestPreview();});waitFor(()->!app.pending.get(),10000);capture("ui101-home-en.png");runOnMainSync(()->app.panels.show(1));capture("ui101-effect-en.png");
            runOnMainSync(()->{app.inspectorDialog.dismiss();app.english=false;app.batchMode=false;app.selected.clear();app.selected.add(100);app.settings.get(100).seconds=.5f;app.fps=24;app.buildUI();app.export.performClick();});waitFor(()->app.inspectorDialog!=null&&app.panels.visiblePage==3,10000);if(app.busy)throw new Exception("Export started before output options");capture("ui101-export.png");
            clickText("开始导出");waitFor(()->!app.busy&&app.lastOutput!=null,120000);
            try(InputStream input=context.getContentResolver().openInputStream(app.lastOutput);OutputStream output=new FileOutputStream(new File(dir,"ui101-export.mp4"))){if(input==null)throw new Exception("Export was not saved");byte[] bytes=new byte[65536];int n;while((n=input.read(bytes))>=0)output.write(bytes,0,n);}
            report.put("singleTapSelectsOne",true).put("selectedEffectPreviewsOnce",true).put("queueOnlyInMulti",true).put("advancedCollapsed",true).put("hslRetained",true).put("gradeReusesCache",true).put("sourceProgressVisibleInPanel",true).put("finishedProgressHidden",true).put("exportOptionsBeforeStart",true).put("realExportSaved",true).put("chineseEnglishScreens",true).put("passed",true);
        }catch(Throwable error){try{report.put("passed",false).put("error",android.util.Log.getStackTraceString(error));}catch(Exception ignored){}}
        finally{try{if(dir==null)dir=getTargetContext().getExternalFilesDir(null);try(FileOutputStream output=new FileOutputStream(new File(dir,"ui101-report.json"))){output.write(report.toString(2).getBytes("UTF-8"));}}catch(Exception ignored){}Bundle result=new Bundle();result.putString("report",report.toString());finish(0,result);}
    }
}
