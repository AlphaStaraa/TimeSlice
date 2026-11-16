package studio.shiren.mobile;

import android.content.Context;
import java.nio.ByteBuffer;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.features2d.*;
import org.opencv.calib3d.Calib3d;
import org.opencv.video.Video;

/** 固定机位多参照稳像、ECC精修和保留昼夜趋势的三级去闪。 */
public final class SourceProcessor {
    static {System.loadLibrary("opencv_java4");}
    static final double[] LINEAR=new double[256];
    static {for(int i=0;i<256;i++){double c=i/255.;LINEAR[i]=c<=.04045?c/12.92:Math.pow((c+.055)/1.055,2.4);}}
    public static final class Result {
        public VideoSource.Cache cache;
        public double crop=1,validationP95=0,beforeFlicker=0,afterFlicker=0;
        public boolean nightToDay;public String algorithm="off";
        public double[][] transforms,gains;
    }
    static final class Reference {
        Mat descriptors;Point[] points;double[] pose;
        /* 保存稀疏参考帧的特征与统一坐标变换。 */
        Reference(Mat d,Point[] p,double[] m){descriptors=d;points=p;pose=m;}
    }

    /* 将缓存帧包装成零拷贝的 RGBA Mat，调用方负责 release。 */
    static Mat rgba(VideoSource.Cache c,int index){return new Mat(c.h,c.w,CvType.CV_8UC4,c.frame(index));}

    /* 去除局部亮度影响后提取建筑纹理，减弱昼夜变化对匹配的影响。 */
    static Mat detail(VideoSource.Cache cache,int index,Size size,boolean bytes){
        Mat raw=rgba(cache,index),small=new Mat(),gray=new Mat(),levels=new Mat(),blur=new Mat(),rms=new Mat();
        try{
            Imgproc.resize(raw,small,size,0,0,Imgproc.INTER_AREA);Imgproc.cvtColor(small,gray,Imgproc.COLOR_RGBA2GRAY);
            gray.convertTo(levels,CvType.CV_32F,.12,1);Core.log(levels,levels);
            Imgproc.GaussianBlur(levels,blur,new Size(0,0),2.1);Core.subtract(levels,blur,levels);
            Core.multiply(levels,levels,rms);Imgproc.GaussianBlur(rms,rms,new Size(0,0),3.2);
            Core.max(rms,new Scalar(.0015),rms);Core.sqrt(rms,rms);Core.divide(levels,rms,levels);
            Mat out=new Mat();levels.convertTo(out,bytes?CvType.CV_8U:CvType.CV_32F,bytes?60:1,bytes?120:0);return out;
        }finally{raw.release();small.release();gray.release();levels.release();blur.release();rms.release();}
    }

    /* 返回3×3单位变换。 */
    static double[] identity(){return new double[]{1,0,0,0,1,0,0,0,1};}
    /* 按矩阵顺序组合参照变换和当前帧位移。 */
    static double[] multiply(double[] a,double[] b){double[] c=new double[9];for(int y=0;y<3;y++)for(int x=0;x<3;x++)for(int k=0;k<3;k++)c[y*3+x]+=a[y*3+k]*b[k*3+x];return c;}
    /* 求仿射逆变换，用于全片一致裁切和边界核查。 */
    static double[] inverse(double[] a){double d=a[0]*a[4]-a[1]*a[3];return new double[]{a[4]/d,-a[1]/d,(a[1]*a[5]-a[4]*a[2])/d,-a[3]/d,a[0]/d,(a[3]*a[2]-a[0]*a[5])/d,0,0,1};}
    /* 创建 OpenCV 仿射矩阵。 */
    static Mat matrix(double[] values){Mat out=new Mat(2,3,CvType.CV_64F);out.put(0,0,Arrays.copyOf(values,6));return out;}

    /* 估计多参照相似变换；每四个匹配点留一个用于独立误差核查。 */
    static double[][] registration(Context context,VideoSource.Cache cache,boolean extreme,AtomicBoolean stop,VideoSource.Progress progress,Result report)throws Exception{
        int n=cache.frames;double scale=Math.min(1,960./Math.max(cache.w,cache.h));Size size=new Size(Math.round(cache.w*scale),Math.round(cache.h*scale));
        SIFT sift=SIFT.create(2200,3,.015,10,1.6);BFMatcher matcher=BFMatcher.create(Core.NORM_L2,false);
        List<Reference> refs=new ArrayList<>();double[][] poses=new double[n][];List<Double> errors=new ArrayList<>();
        try{
            for(int i=0;i<n;i++){
                ExportSafety.pace(context,stop);Mat gray=detail(cache,i,size,true),desc=new Mat(),mask=new Mat();MatOfKeyPoint keys=new MatOfKeyPoint();
                try{
                    sift.detectAndCompute(gray,mask,keys,desc);KeyPoint[] kp=keys.toArray();Point[] points=new Point[kp.length];for(int j=0;j<kp.length;j++)points[j]=kp[j].pt;
                    if(i==0){if(points.length<16)throw new Exception("纹理不足，无法可靠锁定画面；请关闭稳定或更换素材。");poses[i]=identity();}
                    else if(points.length>=16){
                        int best=0;List<Reference> candidates=new ArrayList<>();candidates.add(refs.get(0));for(int k=Math.max(1,refs.size()-3);k<refs.size();k++)candidates.add(refs.get(k));
                        for(Reference ref:candidates){
                            List<MatOfDMatch> pairs=new ArrayList<>();matcher.knnMatch(desc,ref.descriptors,pairs,2);
                            List<Point> from=new ArrayList<>(),to=new ArrayList<>(),heldFrom=new ArrayList<>(),heldTo=new ArrayList<>();int valid=0;
                            for(MatOfDMatch pair:pairs){DMatch[] matches=pair.toArray();if(matches.length==2&&matches[0].distance<.72*matches[1].distance){DMatch m=matches[0];boolean held=(valid++%4)==0;(held?heldFrom:from).add(points[m.queryIdx]);(held?heldTo:to).add(ref.points[m.trainIdx]);}pair.release();}
                            if(from.size()<12)continue;MatOfPoint2f a=new MatOfPoint2f(),b=new MatOfPoint2f();a.fromList(from);b.fromList(to);Mat inliers=new Mat(),warp=new Mat();
                            try{
                                warp=Calib3d.estimateAffinePartial2D(a,b,inliers,Calib3d.RANSAC,1.,2500,.995,20);
                                int score=Core.countNonZero(inliers);if(warp.empty()||score<12||score<=best)continue;
                                double[] local=identity();warp.get(0,0,local);local[6]=0;local[7]=0;local[8]=1;
                                double zoom=Math.hypot(local[0],local[3]);if(zoom<.85||zoom>1.15)continue;
                                poses[i]=multiply(ref.pose,local);best=score;
                                for(int j=0;j<heldFrom.size();j++){Point p=heldFrom.get(j),q=heldTo.get(j);errors.add(Math.hypot(local[0]*p.x+local[1]*p.y+local[2]-q.x,local[3]*p.x+local[4]*p.y+local[5]-q.y)/scale);}
                            }finally{a.release();b.release();inliers.release();warp.release();}
                        }
                    }
                    if(poses[i]!=null&&(refs.isEmpty()||i%Math.max(8,n/12)==0))refs.add(new Reference(desc.clone(),points,poses[i]));
                }finally{gray.release();desc.release();mask.release();keys.release();}
                progress.update(.65f*(i+1)/n,"匹配固定机位 "+(i+1)+"/"+n);
            }
            int missing=0;for(double[] p:poses)if(p==null)missing++;
            if(missing>n*.05)throw new Exception("可可靠锁定的画面不足95%，已停止稳定；不会用错误匹配强行处理。");
            for(int i=0;i<n;i++)if(poses[i]==null){int a=i-1,b=i+1;while(b<n&&poses[b]==null)b++;if(b==n)poses[i]=poses[a].clone();else{poses[i]=new double[9];for(int j=0;j<9;j++)poses[i][j]=poses[a][j]+(poses[b][j]-poses[a][j])*(i-a)/(b-a);}}
            if(extreme){
                Map<Integer,Mat> references=new HashMap<>();int stride=Math.max(1,(n-1)/8);
                try{
                    for(int i=0;i<n;i+=stride){Mat d=detail(cache,i,size,false),target=new Mat(),m=matrix(poses[i]);Imgproc.warpAffine(d,target,m,size);d.release();m.release();references.put(i,target);}
                    for(int i=0;i<n;i++){
                        ExportSafety.pace(context,stop);int nearest=0;for(int k:references.keySet())if(Math.abs(k-i)<Math.abs(nearest-i))nearest=k;
                        Mat input=detail(cache,i,size,false),aligned=new Mat(),m=matrix(poses[i]),warp=Mat.eye(2,3,CvType.CV_32F),mask=new Mat();
                        try{
                            Imgproc.warpAffine(input,aligned,m,size);Mat target=references.get(nearest);
                            Core.absdiff(target,aligned,mask);Core.compare(mask,new Scalar(1),mask,Core.CMP_LT);
                            double before=Core.norm(target,aligned,Core.NORM_L2,mask);
                            Video.findTransformECC(target,aligned,warp,Video.MOTION_EUCLIDEAN,new TermCriteria(TermCriteria.COUNT|TermCriteria.EPS,70,1e-7),mask,5);
                            float[] v=new float[6];warp.get(0,0,v);double[] d=identity();for(int k=0;k<6;k++)d[k]=v[k];double[] correction=inverse(d);
                            if(Math.hypot(correction[2],correction[5])<2.5){Mat refined=new Mat(),cm=matrix(correction);Imgproc.warpAffine(aligned,refined,cm,size);if(Core.norm(target,refined,Core.NORM_L2,mask)<before)poses[i]=multiply(correction,poses[i]);refined.release();cm.release();}
                        }catch(CvException ignored){/* 保留已通过特征验证的原变换，不用失败ECC覆盖它。 */}
                        finally{input.release();aligned.release();m.release();warp.release();mask.release();}
                        progress.update(.65f+.25f*(i+1)/n,"亚像素精修 "+(i+1)+"/"+n);
                    }
                }finally{for(Mat m:references.values())m.release();}
            }
            double sx=size.width/cache.w,sy=size.height/cache.h;double[] sampling={sx,0,(sx-1)*.5,0,sy,(sy-1)*.5,0,0,1};
            for(int i=0;i<n;i++)poses[i]=multiply(multiply(inverse(sampling),poses[i]),sampling);
            report.algorithm=extreme?"SIFT + RANSAC + ECC":"SIFT + RANSAC";
            Collections.sort(errors);if(!errors.isEmpty())report.validationP95=errors.get(Math.min(errors.size()-1,(int)(errors.size()*.95)));
            return poses;
        }finally{sift.clear();matcher.clear();for(Reference ref:refs)ref.descriptors.release();}
    }

    /* 用整段共同的裁切量避免抖动黑边；超过12%时明确拒绝。 */
    static double crop(double[][] poses,int w,int h)throws Exception{
        double low=1,high=1.12;if(!fits(poses,w,h,high))throw new Exception("锁定画面所需裁切超过12%，请检查机位是否移动。");
        for(int i=0;i<22;i++){double mid=(low+high)*.5;if(fits(poses,w,h,mid))high=mid;else low=mid;}return high;
    }
    /* 检查所有逆变换后的画面四角都落在有效源像素内。 */
    static boolean fits(double[][] poses,int w,int h,double zoom){
        double cx=(w-1)*.5,cy=(h-1)*.5;
        for(double[] pose:poses){double[] inv=inverse(pose);for(double x:new double[]{0,w-1})for(double y:new double[]{0,h-1}){double px=cx+(x-cx)/zoom,py=cy+(y-cy)/zoom;double xx=inv[0]*px+inv[1]*py+inv[2],yy=inv[3]*px+inv[4]*py+inv[5];if(xx<2||yy<2||xx>w-3||yy>h-3)return false;}}
        return true;
    }

    /* 计算线性曝光网格，只让瞬时亮度波动参与去闪，不抹掉日夜变化。 */
    static double[][] exposure(Context context,VideoSource.Cache cache,AtomicBoolean stop,VideoSource.Progress progress)throws Exception{
        double[][] tiles=new double[cache.frames][64];cache.chroma=new double[cache.frames][2];
        for(int i=0;i<cache.frames;i++){
            ExportSafety.pace(context,stop);Mat raw=rgba(cache,i),small=new Mat();byte[] pixels=new byte[96*64*4];
            try{Imgproc.resize(raw,small,new Size(96,64),0,0,Imgproc.INTER_AREA);small.get(0,0,pixels);}finally{raw.release();small.release();}
            for(int gy=0;gy<8;gy++)for(int gx=0;gx<8;gx++){
                double[] patch=new double[96];int k=0;
                for(int y=gy*8;y<gy*8+8;y++)for(int x=gx*12;x<gx*12+12;x++){int p=(y*96+x)*4;double l=.2126*LINEAR[pixels[p]&255]+.7152*LINEAR[pixels[p+1]&255]+.0722*LINEAR[pixels[p+2]&255];patch[k++]=l>.006&&l<.85?Math.log(l)/Math.log(2):Double.NaN;}
                tiles[i][gy*8+gx]=SourceOptions.median(patch);
            }
            double[] red=new double[96*64],blue=new double[red.length];Arrays.fill(red,Double.NaN);Arrays.fill(blue,Double.NaN);int valid=0;
            for(int j=0;j<red.length;j++){int p=j*4;double r=LINEAR[pixels[p]&255],g=LINEAR[pixels[p+1]&255],b=LINEAR[pixels[p+2]&255],y=.2126*r+.7152*g+.0722*b;if(y>.025&&y<.65&&Math.max(r,Math.max(g,b))<2.2*Math.max(.001,Math.min(r,Math.min(g,b)))){red[valid]=Math.log((r+.002)/(g+.002))/Math.log(2);blue[valid++]=Math.log((b+.002)/(g+.002))/Math.log(2);}}
            cache.chroma[i][0]=valid>64?SourceOptions.median(red):Double.NaN;cache.chroma[i][1]=valid>64?SourceOptions.median(blue):Double.NaN;
            progress.update((i+1f)/cache.frames,"分析亮度 "+(i+1)+"/"+cache.frames);
        }return tiles;
    }

    /* 保持所有输入帧，准备可复用的稳定去闪缓存；首尾调色交给实时渲染。 */
    public static Result process(Context context,VideoSource.Cache base,SourceOptions options,AtomicBoolean stop,VideoSource.Progress progress)throws Exception{
        if(base.precision)return processPrecision(context,base,options,stop,progress);
        Result result=new Result();boolean enabled=!options.stabilize.equals("off")||!options.deflicker.equals("off");
        VideoSource.Cache cache=enabled?VideoSource.allocate(context,base.w,base.h,base.frames):base;result.cache=cache;
        result.transforms=new double[base.frames][9];result.gains=new double[base.frames][3];for(int i=0;i<base.frames;i++){result.transforms[i]=new double[]{1,0,0,0,1,0,0,0,1};Arrays.fill(result.gains[i],1);}
        try{
            double[][] poses=null;
            if(!options.stabilize.equals("off"))poses=registration(context,base,options.stabilize.equals("extreme"),stop,(p,t)->progress.update(p*.6f,t),result);
            if(poses!=null)result.crop=crop(poses,base.w,base.h);
            for(int i=0;enabled&&i<base.frames;i++){
                ExportSafety.pace(context,stop);Mat input=rgba(base,i),output=rgba(cache,i);
                try{if(poses==null)input.copyTo(output);else{double z=result.crop;double[] framing={z,0,(base.w-1)*.5*(1-z),0,z,(base.h-1)*.5*(1-z),0,0,1};result.transforms[i]=multiply(framing,poses[i]);Mat m=matrix(result.transforms[i]);Imgproc.warpAffine(input,output,m,new Size(base.w,base.h),Imgproc.INTER_LANCZOS4,Core.BORDER_REFLECT_101,new Scalar(0));m.release();}}
                finally{input.release();output.release();}
                progress.update(.6f+.1f*(i+1)/base.frames,"稳定画面 "+(i+1)+"/"+base.frames);
            }
            double[][] tiles=exposure(context,cache,stop,(p,t)->progress.update(.7f+.1f*p,t));double[] curve=new double[cache.frames],levels=new double[cache.frames];
            for(int i=0;i<cache.frames;i++){levels[i]=SourceOptions.median(tiles[i]);if(!Double.isFinite(levels[i]))levels[i]=i>0?levels[i-1]:-13;if(i>0){double[] steps=new double[64];for(int j=0;j<64;j++)steps[j]=tiles[i][j]-tiles[i-1][j];double step=SourceOptions.median(steps);curve[i]=curve[i-1]+(Double.isFinite(step)?step:0);}}
            cache.brightness=levels;result.nightToDay=levels[levels.length-1]>levels[0];
            if(!options.deflicker.equals("off")){
                double sigma=options.deflicker.equals("light")?2:options.deflicker.equals("standard")?4:8;
                double limit=options.deflicker.equals("light")?.18:options.deflicker.equals("standard")?.4:.8;
                double[] trend=SourceOptions.smooth(curve,sigma,true),after=curve.clone();
                double[][] chromaGain=new double[cache.frames][3];
                if(options.deflicker.equals("extreme"))for(int col=0;col<2;col++){
                    double[] track=new double[cache.frames];int good=0;for(int i=0;i<track.length;i++){track[i]=cache.chroma[i][col];if(Double.isFinite(track[i]))good++;}
                    if(good>4){for(int i=0;i<track.length;i++)if(!Double.isFinite(track[i])){int a=i-1,b=i+1;while(a>=0&&!Double.isFinite(track[a]))a--;while(b<track.length&&!Double.isFinite(track[b]))b++;track[i]=a<0?track[b]:b==track.length?track[a]:track[a]+(track[b]-track[a])*(i-a)/(b-a);}
                        double[] fit=SourceOptions.smooth(track,sigma,true);for(int i=0;i<track.length;i++)chromaGain[i][col==0?0:2]=Math.max(-.055,Math.min(.055,fit[i]-track[i]));
                    }
                }

                for(int i=0;i<cache.frames;i++){
                    ExportSafety.pace(context,stop);double ev=Math.max(-limit,Math.min(limit,trend[i]-curve[i]));after[i]+=ev;for(int c=0;c<3;c++)result.gains[i][c]=Math.pow(2,ev+chromaGain[i][c]);
                    byte[] values=new byte[256*4];for(int x=0;x<256;x++){for(int c=0;c<3;c++){double linear=LINEAR[x]*Math.pow(2,ev+chromaGain[i][c]);double srgb=linear<=.0031308?12.92*linear:1.055*Math.pow(linear,1/2.4)-.055;values[x*4+c]=(byte)Math.round(Math.max(0,Math.min(1,srgb))*255);}values[x*4+3]=(byte)x;}
                    Mat frame=rgba(cache,i),lut=new Mat(1,256,CvType.CV_8UC4);try{lut.put(0,0,values);Core.LUT(frame,lut,frame);}finally{frame.release();lut.release();}
                    progress.update(.8f+.2f*(i+1)/cache.frames,"去闪修正 "+(i+1)+"/"+cache.frames);
                }
                result.beforeFlicker=jump95(curve);result.afterFlicker=jump95(after);
            }
            cache.grade=options.buffer(cache.frames,cache.brightness);progress.update(1,"素材已就绪，导出复用处理结果");return result;
        }catch(Exception error){if(cache!=base)cache.close();throw error;}
    }

    /* 记录相邻帧曝光跳变的95分位值。 */
    static double jump95(double[] values){double[] jumps=new double[Math.max(1,values.length-1)];for(int i=1;i<values.length;i++)jumps[i-1]=Math.abs(values[i]-values[i-1]);Arrays.sort(jumps);return jumps[Math.min(jumps.length-1,(int)(jumps.length*.95))];}

    /* SDR代理只负责运动和去闪计划；正式帧始终由RGB10原始缓存重采样。 */
    static Result processPrecision(Context context,VideoSource.Cache base,SourceOptions options,AtomicBoolean stop,VideoSource.Progress progress)throws Exception{
        double scale=Math.min(1,640./Math.max(base.w,base.h));int w=Math.max(2,(int)(base.w*scale)/2*2),h=Math.max(2,(int)(base.h*scale)/2*2);
        VideoSource.Cache proxy=VideoSource.allocate(context,w,h,base.frames);Result measured=null;VideoSource.Cache output=null,processedProxy=null;
        try{
            float[] resize={(float)base.w/w,0,((float)base.w/w-1)/2,0,(float)base.h/h,((float)base.h/h-1)/2},unit={1,1,1};
            for(int i=0;i<base.frames;i++){VideoSource.check(stop);if(!NativeCore.transformPrecision(base.frame(i),base.w,base.h,proxy.frame(i),w,h,resize,unit,base.colorFlags,base.sourcePeak,false))throw new Exception("高精度分析代理失败");}
            measured=process(context,proxy,options,stop,progress);processedProxy=measured.cache;boolean enabled=!options.stabilize.equals("off")||!options.deflicker.equals("off");
            output=enabled?VideoSource.allocate(context,base.w,base.h,base.frames):base;VideoColor.copy(base,output);output.brightness=measured.cache.brightness;output.chroma=measured.cache.chroma;output.grade=measured.cache.grade;
            double sx=base.w/(double)w,sy=base.h/(double)h;double[] expand={sx,0,(sx-1)/2,0,sy,(sy-1)/2,0,0,1},contract=inverse(expand);
            if(enabled)for(int i=0;i<base.frames;i++){
                VideoSource.check(stop);double[] inv=inverse(multiply(multiply(expand,measured.transforms[i]),contract));float[] m={(float)inv[0],(float)inv[1],(float)inv[2],(float)inv[3],(float)inv[4],(float)inv[5]},g={(float)measured.gains[i][0],(float)measured.gains[i][1],(float)measured.gains[i][2]};
                if(!NativeCore.transformPrecision(base.frame(i),base.w,base.h,output.frame(i),base.w,base.h,m,g,base.colorFlags,base.sourcePeak,true))throw new Exception("高精度稳定/去闪写入失败");
            }
            measured.cache=output;return measured;
        }catch(Exception error){if(output!=null&&output!=base)output.close();throw error;}
        finally{if(processedProxy!=null&&processedProxy!=proxy)processedProxy.close();proxy.close();}
    }

    /* 从正式缓存生成轻量预览，不重新去闪或稳定。 */
    public static VideoSource.Cache preview(Context context,VideoSource.Cache full,int edge)throws Exception{
        double scale=Math.min(1,edge/(double)Math.max(full.w,full.h));int w=Math.max(2,(int)(full.w*scale)/2*2),h=Math.max(2,(int)(full.h*scale)/2*2);
        VideoSource.Cache out=VideoSource.allocate(context,w,h,full.frames);out.brightness=full.brightness;out.grade=full.grade;
        VideoColor.copy(full,out);
        for(int i=0;i<full.frames;i++){
            if(full.precision){float sx=full.w/(float)w,sy=full.h/(float)h;if(!NativeCore.transformPrecision(full.frame(i),full.w,full.h,out.frame(i),w,h,new float[]{sx,0,(sx-1)/2,0,sy,(sy-1)/2},new float[]{1,1,1},full.colorFlags,full.sourcePeak,true))throw new Exception("高精度预览生成失败");}
            else{Mat source=rgba(full,i),dest=rgba(out,i);try{Imgproc.resize(source,dest,new Size(w,h),0,0,Imgproc.INTER_AREA);}finally{source.release();dest.release();}}
        }
        return out;
    }
}
