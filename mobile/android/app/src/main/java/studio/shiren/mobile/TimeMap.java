package studio.shiren.mobile;

import android.content.Context;
import android.net.Uri;
import java.io.*;
import java.nio.*;
import java.util.concurrent.ConcurrentHashMap;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.imgcodecs.Imgcodecs;

/** 保留8/16位及浮点灰度时间图的精度，不把16位PNG降成8位缩略图。 */
public final class TimeMap {
    static{System.loadLibrary("opencv_java4");}
    final Mat absolute,relative;
    public final int bits;
    final ConcurrentHashMap<String,ByteBuffer> scaled=new ConcurrentHashMap<>();

    /* 保存不可变时间图，透明区域在相对模式下为零偏移。 */
    private TimeMap(Mat a,Mat r,int depth){absolute=a;relative=r;bits=depth;}

    /* 读取用户选择的PNG/TIFF/JPEG，按真实像素位深归一化。 */
    public static TimeMap load(Context context,Uri uri)throws Exception{
        ByteArrayOutputStream bytes=new ByteArrayOutputStream();try(InputStream input=context.getContentResolver().openInputStream(uri)){if(input==null)throw new IOException("无法读取时间图");byte[] buffer=new byte[65536];int n;while((n=input.read(buffer))>=0){if(bytes.size()>128*1024*1024)throw new IOException("时间图超过128MB");bytes.write(buffer,0,n);}}
        MatOfByte encoded=new MatOfByte(bytes.toByteArray());Mat image=Imgcodecs.imdecode(encoded,Imgcodecs.IMREAD_UNCHANGED);encoded.release();if(image.empty())throw new IOException("无法解码时间图");int bits=image.depth()==CvType.CV_16U?16:image.depth()==CvType.CV_32F||image.depth()==CvType.CV_64F?32:8;double divisor=bits==16?65535:bits==8?255:1;Mat value=new Mat();image.convertTo(value,CvType.CV_32F,1/divisor);int channels=value.channels();float[] data=new float[(int)(value.total()*channels)];value.get(0,0,data);float[] absolute=new float[(int)value.total()],relative=new float[absolute.length];float neutral=bits==8?128/255f:bits==16?32768/65535f:.5f;
        for(int i=0;i<absolute.length;i++){int p=i*channels;float gray=channels>=3?data[p]*.0722f+data[p+1]*.7152f+data[p+2]*.2126f:data[p];float alpha=channels==4?data[p+3]:1;absolute[i]=Math.max(0,Math.min(1,gray*alpha));relative[i]=Math.max(0,Math.min(1,gray*alpha+neutral*(1-alpha)));}
        Mat a=new Mat(value.rows(),value.cols(),CvType.CV_32F),r=new Mat(value.rows(),value.cols(),CvType.CV_32F);a.put(0,0,absolute);r.put(0,0,relative);image.release();value.release();return new TimeMap(a,r,bits);
    }

    /* 为预览或正式尺寸缓存浮点图，只缓存少量当前尺寸。 */
    public ByteBuffer buffer(int w,int h,boolean offsets){String key=w+"x"+h+"/"+offsets;ByteBuffer found=scaled.get(key);if(found!=null)return found;Mat out=new Mat();try{Imgproc.resize(offsets?relative:absolute,out,new Size(w,h),0,0,Imgproc.INTER_LINEAR);float[] data=new float[w*h];out.get(0,0,data);ByteBuffer bytes=ByteBuffer.allocateDirect(w*h*4).order(ByteOrder.nativeOrder());bytes.asFloatBuffer().put(data);if(scaled.size()>4)scaled.clear();scaled.put(key,bytes);return bytes;}finally{out.release();}}
}
