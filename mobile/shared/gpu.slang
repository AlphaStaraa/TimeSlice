#include "field_common.h"
[[vk::binding(0,0)]] ConstantBuffer<TFParams> param;
[[vk::binding(1,0)]] StructuredBuffer<uint> cfg;
[[vk::binding(3,0)]] StructuredBuffer<float> timeMap;
[[vk::binding(5,0)]] RWStructuredBuffer<float4> diagnostics;

[numthreads(8,8,1)]
/* 批量输出时间场诊断值，供渲染和一致性检查使用。 */ void fields(uint3 id:SV_DispatchThreadID){
 if(id.x>=cfg[2]||id.y>=cfg[3])return;
 uint local=id.y*cfg[2]+id.x;
 float2 uv=(float2(id.xy+uint2(cfg[0],cfg[1]))+.5f)/float2(cfg[4],cfg[5]);
 Field f=evaluate3(uv,param,param.customMap!=0 ? timeMap[local]:0);
 diagnostics[local*2]=float4(adjusted3(f.a,param),adjusted3(f.b,param),clamp(f.weight,0.f,1.f),f.shade);
 diagnostics[local*2+1]=float4(f.light,0,0,0);
}
