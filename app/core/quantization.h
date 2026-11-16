#ifndef TIMESLICE_QUANTIZATION_105
#define TIMESLICE_QUANTIZATION_105

/* 固定8×8有序抖动，均值为零、幅度小于半个8位色阶，不产生逐帧随机闪烁。 */
float gradientOffset105(uint x,uint y){
 uint rank=(((x^y)&1u)<<5)|((y&1u)<<4)|((((x>>1)^(y>>1))&1u)<<3)|(((y>>1)&1u)<<2)|((((x>>2)^(y>>2))&1u)<<1)|((y>>2)&1u);
 return (float(rank)+.5f)/64.f-.5f;
}

/* 只在导出显式开启时保留亚色阶的平均亮度，兼容原有诊断与标准帧。 */
float quantizeColor105(float value,uint x,uint y,uint flags){
 float noise=(flags&4096u)!=0 ? gradientOffset105(x,y):0.f;
 return round(clamp(value,0.f,1.f)*255.f+noise);
}
#endif
