package studio.shiren.mobile;

import android.content.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import java.io.IOException;
import java.util.*;

/** 只承载手机首屏：画面、效果与导出；处理和渲染仍交给MainActivity。 */
final class PhoneWorkspace {
    final MainActivity a;
    LinearLayout categories,selectionHost,body;
    TextView effectTag;
    Button batchButton;
    final List<View> secondary=new ArrayList<>();

    /* 绑定当前工作台，不创建第二套业务状态。 */
    PhoneWorkspace(MainActivity activity){a=activity;}

    /* 构造固定层级首屏，效果库和导出无需在长页面内寻找。 */
    void mount(){
        a.getWindow().setStatusBarColor(a.BG);a.getWindow().setNavigationBarColor(a.BG);
        a.getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION|(a.dark?0:View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR|View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR));
        LinearLayout root=a.column();root.setBackground(StudioUi.wallpaper(a));root.setPadding(a.dp(16),a.dp(8),a.dp(16),a.dp(8));
        root.setOnApplyWindowInsetsListener((v,insets)->{v.setPadding(a.dp(16),insets.getSystemWindowInsetTop()+a.dp(4),a.dp(16),insets.getSystemWindowInsetBottom()+a.dp(8));return insets;});a.setContentView(root);
        LinearLayout header=new LinearLayout(a);header.setGravity(Gravity.CENTER_VERTICAL);
        ImageView brandMark=new ImageView(a);try{brandMark.setImageBitmap(BitmapFactory.decodeStream(a.getAssets().open("brand.png")));}catch(IOException ignored){}LinearLayout.LayoutParams brandSize=new LinearLayout.LayoutParams(a.dp(34),a.dp(34));brandSize.rightMargin=a.dp(10);header.addView(brandMark,brandSize);
        LinearLayout brand=a.column();TextView name=a.text(a.english?"TimeSlice":"时刃",20,a.INK);name.setTypeface(Typeface.create("sans-serif-medium",0));brand.addView(name,new LinearLayout.LayoutParams(-1,a.dp(25)));
        a.metadata=a.text(a.source==null?a.t("延时切片","Timelapse slicing"):metadata(),10,a.MUTED);a.metadata.setSingleLine(true);a.metadata.setEllipsize(android.text.TextUtils.TruncateAt.END);brand.addView(a.metadata,new LinearLayout.LayoutParams(-1,a.dp(17)));header.addView(brand,new LinearLayout.LayoutParams(0,a.dp(48),1));
        Button importAction=StudioUi.iconButton(a,"plus",a.t("导入视频","Import video"),a::pick);secondary.add(importAction);importAction.setVisibility(a.source==null?View.GONE:View.VISIBLE);header.addView(importAction,new LinearLayout.LayoutParams(a.dp(44),a.dp(48)));
        Button more=StudioUi.iconButton(a,"more",a.t("更多","More"),()->a.panels.more());secondary.add(more);header.addView(more,new LinearLayout.LayoutParams(a.dp(44),a.dp(48)));root.addView(header,new LinearLayout.LayoutParams(-1,a.dp(56)));

        body=a.column();body.setVisibility(a.source==null?View.GONE:View.VISIBLE);root.addView(body,new LinearLayout.LayoutParams(-1,0,a.source==null?0:1));
        FrameLayout canvas=new StudioUi.RoundFrame(a,22);canvas.setBackground(StudioUi.glass(a,22));canvas.setClipToOutline(true);
        a.image=new ImageView(a);a.image.setScaleType(ImageView.ScaleType.FIT_CENTER);a.image.setOnClickListener(v->a.showFullPreview());canvas.addView(a.image,new FrameLayout.LayoutParams(-1,-1));if(a.lastPreview!=null)a.image.setImageBitmap(a.lastPreview);
        effectTag=a.text("",11,a.INK);effectTag.setSingleLine(true);effectTag.setEllipsize(android.text.TextUtils.TruncateAt.END);effectTag.setPadding(a.dp(8),0,a.dp(8),0);effectTag.setBackground(StudioUi.glass(a,13));effectTag.setOnClickListener(v->a.showInspector(1));
        FrameLayout.LayoutParams tag=new FrameLayout.LayoutParams(-2,a.dp(26),Gravity.LEFT|Gravity.BOTTOM);tag.leftMargin=a.dp(10);tag.bottomMargin=a.dp(10);tag.rightMargin=a.dp(10);canvas.addView(effectTag,tag);
        LinearLayout.LayoutParams preview=new LinearLayout.LayoutParams(-1,0,1);preview.topMargin=a.dp(4);preview.bottomMargin=a.dp(4);body.addView(canvas,preview);

        a.prepareStatus=a.text("",11,a.MUTED);a.prepareStatus.setSingleLine(true);a.prepareStatus.setEllipsize(android.text.TextUtils.TruncateAt.END);a.prepareStatus.setVisibility(a.preparing?View.VISIBLE:View.GONE);body.addView(a.prepareStatus,new LinearLayout.LayoutParams(-1,a.dp(24)));
        a.prepareBar=bar();a.prepareBar.setVisibility(a.preparing?View.VISIBLE:View.GONE);body.addView(a.prepareBar,new LinearLayout.LayoutParams(-1,a.dp(2)));

        LinearLayout transport=new LinearLayout(a);transport.setGravity(Gravity.CENTER_VERTICAL);
        a.play=StudioUi.iconButton(a,"play",a.t("播放预览","Play preview"),a::togglePlay);transport.addView(a.play,new LinearLayout.LayoutParams(a.dp(44),a.dp(44)));
        a.timeline=new SeekBar(a);a.timeline.setMax(1000);a.timeline.setProgress((int)(a.u*1000));a.timeline.setPadding(a.dp(12),0,a.dp(12),0);a.timeline.setProgressTintList(android.content.res.ColorStateList.valueOf(a.ACCENT));a.timeline.setThumbTintList(android.content.res.ColorStateList.valueOf(a.dark?0xffe8f1ff:0xffffffff));transport.addView(a.timeline,new LinearLayout.LayoutParams(0,a.dp(44),1));
        a.clock=a.text("",11,a.MUTED);a.clock.setGravity(Gravity.CENTER);a.clock.setTypeface(Typeface.create("monospace",0));a.clock.setSingleLine(true);a.clock.setAutoSizeTextTypeUniformWithConfiguration(9,11,1,android.util.TypedValue.COMPLEX_UNIT_SP);transport.addView(a.clock,new LinearLayout.LayoutParams(a.dp(78),a.dp(44)));
        transport.addView(StudioUi.iconButton(a,"expand",a.t("全屏预览","Fullscreen preview"),a::showFullPreview),new LinearLayout.LayoutParams(a.dp(40),a.dp(44)));body.addView(transport,new LinearLayout.LayoutParams(-1,a.dp(44)));
        a.timeline.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){/* 拖动时暂停，保持当前帧精确可控。 */public void onStartTrackingTouch(SeekBar bar){a.playing=false;updatePlay();}/* 松手无需重做源处理。 */public void onStopTrackingTouch(SeekBar bar){}/* 只刷新当前效果画面。 */public void onProgressChanged(SeekBar bar,int value,boolean user){if(user){a.u=value/1000f;a.version++;a.requestPreview();}}});

        selectionHost=a.column();a.selectedLabel=a.text("",11,a.MUTED);a.selectedLabel.setVisibility(View.GONE);selectionHost.addView(a.selectedLabel);
        a.queueScroll=new HorizontalScrollView(a);a.queueScroll.setHorizontalScrollBarEnabled(false);a.queueCards=new LinearLayout(a);a.queueScroll.addView(a.queueCards);selectionHost.addView(a.queueScroll,new LinearLayout.LayoutParams(-1,a.dp(48)));body.addView(selectionHost,new LinearLayout.LayoutParams(-1,-2));
        categories=new LinearLayout(a);categories.setGravity(Gravity.CENTER_VERTICAL);body.addView(categories,new LinearLayout.LayoutParams(-1,a.dp(44)));
        a.libraryScroll=new HorizontalScrollView(a);a.libraryScroll.setHorizontalScrollBarEnabled(false);a.libraryScroll.setClipToPadding(false);a.cards=new LinearLayout(a);a.cards.setPadding(0,a.dp(2),0,a.dp(4));a.libraryScroll.addView(a.cards);body.addView(a.libraryScroll,new LinearLayout.LayoutParams(-1,a.dp(106)));

        LinearLayout empty=a.column();empty.setGravity(Gravity.CENTER);empty.setVisibility(a.source==null?View.VISIBLE:View.GONE);root.addView(empty,new LinearLayout.LayoutParams(-1,0,a.source==null?1:0));
        ImageView mark=new ImageView(a);try{mark.setImageBitmap(BitmapFactory.decodeStream(a.getAssets().open("brand.png")));}catch(IOException ignored){}empty.addView(mark,new LinearLayout.LayoutParams(a.dp(88),a.dp(88)));
        TextView heading=a.text(a.t("让时间，展开。","Unfold time."),28,a.INK);heading.setGravity(Gravity.CENTER);heading.setTypeface(Typeface.create("sans-serif-medium",0));LinearLayout.LayoutParams eh=new LinearLayout.LayoutParams(-1,a.dp(48));eh.topMargin=a.dp(16);empty.addView(heading,eh);
        TextView help=a.text(a.t("导入延时视频，选择切片并导出","Import a timelapse. Choose slices. Export."),13,a.MUTED);help.setGravity(Gravity.CENTER);empty.addView(help,new LinearLayout.LayoutParams(-1,a.dp(30)));
        Button importButton=StudioUi.button(a,a.t("导入视频","Import video"),true,a::pick);LinearLayout.LayoutParams ep=new LinearLayout.LayoutParams(a.dp(164),a.dp(48));ep.topMargin=a.dp(22);empty.addView(importButton,ep);

        a.status=a.text("",11,a.MUTED);a.status.setVisibility(View.GONE);root.addView(a.status,new LinearLayout.LayoutParams(-1,-2));
        a.queue=a.column();a.queue.setVisibility(View.GONE);root.addView(a.queue,new LinearLayout.LayoutParams(-1,-2));
        a.exportStatus=a.text("",11,a.MUTED);a.exportStatus.setSingleLine(true);a.exportStatus.setEllipsize(android.text.TextUtils.TruncateAt.END);a.exportStatus.setVisibility(a.busy?View.VISIBLE:View.GONE);root.addView(a.exportStatus,new LinearLayout.LayoutParams(-1,a.dp(24)));
        a.exportBar=bar();a.exportBar.setVisibility(a.busy?View.VISIBLE:View.GONE);root.addView(a.exportBar,new LinearLayout.LayoutParams(-1,a.dp(2)));
        LinearLayout tools=new LinearLayout(a);tools.setGravity(Gravity.CENTER_VERTICAL);tools.setPadding(a.dp(8),a.dp(6),a.dp(8),a.dp(6));tools.setBackground(StudioUi.glass(a,26));tools.setVisibility(a.source==null?View.GONE:View.VISIBLE);LinearLayout.LayoutParams bp=new LinearLayout.LayoutParams(-1,a.dp(64));bp.topMargin=a.dp(4);root.addView(tools,bp);
        tools.addView(tool("source",a.t("素材","Source"),()->a.showInspector(0)),new LinearLayout.LayoutParams(a.dp(62),a.dp(56)));
        tools.addView(tool("tune",a.t("参数","Adjust"),()->a.showInspector(1)),new LinearLayout.LayoutParams(a.dp(62),a.dp(56)));
        a.export=StudioUi.button(a,a.t("导出","Export"),true,()->{if(a.busy)a.startExport();else if(a.exportAfterPreparation){a.exportAfterPreparation=false;a.updateButton();}else a.panels.showExport();});LinearLayout.LayoutParams primary=new LinearLayout.LayoutParams(0,a.dp(48),1);primary.leftMargin=a.dp(14);tools.addView(a.export,primary);
        refreshLibrary();refreshSelection();updatePlay();setTime(a.u,a.active.seconds(a.settings.get(a.active.id)));a.updateButton();
    }

    /* 次要工具以图标和短标题表达用途，避免与主导出按钮竞争。 */
    View tool(String icon,String label,Runnable action){LinearLayout box=a.column();box.setGravity(Gravity.CENTER);ImageView glyph=new ImageView(a);glyph.setImageDrawable(new StudioUi.Glyph(icon,a.MUTED,a.dp(21)));box.addView(glyph,new LinearLayout.LayoutParams(a.dp(21),a.dp(21)));TextView title=a.text(label,12,a.MUTED);title.setGravity(Gravity.CENTER);LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,a.dp(20));p.topMargin=a.dp(2);box.addView(title,p);box.setContentDescription(label);box.setOnClickListener(v->action.run());box.setBackground(new RippleDrawable(android.content.res.ColorStateList.valueOf(0x15ffffff),null,StudioUi.shape(a,Color.WHITE,12,false)));secondary.add(box);return box;}

    /* 两类工作进度使用统一细线，完成后不占用页面。 */
    ProgressBar bar(){ProgressBar out=new ProgressBar(a,null,android.R.attr.progressBarStyleHorizontal);out.setMax(1000);out.setProgressTintList(android.content.res.ColorStateList.valueOf(a.ACCENT));out.setProgressBackgroundTintList(android.content.res.ColorStateList.valueOf(StudioUi.LINE));return out;}
    /* 导出期间明确变暗次要入口，避免出现点了没有反应的控件。 */
    void updateBusy(){for(View view:secondary){view.setEnabled(!a.busy);view.setAlpha(a.busy?.35f:1);}if(a.cards!=null)a.cards.setAlpha(a.busy?.4f:1);if(a.timeline!=null)a.timeline.setEnabled(!a.busy);if(a.play!=null){a.play.setEnabled(!a.busy);a.play.setAlpha(a.busy?.4f:1);}if(categories!=null){categories.setAlpha(a.busy?.4f:1);for(int i=0;i<categories.getChildCount();i++)categories.getChildAt(i).setEnabled(!a.busy);}if(batchButton!=null){batchButton.setEnabled(!a.busy);batchButton.setAlpha(a.busy?.4f:1);}}
    /* 源信息收进品牌下的一行，不显示后端或设备调试信息。 */
    String metadata(){return a.source.width+" × "+a.source.height+" · "+String.format(Locale.ROOT,"%.1fs",a.source.durationUs/1e6);}


    /* 首屏只显示三个类别和可选批量模式，展开模式与运动参数放到调整面板。 */
    void refreshLibrary(){
        if(a.cards==null||categories==null)return;int scroll=a.libraryScroll.getScrollX();categories.removeAllViews();String[] labels={a.t("冻结","Freeze"),a.t("切片","Slices"),a.t("创意","Creative")};int[] families={0,1,3};
        for(int i=0;i<3;i++){final int family=families[i];LinearLayout tab=a.column();tab.setGravity(Gravity.CENTER);TextView name=a.text(labels[i],14,a.family==family?a.INK:a.MUTED);name.setTypeface(Typeface.create("sans-serif-medium",0));name.setGravity(Gravity.CENTER);tab.addView(name,new LinearLayout.LayoutParams(-1,a.dp(38)));View underline=new View(a);underline.setBackgroundColor(a.family==family?a.ACCENT:Color.TRANSPARENT);LinearLayout.LayoutParams u=new LinearLayout.LayoutParams(a.dp(18),a.dp(2));u.gravity=Gravity.CENTER;tab.addView(underline,u);tab.setOnClickListener(v->{a.family=family;refreshLibrary();});categories.addView(tab,new LinearLayout.LayoutParams(0,a.dp(44),1));}
        batchButton=StudioUi.button(a,a.t("多选","Multi"),false,()->{if(a.busy)return;a.batchMode=!a.batchMode;if(!a.batchMode){a.selected.clear();a.selected.add(a.active.id);}refreshLibrary();refreshSelection();a.updateButton();});batchButton.setBackgroundColor(Color.TRANSPARENT);batchButton.setTextSize(12);batchButton.setTextColor(a.batchMode?a.ACCENT:a.MUTED);batchButton.setContentDescription(a.t("批量选择","Select multiple"));batchButton.setSelected(a.batchMode);categories.addView(batchButton,new LinearLayout.LayoutParams(a.dp(56),a.dp(44)));
        a.cards.removeAllViews();for(EffectGroup group:a.groups){if(group.family!=a.family)continue;Effect effect=a.effectById(a.catalogueActive.get(group.key));boolean active=group.contains(a.active.id);LinearLayout card=a.column();card.setPadding(a.dp(3),a.dp(3),a.dp(3),a.dp(2));GradientDrawable bg=StudioUi.shape(a,active?StudioUi.SELECTED:StudioUi.SURFACE,17,true);if(active)bg.setStroke(a.dp(1.5f),a.ACCENT);card.setBackground(bg);card.setContentDescription(a.name(effect));
            FrameLayout cover=new FrameLayout(a);ImageView image=a.thumbnail(effect,13);cover.addView(image,new FrameLayout.LayoutParams(-1,-1));
            if(a.batchMode){Button include=StudioUi.iconButton(a,"check",a.t("选择 ","Select ")+a.name(effect),()->a.onLibraryTap(effect.id));boolean selected=false;for(EffectGroup.Variant variant:group.variants)selected|=a.selected.contains(variant.effect);include.setBackground(StudioUi.shape(a,selected?StudioUi.BLUE:0xaa111318,10,!selected));StudioUi.setIcon(a,include,selected?"check":"plus",selected?Color.WHITE:a.MUTED);FrameLayout.LayoutParams c=new FrameLayout.LayoutParams(a.dp(23),a.dp(23),Gravity.TOP|Gravity.RIGHT);c.rightMargin=a.dp(3);c.topMargin=a.dp(3);cover.addView(include,c);}
            card.addView(cover,new LinearLayout.LayoutParams(-1,a.dp(62)));TextView label=a.text(group.variants.size()==1?a.name(effect):a.tr(group.name),12,a.INK);label.setGravity(Gravity.CENTER);label.setSingleLine(true);label.setEllipsize(android.text.TextUtils.TruncateAt.END);card.addView(label,new LinearLayout.LayoutParams(-1,a.dp(29)));card.setOnClickListener(v->a.onLibraryTap(effect.id));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(a.dp(104),a.dp(98));p.rightMargin=a.dp(7);a.cards.addView(card,p);
        }
        String tag=a.view==1?a.t("原片","Source"):a.view==2?a.t("时间图","Time map"):a.name(a.active)+(a.active.family==0&&a.freezeSplit?a.t(" · 昼夜"," · Day / Night"):"");effectTag.setText(tag);a.libraryScroll.post(()->a.libraryScroll.scrollTo(scroll,0));
    }

    /* 批量时才展示紧凑有序队列，保留拖动、移除与点按预览。 */
    void refreshSelection(){
        if(a.queueCards==null)return;boolean visible=!a.selected.isEmpty()&&(a.batchMode||a.selected.size()>1);selectionHost.setVisibility(visible?View.VISIBLE:View.GONE);a.queueCards.removeAllViews();int index=1;
        for(int id:new ArrayList<>(a.selected)){Effect effect=a.effectById(id);LinearLayout chip=new LinearLayout(a);chip.setGravity(Gravity.CENTER_VERTICAL);chip.setPadding(a.dp(7),0,0,0);chip.setBackground(StudioUi.shape(a,id==a.active.id?StudioUi.SELECTED:StudioUi.SURFACE,11,false));TextView number=a.text(String.valueOf(index++),10,a.MUTED);chip.addView(number,new LinearLayout.LayoutParams(a.dp(14),-1));TextView label=a.text(a.name(effect),12,a.INK);label.setSingleLine(true);label.setEllipsize(android.text.TextUtils.TruncateAt.END);chip.addView(label,new LinearLayout.LayoutParams(0,-1,1));Button remove=StudioUi.iconButton(a,"close",a.t("移除 ","Remove ")+a.name(effect),()->{if(a.busy)return;a.selected.remove(id);refreshSelection();refreshLibrary();a.updateButton();});chip.addView(remove,new LinearLayout.LayoutParams(a.dp(32),-1));chip.setOnClickListener(v->a.previewEffect(id));chip.setOnLongClickListener(v->{if(a.busy)return false;v.startDragAndDrop(ClipData.newPlainText("effect",String.valueOf(id)),new View.DragShadowBuilder(v),id,0);return true;});chip.setOnDragListener((v,event)->{if(event.getAction()==DragEvent.ACTION_DRAG_STARTED)return event.getLocalState() instanceof Integer;if(event.getAction()==DragEvent.ACTION_DROP&&event.getLocalState() instanceof Integer){a.moveSelection((Integer)event.getLocalState(),id);return true;}return true;});LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(a.dp(120),a.dp(42));p.rightMargin=a.dp(6);p.topMargin=a.dp(3);a.queueCards.addView(chip,p);}
    }

    /* 图标按真实播放状态更新，不用文字字符模拟播放控件。 */
    void updatePlay(){if(a.play!=null){StudioUi.setIcon(a,a.play,a.playing?"pause":"play",a.INK);a.play.setContentDescription(a.playing?a.t("暂停预览","Pause preview"):a.t("播放预览","Play preview"));}}

    /* 时间显示只保留当前值和总长，数值采用固定宽度以免跳动。 */
    void setTime(float progress,float duration){int now=(int)(Math.max(0,Math.min(1,progress))*duration),total=(int)Math.ceil(duration);if(!a.playing&&!a.timeline.isPressed())a.timeline.setProgress(Math.round(progress*1000));a.clock.setText(duration<60?String.format(Locale.ROOT,"%.1f / %ss",Math.max(0,Math.min(1,progress))*duration,a.formatValue(duration)):String.format(Locale.ROOT,"%d:%02d / %d:%02d",now/60,now%60,total/60,total%60));}
}
