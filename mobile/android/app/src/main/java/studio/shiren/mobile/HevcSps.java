package studio.shiren.mobile;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;

/** 读取实际HEVC SPS，编码器只声明Main10但写8位时必须拒绝。 */
final class HevcSps {
    final byte[] data;int bit;
    /* 解析器只接受受限字节数组。 */
    HevcSps(byte[] value){data=value;}
    /* 按位读取，截断参数集明确报错。 */
    long read(int n){if(n<0||bit+n>data.length*8)throw new IllegalArgumentException("HEVC SPS不完整");long value=0;for(int i=0;i<n;i++,bit++)value=value<<1|((data[bit/8]>>(7-bit%8))&1);return value;}
    /* 无符号Exp-Golomb防止非法长前导零。 */
    int ue(){int zero=0;while(read(1)==0)if(++zero>30)throw new IllegalArgumentException("HEVC SPS无效");return (1<<zero)-1+(int)read(zero);}
    /* 找到Annex-B序列参数集并返回实际亮度位深。 */
    static int depth(ByteBuffer config){
        ByteBuffer copy=config.duplicate();byte[] bytes=new byte[copy.remaining()];copy.get(bytes);
        for(int i=0;i+6<bytes.length;i++){
            int start=-1;if(bytes[i]==0&&bytes[i+1]==0&&bytes[i+2]==1)start=i+3;
            else if(i+4<bytes.length&&bytes[i]==0&&bytes[i+1]==0&&bytes[i+2]==0&&bytes[i+3]==1)start=i+4;
            if(start<0||((bytes[start]>>1)&63)!=33)continue;
            ByteArrayOutputStream body=new ByteArrayOutputStream();int zeros=0;
            for(int j=start+2;j<bytes.length;j++){int b=bytes[j]&255;if(zeros>=2&&b==3){zeros=0;continue;}body.write(b);zeros=b==0?zeros+1:0;}
            HevcSps r=new HevcSps(body.toByteArray());r.read(4);int layers=(int)r.read(3);r.read(1);r.read(32);r.read(32);r.read(32);
            int[] profile=new int[layers],level=new int[layers];for(int j=0;j<layers;j++){profile[j]=(int)r.read(1);level[j]=(int)r.read(1);}if(layers>0)r.read((8-layers)*2);
            for(int j=0;j<layers;j++){if(profile[j]!=0){r.read(32);r.read(32);r.read(24);}if(level[j]!=0)r.read(8);}
            r.ue();int chroma=r.ue();if(chroma==3)r.read(1);r.ue();r.ue();if(r.read(1)!=0)for(int j=0;j<4;j++)r.ue();
            int luma=8+r.ue(),colour=8+r.ue();if(luma!=colour)throw new IllegalArgumentException("HEVC亮度色度位深不一致");return luma;
        }
        throw new IllegalArgumentException("未找到HEVC SPS");
    }
}
