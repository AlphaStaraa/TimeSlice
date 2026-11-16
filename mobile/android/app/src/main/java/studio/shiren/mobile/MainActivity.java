package studio.shiren.mobile;

import android.app.*;
import android.os.*;
import android.content.*;
import android.content.res.ColorStateList;
import android.net.Uri;
import android.graphics.*;
import android.graphics.drawable.*;
import android.provider.*;
import android.view.*;
import android.widget.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.nio.*;
import java.io.*;
import java.util.function.*;
import org.json.JSONObject;

/** 手机竖屏工作台；素材准备、轻量预览和正式导出具有独立状态。 */
public final class MainActivity extends Activity {
    int BG,PANEL,INK,MUTED,ACCENT;boolean dark;
    final Handler ui=new Handler(Looper.getMainLooper());
    final ExecutorService worker=Executors.newSingleThreadExecutor(),preparer=Executors.newSingleThreadExecutor();
    final AtomicBoolean pending=new AtomicBoolean();
    AtomicBoolean cancel=new AtomicBoolean(),prepareCancel=new AtomicBoolean();
    List<Effect> effects;List<EffectGroup> groups;Effect active;
    final Map<String,Integer> catalogueActive=new HashMap<>();
    final Map<Integer,Effect.Settings> settings=new HashMap<>();
    final LinkedHashSet<Integer> selected=new LinkedHashSet<>();
    final SourceOptions sourceOptions=new SourceOptions();
    VideoSource source;VideoSource.Cache preview,baseCache,preparedCache;SourceProcessor.Result sourceReport;
    String baseKey="",preparedKey="",mode="auto";Renderer renderer;
    PhoneWorkspace workspace;PhoneSheets panels;
    ImageView image,inspectorImage,fullPreviewImage;Bitmap lastPreview;TextView status,metadata,clock,prepareStatus,exportStatus,selectedLabel;
    Button export,play;SeekBar timeline;ProgressBar prepareBar,exportBar;
    LinearLayout cards,queue,queueCards;
    HorizontalScrollView libraryScroll,queueScroll;
    String exportFormat="h264";
    boolean gradientDither=true;
    int family=0,edge=1280,samples=48,fps=30,bitrate=0,version=0,view=0,prepareGeneration=0,gradeEndpoint=0,hslBand=0,pendingMapId=100;
    boolean previewOnce=false,batchMode=false,busy=false,preparing=false,playing=false,keepSound=true,english=false,freezeSplit=false,exportAfterPreparation=false;
    float u=0,freezeDiscard=.6f;long lastTick;Uri lastOutput,outputTree;
    AlertDialog riskDialog;Dialog inspectorDialog;
    JSONObject englishStrings=new JSONObject(),englishEffects=new JSONObject();

    /* 根据当前语言选择显示文本，功能标识仍使用稳定键。 */
    String t(String zh,String en){return english?en:zh;}
    /* 翻译效果和分组名称，英文品牌固定为TimeSlice。 */
    String tr(String text){
        if(!english||text==null)return text;String exact=englishStrings.optString(text,"");if(!exact.isEmpty())return exact;
        String[][] prefixes={{"读取时间画面 ","Reading source "},{"匹配固定机位 ","Matching camera "},{"亚像素精修 ","Refining alignment "},{"稳定画面 ","Stabilizing "},{"分析亮度 ","Analyzing exposure "},{"去闪修正 ","Deflickering "},{"系统编码 · ","System encoder · "}};
        for(String[] prefix:prefixes)if(text.startsWith(prefix[0]))return (prefix[1]+text.substring(prefix[0].length())).replace(" · 原序列"," · Original sequence ").replace("张"," images");return text;
    }
    /* 英文界面翻译计算设备说明，保留显卡和驱动的真实型号。 */
    String deviceLabel(){return renderer==null?"":english?renderer.label.replace("GPU 时间计算 · CPU 合成","GPU field · CPU composition").replace("CPU 多线程","CPU").replace("显卡暂不可用","GPU unavailable").replace("GPU 运行失败已切换","GPU fallback"):renderer.label;}
    /* 返回当前效果的短名称。 */
    String name(Effect effect){return english?englishEffects.optString(effect.key,tr(effect.name)):effect.name;}
    /* 将密度无关尺寸转换为设备像素。 */
    int dp(float value){return Math.round(value*getResources().getDisplayMetrics().density);}
    /* 在仍有效的界面线程上接收后台结果。 */
    void post(Runnable action){ui.post(()->{if(!isFinishing()&&!isDestroyed())action.run();});}
    /* 构造系统字体文本，不额外打包字体资源。 */
    TextView text(String value,int size,int color){TextView out=new TextView(this);out.setText(value);out.setTextSize(size);out.setTextColor(color);out.setIncludeFontPadding(false);out.setGravity(Gravity.CENTER_VERTICAL);return out;}
    /* 旧业务入口共用新的低对比手机面板样式。 */
    GradientDrawable glass(boolean primary,int radius){return StudioUi.shape(this,primary?StudioUi.BLUE:StudioUi.SURFACE,radius,false);}

    /* 创建纵向布局。 */
    LinearLayout column(){LinearLayout out=new LinearLayout(this);out.setOrientation(LinearLayout.VERTICAL);return out;}
    /* 添加带统一间距的布局子项。 */
    void add(LinearLayout parent,View child,int height){LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,height<0?height:dp(height));p.bottomMargin=dp(10);parent.addView(child,p);}
    /* 主次按钮统一字体和按压态，只有主要操作使用蓝色。 */
    Button button(String label,boolean primary,Runnable action){return StudioUi.button(this,label,primary,action);}

    /* 二级分段采用一个低对比底板，选中项使用浅灰层级。 */
    void segments(LinearLayout parent,String[] labels,int current,IntConsumer changed){
        LinearLayout row=new LinearLayout(this);row.setPadding(dp(3),dp(3),dp(3),dp(3));row.setBackground(StudioUi.shape(this,StudioUi.WELL,14,false));
        for(int i=0;i<labels.length;i++){final int at=i;Button item=button(labels[i],false,()->changed.accept(at));item.setTextSize(12);item.setTextColor(i==current?INK:MUTED);item.setBackground(StudioUi.shape(this,i==current?StudioUi.SELECTED:Color.TRANSPARENT,11,false));row.addView(item,new LinearLayout.LayoutParams(0,-1,1));}
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(44));p.topMargin=dp(8);p.bottomMargin=dp(8);parent.addView(row,p);
    }

    /* 记录状态供错误诊断，普通设备信息不再占据首页。 */
    void message(String value){if(status!=null){status.setText(value);status.setVisibility(View.GONE);}}

    /* 报告当前任务失败，不隐藏已经成功保存的文件。 */
    void fail(Exception error){post(()->{busy=false;exportAfterPreparation=false;updateButton();getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);message(tr(error.getMessage()));if(cancel.get()&&error.getMessage()!=null&&(error.getMessage().contains("已取消")||error.getMessage().contains("Cancelled"))){exportStatus.setText(t("已取消，已完成视频保留。","Cancelled. Completed videos were kept."));return;}StudioUi.alertBuilder(this).setTitle(t("这一步没有完成","Could not finish")).setMessage(tr(error.getMessage())).setPositiveButton(t("知道了","OK"),null).show();});}

    /** 统一系统外观与用户选择，所有页面复用同一套颜色。 */
    void updatePalette(){
        int appearance=getPreferences(0).getInt("appearance",0);
        dark=appearance==2||appearance==0&&(getResources().getConfiguration().uiMode&android.content.res.Configuration.UI_MODE_NIGHT_MASK)==android.content.res.Configuration.UI_MODE_NIGHT_YES;
        setTheme(dark?android.R.style.Theme_Material_NoActionBar:android.R.style.Theme_Material_Light_NoActionBar);
        BG=dark?0xff18253a:0xffedf2fa;PANEL=dark?0xff26384f:0xfff6f9ff;
        INK=dark?0xfff2f6ff:0xff172339;MUTED=dark?0xffb4c5dc:0xff586c88;ACCENT=dark?0xff93caff:0xff0964cc;
        StudioUi.palette(dark);
    }

    /* 创建手机工作台并加载沿用桌面的原始预览素材。 */
    @Override public void onCreate(Bundle state){
        updatePalette();super.onCreate(state);english=getPreferences(0).getBoolean("english",false);String output=getPreferences(0).getString("output","");if(!output.isEmpty())outputTree=Uri.parse(output);
        try{englishStrings=new JSONObject(new String(Assets.read(this,"en.json"),"UTF-8"));englishEffects=new JSONObject(new String(Assets.read(this,"effects-en.json"),"UTF-8"));effects=Effect.load(this);groups=EffectGroup.load(this,effects);for(EffectGroup group:groups)catalogueActive.put(group.key,group.defaultId);active=effects.get(0);for(Effect effect:effects)settings.put(effect.id,effect.defaults());selected.add(active.id);}catch(Exception error){throw new RuntimeException(error);}
        buildUI();worker.execute(()->{try{renderer=new Renderer(this,mode);post(()->message(deviceLabel()));}catch(Exception error){fail(error);}});incoming(getIntent());
    }

    /* 首屏布局与参数面板独立，后台处理状态不随界面重建丢失。 */
    void buildUI(){updatePalette();if(panels==null)panels=new PhoneSheets(this);workspace=new PhoneWorkspace(this);workspace.mount();}


    /* 接收系统共享或外部应用送入的本地视频。 */
    void incoming(Intent intent){if(intent==null)return;Uri uri=Intent.ACTION_VIEW.equals(intent.getAction())?intent.getData():Intent.ACTION_SEND.equals(intent.getAction())?intent.getParcelableExtra(Intent.EXTRA_STREAM):null;if(uri!=null&&!busy)importVideo(uri);}
    /* 新分享不覆盖正在输出的任务。 */
    @Override public void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);incoming(intent);}
    /* 系统选择器直接导入延时视频，避免多余的素材类型选择。 */
    void pick(){if(busy)return;playing=false;Intent request=new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("video/*").addCategory(Intent.CATEGORY_OPENABLE);request.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);startActivityForResult(request,10);}
    /* 保留使用者选择的文档权限，并在后台读元数据。 */
    @Override public void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(result!=RESULT_OK||data==null)return;Uri uri=data.getData();if(uri==null)return;try{getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION|(request==12?Intent.FLAG_GRANT_WRITE_URI_PERMISSION:0));}catch(SecurityException ignored){}if(request==12){outputTree=uri;getPreferences(0).edit().putString("output",uri.toString()).apply();message(t("已选择导出文件夹","Export folder selected"));if(panels!=null)panels.refreshLocation();}else if(request==10)importVideo(uri);else if(request==13){final int id=pendingMapId;worker.execute(()->{try{TimeMap map=TimeMap.load(this,uri);post(()->{settings.get(id).timeMap=map;version++;requestPreview();message(t("已导入浮点时间图","Time map imported"));});}catch(Exception error){fail(error);}});}}

    /* 视频元数据读取失败时保留原工作台。 */
    void importVideo(Uri uri){worker.execute(()->{try{VideoSource next=new VideoSource(this,uri);post(()->attachSource(next));}catch(Exception error){fail(error);}});}
    /* 切换素材身份后立即开始准备正式缓存。 */
    void attachSource(VideoSource next){prepareCancel.set(true);prepareGeneration++;source=next;sourceReport=null;lastPreview=null;preparedKey="";baseKey="";playing=false;u=0;version++;VideoSource.Cache old=preview;preview=null;releaseLater(old,baseCache,preparedCache);baseCache=null;preparedCache=null;buildUI();prepareSource();}
    /* 预览线程用完旧缓存后再释放，避免替换期间出现悬空指针。 */
    void releaseLater(VideoSource.Cache... caches){Set<VideoSource.Cache> unique=Collections.newSetFromMap(new IdentityHashMap<>());for(VideoSource.Cache cache:caches)if(cache!=null)unique.add(cache);worker.execute(()->{for(VideoSource.Cache cache:unique)cache.close();});}
    /* 正式源缓存身份不包括切片、阴影或实时调色。 */
    String sourceKey(){return source==null?"":source.uri+"/"+source.width+"x"+source.height+"/"+source.durationUs+"/"+edge+"/"+samples+"/"+VideoColor.precision(source,exportFormat);}

    /* 素材选项改变就准备输出尺寸缓存，预览仍可切换效果。 */
    void prepareSource(){
        if(source==null||busy)return;String key=sourceKey(),fullKey=key+"/"+sourceOptions.processingKey();
        if(preparedCache!=null&&fullKey.equals(preparedKey)){updateGrade();return;}
        prepareCancel.set(true);prepareCancel=new AtomicBoolean();final AtomicBoolean stop=prepareCancel;final int generation=++prepareGeneration;
        final VideoSource input=source;final int requestedEdge=edge,requestedSamples=samples;final boolean requestedPrecision=VideoColor.precision(input,exportFormat);final SourceOptions opts=sourceOptions.copy();
        final VideoSource.Cache reuse=key.equals(baseKey)?baseCache:null;preparing=true;prepareBar.setVisibility(View.VISIBLE);prepareStatus.setVisibility(View.VISIBLE);prepareBar.setProgress(0);TimeEstimate eta=new TimeEstimate();if(panels!=null)panels.updateProgress(true,t("准备素材…","Preparing source…"),0);
        preparer.execute(()->{
            VideoSource.Cache base=null,small=null;SourceProcessor.Result result=null;
            try{
                VideoSource.Progress progress=(p,label)->post(()->{if(generation==prepareGeneration){prepareBar.setProgress((int)(p*1000));prepareStatus.setText(prepareLabel(label,p,eta.remaining(p,english)));if(panels!=null)panels.updateProgress(true,prepareStatus.getText().toString(),p);}});
                base=reuse!=null?reuse:input.read(requestedEdge,requestedSamples,stop,(p,label)->progress.update(.25f*p,label),requestedPrecision);VideoSource.check(stop);
                result=SourceProcessor.process(this,base,opts,stop,(p,label)->progress.update(.25f+.7f*p,label));VideoSource.check(stop);
                small=SourceProcessor.preview(this,result.cache,480);VideoSource.check(stop);
                final VideoSource.Cache newBase=base,newPreview=small;final SourceProcessor.Result ready=result;
                ui.post(()->{
                    if(isFinishing()||isDestroyed()||generation!=prepareGeneration){if(newBase!=reuse)newBase.close();if(ready.cache!=newBase)ready.cache.close();newPreview.close();return;}
                    VideoSource.Cache oldBase=baseCache,oldFull=preparedCache,oldPreview=preview;baseCache=newBase;baseKey=key;preparedCache=ready.cache;preview=newPreview;sourceReport=ready;preparedKey=fullKey;preparing=false;
                    if(sourceOptions.direction.equals("auto")&&!sourceOptions.look.equals("custom"))sourceOptions.preset(sourceOptions.look,ready.nightToDay);updateGrade();
                    prepareBar.setProgress(1000);prepareBar.setVisibility(View.GONE);prepareStatus.setVisibility(View.GONE);if(panels!=null)panels.updateProgress(false,null,1);
                    metadata.setText(workspace.metadata());
                    Set<VideoSource.Cache> stale=Collections.newSetFromMap(new IdentityHashMap<>());for(VideoSource.Cache c:new VideoSource.Cache[]{oldBase,oldFull,oldPreview})if(c!=null&&c!=newBase&&c!=ready.cache&&c!=newPreview)stale.add(c);releaseLater(stale.toArray(new VideoSource.Cache[0]));
                    version++;requestPreview();updateButton();if(exportAfterPreparation){exportAfterPreparation=false;startExport();}
                });
            }catch(Exception error){if(small!=null)small.close();if(result!=null&&result.cache!=base)result.cache.close();if(base!=null&&base!=reuse)base.close();post(()->{if(generation==prepareGeneration){preparing=false;exportAfterPreparation=false;prepareStatus.setText(t("准备未完成：","Preparation failed: ")+error.getMessage());prepareBar.setVisibility(View.GONE);if(panels!=null)panels.updateProgress(false,prepareStatus.getText().toString(),0);message(tr(error.getMessage()));updateButton();}});}
        });
    }

    /* 压缩工作阶段文字，给百分比和预计时间留出固定空间。 */
    String prepareLabel(String label,float progress,String eta){String stage=label.contains("匹配")||label.contains("稳定")||label.contains("精修")?t("稳定","Stabilize"):label.contains("去闪")?t("去闪","Deflicker"):label.contains("亮度")?t("分析","Analyze"):t("准备","Prepare");return stage+"  "+Math.round(progress*100)+"% · "+eta;}
    /* 调色只更新小配置，既不重读素材，也不再次稳定去闪。 */
    void updateGrade(){if(preview!=null)preview.grade=sourceOptions.buffer(preview.frames,preview.brightness);if(preparedCache!=null)preparedCache.grade=sourceOptions.buffer(preparedCache.frames,preparedCache.brightness);version++;requestPreview();}
    /* 返回当前形状组。 */
    EffectGroup activeGroup(){for(EffectGroup group:groups)if(group.contains(active.id))return group;throw new IllegalStateException("Missing effect group");}
    /* 按稳定效果ID查找定义。 */
    Effect effectById(int id){for(Effect effect:effects)if(effect.id==id)return effect;throw new IllegalArgumentException("Missing effect "+id);}
    /* 切换效果不会取消准备任务或清空跨系列选择。 */
    void selectVariant(int id){if(busy)return;playing=false;if(workspace!=null)workspace.updatePlay();active=effectById(id);catalogueActive.put(activeGroup().key,id);u=0;version++;refreshLibrary();refreshSelection();requestPreview();}
    /* 全部冻结形状共用昼夜模式和跳过比例。 */
    void setFreezeSplit(boolean split){freezeSplit=split;for(Effect effect:effects)if(effect.family==0){settings.get(effect.id).dayNightSplit=split;settings.get(effect.id).discardRatio=freezeDiscard;}u=0;version++;refreshLibrary();requestPreview();}

    /* 更新类别、缩略卡和当前预览标记。 */
    void refreshLibrary(){if(workspace!=null)workspace.refreshLibrary();}

    /* 图片与外框采用同心圆角，手机卡片保持静止。 */
    ImageView thumbnail(Effect effect,int radius){ImageView image=new StudioUi.RoundImage(this,radius);image.setScaleType(ImageView.ScaleType.CENTER_CROP);GradientDrawable mask=new GradientDrawable();mask.setColor(0xff102030);mask.setCornerRadius(dp(radius));image.setBackground(mask);image.setClipToOutline(true);try{image.setImageBitmap(BitmapFactory.decodeStream(getAssets().open("thumbnails/"+effect.key+".jpg")));}catch(IOException ignored){}return image;}


    /* 批量时展示可拖拽队列，单个输出保持简洁。 */
    void refreshSelection(){if(workspace!=null)workspace.refreshSelection();}


    /* 单个模式直接切换；批量模式才勾选多个，队列预览不改变选择。 */
    void onLibraryTap(int id){if(busy)return;view=0;if(batchMode&&selected.contains(id)){selected.remove(id);refreshSelection();refreshLibrary();updateButton();return;}if(!batchMode)selected.clear();selected.add(id);previewEffect(id);refreshSelection();refreshLibrary();updateButton();}
    /* 仅演示用户刚选择的一个效果，图库本身保持静止。 */
    void previewEffect(int id){view=0;selectVariant(id);if(preview==null||renderer==null)return;previewOnce=true;playing=true;if(workspace!=null)workspace.updatePlay();lastTick=System.nanoTime();ui.removeCallbacks(tick);ui.post(tick);}
    /* 关于页从实际安装包读取版本，首页不重复放版本文案。 */
    String appVersion(){try{return getPackageManager().getPackageInfo(getPackageName(),0).versionName.split("-")[0];}catch(Exception ignored){return "1.0.1";}}
    /* 原地拖放保持顺序，其余拖放按目标索引移动，左右方向都能准确移动一位。 */
    void moveSelection(int fromId,int targetId){
        if(busy||fromId==targetId)return;List<Integer> order=new ArrayList<>(selected);int from=order.indexOf(fromId),target=order.indexOf(targetId);if(from<0||target<0)return;order.remove(from);order.add(target,fromId);selected.clear();selected.addAll(order);refreshSelection();
    }
    /* 获取一帧合成的独立参数快照，过期结果不覆盖新效果。 */
    void requestPreview(){
        if(preview==null||renderer==null||busy||!pending.compareAndSet(false,true))return;
        final int serial=version,show=view;final float at=u;final Effect effect=active;final Effect.Settings current=settings.get(effect.id).copy();final VideoSource.Cache cache=preview;int[] dimensions=source.size(edge);current.outputWidth=dimensions[0];current.outputHeight=dimensions[1];
        worker.execute(()->{try{ByteBuffer pixels=renderer.frame(cache,effect,current,at,show);int[] argb=new int[cache.w*cache.h];NativeCore.toARGB(pixels,argb);Bitmap bitmap=Bitmap.createBitmap(argb,cache.w,cache.h,Bitmap.Config.ARGB_8888);post(()->{if(serial==version){image.setImageBitmap(bitmap);lastPreview=bitmap;if(inspectorImage!=null)inspectorImage.setImageBitmap(bitmap);if(fullPreviewImage!=null)fullPreviewImage.setImageBitmap(bitmap);if(workspace!=null)workspace.setTime(at,effect.seconds(current));}else bitmap.recycle();});}catch(Exception error){post(()->message(t("预览失败：","Preview failed: ")+error.getMessage()));}finally{pending.set(false);post(()->{if(serial!=version&&!busy)requestPreview();});}});
    }
    /* 昼夜分割在最后一片停止，再次播放从头开始。 */
    void togglePlay(){if(preview==null||busy)return;previewOnce=false;if(!playing&&u>=1)u=0;playing=!playing;if(workspace!=null)workspace.updatePlay();lastTick=System.nanoTime();ui.removeCallbacks(tick);if(playing)ui.post(tick);}
    final Runnable tick=new Runnable(){/* 使用单调时间推进预览，不以解码耗时改变实际效果时长。 */public void run(){if(!playing)return;long now=System.nanoTime();u+=(now-lastTick)/1e9f/active.seconds(settings.get(active.id));lastTick=now;if(u>=1&&(previewOnce||active.family==0&&freezeSplit)){previewOnce=false;u=1;playing=false;if(workspace!=null)workspace.updatePlay();}else u%=1;timeline.setProgress((int)(u*1000));requestPreview();if(playing)ui.postDelayed(this,50);}};

    /* 设置行左侧是名称、右侧是当前值，菜单避免重复大标题和胶囊。 */
    Spinner choice(LinearLayout form,String caption,String[] labels,int current,IntConsumer changed){
        LinearLayout row=new LinearLayout(this);row.setGravity(Gravity.CENTER_VERTICAL);TextView name=text(caption,13,MUTED);name.setMaxLines(2);row.addView(name,new LinearLayout.LayoutParams(dp(104),dp(52)));
        Spinner spinner=new Spinner(this,Spinner.MODE_DROPDOWN);spinner.setContentDescription(caption);ArrayAdapter<String> adapter=new ArrayAdapter<String>(this,android.R.layout.simple_spinner_dropdown_item,labels){
            /* 当前值右对齐，沿用系统字体的可读字号。 */public View getView(int index,View convert,ViewGroup parent){TextView item=convert instanceof TextView?(TextView)convert:text("",14,INK);item.setText(getItem(index));item.setTextColor(INK);item.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);item.setPadding(dp(8),0,dp(6),0);item.setSingleLine(true);item.setEllipsize(android.text.TextUtils.TruncateAt.END);return item;}
            /* 弹出菜单使用足够高的命中区和简洁选项。 */public View getDropDownView(int index,View convert,ViewGroup parent){TextView item=convert instanceof TextView?(TextView)convert:text("",14,INK);item.setText(getItem(index));item.setTextColor(INK);item.setGravity(Gravity.CENTER_VERTICAL);item.setPadding(dp(16),dp(12),dp(16),dp(12));item.setMinHeight(dp(48));return item;}
        };
        spinner.setAdapter(adapter);spinner.setBackgroundColor(Color.TRANSPARENT);spinner.setPopupBackgroundDrawable(StudioUi.glass(this,18));spinner.setDropDownWidth(dp(220));spinner.setSelection(Math.max(0,current));spinner.setTag(Math.max(0,current));spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener(){/* 只提交真实选择，不把初始化回调当成修改。 */public void onItemSelected(AdapterView<?> parent,View view,int index,long id){int old=(Integer)spinner.getTag();spinner.setTag(index);if(index!=old)changed.accept(index);}/* 关闭菜单不修改参数。 */public void onNothingSelected(AdapterView<?> parent){}});
        row.addView(spinner,new LinearLayout.LayoutParams(0,dp(52),1));ImageView arrow=new ImageView(this);arrow.setImageDrawable(new StudioUi.Glyph("chevron",MUTED,dp(16)));row.addView(arrow,new LinearLayout.LayoutParams(dp(18),dp(24)));form.addView(row);StudioUi.divider(this,form);return spinner;
    }

    /* 开关关闭时使用中性颜色，开启时才强调状态。 */
    Switch toggle(LinearLayout form,String caption,boolean checked,Consumer<Boolean> changed){Switch item=new Switch(this);item.setText(caption);item.setTextColor(INK);item.setTextSize(14);item.setPadding(0,0,0,0);item.setShowText(false);item.setChecked(checked);item.setThumbTintList(ColorStateList.valueOf(0xfff3f5fa));item.setTrackTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},new int[]{StudioUi.BLUE,StudioUi.LINE}));item.setOnCheckedChangeListener((button,on)->changed.accept(on));form.addView(item,new LinearLayout.LayoutParams(-1,dp(52)));StudioUi.divider(this,form);return item;}

    /* 滑块标题与数值分列，去掉无意义的小数和重复说明。 */
    void range(LinearLayout form,String caption,float low,float high,float value,String unit,Consumer<Float> changed){
        LinearLayout row=new LinearLayout(this);TextView name=text(caption,13,MUTED);row.addView(name,new LinearLayout.LayoutParams(0,dp(26),1));TextView number=text(formatValue(value)+unit,12,INK);number.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);row.addView(number,new LinearLayout.LayoutParams(dp(74),dp(26)));form.addView(row);
        SeekBar bar=new SeekBar(this);bar.setPadding(dp(2),0,dp(2),0);bar.setContentDescription(caption);bar.setMax(1000);bar.setProgress(Math.round((value-low)/(high-low)*1000));bar.setProgressTintList(ColorStateList.valueOf(0xff779ee5));bar.setThumbTintList(ColorStateList.valueOf(0xffdae5fa));bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){/* 拖动不启动源素材重处理。 */public void onStartTrackingTouch(SeekBar s){}/* 松手保留最新值。 */public void onStopTrackingTouch(SeekBar s){}/* 立即刷新当前预览。 */public void onProgressChanged(SeekBar s,int p,boolean user){if(user){float next=low+(high-low)*p/1000;number.setText(formatValue(next)+unit);changed.accept(next);}}});LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(32));p.bottomMargin=dp(8);form.addView(bar,p);
    }

    /* 数值直接在同一行编辑，不使用一项一个大输入框。 */
    EditText number(LinearLayout form,String caption,float initial,float minimum,float maximum,boolean whole,Consumer<Float> changed){
        LinearLayout row=new LinearLayout(this);row.setGravity(Gravity.CENTER_VERTICAL);TextView label=text(caption,13,MUTED);row.addView(label,new LinearLayout.LayoutParams(0,dp(52),1));EditText field=new EditText(this);field.setContentDescription(caption);field.setTextColor(INK);field.setTextSize(15);field.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);field.setSingleLine(true);field.setSelectAllOnFocus(true);field.setPadding(dp(8),0,dp(6),0);field.setBackgroundColor(Color.TRANSPARENT);field.setInputType(android.text.InputType.TYPE_CLASS_NUMBER|(whole?0:android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL));field.setText(formatValue(initial));field.setOnFocusChangeListener((v,focus)->{if(!focus)try{float value=Float.parseFloat(field.getText().toString());if(Float.isFinite(value)){if(whole)value=Math.round(value);value=Math.max(minimum,Math.min(maximum,value));field.setText(formatValue(value));if(Math.abs(value-initial)>.00001)changed.accept(value);}}catch(NumberFormatException ignored){field.setText(formatValue(initial));}});field.setOnEditorActionListener((v,id,event)->{field.clearFocus();android.view.inputmethod.InputMethodManager keyboard=(android.view.inputmethod.InputMethodManager)getSystemService(INPUT_METHOD_SERVICE);if(keyboard!=null)keyboard.hideSoftInputFromWindow(field.getWindowToken(),0);form.setFocusableInTouchMode(true);form.requestFocus();return true;});row.addView(field,new LinearLayout.LayoutParams(dp(112),dp(52)));form.addView(row);StudioUi.divider(this,form);return field;
    }
    /* 仅在有意义时显示小数，保持数值排版简洁。 */
    String formatValue(float value){if(Math.abs(value-Math.round(value))<.0005)return String.valueOf(Math.round(value));if(Math.abs(value*10-Math.round(value*10))<.0005)return String.format(Locale.ROOT,"%.1f",value);return String.format(Locale.ROOT,"%.2f",value);}


    /* 点按画面进入全屏审看，双指缩放查看局部，完成按钮返回。 */
    void showFullPreview(){
        if(lastPreview==null)return;Dialog dialog=new Dialog(this,android.R.style.Theme_Material_NoActionBar_Fullscreen);FrameLayout frame=new FrameLayout(this);frame.setBackgroundColor(Color.BLACK);ImageView full=new ImageView(this);full.setScaleType(ImageView.ScaleType.FIT_CENTER);full.setImageBitmap(lastPreview);fullPreviewImage=full;dialog.setOnDismissListener(d->{if(fullPreviewImage==full)fullPreviewImage=null;});frame.addView(full,new FrameLayout.LayoutParams(-1,-1));
        final float[] scale={1};ScaleGestureDetector detector=new ScaleGestureDetector(this,new ScaleGestureDetector.SimpleOnScaleGestureListener(){/* 缩放只影响审看视图，不改变输出裁切。 */public boolean onScale(ScaleGestureDetector gesture){scale[0]=Math.max(1,Math.min(5,scale[0]*gesture.getScaleFactor()));full.setScaleX(scale[0]);full.setScaleY(scale[0]);return true;}});full.setOnTouchListener((v,event)->{detector.onTouchEvent(event);return true;});Button close=button(t("完成","Done"),false,dialog::dismiss);FrameLayout.LayoutParams layout=new FrameLayout.LayoutParams(dp(84),dp(44),Gravity.TOP|Gravity.END);layout.topMargin=dp(24);layout.rightMargin=dp(16);frame.addView(close,layout);dialog.setContentView(frame);dialog.show();
    }
    /* 参数按素材、当前效果和导出分别呈现，不在首页平铺。 */
    void showInspector(int page){if(panels==null)panels=new PhoneSheets(this);panels.show(page);}





    /* 公开与桌面一致的中心、入出点、多源数量及自定义灰度时间图。 */
    void advancedForm(LinearLayout form,Effect effect,Effect.Settings current){

        range(form,t("中心水平","Center X"),0,1,current.centerX,"",value->{current.centerX=value;version++;requestPreview();});
        range(form,t("中心垂直","Center Y"),0,1,current.centerY,"",value->{current.centerY=value;version++;requestPreview();});
        range(form,t("素材入点","Source in"),0,100,current.sourceStart*100,"%",value->{current.sourceStart=Math.min(current.sourceEnd-.001f,value/100);version++;requestPreview();});
        range(form,t("素材出点","Source out"),0,100,current.sourceEnd*100,"%",value->{current.sourceEnd=Math.max(current.sourceStart+.001f,value/100);version++;requestPreview();});
        range(form,t("波纹密度","Ripple density"),.02f,2,current.density,"",value->{current.density=value;version++;requestPreview();});
        if(effect.id==403)choice(form,t("时间源","Time sources"),new String[]{"2","3","4"},current.waveSources-2,index->{current.waveSources=index+2;version++;requestPreview();});
        if(effect.family!=3){
            add(form,button(t("导入灰度时间图…","Import grayscale time map…"),false,()->{pendingMapId=effect.id;startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*").putExtra(Intent.EXTRA_MIME_TYPES,new String[]{"image/png","image/tiff","image/jpeg"}).addCategory(Intent.CATEGORY_OPENABLE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),13);}),44);
            if(current.timeMap!=null){choice(form,t("时间图模式","Time map mode"),new String[]{t("绝对时刻","Absolute time"),t("相对偏移","Relative offset")},current.mapMode,index->{current.mapMode=index;version++;requestPreview();});add(form,text(current.timeMap.bits+t("位浮点采样","-bit precision"),11,MUTED),-2);add(form,button(t("恢复内置形状","Use built-in shape"),false,()->{current.timeMap=null;version++;requestPreview();}),40);}
        }
    }




    /* 查找当前数值对应的设置行。 */
    int index(int[] values,int current){for(int i=0;i<values.length;i++)if(values[i]==current)return i;return 0;}
    /* 显示完整开源声明，作者和英文品牌保持一致。 */
    void showAbout(){PhoneAbout.show(this);}

    /* 首页仅保留一个主操作，工作期间显示清晰的取消入口。 */
    void updateButton(){if(export==null)return;export.setText(busy?t("取消","Cancel"):exportAfterPreparation?t("取消等待","Cancel wait"):selected.size()>1?t("导出 ","Export ")+selected.size()+t(" 项",""):t("导出","Export"));export.setEnabled(busy||source!=null&&!selected.isEmpty());export.setAlpha(export.isEnabled()?1:.35f);if(workspace!=null)workspace.updateBusy();exportBar.setVisibility(busy?View.VISIBLE:View.GONE);exportStatus.setVisibility(busy?View.VISIBLE:View.GONE);}

    /* 高负载参数要求明确确认，继续时保留全部画质设置。 */
    void startExport(){
        if(busy){cancel.set(true);message(t("正在安全取消…","Cancelling safely…"));return;}if(source==null){message(t("请先导入素材","Import media first"));return;}if(selected.isEmpty())return;
        if(preparing||preparedCache==null||!preparedKey.equals(sourceKey()+"/"+sourceOptions.processingKey())){exportAfterPreparation=true;updateButton();if(!preparing)prepareSource();return;}
        int[] size=source.size(edge);int count=samples<=0?(int)Math.ceil(source.durationUs/1e6*source.fps):samples;float seconds=0;for(int id:selected)seconds+=effectById(id).seconds(settings.get(id));ExportSafety.Assessment risk=ExportSafety.inspect(size[0],size[1],fps,bitrate,count,seconds,exportFormat);
        if(risk.highLoad){String description=size[0]+" × "+size[1]+" · "+fps+" fps · "+(formatValue(ExportQuality.resolve(size[0],size[1],fps,bitrate)/1000000f)+" Mbps")+"\n\n"+t("这组参数会增加耗时、耗电和发热。请保持设备通风，并预留足够空间。","These settings increase rendering time, power use and heat. Keep the device ventilated and leave enough free space.")+"\n\n"+(risk.hardwareSupported?t("已找到支持所选参数的硬件编码器。","A hardware encoder supports these settings."):t("未确认硬件编码支持，可能需要兼容编码或调整参数。","Hardware encoding support is unconfirmed. Compatibility encoding or different settings may be needed."));riskDialog=StudioUi.alertBuilder(this).setTitle(t("高负载导出","High-load export")).setMessage(description).setPositiveButton(t("继续导出","Export anyway"),(d,w)->beginExport()).setNegativeButton(t("调整","Adjust"),(d,w)->showInspector(3)).setNeutralButton("1080p / 30fps",(d,w)->{edge=1920;fps=30;bitrate=0;exportAfterPreparation=true;prepareSource();}).show();}
        else beginExport();
    }

    /* 借用已经完成的正式缓存，不在导出时再执行稳定去闪。 */
    void beginExport(){
        if(renderer==null||preparedCache==null)return;playing=false;busy=true;version++;cancel=new AtomicBoolean();AtomicBoolean stop=cancel;final VideoSource.Cache cache=preparedCache;final VideoSource input=source;final int outputFps=fps,outputBits=bitrate;final String outputFormat=exportFormat;final boolean sound=keepSound,smoothGradient=gradientDither;final Uri target=outputTree;
        List<Effect> jobs=new ArrayList<>();Map<Integer,Effect.Settings> snapshots=new HashMap<>();
        for(int id:selected){jobs.add(effectById(id));snapshots.put(id,settings.get(id).copy());}
        updateButton();queue.removeAllViews();queue.setVisibility(View.GONE);exportBar.setProgress(0);getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);TimeEstimate eta=new TimeEstimate();
        worker.execute(()->{try{
            int all=0;for(Effect effect:jobs)all+=Math.max(1,Math.round(effect.seconds(snapshots.get(effect.id))*outputFps));int completed=0,index=0;
            for(Effect effect:jobs){VideoSource.check(stop);Effect.Settings s=snapshots.get(effect.id);s.exportDither=smoothGradient;s.exportFormat=outputFormat;int total=Math.max(1,Math.round(effect.seconds(s)*outputFps));File movie=new File(getCacheDir(),"render_"+UUID.randomUUID()+".mp4");
                try{ByteBuffer first=null;Uri audio=input.uri;boolean withAudio=sound;
                    try(VideoEncoder encoder=new VideoEncoder(this,audio,movie,cache.w,cache.h,outputFps,withAudio,stop,outputBits,outputFormat)){
                        for(int frame=0;frame<total;frame++){
                            int heat=ExportSafety.pace(this,stop);float at=frame/(float)Math.max(1,effect.family==0&&s.dayNightSplit?total-1:total);ByteBuffer pixels=renderer.frame(cache,effect,s,at,0);if(frame==0)first=pixels;encoder.append(pixels,frame);
                            final int done=completed+frame+1,allFrames=all;final float fraction=done/(float)allFrames;final String state=name(effect)+" · "+(frame+1)+"/"+total+" · "+deviceLabel()+" / "+tr(encoder.label);
                            post(()->{exportBar.setProgress((int)(fraction*1000));exportStatus.setText(Math.round(fraction*100)+"% · "+eta.remaining(fraction,english)+(heat>=PowerManager.THERMAL_STATUS_MODERATE?t(" · 温度偏高，放慢处理"," · warm device, pacing render"):""));message(state);});
                        }encoder.finish(total/(float)outputFps);
                    }
                    VideoSource.check(stop);VideoValidator.check(this,movie,first,cache.w,cache.h,outputFormat,stop);String label=String.format(Locale.ROOT,"%02d_",++index)+name(effect);Uri saved=save(movie,label,stop,target);lastOutput=saved;completed+=total;
                    post(()->{queue.removeAllViews();queue.setVisibility(View.VISIBLE);TextView item=text(t("已保存 · 查看","Saved · View"),12,0xffa9d8ff);add(queue,item,36);item.setOnClickListener(v->startActivity(new Intent(Intent.ACTION_VIEW).setDataAndType(saved,"video/mp4").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)));});
                }finally{movie.delete();}
            }
            post(()->{busy=false;updateButton();exportBar.setVisibility(View.VISIBLE);exportBar.setProgress(1000);exportStatus.setText(t("导出完成","Export complete"));message(t("按队列顺序分别导出完成。","All effects exported separately in queue order."));getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);});
        }catch(Exception error){fail(error);}});
    }

    /* 默认保存系统相册，也支持使用者选择的文档文件夹；取消时清理未完成项。 */
    Uri save(File file,String name,AtomicBoolean stop,Uri tree)throws Exception{
        String filename="TimeSlice_"+name+"_"+System.currentTimeMillis()+".mp4";Uri uri;ContentValues values=new ContentValues();
        if(tree!=null){Uri folder=DocumentsContract.buildDocumentUriUsingTree(tree,DocumentsContract.getTreeDocumentId(tree));uri=DocumentsContract.createDocument(getContentResolver(),folder,"video/mp4",filename);}
        else{values.put(MediaStore.Video.Media.DISPLAY_NAME,filename);values.put(MediaStore.Video.Media.MIME_TYPE,"video/mp4");values.put(MediaStore.Video.Media.RELATIVE_PATH,"Movies/时刃");values.put(MediaStore.Video.Media.IS_PENDING,1);uri=getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI,values);}
        if(uri==null)throw new IOException("无法创建输出视频");
        try{try(InputStream input=new FileInputStream(file);OutputStream out=getContentResolver().openOutputStream(uri)){if(out==null)throw new IOException("无法写入输出位置");byte[] buffer=new byte[256*1024];int n;while((n=input.read(buffer))>=0){VideoSource.check(stop);out.write(buffer,0,n);}}if(tree==null){values.clear();values.put(MediaStore.Video.Media.IS_PENDING,0);getContentResolver().update(uri,values,null,null);}return uri;}
        catch(Exception error){if(tree==null)getContentResolver().delete(uri,null,null);else DocumentsContract.deleteDocument(getContentResolver(),uri);throw error;}
    }
    /* 离开前台时停止高负载输出，保留已完成视频。 */
    @Override public void onStop(){super.onStop();playing=false;if(busy)cancel.set(true);}
    /* 取消后台工作并释放自己创建的缓存，不触及用户原素材。 */
    @Override public void onDestroy(){cancel.set(true);prepareCancel.set(true);prepareGeneration++;playing=false;ui.removeCallbacksAndMessages(null);preparer.shutdown();worker.execute(()->{if(renderer!=null)renderer.close();Set<VideoSource.Cache> caches=Collections.newSetFromMap(new IdentityHashMap<>());for(VideoSource.Cache c:new VideoSource.Cache[]{preview,baseCache,preparedCache})if(c!=null)caches.add(c);for(VideoSource.Cache c:caches)c.close();});worker.shutdown();super.onDestroy();}
}
