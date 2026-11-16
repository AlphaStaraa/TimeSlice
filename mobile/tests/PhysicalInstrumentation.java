package studio.shiren.mobile;

import android.app.Instrumentation;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.PowerManager;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.view.WindowManager;
import java.io.*;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.JSONArray;
import org.json.JSONObject;

/** 仅验证助手使用：导出本次证据，或运行真实持续负载；从不覆盖系统热状态。 */
public final class PhysicalInstrumentation extends Instrumentation {
    private String session, mode;
    private File dir;
    private final JSONObject report = new JSONObject();
    private final JSONArray outputs = new JSONArray(), temperatures = new JSONArray();
    private final AtomicBoolean cancel = new AtomicBoolean();
    private Activity activity;
    private boolean keepScreenOriginally;

    /** 只接收测试模式和安全会话名，拒绝任意设备路径。 */
    @Override public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        session = arguments.getString("session", "assets20261115")
                .replaceAll("[^a-zA-Z0-9_-]", "_");
        mode = arguments.getString("mode", "export");
        start();
    }

    /** 只把验证目录的白名单产物写入下载目录，不访问用户相册。 */
    private Uri publish(File file) throws Exception {
        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, file.getName());
        values.put(MediaStore.MediaColumns.RELATIVE_PATH,
                Environment.DIRECTORY_DOWNLOADS + "/TimeSliceValidation_" + session);
        String name = file.getName();
        values.put(MediaStore.MediaColumns.MIME_TYPE, name.endsWith(".mp4") ? "video/mp4" :
                name.endsWith(".png") ? "image/png" : name.endsWith(".jpg") ? "image/jpeg" :
                "application/json");
        values.put(MediaStore.MediaColumns.IS_PENDING, 1);
        Context context = getTargetContext();
        Uri uri = context.getContentResolver().insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
        if (uri == null) throw new IOException("Cannot create validation download");
        try {
            try (InputStream input = new FileInputStream(file);
                 OutputStream output = context.getContentResolver().openOutputStream(uri)) {
                byte[] block = new byte[65536];
                int count;
                while ((count = input.read(block)) != -1) output.write(block, 0, count);
            }
            values.clear();
            values.put(MediaStore.MediaColumns.IS_PENDING, 0);
            context.getContentResolver().update(uri, values, null, null);
            return uri;
        } catch (Exception error) {
            context.getContentResolver().delete(uri, null, null);
            throw error;
        }
    }

    /** 温度来自电池广播，热状态来自系统服务；温度不等于芯片结温。 */
    private JSONObject temperature(long origin) throws Exception {
        Context context = getTargetContext();
        Intent battery = context.registerReceiver(null,
                new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        PowerManager power = (PowerManager)context.getSystemService(Context.POWER_SERVICE);
        JSONObject sample = new JSONObject().put("elapsedSeconds",
                (SystemClock.elapsedRealtime() - origin) / 1000.0)
                .put("thermalStatus", power.getCurrentThermalStatus());
        if (battery != null) sample.put("batteryC",
                battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0)
                .put("plugged", battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0));
        return sample;
    }

    /** 使用正式源读取、混合渲染器和编码器，逐帧执行真实热保护。 */
    private JSONObject segment(VideoSource source, int edge, int fps, float seconds,
                               int index, boolean keep, long origin) throws Exception {
        Context context = getTargetContext();
        long prepareStart = SystemClock.elapsedRealtime();
        try (VideoSource.Cache cache = source.read(edge, 24, cancel, (p, text) -> {});
             Renderer renderer = new Renderer(context, "gpu")) {
            double preparation = (SystemClock.elapsedRealtime() - prepareStart) / 1000.0;
            List<Effect> effects = Effect.load(context);
            Effect effect = null;
            for (Effect item : effects) if (item.id == 100) effect = item;
            if (effect == null) throw new Exception("Missing vertical freeze");
            Effect.Settings settings = effect.defaults();
            settings.countMode = 1;
            settings.count = 60;
            settings.exportDither = mode.equals("quality");
            int requestedBitrate = mode.equals("quality") && index == 2 ? 73500000 : 0;
            File output = new File(dir, "stress-" + index + "-" + edge + "p" + fps + ".mp4");
            int frames = Math.round(seconds * fps);
            long started = SystemClock.elapsedRealtime();
            String encoder;
            try {
                try (VideoEncoder video = new VideoEncoder(context, source.uri, output,
                        cache.w, cache.h, fps, false, cancel, requestedBitrate)) {
                    encoder = video.label;
                    for (int frame = 0; frame < frames; frame++) {
                        ExportSafety.pace(context, cancel);
                        if (frame % fps == 0) {
                            JSONObject sample = temperature(origin);
                            temperatures.put(sample);
                            if (sample.optDouble("batteryC", 0) >= 44)
                                throw new Exception("Validation stopped at battery 44C");
                        }
                        ByteBuffer pixels = renderer.frame(cache, effect, settings,
                                frame / (float)Math.max(1, frames - 1), 0);
                        video.append(pixels, frame);
                    }
                    video.finish(seconds);
                }
                JSONObject item = new JSONObject().put("width", cache.w).put("height", cache.h)
                        .put("fps", fps).put("outputFrames", frames).put("sourceSamples", cache.frames)
                        .put("targetMbps", ExportQuality.resolve(cache.w, cache.h, fps, requestedBitrate)/1000000.)
                        .put("gradientDither", settings.exportDither)
                        .put("sourcePreparationSeconds", preparation)
                        .put("renderEncodeSeconds", (SystemClock.elapsedRealtime() - started) / 1000.0)
                        .put("engine", renderer.label).put("encoder", encoder)
                        .put("file", output.getName());
                if (keep) item.put("download", publish(output).toString());
                else output.delete();
                return item;
            } catch (Exception error) {
                output.delete();
                throw error;
            }
        }
    }

    /** 连续真实工作不少于十分钟；先验1080p30和4K60，再循环1080p30。 */
    private void stress() throws Exception {
        ActivityMonitor monitor = addMonitor("studio.shiren.mobile.MainActivity", null, false);
        try {
            try (android.os.ParcelFileDescriptor command = getUiAutomation().executeShellCommand(
                    "am start -n studio.shiren.mobile/.MainActivity");
                 InputStream stream = new android.os.ParcelFileDescriptor.AutoCloseInputStream(command)) {
                while (stream.read() != -1) { }
            }
            activity = waitForMonitorWithTimeout(monitor, 30000);
            if (activity == null) throw new Exception("Cannot foreground validation activity");
            runOnMainSync(() -> {
                keepScreenOriginally = (activity.getWindow().getAttributes().flags &
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0;
                activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            });
        } finally { removeMonitor(monitor); }
        Bundle status = new Bundle();
        status.putString("progress", "Foreground ready; preparing real 4K source");
        sendStatus(1, status);
        File input = new File(dir, "stress.mov");
        if (!input.isFile()) {
            try (InputStream in = getContext().getAssets().open("validation/stress.mov");
                 OutputStream out = new FileOutputStream(input)) {
                byte[] block = new byte[65536];
                int count;
                while ((count = in.read(block)) != -1) out.write(block, 0, count);
            }
        }
        VideoSource source = new VideoSource(getTargetContext(), Uri.fromFile(input));
        long origin = SystemClock.elapsedRealtime();
        report.put("manufacturer", Build.MANUFACTURER).put("model", Build.MODEL)
                .put("android", Build.VERSION.RELEASE).put("soc", Build.SOC_MODEL)
                .put("sourceWidth", source.width).put("sourceHeight", source.height)
                .put("sourceSeconds", source.durationUs / 1e6).put("sourceSamples", 24)
                .put("thermalSimulationRun", false).put("environmentTemperatureC", JSONObject.NULL);
        temperatures.put(temperature(origin));
        outputs.put(segment(source, 1920, 30, 1, 0, true, origin));
        outputs.put(segment(source, 3840, 60, 1, 1, true, origin));
        if(mode.equals("quality")){outputs.put(segment(source,3840,60,.5f,2,true,origin));return;}
        int index = 2;
        while (SystemClock.elapsedRealtime() - origin < 600000) {
            outputs.put(segment(source, 1920, 30, 6, index++, false, origin));
            Bundle update = new Bundle();
            update.putString("progress", "Real exports: " + index + "; elapsed " +
                    (SystemClock.elapsedRealtime() - origin) / 1000 + "s");
            sendStatus(1, update);
        }
        temperatures.put(temperature(origin));
        report.put("continuousWorkSeconds", (SystemClock.elapsedRealtime() - origin) / 1000.0);
    }

    /** 导出模式只取已完成证据，避免再次运行完整功能套件。 */
    private void exportEvidence() throws Exception {
        for (String name : new String[]{"stable-report.json", "phone-zh.png", "phone-en.png",
                "queue-last.mp4"}) {
            File file = new File(dir, name);
            if (file.isFile()) outputs.put(new JSONObject().put("file", name)
                    .put("bytes", file.length()).put("download", publish(file).toString()));
        }
        if (outputs.length() == 0) throw new Exception("No evidence found for session");
    }

    /** 仅清理本轮已知的内部验证副本；不操作原片、用户偏好或相册。 */
    private void cleanupEvidence() throws Exception {
        for (String name : new String[]{"assets20261115", "thermal20261115", "thermal20261115b", "visual103"}) {
            File root = new File(getTargetContext().getCacheDir(), "validation_" + name);
            if (root.exists()) removeTestFile(root, root.getCanonicalPath());
        }
    }

    /** 限制递归范围，遇到指向验证目录之外的链接时只删除链接本身。 */
    private void removeTestFile(File file, String allowed) throws Exception {
        String canonical = file.getCanonicalPath();
        if (file.isDirectory() && (canonical.equals(allowed) || canonical.startsWith(allowed + "/"))) {
            File[] children = file.listFiles();
            if (children == null) throw new IOException("Cannot list test directory");
            for (File child : children) removeTestFile(child, allowed);
        }
        if (!file.delete()) throw new IOException("Cannot remove test copy: " + file.getName());
    }

    /** 独立助手输出报告；不增加正式应用接口，不删除原功能验收证据。 */
    @Override public void onStart() {
        dir = new File(getTargetContext().getCacheDir(), "validation_" + session);
        try {
            if (mode.equals("cleanup")) cleanupEvidence();
            else if (!dir.exists() && !dir.mkdirs()) throw new IOException("Cannot create test directory");
            if (mode.equals("cleanup")) { /* 清理模式不创建新的设备端测试文件。 */ }
            else if (mode.equals("stress") || mode.equals("quality")) stress();
            else if (mode.equals("export")) exportEvidence();
            else throw new IllegalArgumentException("Unknown validation mode");
            report.put("passed", true);
        } catch (Throwable error) {
            try { report.put("passed", false).put("error", android.util.Log.getStackTraceString(error)); }
            catch (Exception ignored) { }
        } finally {
            if (activity != null && !keepScreenOriginally) runOnMainSync(() ->
                    activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON));
            try {
                report.put("mode", mode).put("outputs", outputs).put("temperatures", temperatures);
                if (!mode.equals("cleanup")) {
                    File file = new File(dir, "physical-" + mode + "-report.json");
                    try (OutputStream output = new FileOutputStream(file)) {
                        output.write(report.toString(2).getBytes("UTF-8"));
                    }
                    report.put("reportDownload", publish(file).toString());
                }
            } catch (Exception error) {
                try { report.put("evidenceError", error.toString()); } catch (Exception ignored) { }
            }
            Bundle result = new Bundle();
            result.putString("report", report.toString());
            finish(0, result);
        }
    }
}
