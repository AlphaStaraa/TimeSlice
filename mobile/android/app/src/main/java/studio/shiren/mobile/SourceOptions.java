package studio.shiren.mobile;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;

/** 与桌面相同的素材处理与首尾调色参数；调色不改变稳定去闪缓存。 */
public final class SourceOptions {
    public String stabilize="off", deflicker="off", direction="auto", look="cinematic";
    public boolean grade=false;
    public float[] start={24,3,1.08f,0,1.03f}, end={-24,-7,1.08f,0,1.04f};
    public float[][] hsl=new float[8][3];

    /* 深复制参数，后台任务不读取界面正在修改的数组。 */
    public SourceOptions copy(){
        SourceOptions out=new SourceOptions();out.stabilize=stabilize;out.deflicker=deflicker;
        out.direction=direction;out.look=look;out.grade=grade;out.start=start.clone();out.end=end.clone();
        for(int i=0;i<8;i++)out.hsl[i]=hsl[i].clone();return out;
    }

    /* 只包含需要重新准备源素材的配置，不把实时调色混入缓存身份。 */
    public String processingKey(){return stabilize+"/"+deflicker;}

    /* 按日夜方向设置与桌面相同的风格端点。 */
    public void preset(String name,boolean nightToDay){
        look=name;
        if(name.equals("natural")){start=new float[]{8,0,1.02f,0,1};end=new float[]{-8,-2,1.02f,0,1};}
        else if(name.equals("amber")){start=new float[]{38,5,1.12f,0,1.06f};end=new float[]{-30,-10,1.1f,0,1.06f};}
        else{start=new float[]{24,3,1.08f,0,1.03f};end=new float[]{-24,-7,1.08f,0,1.04f};}
        if(nightToDay){float[] swap=start;start=end;end=swap;}
    }

    /* 生成桌面 grade.h 读取的首尾参数、平滑进度和连续八色 HSL 表。 */
    public ByteBuffer buffer(int count,double[] brightness){
        ByteBuffer bytes=ByteBuffer.allocateDirect((16+count+3072)*4).order(ByteOrder.nativeOrder());
        float[] data=new float[16+count+3072];data[0]=grade?1:0;data[1]=count;
        System.arraycopy(start,0,data,2,5);System.arraycopy(end,0,data,7,5);
        double[] curve=progress(brightness,count);
        for(int i=0;i<count;i++)data[16+i]=(float)curve[i];
        int[] centers={0,30,60,120,180,240,270,300};
        for(int hue=0;hue<1024;hue++){
            double sum=0;double[] weights=new double[8];
            for(int band=0;band<8;band++){double distance=Math.abs((hue*360./1024-centers[band]+540)%360-180);weights[band]=Math.exp(-.5*Math.pow(distance/19,2));sum+=weights[band];}
            for(int channel=0;channel<3;channel++){
                double value=0;for(int band=0;band<8;band++)value+=weights[band]/sum*hsl[band][channel];
                if(channel>0)value/=100;data[16+count+hue*3+channel]=(float)value;
                if(Math.abs(value)>1e-8)data[12]=1;
            }
        }
        bytes.asFloatBuffer().put(data);return bytes;
    }

    /* 用亮度趋势平滑驱动首尾调色，弱变化时采用平滑时间关键帧。 */
    static double[] progress(double[] levels,int n){
        double[] result=new double[n];
        if(levels==null||levels.length!=n||n<8||Math.abs(levels[n-1]-levels[0])<.2){
            for(int i=0;i<n;i++){double t=i/(double)Math.max(1,n-1);result[i]=t*t*(3-2*t);}return result;
        }
        double[] trend=smooth(levels,Math.max(4,n*.06),false);double sign=trend[n-1]>trend[0]?1:-1;
        for(int i=1;i<n;i++)result[i]=result[i-1]+Math.max(0,sign*(trend[Math.min(n-1,i+1)]-trend[i-1])*.5)+.15/n;
        double span=Math.max(1e-6,result[n-1]);
        for(int i=0;i<n;i++){double t=.35*i/Math.max(1.,n-1)+.65*result[i]/span;result[i]=t*t*(3-2*t);}return result;
    }

    /* 用与桌面相同的五对角 LDL 平滑，保留日夜慢变化并移除瞬时闪烁。 */
    static double[] smooth(double[] y,double sigma,boolean robust){
        int n=y.length;if(n<4)return y.clone();double penalty=Math.max(1,Math.pow(sigma/1.4,4));
        double[] weights=new double[n],fit=y.clone();Arrays.fill(weights,1);
        for(int pass=0;pass<(robust?3:1);pass++){
            double[] d=new double[n],a=new double[n],b=new double[n],z=new double[n];
            d[0]=weights[0]+penalty;a[1]=-2*penalty/d[0];d[1]=weights[1]+5*penalty-a[1]*a[1]*d[0];
            for(int i=2;i<n;i++){
                b[i]=penalty/d[i-2];double one=(i==n-1?-2:-4)*penalty;
                a[i]=(one-b[i]*d[i-2]*a[i-1])/d[i-1];
                d[i]=weights[i]+penalty*(i==n-1?1:i==n-2?5:6)-a[i]*a[i]*d[i-1]-b[i]*b[i]*d[i-2];
            }
            for(int i=0;i<n;i++)z[i]=weights[i]*y[i];z[1]-=a[1]*z[0];
            for(int i=2;i<n;i++)z[i]-=a[i]*z[i-1]+b[i]*z[i-2];
            for(int i=0;i<n;i++)fit[i]=z[i]/d[i];
            for(int i=n-2;i>=0;i--){fit[i]-=a[i+1]*fit[i+1];if(i+2<n)fit[i]-=b[i+2]*fit[i+2];}
            if(robust){double[] residual=new double[n];for(int i=0;i<n;i++)residual[i]=y[i]-fit[i];double center=median(residual);
                for(int i=0;i<n;i++)residual[i]=Math.abs(residual[i]-center);double scale=Math.max(.008,median(residual)*1.4826);
                for(int i=0;i<n;i++)weights[i]=Math.max(.08,1/Math.max(1,Math.abs(y[i]-fit[i])/(2.5*scale)));
            }
        }return fit;
    }

    /* 返回有限数值的中位数，不把缺失测量当作曝光变化。 */
    static double median(double[] input){
        double[] values=Arrays.stream(input).filter(Double::isFinite).sorted().toArray();
        if(values.length==0)return Double.NaN;int k=values.length/2;
        return values.length%2==0?(values[k-1]+values[k])*.5:values[k];
    }
}
