package studio.shiren.mobile;

/** 与桌面保持一致的推荐码率；手动目标不因设备限制而被静默覆盖。 */
public final class ExportQuality {
    private ExportQuality() {}

    /* 按实际输出像素面积和帧率计算推荐值，横竖屏相同。 */
    public static int recommended(int width, int height, int fps) {
        if (width <= 0 || height <= 0 || fps <= 0)
            throw new IllegalArgumentException("输出尺寸和帧率必须为正数");
        double pixels = width * (double) height / (1920 * 1080);
        double estimate = 20 * Math.pow(pixels, .8) * Math.pow(fps / 30., .75);
        int mbps = (int) Math.min(500, Math.max(2, 5 * Math.floor(estimate / 5 + .5)));
        return mbps * 1000000;
    }

    /* 0代表推荐码率；自定义范围为1–500Mbps，不静默使用其他参数。 */
    public static int resolve(int width, int height, int fps, int requested) {
        if (requested == 0) return recommended(width, height, fps);
        if (requested < 1000000 || requested > 500000000)
            throw new IllegalArgumentException("码率范围为1–500 Mbps");
        return requested;
    }
}
