package studio.shiren.mobile;

/** 用单调时间估计剩余时长，避免系统时钟变化导致倒计时跳变。 */
public final class TimeEstimate {
    private long start=System.nanoTime();
    /* 根据实际完成比例估计剩余秒数，开头样本不足时显示计算中。 */
    public String remaining(float fraction,boolean english){
        double elapsed=(System.nanoTime()-start)/1e9;
        if(fraction<.015||elapsed<.5)return english?"Estimating…":"预计时间计算中…";
        long seconds=(long)Math.ceil(elapsed*(1-Math.min(1,fraction))/fraction);
        if(seconds<60)return english?"~"+seconds+"s left":"约剩 "+seconds+" 秒";
        return english?"~"+(seconds+59)/60+" min left":"约剩 "+(seconds+59)/60+" 分钟";
    }
}
