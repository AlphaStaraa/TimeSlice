// Subpixel area sampling of the time field; source texture stays at the pixel centre.
/* 检查像素是否跨越切片或展开边缘，决定是否细分面积采样。 */ bool needsAA53(float2 uv,TFParams p,float mapValue){
 if(p.customMap!=0)return false;
 if(p.pixel>0 && p.family!=3 && p.shadowStrength<=0)return false;
 if((p.shape==0||p.shape==1||p.shape==11)&&p.direction<2){
  float pitch=(p.shape==1?p.sampleH:p.sampleW)/max(2.0f,p.slices);
  if(abs(pitch-round(pitch))<1e-6f)return false;
 }
 TFParams q=p;q.reserved0=.25f;
 float2 delta=.49f/float2(p.sampleW,p.sampleH);
 Coord c=coordinate3(uv-delta,q,mapValue);
 Field first=evaluate3(uv-delta,q,mapValue);
 for(int i=1;i<4;i++){
  float2 v=uv+float2((i&1)!=0 ? delta.x:-delta.x,(i&2)!=0 ? delta.y:-delta.y);
  Coord other=coordinate3(v,q,mapValue);Field f=evaluate3(v,q,mapValue);
  if(other.index!=c.index || abs(other.coverage-c.coverage)>.001f || abs(first.weight-f.weight)>.01f)return true;
  if(p.family==3 && (abs(first.a-f.a)>.02f || abs(first.b-f.b)>.02f))return true;
 }
 return false;
}
