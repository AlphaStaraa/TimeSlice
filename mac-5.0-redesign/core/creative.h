/* 为创意切片计算统一的轴向坐标。 */ float creativeAxis42(float q,uint direction){
 if(direction==1)return 1-q;
 if(direction>=2){
  q=abs(q-.5f)*2;
  return direction==3 ? 1-q:q;
 }
 return q;
}

/* 按创意效果编号生成对应的时间场。 */ Field creative42(float2 uv,TFParams p){
 float2 center=float2(p.cx,p.cy),size=float2(p.sampleW,p.sampleH);
 float2 metric=float2(p.aspect,1),v=(uv-center)*metric;
 float u=p.u,clock=2*p.cycles*u,n=max(2.0f,p.slices);
 Field f=single3(uv,bounce3(clock+1));
 switch(p.design){
  case 407:{
   float y=uv.y-center.y;
   float bend=.105f*sin(2*PI3*(y+.35f*u))+.026f*sin(2*PI3*(2*y-.7f*u));
   float q=creativeAxis42(uv.x+bend,p.direction)-.52f*p.cycles*u;
   float band=q*n,cell=floor(band);
   float t=bounce3(clock-.75f*cell/n);
   f.a=f.b=lerp(t,1-t,frac(cell*.5f)*2*p.span);
   MAC_TILED_EDGE(f,frac(band),size.x/n,1)
   break;
  }
  case 408:{
   const float root3=1.732050808f;
   float pitch=sqrt(2*p.aspect/(root3*n));
   float2 basis=float2(1,root3);
   float2 pos=rot3(v,.16f*sin(2*PI3*u))/pitch;
   float2 a=floor(pos/basis+.5f)*basis;
   float2 b=(floor(pos/basis)*basis)+basis*.5f;
   float2 da=pos-a,db=pos-b;
   bool first=dot(da,da)<=dot(db,db);
   float2 cell=first ? a:b,local=first ? da:db;
   float q=creativeAxis42(.5f+cell.x*pitch/p.aspect,p.direction);
   // Three interleaved time phases give adjacent cells distinct exposures.
   float row=round(2*cell.y/root3),col=round(cell.x-.5f*row);
   float phase=frac((col-row)/3.f);
   float age=bounce3(clock-(1.4f*q+.34f*cell.y*pitch+1.1f*phase)*p.span);
   f.a=f.b=.04f+.93f*smoothstep(.16f,.84f,age);
   // The right and left faces meet their neighbours along the sloped hex edges.
   float halfWidth=min(.5f,max(.001f,1-root3*abs(local.y)));
   MAC_EDGE(f,.5f+.5f*local.x/halfWidth,2*halfWidth*pitch*size.y,1)
   break;
  }
  case 409:{
   float swing=.53f*sin(2*PI3*u);
   float2 axis=float2(cos(swing),sin(swing));
   float focal=.22f*min(p.aspect,1.0f);
   float2 focus=axis*focal;
   float farthest=max(length(max(center,1-center)*metric),.001f);
   float range=2*(farthest-focal)+.04f;
   float q=clamp((length(v-focus)+length(v+focus)-2*focal)/max(.02f,range),0.0f,1.0f);
   float band=creativeAxis42(q,p.direction)*n-.78f*p.cycles*u;
   float cell=floor(band);
   float t=bounce3(clock-p.span*cell/n);
   f.a=f.b=lerp(t,1-t,.8f*frac(cell*.5f)*2);
   MAC_TILED_EDGE(f,frac(band),range*.5f*size.y/n,1)
   break;
  }
  case 410:{
   float rows=min(3.0f,n);
   float2 shift=uv-center+.5f;
   float row=floor(shift.y*rows);
   float base=floor(n/rows);
   float cols=base+(clamp(row,0.0f,rows-1)<n-base*rows ? 1:0);
   float time=creativeAxis42(u,p.direction);
   float x=shift.x*cols-(.63f+.13f*row)*p.cycles*time+.36f*row;
   float col=floor(x);
   float2 local=float2(frac(x)-.5f,frac(shift.y*rows)-.5f);
   float2 roundBox=abs(local)-float2(.37f,.33f);
   float edge=length(max(roundBox,0.0f))+min(max(roundBox.x,roundBox.y),0.0f)-.075f;
   float aa=max(cols/size.x,rows/size.y)*1.1f;
   f.a=.2f+.64f*bounce3(clock+.7f);
   f.b=bounce3(clock-.41f*col-.29f*row)*p.span+.04f;
   f.weight=1-smoothstep(-aa,aa,edge);
   float corner=max(0.0f,abs(local.y)-.33f);
   float bound=.37f+sqrt(max(0.0f,.075f*.075f-corner*corner));
   MAC_EDGE(f,clamp(.5f+.5f*local.x/bound,0.0f,1.0f),2*bound*size.x/cols,f.weight)
   break;
  }
 }
 return f;
}
