package studio.shiren.mobile;

import android.content.Context;
import java.nio.*;
import java.util.*;
import org.json.*;

public final class Effect {
    public static final int PARAM_BYTES = 160;
    private static final float[][] CENTERS = {{.5f,1},{.5f,0},{0,.5f},{1,.5f},{.5f,.5f}};
    public int id,family,shape,slices,origin;
    public String key,name,description;
    public float duration,cycles,span,turns;
    public boolean pixel;

    /* 读取内置资源、效果定义或素材信息。 */ public static List<Effect> load(Context context) throws Exception {
        JSONArray data = new JSONArray(new String(Assets.read(context,"effects.json"),"UTF-8"));
        List<Effect> result = new ArrayList<>();
        for(int i=0;i<data.length();i++){
            JSONObject o=data.getJSONObject(i);
            Effect e=new Effect();
            e.id=o.getInt("id"); e.family=o.getInt("family"); e.shape=o.getInt("shape");
            e.slices=o.getInt("slices"); e.origin=o.getInt("origin"); e.key=o.getString("key");
            e.name=o.getString("name"); e.description=o.getString("description");
            e.duration=(float)o.getDouble("duration"); e.cycles=(float)o.getDouble("cycles");
            e.span=(float)o.getDouble("span"); e.turns=(float)o.getDouble("turns");
            e.pixel=o.getBoolean("pixel");
            result.add(e);
        }
        return result;
    }

    /* 每个效果的默认阴影羽化与桌面保持一致。 */ public Settings defaults(){Settings out=new Settings();out.shadowSoftness=family==0?1f:.82f;return out;}
    public static final class Settings implements Cloneable {
        public int outputWidth=0, outputHeight=0, countMode=0, count=60;
        public int ending=-1, origin=-1, direction=0, playback=1, shadow=-1, shadowSide=0;
        public float seconds=0, build=.5f, angle=45, cycles=0, turns=-1, span=0, density=.42f, softness=.15f;
        public float shadowStrength=.25f, shadowWidth=.50f, shadowSoftness=1f;
        public float rotationStartAngle=0, discardRatio=.60f,sourceStart=0,sourceEnd=1,centerX=.5f,centerY=.5f;
        public boolean reverse=false, dayNightSplit=false, smooth=false;
        public TimeMap timeMap=null;
        public int mapMode=0,waveSources=2;
        /* 复制当前设置以隔离后台任务与界面编辑。 */ public Settings copy(){
            try { return (Settings)super.clone(); }
            catch(CloneNotSupportedException error) { throw new AssertionError(error); }
        }
    }

    /* 读取或计算当前效果的有效时长。 */ public float seconds(Settings s){return s.seconds>0?s.seconds:duration;}
    /* 昼夜模式展开后结束，标准冻结仍按用户选择继续流动。 */ public int ending(Settings s){return family==0&&s.dayNightSplit?0:s.ending>=0?s.ending:family==0?3:0;}
    /* 读取或切换当前效果是否启用阴影。 */ public boolean shadowEnabled(Settings s){return s.shadow<0?family==0:s.shadow!=0;}

    /* 按几何形状和输出像素尺寸计算切片数量上限。 */ public int limit(Settings s,int w,int h){
        float[] center=CENTERS[id==0||id==104?4:s.origin<0?origin:s.origin];
        double cx=center[0]+s.centerX-.5,cy=center[1]+s.centerY-.5;
        double rx=Math.max(Math.abs(cx),Math.abs(1-cx))*w,ry=Math.max(Math.abs(cy),Math.abs(1-cy))*h,r=Math.hypot(rx,ry);
        if(s.timeMap!=null)return w*h;
        if(id==13)return 1;
        if(id==410)return Math.min(3,h)*w;
        switch(shape){
            case 0:case 11:return w;
            case 1:return h;
            case 2:case 12:double a=Math.toRadians(s.angle);return Math.max(2,(int)Math.floor((w-1)*Math.abs(Math.cos(a))+(h-1)*Math.abs(Math.sin(a)))+1);
            case 5:case 13:case 14:return Math.max(2,(int)Math.ceil(r));
            case 6:return Math.max(2,(int)Math.ceil(rx+ry));
            case 7:return Math.max(2,(int)Math.ceil(Math.min(rx,ry)));
            case 3:return Math.max(2,Math.min(w*h,(int)Math.ceil(Math.PI*r)));
            case 4:case 9:return Math.max(2,Math.min(w*h,(int)Math.ceil(2*Math.PI*r)));
            default:return w*h;
        }
    }

    /* 把效果与设置编码为 CPU/GPU 共用参数布局。 */ public ByteBuffer params(Settings s,int w,int h,int frames,float u,int view){
        int ow=s.outputWidth>0?s.outputWidth:w,oh=s.outputHeight>0?s.outputHeight:h;
        int cap=limit(s,ow,oh),o=id==0||id==104?4:s.origin<0?origin:s.origin;
        boolean pix=s.countMode==2||(s.countMode==0&&pixel);
        int n=Math.min(cap,Math.max(id==403?3:2,pix?cap:s.countMode==1?s.count:family==0?60:slices));
        float[] c=CENTERS[o];
        boolean split=family==0&&s.dayNightSplit;
        float build=Math.max(.1f,Math.min(.9f,s.build));
        float[] f={u,split?Math.max(0,Math.min(1,u))*build:u,frames-1,(float)ow/oh,n,pix?1:0,s.span>0?s.span:span,
            s.cycles>0?s.cycles:cycles,c[0]+s.centerX-.5f,c[1]+s.centerY-.5f,shape==2||shape==12?s.angle:shape==4?s.rotationStartAngle:0,
            s.turns<0?turns:s.turns,build,s.softness,s.density,s.reverse?1:0,s.sourceStart,s.sourceEnd,ow,oh};
        int flags=(s.smooth?1:0)|(split?1024:0)|(s.mapMode==1?2:0);
        if(s.timeMap!=null)flags|=s.timeMap.bits==8?4:s.timeMap.bits==16?8:0;
        int[] v={family,shape,id,ending(s),s.direction,s.playback,o,view,frames,s.timeMap!=null&&family!=3?1:0,s.waveSources,flags};
        float strength=view==0&&shadowEnabled(s)?s.shadowStrength:0;
        float[] shading={strength,s.shadowWidth,s.shadowSoftness,s.shadowSide,w,h,0,split?s.discardRatio:0};
        ByteBuffer b=ByteBuffer.allocateDirect(PARAM_BYTES).order(ByteOrder.nativeOrder());
        for(float x:f)b.putFloat(x);
        for(int x:v)b.putInt(x);
        for(float x:shading)b.putFloat(x);
        b.rewind();
        return b;
    }
}
