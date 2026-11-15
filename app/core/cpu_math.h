#pragma once
#include <cmath>
#include <cstdint>
#include <algorithm>
using uint=uint32_t;
struct float2 {float x,y;/* 建立二维向量的分量。 */ float2(float a=0):x(a),y(a){} /* 建立二维向量的分量。 */ float2(float a,float b):x(a),y(b){} /* 对二维向量就地应用标量缩放。 */ float2& operator*=(float a){x*=a;y*=a;return *this;} };
#define OP(o) inline float2 operator o(float2 a,float2 b){return {a.x o b.x,a.y o b.y};}
OP(+) OP(-) OP(*) OP(/)
#undef OP
inline float2 operator-(float2 a){return {-a.x,-a.y};}
// 引入浮点绝对值重载，避免坐标被隐式转换为整数。
using std::abs;
inline float2 abs(float2 a){return {abs(a.x),abs(a.y)};}
inline float min(float a,float b){return std::min(a,b);} inline float max(float a,float b){return std::max(a,b);}
inline uint min(uint a,uint b){return std::min(a,b);} inline uint max(uint a,uint b){return std::max(a,b);}
inline float2 min(float2 a,float2 b){return {min(a.x,b.x),min(a.y,b.y)};} inline float2 max(float2 a,float2 b){return {max(a.x,b.x),max(a.y,b.y)};}
inline float clamp(float a,float l,float h){return min(max(a,l),h);} inline uint clamp(uint a,uint l,uint h){return min(max(a,l),h);}
inline float frac(float a){return a-std::floor(a);} inline float2 frac(float2 a){return {frac(a.x),frac(a.y)};}
inline float2 floor(float2 a){return {std::floor(a.x),std::floor(a.y)};}
inline float lerp(float a,float b,float t){return a+(b-a)*t;}
inline float dot(float2 a,float2 b){return a.x*b.x+a.y*b.y;} inline float length(float2 a){return std::sqrt(dot(a,a));}
inline float smoothstep(float a,float b,float t){float x=clamp((t-a)/(b-a),0.f,1.f);return x*x*(3-2*x);}
