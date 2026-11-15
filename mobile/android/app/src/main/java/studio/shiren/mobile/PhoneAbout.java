package studio.shiren.mobile;

import android.app.Dialog;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.view.Gravity;
import android.widget.*;

/** 品牌、作者、许可与法律全文分层呈现，避免首次打开就是长篇协议。 */
final class PhoneAbout {
    /** 创建与桌面同风格的关于页，始终显示实际安装版本与作者。 */
    static Dialog show(MainActivity a) {
        Dialog dialog = new Dialog(a);
        LinearLayout shell = a.column();
        shell.setPadding(a.dp(22), a.dp(18), a.dp(22), a.dp(18));
        LinearLayout header = new LinearLayout(a);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView title = a.text(a.t("关于时刃", "About TimeSlice"), 17, a.INK);
        header.addView(title, new LinearLayout.LayoutParams(0, a.dp(44), 1));
        header.addView(StudioUi.iconButton(a, "close", a.t("关闭", "Close"), dialog::dismiss),
                new LinearLayout.LayoutParams(a.dp(44), a.dp(44)));
        shell.addView(header);
        ScrollView scroll = new ScrollView(a);
        scroll.setVerticalScrollBarEnabled(false);
        LinearLayout body = a.column();
        body.setGravity(Gravity.CENTER_HORIZONTAL);
        body.setPadding(0, a.dp(14), 0, a.dp(16));
        ImageView icon = new ImageView(a);
        try { icon.setImageBitmap(BitmapFactory.decodeStream(a.getAssets().open("brand.png"))); }
        catch (Exception ignored) { }
        body.addView(icon, new LinearLayout.LayoutParams(a.dp(80), a.dp(80)));
        TextView name = a.text(a.english ? "TimeSlice" : "时刃", 30, a.INK);
        name.setTypeface(Typeface.create("sans-serif-medium", 0));
        name.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams nameSize = new LinearLayout.LayoutParams(-1, a.dp(52));
        nameSize.topMargin = a.dp(10);
        body.addView(name, nameSize);
        centered(a, body, a.t("延时里的无限可能", "More possibilities in every moment"), 13, a.MUTED, 30);
        centered(a, body, a.t("版本 ", "Version ") + a.appVersion(), 12, a.MUTED, 28);
        centered(a, body, "AlphaStar", 17, a.INK, 40);
        centered(a, body, a.t("完全免费 · 开放源码", "Free to use · Open source"), 13, a.ACCENT, 32);
        TextView description = a.text(a.t("导入一段延时，探索不同的时间切片。",
                "Turn a timelapse into a new perspective on time."), 13, a.MUTED);
        description.setGravity(Gravity.CENTER);
        description.setPadding(a.dp(8), a.dp(12), a.dp(8), a.dp(20));
        body.addView(description, new LinearLayout.LayoutParams(-1, -2));
        Button license = StudioUi.button(a, a.t("开源许可与声明", "License & notices"), false,
                () -> showLicense(a, dialog, false));
        a.add(body, license, 48);
        Button thirdParty = StudioUi.button(a, a.t("第三方组件许可", "Third-party licenses"), false,
                () -> showLicense(a, dialog, true));
        a.add(body, thirdParty, 48);
        centered(a, body, "AGPL-3.0-only · © 2026 AlphaStar", 11, a.MUTED, 32);
        scroll.addView(body);
        shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        Button done = StudioUi.button(a, a.t("完成", "Done"), true, dialog::dismiss);
        shell.addView(done, new LinearLayout.LayoutParams(-1, a.dp(48)));
        StudioUi.showSheet(a, dialog, shell, .82f);
        return dialog;
    }

    /** 统一居中文字高度、字色与触摸无关的内容间距。 */
    private static void centered(MainActivity a, LinearLayout parent, String value,
                                 int size, int color, int height) {
        TextView text = a.text(value, size, color);
        text.setGravity(Gravity.CENTER);
        parent.addView(text, new LinearLayout.LayoutParams(-1, a.dp(height)));
    }

    /** 完整法律声明按需展开，全文可选中复制，保留准确许可义务。 */
    private static void showLicense(MainActivity a, Dialog about, boolean thirdParty) {
        try {
            String asset = thirdParty ? "THIRD-PARTY-Stable.txt" :
                    a.english ? "LICENSE.en.txt" : "notice-zh.txt";
            String notice = new String(Assets.read(a, asset), "UTF-8");
            Dialog dialog = new Dialog(a);
            LinearLayout shell = a.column();
            shell.setPadding(a.dp(22), a.dp(20), a.dp(22), a.dp(18));
            TextView heading = a.text(thirdParty ? a.t("第三方许可", "Third-party licenses") :
                    a.t("开源许可与声明", "License & notices"), 18, a.INK);
            a.add(shell, heading, 42);
            ScrollView scroll = new ScrollView(a);
            TextView text = a.text(notice, 13, a.INK);
            text.setGravity(Gravity.TOP);
            text.setTextIsSelectable(true);
            text.setLineSpacing(a.dp(4), 1);
            text.setPadding(0, a.dp(8), 0, a.dp(16));
            scroll.addView(text);
            shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
            shell.addView(StudioUi.button(a, a.t("返回关于", "Back to About"), true, dialog::dismiss),
                    new LinearLayout.LayoutParams(-1, a.dp(48)));
            StudioUi.showSheet(a, dialog, shell, .84f);
        } catch (Exception error) { a.fail(error); }
    }
}
