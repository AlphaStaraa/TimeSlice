package studio.shiren.mobile;
import android.content.Context;import java.io.*;
final class Assets {/* 读取输入或资源并返回后续处理需要的数据。 */ static byte[] read(Context c,String name)throws IOException{try(InputStream in=c.getAssets().open(name);ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] b=new byte[8192];int n;while((n=in.read(b))>=0)out.write(b,0,n);return out.toByteArray();}}}
