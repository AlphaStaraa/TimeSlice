package studio.shiren.mobile;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.view.*;
import android.widget.*;
import java.util.*;
import java.util.function.Consumer;

/** 按用途渐进展开参数，首屏无需同时理解素材、几何、阴影和编码。 */
final class PhoneSheets {
    final MainActivity a;
    final Set<String> expanded=new HashSet<>();
    int sourcePage=0;
    TextView location,processingText;
    ProgressBar processingBar;
    Dialog current;
    ScrollView scroller;
    int visiblePage=-1;

    /* 保存面板展开状态，不复制效果或素材参数。 */
    PhoneSheets(MainActivity activity){a=activity;}

    /* 打开当前切片队列的导出设置。 */
    void showExport(){show(3);}

    /* 手机底部面板只呈现当前任务相关的分组，预览保持可见。 */
    void show(int page){
        if(a.busy)return;processingText=null;processingBar=null;a.playing=false;if(a.workspace!=null)a.workspace.updatePlay();
        boolean reuse=current!=null&&current.isShowing();int previousScroll=reuse&&visiblePage==page&&scroller!=null?scroller.getScrollY():0;
        Dialog dialog=reuse?current:new Dialog(a);current=dialog;visiblePage=page;a.inspectorDialog=dialog;
        LinearLayout shell=a.column();shell.setFocusableInTouchMode(true);shell.requestFocus();shell.setPadding(a.dp(20),a.dp(10),a.dp(20),a.dp(12));shell.setBackground(StudioUi.glass(a,26));shell.setClipToOutline(true);
        View handle=new View(a);handle.setBackground(StudioUi.shape(a,a.dark?0xff7386a1:0xffa2b3cd,2,false));LinearLayout.LayoutParams hp=new LinearLayout.LayoutParams(a.dp(30),a.dp(3));hp.gravity=Gravity.CENTER;hp.bottomMargin=a.dp(10);shell.addView(handle,hp);
        LinearLayout heading=new LinearLayout(a);heading.setGravity(Gravity.CENTER_VERTICAL);String title=page==0?a.t("素材","Source"):page==3?a.t("导出","Export"):a.name(a.active);
        TextView name=a.text(title,19,a.INK);name.setTypeface(Typeface.create("sans-serif-medium",0));name.setSingleLine(true);name.setEllipsize(android.text.TextUtils.TruncateAt.END);heading.addView(name,new LinearLayout.LayoutParams(0,a.dp(44),1));heading.addView(StudioUi.iconButton(a,"close",a.t("关闭面板","Close panel"),dialog::dismiss),new LinearLayout.LayoutParams(a.dp(44),a.dp(44)));shell.addView(heading);
        final ImageView mini=new StudioUi.RoundImage(a,12);mini.setScaleType(ImageView.ScaleType.FIT_CENTER);mini.setBackground(StudioUi.shape(a,0xff0c0e13,12,false));mini.setClipToOutline(true);
        mini.setOnClickListener(v->a.showFullPreview());if(page!=3&&a.lastPreview!=null){mini.setImageBitmap(a.lastPreview);shell.addView(mini,new LinearLayout.LayoutParams(-1,a.dp(a.source!=null&&a.source.height>a.source.width?156:136)));a.inspectorImage=mini;}
        if(page==0)a.segments(shell,new String[]{a.t("画质","Quality"),a.t("调色","Color")},sourcePage,index->{sourcePage=index;show(0);});
        else if(page==1||page==2)a.segments(shell,new String[]{a.t("切片","Slices"),a.t("阴影","Shadow")},page==2?1:0,index->show(index==1?2:1));
        ScrollView scroll=new ScrollView(a);scroller=scroll;scroll.setFillViewport(false);scroll.setVerticalScrollBarEnabled(false);LinearLayout form=a.column();form.setPadding(0,a.dp(8),0,a.dp(8));scroll.addView(form);shell.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        if(page==0){if(sourcePage==0)quality(form);else color(form);}else if(page==1)effect(form);else if(page==2)shadow(form);else export(form);
        if(page==3){Button start=StudioUi.button(a,a.t("开始导出","Start export"),true,()->{form.clearFocus();dialog.dismiss();a.startExport();});shell.addView(start,new LinearLayout.LayoutParams(-1,a.dp(48)));}
        dialog.setContentView(shell);dialog.setOnDismissListener(d->{if(a.inspectorImage==mini)a.inspectorImage=null;if(a.inspectorDialog==dialog)a.inspectorDialog=null;if(current==dialog)current=null;});
        StudioUi.showSheet(a,dialog,shell,heightFraction(page));scroll.post(()->scroll.scrollTo(0,previousScroll));
    }

    /* 简短页面采用较低面板，复杂参数才使用更大高度。 */
    float heightFraction(int page){if(page==3)return .72f;if(page==0&&sourcePage==0&&!expanded.contains("source.info"))return .68f;if(page==0&&sourcePage==1&&!a.sourceOptions.grade)return .5f;if(page==2&&!a.active.shadowEnabled(a.settings.get(a.active.id)))return .58f;return .86f;}
    /* 非常用参数保持折叠，展开不会重置已调整的值。 */
    void fold(LinearLayout form,String key,String title,Consumer<LinearLayout> populate){
        LinearLayout row=new LinearLayout(a);row.setGravity(Gravity.CENTER_VERTICAL);TextView label=a.text(title,14,a.INK);label.setTypeface(Typeface.create("sans-serif-medium",0));row.addView(label,new LinearLayout.LayoutParams(0,a.dp(48),1));ImageView arrow=new ImageView(a);arrow.setImageDrawable(new StudioUi.Glyph("chevron",a.MUTED,a.dp(18)));row.addView(arrow,new LinearLayout.LayoutParams(a.dp(24),a.dp(24)));form.addView(row);
        LinearLayout content=a.column();content.setPadding(a.dp(12),a.dp(4),a.dp(12),a.dp(8));content.setBackground(StudioUi.glass(a,18));content.setVisibility(expanded.contains(key)?View.VISIBLE:View.GONE);arrow.setRotation(expanded.contains(key)?180:0);form.addView(content,new LinearLayout.LayoutParams(-1,-2));
        populate.accept(content);row.setOnClickListener(v->{boolean open=content.getVisibility()!=View.VISIBLE;content.setVisibility(open?View.VISIBLE:View.GONE);arrow.setRotation(open?180:0);if(open)expanded.add(key);else expanded.remove(key);});
    }

    /* 常用画质页只保留两项处理，进度由主预览旁的状态行显示。 */
    void quality(LinearLayout form){
        String[] stabilize={"off","lock","extreme"},deflicker={"off","light","standard","extreme"};
        a.choice(form,a.t("稳定","Stabilization"),new String[]{a.t("关闭","Off"),a.t("固定机位","Camera lock"),a.t("精细锁定","Precise lock")},Arrays.asList(stabilize).indexOf(a.sourceOptions.stabilize),index->{a.sourceOptions.stabilize=stabilize[index];a.prepareSource();});
        a.choice(form,a.t("去闪","Deflicker"),new String[]{a.t("关闭","Off"),a.t("轻柔","Gentle"),a.t("标准","Standard"),a.t("极致","Strong")},Arrays.asList(deflicker).indexOf(a.sourceOptions.deflicker),index->{a.sourceOptions.deflicker=deflicker[index];a.prepareSource();});
        addProgress(form);
        fold(form,"source.info",a.t("处理信息","Processing details"),box->{String message=a.sourceReport==null?a.t("导入素材后可处理","Available after import"):a.sourceReport.algorithm+"\n"+a.t("裁切 ","Crop ")+String.format(Locale.ROOT,"%.1f%%",(a.sourceReport.crop-1)*100);a.add(box,a.text(message,12,a.MUTED),-2);});
    }

    /* 调色以预设为起点，首尾微调和HSL只在需要时展开。 */
    void color(LinearLayout form){
        a.toggle(form,a.t("风格调色","Color style"),a.sourceOptions.grade,on->{a.sourceOptions.grade=on;a.updateGrade();show(0);});if(!a.sourceOptions.grade)return;
        String[] looks={"cinematic","natural","amber","custom"},directions={"auto","day_to_night","night_to_day"};
        a.choice(form,a.t("风格","Style"),new String[]{a.t("昼暖夜青","Warm / Cool"),a.t("自然","Natural"),a.t("琥珀","Amber"),a.t("自定","Custom")},Arrays.asList(looks).indexOf(a.sourceOptions.look),index->{a.sourceOptions.preset(looks[index],nightToDay());a.updateGrade();show(0);});
        a.choice(form,a.t("变化方向","Direction"),new String[]{a.t("自动","Automatic"),a.t("日转夜","Day to night"),a.t("夜转日","Night to day")},Arrays.asList(directions).indexOf(a.sourceOptions.direction),index->{a.sourceOptions.direction=directions[index];if(!a.sourceOptions.look.equals("custom"))a.sourceOptions.preset(a.sourceOptions.look,nightToDay());a.updateGrade();show(0);});
        fold(form,"color.endpoints",a.t("首尾微调","Fine-tune endpoints"),box->{
            a.segments(box,new String[]{a.t("首帧","First"),a.t("末帧","Last")},a.gradeEndpoint,index->{a.gradeEndpoint=index;show(0);});float[] values=a.gradeEndpoint==0?a.sourceOptions.start:a.sourceOptions.end;
            String[] names={a.t("色温","Temperature"),a.t("色调","Tint"),a.t("饱和度","Saturation"),a.t("曝光","Exposure"),a.t("对比","Contrast")};float[] lo={-100,-100,0,-2,.6f},hi={100,100,2,2,1.5f};
            for(int i=0;i<5;i++){final int channel=i;a.range(box,names[i],lo[i],hi[i],values[i],"",value->{values[channel]=value;a.sourceOptions.look="custom";a.updateGrade();});}
        });
        fold(form,"color.hsl","HSL",box->{a.choice(box,a.t("色彩","Color"),new String[]{a.t("红","Red"),a.t("橙","Orange"),a.t("黄","Yellow"),a.t("绿","Green"),a.t("青","Aqua"),a.t("蓝","Blue"),a.t("紫","Purple"),a.t("洋红","Magenta")},a.hslBand,index->{a.hslBand=index;show(0);});String[] labels={a.t("色相","Hue"),a.t("饱和度","Saturation"),a.t("明度","Luminance")};for(int i=0;i<3;i++){final int channel=i;a.range(box,labels[i],i==0?-60:-100,i==0?60:100,a.sourceOptions.hsl[a.hslBand][i],i==0?"°":"%",value->{a.sourceOptions.hsl[a.hslBand][channel]=value;a.updateGrade();});}});
    }

    /* 工作反馈同时出现在当前面板，避免被底部面板挡在主页后面。 */
    void addProgress(LinearLayout form){processingText=a.text(a.prepareStatus.getText().toString(),11,a.MUTED);processingText.setMaxLines(2);processingBar=new ProgressBar(a,null,android.R.attr.progressBarStyleHorizontal);processingBar.setMax(1000);processingBar.setProgress(a.prepareBar.getProgress());processingBar.setProgressTintList(android.content.res.ColorStateList.valueOf(a.ACCENT));processingText.setVisibility(a.preparing?View.VISIBLE:View.GONE);processingBar.setVisibility(a.preparing?View.VISIBLE:View.GONE);form.addView(processingText,new LinearLayout.LayoutParams(-1,-2));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,a.dp(2));p.topMargin=a.dp(6);form.addView(processingBar,p);}
    /* 处理完成即收起进度，错误保留简短反馈。 */
    void updateProgress(boolean working,String label,float fraction){if(processingText==null||processingBar==null)return;processingText.setText(label==null?"":label);processingText.setVisibility(working||label!=null&&!label.isEmpty()?View.VISIBLE:View.GONE);processingBar.setProgress(Math.round(fraction*1000));processingBar.setVisibility(working?View.VISIBLE:View.GONE);}
    /* 根据手动选择或实际分析结果取昼夜顺序。 */
    boolean nightToDay(){return a.sourceOptions.direction.equals("night_to_day")||a.sourceOptions.direction.equals("auto")&&a.sourceReport!=null&&a.sourceReport.nightToDay;}

    /* 当前形状只显示相关的运动和排列，避免所有类型共用一长页选项。 */
    void variants(LinearLayout form){
        EffectGroup group=a.activeGroup();EffectGroup.Variant current=group.variant(a.active.id);if(group.family!=1)return;List<String> motions=group.motions();
        if(motions.size()>1)a.choice(form,a.t("运动","Motion"),motions.stream().map(a::tr).toArray(String[]::new),motions.indexOf(current.motion),index->{List<EffectGroup.Variant> options=group.forMotion(motions.get(index));a.selectVariant(options.get(0).effect);show(1);});
        List<EffectGroup.Variant> options=group.forMotion(current.motion);if(options.size()>1){String[] labels=new String[options.size()];int selected=0;for(int i=0;i<labels.length;i++){labels[i]=a.tr(options.get(i).orientation);if(options.get(i).effect==a.active.id)selected=i;}a.choice(form,a.t("排列","Orientation"),labels,selected,index->{a.selectVariant(options.get(index).effect);show(1);});}
    }

    /* 片数和时长优先，其余几何、展开后动作与时间图收进高级。 */
    void effect(LinearLayout form){
        Effect effect=a.active;Effect.Settings s=a.settings.get(effect.id);variants(form);int[] size=a.source==null?new int[]{720,1280}:a.source.size(a.edge);int cap=effect.limit(s,size[0],size[1]);
        if(effect.family==0)a.choice(form,a.t("模式","Mode"),new String[]{a.t("标准冻结","Standard"),a.t("昼夜分割","Day / Night")},a.freezeSplit?1:0,index->{a.setFreezeSplit(index==1);show(1);});
        int count=s.countMode==2?cap:s.countMode==0&&effect.family==0?60:s.countMode==1?s.count:effect.slices;
        final Spinner[] density=new Spinner[1];EditText countField=a.number(form,a.t("片数","Slices"),count,Math.min(cap,effect.id==403?3:2),cap,true,value->{s.count=Math.round(value);s.countMode=1;if(density[0]!=null)density[0].setSelection(1);a.version++;a.requestPreview();});countField.setEnabled(s.countMode!=2&&cap>1);
        a.number(form,a.t("时长（秒）","Duration (s)"),effect.seconds(s),.1f,600,false,value->{s.seconds=Math.max(.1f,Math.min(600,value));a.version++;a.requestPreview();});
        if(effect.family==0&&a.freezeSplit)a.range(form,a.t("跳过中段","Skip middle"),0,100,a.freezeDiscard*100,"%",value->{a.freezeDiscard=value/100;for(Effect e:a.effects)if(e.family==0)a.settings.get(e.id).discardRatio=a.freezeDiscard;a.version++;a.requestPreview();});
        if(effect.id==0||effect.id==104)a.range(form,a.t("起始角度","Start angle"),0,360,s.rotationStartAngle,"°",value->{s.rotationStartAngle=value;s.origin=-1;a.version++;a.requestPreview();});
        
        if(effect.shape==3)origin(form,s);
        fold(form,"effect.advanced",a.t("高级","Advanced"),box->{
            if(effect.shape==2||effect.shape==12)a.range(box,a.t("角度","Angle"),0,180,s.angle,"°",value->{s.angle=value;a.version++;a.requestPreview();});
            density[0]=a.choice(box,a.t("片数模式","Density"),new String[]{a.t("推荐","Recommended"),a.t("自定","Custom"),a.t("逐像素","Pixel scale")},s.countMode,index->{if(s.countMode==index)return;s.countMode=index;a.version++;a.requestPreview();show(1);});
            a.choice(box,a.t("方向","Direction"),new String[]{a.t("正向","Forward"),a.t("反向","Reverse"),a.t("向外","Outward"),a.t("向内","Inward")},s.direction,index->{s.direction=index;a.version++;a.requestPreview();});
            if(effect.shape!=3&&effect.id!=0&&effect.id!=104)origin(box,s);
            if(effect.family==0&&!a.freezeSplit){a.range(box,a.t("展开占比","Reveal share"),10,90,s.build*100,"%",value->{s.build=value/100;a.version++;a.requestPreview();});a.choice(box,a.t("展开后","After reveal"),new String[]{a.t("定格","Hold"),a.t("同时解冻","Together"),a.t("依次解冻","Sequential"),a.t("流动","Flow"),a.t("波纹","Ripples")},effect.ending(s),index->{s.ending=index;a.version++;a.requestPreview();});}
            if(effect.family!=0)a.range(box,a.t("时间跨度","Time span"),.01f,1.5f,s.span>0?s.span:effect.span,"",value->{s.span=value;a.version++;a.requestPreview();});
            a.number(box,a.t("循环","Cycles"),s.cycles>0?s.cycles:effect.cycles,.01f,50,false,value->{s.cycles=Math.max(.01f,Math.min(50,value));a.version++;a.requestPreview();});
            a.range(box,a.t("自转","Rotations"),0,8,s.turns<0?effect.turns:s.turns,"",value->{s.turns=value;a.version++;a.requestPreview();});
            a.choice(box,a.t("播放方式","Playback"),new String[]{a.t("保持","Hold"),a.t("往复","Ping-pong"),a.t("循环","Loop")},s.playback,index->{s.playback=index;a.version++;a.requestPreview();});
            a.toggle(box,a.t("素材倒放","Reverse source"),s.reverse,on->{s.reverse=on;a.version++;a.requestPreview();});a.advancedForm(box,effect,s);reset(box,1);
        });
    }

    /* 只有与当前形状相关时才出现位置起点。 */
    void origin(LinearLayout form,Effect.Settings s){a.choice(form,a.t("起点","Origin"),new String[]{a.t("推荐","Recommended"),a.t("底部","Bottom"),a.t("顶部","Top"),a.t("左侧","Left"),a.t("右侧","Right"),a.t("中心","Center")},s.origin+1,index->{s.origin=index-1;a.version++;a.requestPreview();});}

    /* 关闭阴影时收起参数，避免无效的灰色滑块占满页面。 */
    void shadow(LinearLayout form){
        Effect effect=a.active;Effect.Settings s=a.settings.get(effect.id);
        a.toggle(form,a.t("单侧阴影","Shadow"),effect.shadowEnabled(s),on->{s.shadow=on?1:0;a.version++;a.requestPreview();show(2);});
        if(!effect.shadowEnabled(s))return;
        a.range(form,a.t("强度","Strength"),0,100,s.shadowStrength*100,"%",value->{s.shadowStrength=value/100;a.version++;a.requestPreview();});
        a.range(form,a.t("宽度","Width"),2,75,s.shadowWidth*100,"%",value->{s.shadowWidth=value/100;a.version++;a.requestPreview();});
        fold(form,"shadow.advanced",a.t("高级","Advanced"),box->{a.range(box,a.t("羽化","Feather"),0,100,s.shadowSoftness*100,"%",value->{s.shadowSoftness=value/100;a.version++;a.requestPreview();});a.choice(box,a.t("边位","Side"),new String[]{a.t("前侧渐隐","Fade before"),a.t("后侧渐隐","Fade after")},s.shadowSide,index->{s.shadowSide=index;a.version++;a.requestPreview();});reset(box,2);});
    }

    /* 重置只作用于当前效果，保留全局昼夜模式。 */
    void reset(LinearLayout form,int page){Button reset=StudioUi.button(a,a.t("恢复默认","Reset"),false,()->{Effect.Settings s=a.active.defaults();if(a.active.family==0){s.dayNightSplit=a.freezeSplit;s.discardRatio=a.freezeDiscard;}a.settings.put(a.active.id,s);a.version++;a.requestPreview();show(page);});LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,a.dp(44));p.topMargin=a.dp(12);form.addView(reset,p);}

    /* 导出先确认画面规格和位置，其余编码细节保留在高级分组。 */
    void export(LinearLayout form){
        int[] edges={1280,1920,2560,3840,0},rates={24,30,50,60,120},samples={24,48,96,0};
        int count=a.selected.size();TextView summary=a.text(exportSummary(),12,a.MUTED);a.add(form,summary,28);
        addProgress(form);
        a.choice(form,a.t("格式","Format"),new String[]{"H.264 · 8-bit SDR","HEVC · 10-bit SDR","HDR · PQ 10-bit","HDR · HLG 10-bit"},Arrays.asList(VideoColor.FORMATS).indexOf(a.exportFormat),index->{String format=VideoColor.FORMATS[index];try{if(VideoColor.high(format))VideoColor.requirePrecision();a.exportFormat=format;a.preparedKey="";a.prepareSource();show(3);}catch(Exception error){StudioUi.alertBuilder(a).setTitle(a.t("格式不可用","Format unavailable")).setMessage(error.getMessage()).setPositiveButton(a.t("知道了","OK"),(d,w)->show(3)).show();}});
        if(a.exportFormat.startsWith("hdr_")||(a.source!=null&&a.source.hdr)){TextView hint=a.text(a.t("HDR预览以SDR映射显示，成片按所选格式输出。","HDR previews use an SDR mapping. Export follows the selected format."),11,a.MUTED);hint.setPadding(0,0,0,a.dp(8));form.addView(hint);}
        a.choice(form,a.t("分辨率","Resolution"),new String[]{"720p","1080p","1440p","4K",a.t("原始尺寸","Original")},a.index(edges,a.edge),index->{a.edge=edges[index];summary.setText(exportSummary());a.preparedKey="";a.prepareSource();});
        a.choice(form,a.t("帧率","Frame rate"),new String[]{"24 fps","30 fps","50 fps","60 fps","120 fps"},a.index(rates,a.fps),index->{a.fps=rates[index];summary.setText(exportSummary());});
        a.choice(form,a.t("码率","Bitrate"),new String[]{a.t("推荐","Recommended"),a.t("自定义","Custom")},a.bitrate>0?1:0,index->{int next=index==0?0:outputBitrate();if(next!=a.bitrate){a.bitrate=next;show(3);}});
        if(a.bitrate>0)a.number(form,a.t("目标码率（Mbps）","Target bitrate (Mbps)"),a.bitrate/1000000f,1,500,false,value->{a.bitrate=Math.round(value*1000000f);summary.setText(exportSummary());});
        TextView bitrateHint=a.text(a.t("码率越高，文件越大。实际码率随画面变化。","Higher bitrate increases file size. Actual bitrate varies with the image."),11,a.MUTED);bitrateHint.setPadding(0,a.dp(6),0,a.dp(10));form.addView(bitrateHint);
        LinearLayout output=new LinearLayout(a);output.setGravity(Gravity.CENTER_VERTICAL);location=a.text("",12,a.MUTED);location.setSingleLine(true);location.setEllipsize(android.text.TextUtils.TruncateAt.MIDDLE);output.addView(location,new LinearLayout.LayoutParams(0,a.dp(52),1));Button change=StudioUi.button(a,a.t("更换","Change"),false,()->a.startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION|Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION),12));change.setTextSize(12);output.addView(change,new LinearLayout.LayoutParams(a.dp(a.english?84:64),a.dp(40)));form.addView(output);refreshLocation();
        fold(form,"export.advanced",a.t("高级","Advanced"),box->{
            a.toggle(box,a.t("平滑渐变","Smooth gradients"),a.gradientDither,on->a.gradientDither=on);
            a.choice(box,a.t("时间细节","Time detail"),new String[]{"24","48","96",a.t("原始精度","Full precision")},a.index(samples,a.samples),index->{a.samples=samples[index];a.preparedKey="";a.prepareSource();});
            a.choice(box,a.t("计算方式","Compute"),new String[]{a.t("自动","Auto"),"GPU","CPU"},Arrays.asList("auto","gpu","cpu").indexOf(a.mode),index->{a.mode=new String[]{"auto","gpu","cpu"}[index];a.worker.execute(()->{try{if(a.renderer!=null)a.renderer.close();a.renderer=new Renderer(a,a.mode);a.post(()->{a.version++;a.requestPreview();});}catch(Exception error){a.fail(error);}});});
            a.toggle(box,a.t("保留原声","Keep audio"),a.keepSound,on->a.keepSound=on);
            if(a.outputTree!=null)a.add(box,StudioUi.button(a,a.t("改存相册","Use gallery"),false,()->{a.outputTree=null;a.getPreferences(0).edit().remove("output").apply();refreshLocation();}),44);
        });
        if(a.lastOutput!=null)a.add(form,StudioUi.button(a,a.t("查看上次导出","View last export"),false,()->a.startActivity(new Intent(Intent.ACTION_VIEW).setDataAndType(a.lastOutput,"video/mp4").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))),44);
    }

    /* 注明实际尺寸和导出对象，原片小于目标规格时不冒充已放大。 */
    String exportSummary(){String subject=a.selected.size()==1?a.name(a.effectById(a.selected.iterator().next())):a.selected.size()+a.t(" 项"," items");if(a.source==null)return subject;int[] size=a.source.size(a.edge);return subject+" · "+size[0]+" × "+size[1]+" · "+a.fps+" fps · "+a.formatValue(outputBitrate()/1000000f)+" Mbps";}

    /* 按实际输出尺寸计算推荐值，使手机界面、负载估计与编码器保持一致。 */
    int outputBitrate(){int[] size=a.source==null?new int[]{1280,720}:a.source.size(a.edge);return ExportQuality.resolve(size[0],size[1],a.fps,a.bitrate);}

    /* 系统目录选择结束后立即更新保存位置，避免显示旧值。 */
    void refreshLocation(){if(location!=null)location.setText(a.outputTree==null?a.t("保存至  相册 / 时刃","Save to  Gallery / TimeSlice"):a.t("保存至  自选文件夹","Save to  Chosen folder"));}

    /* 低频入口放进更多菜单，首页不摆版本和许可长文。 */
    void more(){
        if(a.busy)return;Dialog dialog=new Dialog(a);LinearLayout form=a.column();form.setPadding(a.dp(20),a.dp(16),a.dp(20),a.dp(20));form.setBackground(StudioUi.shape(a,StudioUi.SURFACE,22,false));
        TextView title=a.text(a.t("更多","More"),20,a.INK);a.add(form,title,40);
        if(a.source!=null){a.choice(form,a.t("预览","Preview"),new String[]{a.t("成片","Result"),a.t("原片","Source"),a.t("时间图","Time map")},a.view,index->{a.view=index;a.version++;a.refreshLibrary();a.requestPreview();dialog.dismiss();});}
        a.choice(form,a.t("语言","Language"),new String[]{"简体中文","English"},a.english?1:0,index->{a.english=index==1;a.getPreferences(0).edit().putBoolean("english",a.english).apply();dialog.dismiss();a.buildUI();a.requestPreview();});
        a.choice(form,a.t("外观","Appearance"),new String[]{a.t("跟随系统","System"),a.t("浅色","Light"),a.t("深色","Dark")},a.getPreferences(0).getInt("appearance",0),index->{a.getPreferences(0).edit().putInt("appearance",index).apply();dialog.dismiss();a.buildUI();a.requestPreview();});
        a.add(form,StudioUi.button(a,a.t("关于时刃","About TimeSlice"),false,()->{dialog.dismiss();a.showAbout();}),46);
        a.add(form,StudioUi.button(a,a.t("完成","Done"),false,dialog::dismiss),44);StudioUi.showSheet(a,dialog,form,0);
    }
}
