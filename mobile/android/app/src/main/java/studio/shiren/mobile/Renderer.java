package studio.shiren.mobile;

import android.content.Context;
import java.nio.*;
import java.util.*;
import java.util.concurrent.*;

public final class Renderer implements AutoCloseable {
    private final ExecutorService workers=Executors.newFixedThreadPool(Math.min(8,Runtime.getRuntime().availableProcessors()));
    private final String requested;
    private GLField gpu;
    private boolean closed;
    public String label="CPU 多线程";

    /* 初始化当前设备的渲染后端。 */ public Renderer(Context context,String mode) throws Exception {
        requested=mode;
        if(!mode.equals("cpu")){
            try {
                gpu=new GLField(context);
                label="GPU 时间计算 · CPU 合成 / "+gpu.device;
            } catch(Exception error) {
                if(mode.equals("gpu"))throw error;
                label="CPU 多线程 · 显卡暂不可用";
            }
        }
    }

    /* 按当前时间与效果生成一帧画面。 */ public ByteBuffer frame(VideoSource.Cache cache,Effect effect,Effect.Settings settings,float u,int view) throws Exception {
        ByteBuffer output=ByteBuffer.allocateDirect(cache.w*cache.h*4).order(ByteOrder.nativeOrder());
        ByteBuffer p=effect.params(settings,cache.w,cache.h,cache.frames,u,view);
        ByteBuffer mapping=settings.timeMap==null?null:settings.timeMap.buffer(cache.w,cache.h,settings.mapMode==1);
        if(gpu!=null && view!=1){
            try {
                gpu.render(p,cache,output,mapping);
                return output;
            } catch(Exception error) {
                if(requested.equals("gpu"))throw error;
                gpu.close(); gpu=null; label="CPU 多线程 · GPU 运行失败已切换";
            }
        }
        List<Future<?>> tasks=new ArrayList<>();
        for(int y=0;y<cache.h;y+=32){
            final int row=y,rows=Math.min(32,cache.h-y);
            tasks.add(workers.submit(()->NativeCore.renderMapped(p,cache.w,cache.h,row,rows,cache.bytes,output,cache.grade,mapping)));
        }
        for(Future<?> task:tasks)task.get();
        return output;
    }

    /* 关闭当前对象持有的资源，避免重复占用文件、线程或设备。 */ @Override public void close(){
        if(closed)return;
        closed=true;
        try {if(gpu!=null)gpu.close();}
        finally {gpu=null;workers.shutdown();}
    }
}
