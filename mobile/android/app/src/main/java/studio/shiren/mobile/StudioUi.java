package studio.shiren.mobile;

import android.content.res.ColorStateList;
import android.app.AlertDialog;
import android.app.Dialog;
import android.os.Build;
import android.graphics.*;
import android.graphics.drawable.*;
import android.view.*;
import android.widget.*;

/** 手机工作台的排版、色彩与线性图标；不依赖额外字体或图片生成。 */
final class StudioUi {
    static int SURFACE,RAISED,LINE,BLUE,WELL,SELECTED;

    /** 与桌面同用冷色玻璃层级，随系统切换浅色和深色。 */
    static void palette(boolean dark){
        SURFACE=dark?0xeb1c2a40:0xeef8fbff;RAISED=dark?0xff2c3d55:0xfff4f8ff;
        LINE=dark?0x557c9bbd:0x408197b7;BLUE=0xff096bd8;
        WELL=dark?0x66101b2c:0x6094acce;SELECTED=dark?0x996080a9:0xe6ffffff;
    }

    /** 背景仅绘制一次渐变，不给视频渲染增加逐帧模糊负载。 */
    static Drawable wallpaper(MainActivity a){
        return new GradientDrawable(GradientDrawable.Orientation.TL_BR,a.dark?
                new int[]{0xff111d30,0xff253953,0xff182339}:
                new int[]{0xffeef4fd,0xffe1eaf8,0xfff0edf7});
    }

    /** 玻璃面板的高光、边框和内层色与桌面保持一致。 */
    static GradientDrawable glass(MainActivity a,int radius){
        return glass(a,radius,false);
    }

    /** 弹层采用不透明的玻璃色底，系统关闭模糊时仍保证文字可读。 */
    static GradientDrawable glass(MainActivity a,int radius,boolean solid){
        GradientDrawable out=new GradientDrawable(GradientDrawable.Orientation.TL_BR,a.dark?
                solid?new int[]{0xff394c65,0xff1d2c43,0xff2a3c56}:new int[]{0xf0394c65,0xf01d2c43,0xf02a3c56}:
                solid?new int[]{0xfffcfeff,0xfff0f5fd,0xffe5eefb}:new int[]{0xfaffffff,0xeef0f5fd,0xf5e5eefb});
        out.setCornerRadius(a.dp(radius));out.setStroke(a.dp(1),a.dark?0x669fb8d9:0xeeffffff);
        return out;
    }

    /** 统一自绘弹层的圆角、边距、系统栏与可用高度。 */
    static void showSheet(MainActivity a,Dialog dialog,View content,float fraction){
        content.setBackground(glass(a,26,true));content.setClipToOutline(true);
        dialog.setContentView(content);Window window=dialog.getWindow();
        if(window!=null){
            window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            window.setGravity(Gravity.BOTTOM);window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
            WindowManager.LayoutParams p=window.getAttributes();p.dimAmount=a.dark?.48f:.22f;p.y=a.dp(10);window.setAttributes(p);
            window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE|WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);
            if(Build.VERSION.SDK_INT>=31){window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);window.setBackgroundBlurRadius(a.dp(18));}
        }
        dialog.show();if(window!=null){
            int width=Math.min(a.getResources().getDisplayMetrics().widthPixels-a.dp(24),a.dp(560));
            int height=fraction<=0?-2:(int)(a.getResources().getDisplayMetrics().heightPixels*fraction);
            window.setLayout(width,height);
        }
    }

    /** 系统确认、导入、错误与预设窗口共用产品样式，不再出现方形系统底板。 */
    static AlertDialog.Builder alertBuilder(MainActivity a){
        return new AlertDialog.Builder(a){
            /** 保留原系统确认行为，仅统一外观和圆角裁切。 */
            @Override public AlertDialog show(){
                AlertDialog dialog=super.show();Window window=dialog.getWindow();
                if(window!=null){View decor=window.getDecorView();decor.setBackground(glass(a,26,true));decor.setClipToOutline(true);
                    window.setLayout(Math.min(a.getResources().getDisplayMetrics().widthPixels-a.dp(32),a.dp(520)),-2);}
                for(int which:new int[]{AlertDialog.BUTTON_POSITIVE,AlertDialog.BUTTON_NEGATIVE,AlertDialog.BUTTON_NEUTRAL}){
                    Button button=dialog.getButton(which);if(button==null)continue;
                    button.setAllCaps(false);button.setTextColor(which==AlertDialog.BUTTON_POSITIVE?BLUE:a.INK);
                    button.setTextSize(13);button.setTypeface(Typeface.create("sans-serif-medium",0));
                }
                return dialog;
            }
        };
    }

    /** 显式圆角裁切使硬件显示和软件视图预览采用相同轮廓。 */
    static final class RoundImage extends ImageView {
        final float radius;final Path outline=new Path();
        /* 圆角单位跟随当前屏幕密度。 */
        RoundImage(MainActivity a,int r){super(a);radius=a.dp(r);}
        /* 保留完整圆角，避免缩略图角部穿过外框。 */
        @Override protected void onDraw(Canvas canvas){outline.reset();outline.addRoundRect(new RectF(0,0,getWidth(),getHeight()),radius,radius,Path.Direction.CW);int saved=canvas.save();canvas.clipPath(outline);super.onDraw(canvas);canvas.restoreToCount(saved);}
    }

    /** 主画布的子内容和底板共用一个圆角轮廓。 */
    static final class RoundFrame extends FrameLayout {
        final float radius;final Path outline=new Path();
        /* 保存画布的逻辑圆角。 */
        RoundFrame(MainActivity a,int r){super(a);radius=a.dp(r);}
        /* 绘制图片和角标时保持裁切一致。 */
        @Override protected void dispatchDraw(Canvas canvas){outline.reset();outline.addRoundRect(new RectF(0,0,getWidth(),getHeight()),radius,radius,Path.Direction.CW);int saved=canvas.save();canvas.clipPath(outline);super.dispatchDraw(canvas);canvas.restoreToCount(saved);}
    }

    /* 生成轻量圆角底板，描边只用于层级分隔。 */
    static GradientDrawable shape(MainActivity a,int color,int radius,boolean border){
        GradientDrawable out=new GradientDrawable();out.setColor(color);out.setCornerRadius(a.dp(radius));
        if(border)out.setStroke(a.dp(1),LINE);return out;
    }

    /* 保留按压反馈，次要按钮采用低对比底色而非高光胶囊。 */
    static Drawable background(MainActivity a,boolean primary,int radius){
        Drawable base=primary?new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{0xff2184ef,0xff0964cc}):glass(a,radius);
        if(primary)((GradientDrawable)base).setCornerRadius(a.dp(radius));
        return new RippleDrawable(ColorStateList.valueOf(0x25ffffff),base,shape(a,Color.WHITE,radius,false));
    }

    /* 统一文字按钮的尺寸、字重与按压态。 */
    static Button button(MainActivity a,String label,boolean primary,Runnable action){
        Button out=new Button(a);out.setText(label);out.setAllCaps(false);out.setTextSize(14);
        out.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));out.setTextColor(primary?Color.WHITE:a.INK);
        out.setSingleLine(true);out.setEllipsize(android.text.TextUtils.TruncateAt.END);
        out.setGravity(Gravity.CENTER);out.setPadding(a.dp(12),0,a.dp(12),0);out.setMinWidth(0);out.setMinimumWidth(0);out.setMinHeight(0);out.setMinimumHeight(0);
        out.setBackground(background(a,primary,22));out.setElevation(a.dp(primary?2:0));out.setOnClickListener(v->action.run());return out;
    }

    /* 创建有无障碍名称的矢量图标按钮，避免用字体字符拼图标。 */
    static Button iconButton(MainActivity a,String icon,String description,Runnable action){
        Button out=new Button(a){/* 将纯图标放在命中区几何中心，不预留空文字基线。 */@Override protected void onDraw(Canvas canvas){Object tag=getTag();if(tag instanceof Glyph){Glyph icon=(Glyph)tag;int size=a.dp(22);icon.setBounds((getWidth()-size)/2,(getHeight()-size)/2,(getWidth()+size)/2,(getHeight()+size)/2);icon.draw(canvas);}}};
        out.setMinWidth(0);out.setMinimumWidth(0);out.setMinHeight(0);out.setMinimumHeight(0);out.setPadding(0,0,0,0);out.setOnClickListener(v->action.run());out.setBackground(new RippleDrawable(ColorStateList.valueOf(0x1fffffff),shape(a,Color.TRANSPARENT,12,false),shape(a,Color.WHITE,12,false)));
        out.setContentDescription(description);setIcon(a,out,icon,a.INK);return out;
    }

    /* 在按钮内居中放置矢量图标。 */
    static void setIcon(MainActivity a,Button button,String name,int color){
        Glyph glyph=new Glyph(name,color,a.dp(22));glyph.setBounds(0,0,a.dp(22),a.dp(22));
        button.setText("");button.setTag(glyph);button.invalidate();
    }

    /* 固定高度的分隔线只占一个逻辑像素。 */
    static void divider(MainActivity a,LinearLayout parent){View line=new View(a);line.setBackgroundColor(LINE);line.setAlpha(.45f);parent.addView(line,new LinearLayout.LayoutParams(-1,a.dp(1)));}

    /** 所有导航和播放控件使用相同的22像素线性图形。 */
    static final class Glyph extends Drawable {
        final String name;final int size;final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);int color;
        /* 保存图标种类与当前主题颜色。 */
        Glyph(String name,int color,int size){this.name=name;this.color=color;this.size=size;}
        /* 用规范化坐标绘制清晰且同一笔画粗细的图标。 */
        @Override public void draw(Canvas canvas){
            canvas.save();Rect bounds=getBounds();canvas.translate(bounds.left,bounds.top);canvas.scale(bounds.width()/24f,bounds.height()/24f);
            paint.setColor(color);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(1.7f);paint.setStrokeCap(Paint.Cap.ROUND);paint.setStrokeJoin(Paint.Join.ROUND);
            Path p=new Path();
            switch(name){
                case "play":paint.setStyle(Paint.Style.FILL);p.moveTo(9,5.5f);p.lineTo(19,12);p.lineTo(9,18.5f);p.close();canvas.drawPath(p,paint);break;
                case "pause":paint.setStrokeWidth(3);canvas.drawLine(9,6,9,18,paint);canvas.drawLine(15,6,15,18,paint);break;
                case "plus":canvas.drawLine(12,5,12,19,paint);canvas.drawLine(5,12,19,12,paint);break;
                case "close":canvas.drawLine(7,7,17,17,paint);canvas.drawLine(17,7,7,17,paint);break;
                case "more":paint.setStyle(Paint.Style.FILL);for(int x:new int[]{5,12,19})canvas.drawCircle(x,12,1.5f,paint);break;
                case "expand":p.moveTo(4,9);p.lineTo(4,4);p.lineTo(9,4);p.moveTo(15,4);p.lineTo(20,4);p.lineTo(20,9);p.moveTo(20,15);p.lineTo(20,20);p.lineTo(15,20);p.moveTo(9,20);p.lineTo(4,20);p.lineTo(4,15);canvas.drawPath(p,paint);break;
                case "tune":for(int y:new int[]{6,12,18})canvas.drawLine(4,y,20,y,paint);paint.setStyle(Paint.Style.FILL);canvas.drawCircle(9,6,2.4f,paint);canvas.drawCircle(16,12,2.4f,paint);canvas.drawCircle(8,18,2.4f,paint);break;
                case "source":canvas.drawRoundRect(4,4,20,20,3,3,paint);canvas.drawLine(8,4,8,20,paint);for(int y:new int[]{8,12,16})canvas.drawLine(4,y,8,y,paint);break;
                case "batch":canvas.drawRoundRect(7,4,20,17,3,3,paint);p.moveTo(4,8);p.lineTo(4,18);p.quadTo(4,21,7,21);p.lineTo(17,21);canvas.drawPath(p,paint);break;
                case "check":p.moveTo(6,12);p.lineTo(10,16);p.lineTo(18,8);canvas.drawPath(p,paint);break;
                case "chevron":p.moveTo(8,10);p.lineTo(12,14);p.lineTo(16,10);canvas.drawPath(p,paint);break;
                case "right":p.moveTo(10,6);p.lineTo(16,12);p.lineTo(10,18);canvas.drawPath(p,paint);break;
                case "export":p.moveTo(5,13);p.lineTo(5,19);p.lineTo(19,19);p.lineTo(19,13);p.moveTo(12,15);p.lineTo(12,3);p.moveTo(8,7);p.lineTo(12,3);p.lineTo(16,7);canvas.drawPath(p,paint);break;
                case "magic":p.moveTo(13,3);p.lineTo(15.5f,9);p.lineTo(21,11);p.lineTo(15.5f,13);p.lineTo(13,19);p.lineTo(10.5f,13);p.lineTo(5,11);p.lineTo(10.5f,9);p.close();canvas.drawPath(p,paint);break;
                case "grip":paint.setStyle(Paint.Style.FILL);for(int x:new int[]{9,15})for(int y:new int[]{7,12,17})canvas.drawCircle(x,y,1,paint);break;
                default:canvas.drawRoundRect(4,5,20,19,3,3,paint);break;
            }
            canvas.restore();
        }
        /* 设置绘制透明度。 */
        @Override public void setAlpha(int alpha){paint.setAlpha(alpha);invalidateSelf();}
        /* 接受系统颜色过滤器。 */
        @Override public void setColorFilter(ColorFilter filter){paint.setColorFilter(filter);invalidateSelf();}
        /* 图标仅覆盖自己的透明画布。 */
        @Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
        /* 返回同一套逻辑图标宽度。 */
        @Override public int getIntrinsicWidth(){return size;}
        /* 返回同一套逻辑图标高度。 */
        @Override public int getIntrinsicHeight(){return size;}
    }
}
