@binding(1) @group(0) var<storage, read> cfg_0 : array<u32>;

struct TFParams_std140_0
{
    @align(16) outTime_0 : f32,
    @align(4) u_0 : f32,
    @align(8) sourceDuration_0 : f32,
    @align(4) aspect_0 : f32,
    @align(16) slices_0 : f32,
    @align(4) pixel_0 : f32,
    @align(8) span_0 : f32,
    @align(4) cycles_0 : f32,
    @align(16) cx_0 : f32,
    @align(4) cy_0 : f32,
    @align(8) angle_0 : f32,
    @align(4) turns_0 : f32,
    @align(16) build_0 : f32,
    @align(4) softness_0 : f32,
    @align(8) density_0 : f32,
    @align(4) sourceReverse_0 : f32,
    @align(16) sourceStart_0 : f32,
    @align(4) sourceEnd_0 : f32,
    @align(8) outputW_0 : f32,
    @align(4) outputH_0 : f32,
    @align(16) family_0 : u32,
    @align(4) shape_0 : u32,
    @align(8) design_0 : u32,
    @align(4) ending_0 : u32,
    @align(16) direction_0 : u32,
    @align(4) playback_0 : u32,
    @align(8) origin_0 : u32,
    @align(4) viewMode_0 : u32,
    @align(16) frames_0 : u32,
    @align(4) customMap_0 : u32,
    @align(8) waveSources_0 : u32,
    @align(4) flags_0 : u32,
    @align(16) shadowStrength_0 : f32,
    @align(4) shadowWidth_0 : f32,
    @align(8) shadowSoftness_0 : f32,
    @align(4) shadowSide_0 : f32,
    @align(16) sampleW_0 : f32,
    @align(4) sampleH_0 : f32,
    @align(8) reserved0_0 : f32,
    @align(4) reserved1_0 : f32,
};

@binding(0) @group(0) var<uniform> param_0 : TFParams_std140_0;
@binding(2) @group(0) var<storage, read> source_0 : array<u32>;

@binding(6) @group(0) var<storage, read> gradeData_0 : array<f32>;

@binding(3) @group(0) var<storage, read> timeMap_0 : array<f32>;

@binding(4) @group(0) var<storage, read_write> output_0 : array<u32>;

struct TFParams_0
{
     outTime_0 : f32,
     u_0 : f32,
     sourceDuration_0 : f32,
     aspect_0 : f32,
     slices_0 : f32,
     pixel_0 : f32,
     span_0 : f32,
     cycles_0 : f32,
     cx_0 : f32,
     cy_0 : f32,
     angle_0 : f32,
     turns_0 : f32,
     build_0 : f32,
     softness_0 : f32,
     density_0 : f32,
     sourceReverse_0 : f32,
     sourceStart_0 : f32,
     sourceEnd_0 : f32,
     outputW_0 : f32,
     outputH_0 : f32,
     family_0 : u32,
     shape_0 : u32,
     design_0 : u32,
     ending_0 : u32,
     direction_0 : u32,
     playback_0 : u32,
     origin_0 : u32,
     viewMode_0 : u32,
     frames_0 : u32,
     customMap_0 : u32,
     waveSources_0 : u32,
     flags_0 : u32,
     shadowStrength_0 : f32,
     shadowWidth_0 : f32,
     shadowSoftness_0 : f32,
     shadowSide_0 : f32,
     sampleW_0 : f32,
     sampleH_0 : f32,
     reserved0_0 : f32,
     reserved1_0 : f32,
};

fn adjusted3_0( n_0 : f32,  p_0 : TFParams_0) -> f32
{
    var _S1 : f32 = clamp(n_0, 0.0f, 1.0f);
    var _S2 : f32;
    if(((p_0.sourceReverse_0) > 0.0f))
    {
        _S2 = 1.0f - _S1;
    }
    else
    {
        _S2 = _S1;
    }
    return mix(p_0.sourceStart_0, p_0.sourceEnd_0, _S2);
}

fn unpack_0( v_0 : u32) -> vec4<f32>
{
    return vec4<f32>(f32((v_0 & (u32(255)))), f32((((v_0 >> (u32(8)))) & (u32(255)))), f32((((v_0 >> (u32(16)))) & (u32(255)))), f32((((v_0 >> (u32(24)))) & (u32(255))))) / vec4<f32>(255.0f);
}

struct Color53_0
{
     r_0 : f32,
     g_0 : f32,
     b_0 : f32,
};

fn color53_0( r_1 : f32,  g_1 : f32,  b_1 : f32) -> Color53_0
{
    var c_0 : Color53_0;
    c_0.r_0 = r_1;
    c_0.g_0 = g_1;
    c_0.b_0 = b_1;
    return c_0;
}

fn linear53_0( c_1 : f32) -> f32
{
    var _S3 : f32;
    if((c_1 <= 0.040449999272823334f))
    {
        _S3 = c_1 / 12.920000076293945f;
    }
    else
    {
        _S3 = pow((c_1 + 0.054999999701976776f) / 1.0549999475479126f, 2.4000000953674316f);
    }
    return _S3;
}

fn srgb53_0( c_2 : f32) -> f32
{
    var _S4 : f32 = max(c_2, 0.0f);
    var _S5 : f32;
    if((_S4 <= 0.0031308000907301903f))
    {
        _S5 = 12.920000076293945f * _S4;
    }
    else
    {
        _S5 = 1.0549999475479126f * pow(_S4, 0.4166666567325592f) - 0.054999999701976776f;
    }
    return _S5;
}

fn hue53_0( p_1 : f32,  q_0 : f32,  t_0 : f32) -> f32
{
    var _S6 : f32 = fract(t_0);
    if((_S6 < 0.1666666716337204f))
    {
        return p_1 + (q_0 - p_1) * 6.0f * _S6;
    }
    if((_S6 < 0.5f))
    {
        return q_0;
    }
    if((_S6 < 0.66666668653488159f))
    {
        return p_1 + (q_0 - p_1) * (0.66666668653488159f - _S6) * 6.0f;
    }
    return p_1;
}

fn grade53_0( rgb_0 : Color53_0,  frame_0 : i32) -> Color53_0
{
    if((gradeData_0[i32(0)] < 0.5f))
    {
        return rgb_0;
    }
    var count_0 : i32 = i32(gradeData_0[i32(1)]);
    var t_1 : f32 = gradeData_0[i32(16.0f + min(f32(frame_0), f32(count_0 - i32(1))))];
    var temperature_0 : f32 = mix(gradeData_0[i32(2)], gradeData_0[i32(7)], t_1);
    var tint_0 : f32 = mix(gradeData_0[i32(3)], gradeData_0[i32(8)], t_1);
    var sat_0 : f32 = mix(gradeData_0[i32(4)], gradeData_0[i32(9)], t_1);
    var _S7 : f32 = tint_0 * 0.0020000000949949026f;
    var gr_0 : f32 = exp2(temperature_0 * 0.0060000000521540642f + _S7);
    var gg_0 : f32 = exp2(- tint_0 * 0.0040000001899898052f);
    var gb_0 : f32 = exp2(- temperature_0 * 0.0060000000521540642f + _S7);
    var norm_0 : f32 = gr_0 * 0.2125999927520752f + gg_0 * 0.71520000696182251f + gb_0 * 0.072200000286102295f;
    var r_2 : f32 = linear53_0(rgb_0.r_0) * (gr_0 / norm_0);
    var g_2 : f32 = linear53_0(rgb_0.g_0) * (gg_0 / norm_0);
    var b_2 : f32 = linear53_0(rgb_0.b_0) * (gb_0 / norm_0);
    var scale_0 : f32 = pow(max(9.9999997473787516e-05f, r_2 * 0.2125999927520752f + g_2 * 0.71520000696182251f + b_2 * 0.072200000286102295f) / 0.18000000715255737f, mix(gradeData_0[i32(6)], gradeData_0[i32(11)], t_1) - 1.0f);
    var r_3 : f32 = r_2 * scale_0;
    var g_3 : f32 = g_2 * scale_0;
    var b_3 : f32 = b_2 * scale_0;
    var y_0 : f32 = r_3 * 0.2125999927520752f + g_3 * 0.71520000696182251f + b_3 * 0.072200000286102295f;
    var _S8 : f32 = exp2(mix(gradeData_0[i32(5)], gradeData_0[i32(10)], t_1));
    var r_4 : f32 = (y_0 + sat_0 * (r_3 - y_0)) * _S8;
    var g_4 : f32 = (y_0 + sat_0 * (g_3 - y_0)) * _S8;
    var b_4 : f32 = (y_0 + sat_0 * (b_3 - y_0)) * _S8;
    var _S9 : f32 = max(1.0f, max(r_4, max(g_4, b_4)));
    var r_5 : f32 = clamp(srgb53_0(r_4 / _S9), 0.0f, 1.0f);
    var g_5 : f32 = clamp(srgb53_0(g_4 / _S9), 0.0f, 1.0f);
    var b_5 : f32 = clamp(srgb53_0(b_4 / _S9), 0.0f, 1.0f);
    var r_6 : f32;
    var g_6 : f32;
    var b_6 : f32;
    if((gradeData_0[i32(12)] > 0.5f))
    {
        var _S10 : f32 = max(r_5, max(g_5, b_5));
        var _S11 : f32 = min(r_5, min(g_5, b_5));
        var d_0 : f32 = _S10 - _S11;
        var l_0 : f32 = (_S10 + _S11) * 0.5f;
        if((d_0 > 1.00000001168609742e-07f))
        {
            var saturation_0 : f32 = d_0 / max(1.00000001168609742e-07f, 1.0f - abs(2.0f * l_0 - 1.0f));
            if(_S10 == r_5)
            {
                r_6 = (g_5 - b_5) / d_0;
            }
            else
            {
                if(_S10 == g_5)
                {
                    r_6 = (b_5 - r_5) / d_0 + 2.0f;
                }
                else
                {
                    r_6 = (r_5 - g_5) / d_0 + 4.0f;
                }
            }
            var h_0 : f32 = fract(r_6 / 6.0f);
            var position_0 : f32 = h_0 * 1024.0f;
            var i_0 : i32 = i32(floor(position_0));
            var f_0 : f32 = fract(position_0);
            var offset_0 : i32 = i32(16) + count_0;
            var a_0 : i32 = offset_0 + i_0 % i32(1024) * i32(3);
            var bb_0 : i32 = offset_0 + (i_0 + i32(1)) % i32(1024) * i32(3);
            var chroma_0 : f32 = clamp(saturation_0 / 0.11999999731779099f, 0.0f, 1.0f);
            var h_1 : f32 = fract(h_0 + mix(gradeData_0[a_0], gradeData_0[bb_0], f_0) * chroma_0 / 360.0f);
            var saturation_1 : f32 = clamp(saturation_0 * (1.0f + mix(gradeData_0[a_0 + i32(1)], gradeData_0[bb_0 + i32(1)], f_0) * chroma_0), 0.0f, 1.0f);
            var dl_0 : f32 = mix(gradeData_0[a_0 + i32(2)], gradeData_0[bb_0 + i32(2)], f_0) * chroma_0;
            if((dl_0 >= 0.0f))
            {
                r_6 = (1.0f - l_0) * dl_0;
            }
            else
            {
                r_6 = l_0 * dl_0;
            }
            var l_1 : f32 = l_0 + r_6;
            if((l_1 < 0.5f))
            {
                r_6 = l_1 * (1.0f + saturation_1);
            }
            else
            {
                r_6 = l_1 + saturation_1 - l_1 * saturation_1;
            }
            var p_2 : f32 = 2.0f * l_1 - r_6;
            var _S12 : f32 = hue53_0(p_2, r_6, h_1);
            var _S13 : f32 = hue53_0(p_2, r_6, h_1 - 0.3333333432674408f);
            r_6 = hue53_0(p_2, r_6, h_1 + 0.3333333432674408f);
            g_6 = _S12;
            b_6 = _S13;
        }
        else
        {
            r_6 = r_5;
            g_6 = g_5;
            b_6 = b_5;
        }
    }
    else
    {
        r_6 = r_5;
        g_6 = g_5;
        b_6 = b_5;
    }
    return color53_0(r_6, g_6, b_6);
}

fn sourceFrame53_0( frame_1 : u32,  pixel_1 : u32,  p_3 : TFParams_0) -> vec4<f32>
{
    var c_3 : vec4<f32>;
    if((((p_3.flags_0) & (u32(64)))) != u32(0))
    {
        var _S14 : u32 = pixel_1 % cfg_0[i32(2)];
        var x_0 : u32 = _S14 + cfg_0[i32(0)];
        var _S15 : u32 = pixel_1 / cfg_0[i32(2)];
        var _S16 : vec2<f32> = vec2<f32>(0.5f);
        var point_0 : vec2<f32> = clamp((vec2<f32>(f32(x_0), f32(_S15 + cfg_0[i32(1)])) + _S16) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)])) * vec2<f32>(f32(cfg_0[i32(10)]), f32(cfg_0[i32(11)])) - _S16, vec2<f32>(0.0f), vec2<f32>(f32(cfg_0[i32(10)] - u32(1)), f32(cfg_0[i32(11)] - u32(1))));
        var _S17 : vec2<u32> = vec2<u32>(floor(point_0));
        var _S18 : vec2<u32> = min(_S17 + vec2<u32>(u32(1)), vec2<u32>(cfg_0[i32(10)] - u32(1), cfg_0[i32(11)] - u32(1)));
        var t_2 : vec2<f32> = fract(point_0);
        var base_0 : u32 = frame_1 * cfg_0[i32(14)] * cfg_0[i32(15)];
        var xa_0 : u32 = _S17.x - cfg_0[i32(12)];
        var xb_0 : u32 = _S18.x - cfg_0[i32(12)];
        var ya_0 : u32 = _S17.y - cfg_0[i32(13)];
        var yb_0 : u32 = _S18.y - cfg_0[i32(13)];
        var _S19 : vec4<f32> = vec4<f32>(t_2.x);
        c_3 = mix(mix(unpack_0(source_0[base_0 + ya_0 * cfg_0[i32(14)] + xa_0]), unpack_0(source_0[base_0 + ya_0 * cfg_0[i32(14)] + xb_0]), _S19), mix(unpack_0(source_0[base_0 + yb_0 * cfg_0[i32(14)] + xa_0]), unpack_0(source_0[base_0 + yb_0 * cfg_0[i32(14)] + xb_0]), _S19), vec4<f32>(t_2.y));
    }
    else
    {
        c_3 = unpack_0(source_0[frame_1 * cfg_0[i32(2)] * cfg_0[i32(3)] + pixel_1]);
    }
    if((((p_3.flags_0) & (u32(128)))) != u32(0))
    {
        var rgb_1 : Color53_0 = grade53_0(color53_0(c_3.x, c_3.y, c_3.z), i32(frame_1));
        c_3 = vec4<f32>(rgb_1.r_0, rgb_1.g_0, rgb_1.b_0, 1.0f);
    }
    return c_3;
}

fn sampleSource_0( n_1 : f32,  pixel_2 : u32,  p_4 : TFParams_0) -> vec4<f32>
{
    var f_1 : f32 = clamp(adjusted3_0(n_1, p_4) * p_4.sourceDuration_0, 0.0f, f32(cfg_0[i32(6)] - u32(1)));
    var a_1 : u32 = u32(floor(f_1));
    var _S20 : u32 = min(a_1 + u32(1), cfg_0[i32(6)] - u32(1));
    var _S21 : vec4<f32> = sourceFrame53_0(a_1, pixel_2, p_4);
    var _S22 : vec4<f32> = sourceFrame53_0(_S20, pixel_2, p_4);
    return mix(_S21, _S22, vec4<f32>((f_1 - f32(a_1))));
}

fn filteredFreeze52_0( p_5 : TFParams_0) -> bool
{
    var _S23 : bool;
    if((p_5.family_0) != u32(0))
    {
        _S23 = true;
    }
    else
    {
        _S23 = (p_5.customMap_0) != u32(0);
    }
    if(_S23)
    {
        _S23 = true;
    }
    else
    {
        _S23 = ((p_5.pixel_0) > 0.0f);
    }
    if(_S23)
    {
        _S23 = true;
    }
    else
    {
        if((p_5.shape_0) != u32(0))
        {
            _S23 = (p_5.shape_0) != u32(1);
        }
        else
        {
            _S23 = false;
        }
        if(_S23)
        {
            _S23 = (p_5.shape_0) != u32(2);
        }
        else
        {
            _S23 = false;
        }
    }
    if(_S23)
    {
        return false;
    }
    if((p_5.shape_0) != u32(2))
    {
        _S23 = ((p_5.direction_0) < u32(2));
    }
    else
    {
        _S23 = false;
    }
    if(_S23)
    {
        _S23 = (p_5.outputW_0) == (p_5.sampleW_0);
    }
    else
    {
        _S23 = false;
    }
    if(_S23)
    {
        _S23 = (p_5.outputH_0) == (p_5.sampleH_0);
    }
    else
    {
        _S23 = false;
    }
    if(_S23)
    {
        var _S24 : f32;
        if((p_5.shape_0) == u32(1))
        {
            _S24 = p_5.sampleH_0;
        }
        else
        {
            _S24 = p_5.sampleW_0;
        }
        var pitch_0 : f32 = _S24 / max(2.0f, p_5.slices_0);
        if(((abs(pitch_0 - round(pitch_0))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    return true;
}

fn stripeGradient52_0( p_6 : TFParams_0) -> vec2<f32>
{
    if((p_6.shape_0) == u32(0))
    {
        return vec2<f32>(1.0f, 0.0f);
    }
    if((p_6.shape_0) == u32(1))
    {
        return vec2<f32>(0.0f, 1.0f);
    }
    var a_2 : f32 = p_6.angle_0 * 3.1415927410125732f / 180.0f;
    var _S25 : f32 = cos(a_2);
    var _S26 : f32 = sin(a_2);
    return vec2<f32>(p_6.outputW_0, p_6.outputH_0) * vec2<f32>(_S25, _S26) / vec2<f32>(max(1.0f, abs(p_6.outputW_0 * _S25) + abs(p_6.outputH_0 * _S26)));
}

fn stripeAxis52_0( uv_0 : vec2<f32>,  p_7 : TFParams_0) -> f32
{
    var gradient_0 : vec2<f32> = stripeGradient52_0(p_7);
    return clamp(dot(uv_0, gradient_0) - min(0.0f, gradient_0.x) - min(0.0f, gradient_0.y), 0.0f, 1.0f);
}

fn tentArea52_0( x_1 : f32) -> f32
{
    var _S27 : f32 = clamp(x_1, -1.0f, 1.0f);
    var _S28 : f32;
    if((_S27 <= 0.0f))
    {
        var _S29 : f32 = _S27 + 1.0f;
        _S28 = 0.5f * _S29 * _S29;
    }
    else
    {
        var _S30 : f32 = 1.0f - _S27;
        _S28 = 1.0f - 0.5f * _S30 * _S30;
    }
    return _S28;
}

struct StripeFootprint52_0
{
     first_0 : f32,
     last_0 : f32,
     low_0 : f32,
     high_0 : f32,
     center_0 : f32,
     step_0 : f32,
     count_1 : f32,
     normalization_0 : f32,
};

fn stripeFootprint52_0( uv_1 : vec2<f32>,  p_8 : TFParams_0) -> StripeFootprint52_0
{
    var gradient_1 : vec2<f32> = abs(stripeGradient52_0(p_8));
    var pixelStep_0 : f32 = gradient_1.x / p_8.sampleW_0 + gradient_1.y / p_8.sampleH_0;
    var f_2 : StripeFootprint52_0;
    var _S31 : f32 = max(2.0f, p_8.slices_0);
    var _S32 : f32;
    if(((p_8.direction_0) >= u32(2)))
    {
        _S32 = 2.0f;
    }
    else
    {
        _S32 = 1.0f;
    }
    var _S33 : f32 = _S31 * _S32;
    f_2.count_1 = _S33;
    var _S34 : f32 = stripeAxis52_0(uv_1, p_8) * _S33;
    f_2.center_0 = _S34;
    var _S35 : f32 = _S33 * pixelStep_0;
    f_2.step_0 = _S35;
    var _S36 : f32 = max(0.0f, _S34 - _S35);
    f_2.low_0 = _S36;
    var _S37 : f32 = min(_S33, _S34 + _S35);
    f_2.high_0 = _S37;
    f_2.first_0 = floor(_S36);
    f_2.last_0 = min(_S33 - 1.0f, ceil(_S37) - 1.0f);
    f_2.normalization_0 = max(9.99999993922529029e-09f, tentArea52_0((_S37 - _S34) / _S35) - tentArea52_0((_S36 - _S34) / _S35));
    return f_2;
}

fn stripeWeight52_0( low_1 : f32,  high_1 : f32,  f_3 : StripeFootprint52_0) -> f32
{
    return max(0.0f, tentArea52_0((high_1 - f_3.center_0) / f_3.step_0) - tentArea52_0((low_1 - f_3.center_0) / f_3.step_0));
}

fn bounce3_0( x_2 : f32) -> f32
{
    return 1.0f - abs(2.0f * fract(x_2 * 0.5f) - 1.0f);
}

struct Field_0
{
     a_3 : f32,
     b_7 : f32,
     weight_0 : f32,
     shade_0 : f32,
     uvA_0 : vec2<f32>,
     uvB_0 : vec2<f32>,
     light_0 : f32,
};

fn single3_0( uv_2 : vec2<f32>,  t_3 : f32) -> Field_0
{
    var f_4 : Field_0;
    f_4.a_3 = t_3;
    f_4.b_7 = t_3;
    f_4.weight_0 = 0.0f;
    f_4.shade_0 = 1.0f;
    f_4.uvA_0 = uv_2;
    f_4.uvB_0 = uv_2;
    f_4.light_0 = 1.0f;
    return f_4;
}

fn creativeAxis42_0( q_1 : f32,  direction_1 : u32) -> f32
{
    if(direction_1 == u32(1))
    {
        return 1.0f - q_1;
    }
    if((direction_1 >= u32(2)))
    {
        var _S38 : f32 = abs(q_1 - 0.5f) * 2.0f;
        var _S39 : f32;
        if(direction_1 == u32(3))
        {
            _S39 = 1.0f - _S38;
        }
        else
        {
            _S39 = _S38;
        }
        return _S39;
    }
    return q_1;
}

fn shadowArea42_0( distance_0 : f32,  solid_0 : f32,  feather_0 : f32) -> f32
{
    var _S40 : f32 = max(0.0f, distance_0);
    var t_4 : f32 = clamp((_S40 - solid_0) / feather_0, 0.0f, 1.0f);
    return min(_S40, solid_0) + feather_0 * t_4 * (1.0f - t_4 * t_4 * (1.0f - 0.5f * t_4));
}

fn repeatedShadowArea42_0( distance_1 : f32,  solid_1 : f32,  feather_1 : f32) -> f32
{
    return floor(distance_1) * (solid_1 + 0.5f * feather_1) + shadowArea42_0(fract(distance_1), solid_1, feather_1);
}

fn filteredLight42_0( distance_2 : f32,  span_1 : f32,  coverage_0 : f32,  filterWidth_0 : f32,  repeat_0 : bool,  p_9 : TFParams_0) -> f32
{
    var _S41 : bool;
    if((span_1 <= 1.0f))
    {
        _S41 = true;
    }
    else
    {
        _S41 = (coverage_0 <= 0.0f);
    }
    if(_S41)
    {
        return 1.0f;
    }
    var _S42 : f32 = min(0.77999997138977051f, max(p_9.shadowWidth_0, 1.5f / span_1));
    var halfPixel_0 : f32 = 0.5f * filterWidth_0 / span_1;
    if((distance_2 > (_S42 + halfPixel_0)))
    {
        if(!repeat_0)
        {
            _S41 = true;
        }
        else
        {
            _S41 = (distance_2 < (1.0f - halfPixel_0));
        }
    }
    else
    {
        _S41 = false;
    }
    if(_S41)
    {
        return 1.0f;
    }
    var feather_2 : f32 = _S42 * max(0.02500000037252903f, p_9.shadowSoftness_0);
    var solid_2 : f32 = _S42 - feather_2;
    var lo_0 : f32 = distance_2 - halfPixel_0;
    var hi_0 : f32 = distance_2 + halfPixel_0;
    var area_0 : f32;
    if(repeat_0)
    {
        area_0 = repeatedShadowArea42_0(hi_0, solid_2, feather_2) - repeatedShadowArea42_0(lo_0, solid_2, feather_2);
    }
    else
    {
        area_0 = shadowArea42_0(hi_0, solid_2, feather_2) - shadowArea42_0(lo_0, solid_2, feather_2);
    }
    return 1.0f - p_9.shadowStrength_0 * coverage_0 * (clamp(area_0 / (2.0f * halfPixel_0), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, span_1));
}

fn tiledLight42_0( phase_0 : f32,  span_2 : f32,  coverage_1 : f32,  p_10 : TFParams_0) -> f32
{
    var _S43 : f32;
    if(((p_10.shadowSide_0) > 0.0f))
    {
        _S43 = phase_0;
    }
    else
    {
        _S43 = 1.0f - phase_0;
    }
    return filteredLight42_0(_S43, span_2, coverage_1, 1.2999999523162842f, true, p_10);
}

fn rot3_0( v_1 : vec2<f32>,  a_4 : f32) -> vec2<f32>
{
    var _S44 : f32 = cos(a_4);
    var _S45 : f32 = v_1.x;
    var _S46 : f32 = sin(a_4);
    var _S47 : f32 = v_1.y;
    return vec2<f32>(_S44 * _S45 + _S46 * _S47, - _S46 * _S45 + _S44 * _S47);
}

fn edgeLight42_0( phase_1 : f32,  span_3 : f32,  coverage_2 : f32,  p_11 : TFParams_0) -> f32
{
    var _S48 : f32;
    if(((p_11.shadowSide_0) > 0.0f))
    {
        _S48 = phase_1;
    }
    else
    {
        _S48 = 1.0f - phase_1;
    }
    return filteredLight42_0(_S48, span_3, coverage_2, 1.0f, false, p_11);
}

fn creative42_0( uv_3 : vec2<f32>,  p_12 : TFParams_0) -> Field_0
{
    var center_1 : vec2<f32> = vec2<f32>(p_12.cx_0, p_12.cy_0);
    var metric_0 : vec2<f32> = vec2<f32>(p_12.aspect_0, 1.0f);
    var _S49 : vec2<f32> = uv_3 - center_1;
    var v_2 : vec2<f32> = _S49 * metric_0;
    var clock_0 : f32 = 2.0f * p_12.cycles_0 * p_12.u_0;
    var _S50 : f32 = max(2.0f, p_12.slices_0);
    var f_5 : Field_0 = single3_0(uv_3, bounce3_0(clock_0 + 1.0f));
    switch(p_12.design_0)
    {
    case u32(407):
        {
            var y_1 : f32 = uv_3.y - p_12.cy_0;
            var band_0 : f32 = (creativeAxis42_0(uv_3.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_1 + 0.34999999403953552f * p_12.u_0)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_1 - 0.69999998807907104f * p_12.u_0))), p_12.direction_0) - 0.51999998092651367f * p_12.cycles_0 * p_12.u_0) * _S50;
            var cell_0 : f32 = floor(band_0);
            var t_5 : f32 = bounce3_0(clock_0 - 0.75f * cell_0 / _S50);
            var _S51 : f32 = mix(t_5, 1.0f - t_5, fract(cell_0 * 0.5f) * 2.0f * p_12.span_0);
            f_5.b_7 = _S51;
            f_5.a_3 = _S51;
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_0(fract(band_0), p_12.sampleW_0 / _S50, 1.0f, p_12);
            }
        }
    case u32(408):
        {
            var pitch_1 : f32 = sqrt(2.0f * p_12.aspect_0 / (1.7320507764816284f * _S50));
            const basis_0 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_0 : vec2<f32> = rot3_0(v_2, 0.15999999642372131f * sin(6.2831854820251465f * p_12.u_0)) / vec2<f32>(pitch_1);
            var _S52 : vec2<f32> = vec2<f32>(0.5f);
            var a_5 : vec2<f32> = floor(pos_0 / basis_0 + _S52) * basis_0;
            var b_8 : vec2<f32> = floor(pos_0 / basis_0) * basis_0 + basis_0 * _S52;
            var da_0 : vec2<f32> = pos_0 - a_5;
            var db_0 : vec2<f32> = pos_0 - b_8;
            var first_1 : bool = ((dot(da_0, da_0)) <= (dot(db_0, db_0)));
            var cell_1 : vec2<f32>;
            if(first_1)
            {
                cell_1 = a_5;
            }
            else
            {
                cell_1 = b_8;
            }
            var local_0 : vec2<f32>;
            if(first_1)
            {
                local_0 = da_0;
            }
            else
            {
                local_0 = db_0;
            }
            var _S53 : f32 = cell_1.x;
            var _S54 : f32 = cell_1.y;
            var row_0 : f32 = round(2.0f * _S54 / 1.7320507764816284f);
            var _S55 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_0 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S53 * pitch_1 / p_12.aspect_0, p_12.direction_0) + 0.34000000357627869f * _S54 * pitch_1 + 1.1000000238418579f * fract((round(_S53 - 0.5f * row_0) - row_0) / 3.0f)) * p_12.span_0));
            f_5.b_7 = _S55;
            f_5.a_3 = _S55;
            var _S56 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_0.y)));
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_0(0.5f + 0.5f * local_0.x / _S56, 2.0f * _S56 * pitch_1 * p_12.sampleH_0, 1.0f, p_12);
            }
        }
    case u32(409):
        {
            var swing_0 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * p_12.u_0);
            var focal_0 : f32 = 0.2199999988079071f * min(p_12.aspect_0, 1.0f);
            var focus_0 : vec2<f32> = vec2<f32>(cos(swing_0), sin(swing_0)) * vec2<f32>(focal_0);
            var range_0 : f32 = 2.0f * (max(length(max(center_1, vec2<f32>(1.0f) - center_1) * metric_0), 0.0010000000474974513f) - focal_0) + 0.039999999105930328f;
            var band_1 : f32 = creativeAxis42_0(clamp((length(v_2 - focus_0) + length(v_2 + focus_0) - 2.0f * focal_0) / max(0.019999999552965164f, range_0), 0.0f, 1.0f), p_12.direction_0) * _S50 - 0.77999997138977051f * p_12.cycles_0 * p_12.u_0;
            var cell_2 : f32 = floor(band_1);
            var t_6 : f32 = bounce3_0(clock_0 - p_12.span_0 * cell_2 / _S50);
            var _S57 : f32 = mix(t_6, 1.0f - t_6, 0.80000001192092896f * fract(cell_2 * 0.5f) * 2.0f);
            f_5.b_7 = _S57;
            f_5.a_3 = _S57;
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_0(fract(band_1), range_0 * 0.5f * p_12.sampleH_0 / _S50, 1.0f, p_12);
            }
        }
    case u32(410):
        {
            var _S58 : f32 = min(3.0f, _S50);
            var shift_0 : vec2<f32> = _S49 + vec2<f32>(0.5f);
            var _S59 : f32 = shift_0.y * _S58;
            var row_1 : f32 = floor(_S59);
            var base_1 : f32 = floor(_S50 / _S58);
            var _S60 : i32;
            if(((clamp(row_1, 0.0f, _S58 - 1.0f)) < (_S50 - base_1 * _S58)))
            {
                _S60 = i32(1);
            }
            else
            {
                _S60 = i32(0);
            }
            var cols_0 : f32 = base_1 + f32(_S60);
            var x_3 : f32 = shift_0.x * cols_0 - (0.62999999523162842f + 0.12999999523162842f * row_1) * p_12.cycles_0 * creativeAxis42_0(p_12.u_0, p_12.direction_0) + 0.36000001430511475f * row_1;
            var col_0 : f32 = floor(x_3);
            var _S61 : f32 = fract(x_3) - 0.5f;
            var _S62 : f32 = fract(_S59) - 0.5f;
            var roundBox_0 : vec2<f32> = abs(vec2<f32>(_S61, _S62)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_0 : f32 = length(max(roundBox_0, vec2<f32>(0.0f))) + min(max(roundBox_0.x, roundBox_0.y), 0.0f) - 0.075000002980232239f;
            var aa_0 : f32 = max(cols_0 / p_12.sampleW_0, _S58 / p_12.sampleH_0) * 1.1000000238418579f;
            f_5.a_3 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_0 + 0.69999998807907104f);
            f_5.b_7 = bounce3_0(clock_0 - 0.40999999642372131f * col_0 - 0.28999999165534973f * row_1) * p_12.span_0 + 0.039999999105930328f;
            f_5.weight_0 = 1.0f - smoothstep(- aa_0, aa_0, edge_0);
            var _S63 : f32 = max(0.0f, abs(_S62) - 0.33000001311302185f);
            var bound_0 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S63 * _S63));
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * _S61 / bound_0, 0.0f, 1.0f), 2.0f * bound_0 * p_12.sampleW_0 / cols_0, f_5.weight_0, p_12);
            }
        }
    default :
        {
        }
    }
    return f_5;
}

fn axisAngle3_0( y_2 : f32,  x_4 : f32) -> f32
{
    var _S64 : f32 = abs(x_4);
    var _S65 : f32 = abs(y_2);
    if(((_S64 + _S65) < 9.99999997475242708e-07f))
    {
        return 0.0f;
    }
    var _S66 : f32;
    if((_S65 < 9.99999997475242708e-07f))
    {
        if((x_4 < 0.0f))
        {
            _S66 = 3.1415927410125732f;
        }
        else
        {
            _S66 = 0.0f;
        }
        return _S66;
    }
    if((_S64 < 9.99999997475242708e-07f))
    {
        if((y_2 > 0.0f))
        {
            _S66 = 1.5707963705062866f;
        }
        else
        {
            _S66 = -1.5707963705062866f;
        }
        return _S66;
    }
    return atan2(y_2, x_4);
}

fn gridSize3_0( n_2 : f32,  size_0 : vec2<f32>) -> vec2<f32>
{
    var _S67 : f32 = size_0.y;
    var rows_0 : f32 = clamp(round(sqrt(n_2 * _S67 / size_0.x)), 1.0f, min(_S67, n_2));
    return vec2<f32>(floor(n_2 / rows_0), rows_0);
}

fn isStripe42_0( p_13 : TFParams_0) -> bool
{
    var _S68 : bool;
    if((p_13.customMap_0) == u32(0))
    {
        _S68 = ((p_13.direction_0) < u32(2));
    }
    else
    {
        _S68 = false;
    }
    if(_S68)
    {
        if((p_13.shape_0) == u32(0))
        {
            _S68 = true;
        }
        else
        {
            _S68 = (p_13.shape_0) == u32(1);
        }
        if(_S68)
        {
            _S68 = true;
        }
        else
        {
            _S68 = (p_13.shape_0) == u32(11);
        }
    }
    else
    {
        _S68 = false;
    }
    return _S68;
}

fn rasterStripeIndex42_0( pixel_3 : f32,  lengthPx_0 : f32,  count_2 : f32) -> f32
{
    if(((max(lengthPx_0, count_2)) <= 32768.0f))
    {
        var index_0 : u32 = (u32(2) * u32(pixel_3) + u32(1)) * u32(count_2) / (u32(2) * u32(lengthPx_0));
        return min(f32(index_0), count_2 - 1.0f);
    }
    return min(floor((pixel_3 + 0.5f) * count_2 / lengthPx_0), count_2 - 1.0f);
}

struct Coord_0
{
     raw_0 : f32,
     q_2 : f32,
     index_1 : f32,
     coverage_3 : f32,
     cell_3 : vec2<f32>,
     frac_0 : vec2<f32>,
};

fn coordinate3_0( uv_4 : vec2<f32>,  p_14 : TFParams_0,  mapValue_0 : f32) -> Coord_0
{
    var c_4 : Coord_0;
    var _S69 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_4.cell_3 = _S69;
    c_4.frac_0 = _S69;
    c_4.index_1 = 0.0f;
    c_4.coverage_3 = 1.0f;
    var _S70 : f32 = uv_4.x;
    var _S71 : f32 = max(2.0f, p_14.slices_0);
    var dim_0 : vec2<f32> = vec2<f32>(p_14.outputW_0, p_14.outputH_0);
    var _S72 : vec2<f32> = vec2<f32>(p_14.cx_0, p_14.cy_0);
    var v_3 : vec2<f32> = (uv_4 - _S72) * dim_0;
    var _S73 : vec2<f32> = vec2<f32>(1.0f);
    var radii_0 : vec2<f32> = max(_S72, _S73 - _S72) * dim_0;
    var _S74 : f32 = max(length(radii_0), 1.0f);
    var rmin_0 : f32 = length(max(_S69, max((vec2<f32>(0) - _S72), _S72 - _S73)) * dim_0);
    var q_3 : f32;
    var lengthPx_1 : f32;
    var _S75 : i32;
    var _S76 : bool;
    switch(p_14.shape_0)
    {
    case u32(0):
        {
            q_3 = _S70;
        }
    case u32(1):
        {
            q_3 = uv_4.y;
        }
    case u32(2), u32(12):
        {
            var a_6 : f32 = p_14.angle_0 * 3.1415927410125732f / 180.0f;
            var _S77 : f32 = cos(a_6);
            var _S78 : f32 = sin(a_6);
            var _S79 : f32 = p_14.outputW_0 * _S77;
            var _S80 : f32 = p_14.outputH_0 * _S78;
            var q_4 : f32 = (dot(uv_4 * dim_0, vec2<f32>(_S77, _S78)) - (min(0.0f, _S79) + min(0.0f, _S80))) / max(1.0f, abs(_S79) + abs(_S80));
            if((p_14.shape_0) == u32(12))
            {
                q_3 = q_4 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(uv_4.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_3 = q_4;
            }
        }
    case u32(3):
        {
            switch(p_14.origin_0)
            {
            case u32(1):
                {
                    q_3 = axisAngle3_0(v_3.y, v_3.x);
                }
            case u32(2):
                {
                    q_3 = axisAngle3_0(v_3.x, - v_3.y);
                }
            case u32(3):
                {
                    q_3 = axisAngle3_0(- v_3.x, v_3.y);
                }
            default :
                {
                    q_3 = axisAngle3_0(- v_3.y, - v_3.x);
                }
            }
            if((q_3 >= 0.0f))
            {
                _S76 = (q_3 <= 3.1415927410125732f);
            }
            else
            {
                _S76 = false;
            }
            if(_S76)
            {
                _S75 = i32(1);
            }
            else
            {
                _S75 = i32(0);
            }
            c_4.coverage_3 = f32(_S75);
            q_3 = clamp(q_3 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            var startAngle_0 : f32 = p_14.angle_0 / 360.0f;
            var _S81 : f32 = v_3.x;
            var _S82 : f32 = v_3.y;
            var _S83 : f32 = axisAngle3_0(_S81, - _S82);
            var _S84 : f32 = abs(_S81);
            var _S85 : f32 = abs(_S82);
            if(((_S84 + _S85) < 9.99999997475242708e-07f))
            {
                q_3 = 0.0f;
            }
            else
            {
                if((_S85 < 9.99999997475242708e-07f))
                {
                    if((_S81 > 0.0f))
                    {
                        q_3 = 1.5707963705062866f;
                    }
                    else
                    {
                        q_3 = -1.5707963705062866f;
                    }
                }
                else
                {
                    if((_S84 < 9.99999997475242708e-07f))
                    {
                        if((_S82 < 0.0f))
                        {
                            q_3 = 0.0f;
                        }
                        else
                        {
                            q_3 = 3.1415927410125732f;
                        }
                    }
                    else
                    {
                        q_3 = _S83;
                    }
                }
            }
            q_3 = fract(q_3 / 6.2831854820251465f + 1.0f - p_14.turns_0 * p_14.u_0 - startAngle_0);
        }
    case u32(5), u32(14):
        {
            q_3 = (length(v_3) - rmin_0) / max(1.0f, _S74 - rmin_0);
        }
    case u32(6), u32(7):
        {
            var vr_0 : vec2<f32> = rot3_0(v_3, p_14.angle_0 * 3.1415927410125732f / 180.0f + p_14.turns_0 * 2.0f * 3.1415927410125732f * p_14.u_0);
            if((p_14.shape_0) == u32(6))
            {
                q_3 = (abs(vr_0.x) + abs(vr_0.y)) / max(1.0f, radii_0.x + radii_0.y);
            }
            else
            {
                q_3 = max(abs(vr_0.x) / max(radii_0.x, 1.0f), abs(vr_0.y) / max(radii_0.y, 1.0f));
            }
        }
    case u32(8), u32(10):
        {
            var _S86 : bool = (p_14.shape_0) == u32(10);
            if(_S86)
            {
                q_3 = max(1.0f, ceil(_S71 / 2.0f));
            }
            else
            {
                q_3 = _S71;
            }
            var gs_0 : vec2<f32> = gridSize3_0(q_3, dim_0);
            var _S87 : f32 = gs_0.y;
            var _S88 : f32 = uv_4.y * _S87;
            var _S89 : f32 = min(floor(_S88), _S87 - 1.0f);
            var _S90 : f32 = gs_0.x;
            var extra_0 : f32 = q_3 - _S90 * _S87;
            if((_S89 < extra_0))
            {
                _S75 = i32(1);
            }
            else
            {
                _S75 = i32(0);
            }
            var cols_1 : f32 = _S90 + f32(_S75);
            var _S91 : f32 = _S70 * cols_1;
            var _S92 : f32 = min(floor(_S91), cols_1 - 1.0f);
            var index_2 : f32 = _S89 * _S90 + min(_S89, extra_0) + _S92;
            c_4.cell_3 = vec2<f32>(_S92, _S89);
            c_4.frac_0 = fract(vec2<f32>(_S91, _S88));
            if(_S86)
            {
                var _S93 : f32 = _S71 - 1.0f;
                var _S94 : f32 = index_2 * 2.0f;
                if(((c_4.frac_0.x + c_4.frac_0.y) >= 1.0f))
                {
                    _S75 = i32(1);
                }
                else
                {
                    _S75 = i32(0);
                }
                lengthPx_1 = min(_S93, _S94 + f32(_S75));
            }
            else
            {
                lengthPx_1 = index_2;
            }
            q_3 = lengthPx_1 / max(1.0f, _S71 - 1.0f);
        }
    case u32(9):
        {
            q_3 = fract(axisAngle3_0(v_3.y, v_3.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_3) / _S74));
        }
    case u32(11):
        {
            q_3 = _S70;
        }
    case u32(13):
        {
            q_3 = length(v_3) / max(1.0f, _S74 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * axisAngle3_0(v_3.y, v_3.x))));
        }
    default :
        {
            q_3 = _S70;
        }
    }
    if((p_14.customMap_0) != u32(0))
    {
        c_4.coverage_3 = 1.0f;
        q_3 = mapValue_0;
    }
    var q_5 : f32 = clamp(q_3, 0.0f, 1.0f);
    var _S95 : bool = (p_14.direction_0) == u32(1);
    if(_S95)
    {
        q_3 = 1.0f - q_5;
    }
    else
    {
        q_3 = q_5;
    }
    if(((p_14.direction_0) >= u32(2)))
    {
        if((p_14.shape_0) == u32(8))
        {
            _S76 = true;
        }
        else
        {
            _S76 = (p_14.shape_0) == u32(10);
        }
        if(_S76)
        {
            q_3 = max(abs(_S70 - 0.5f), abs(uv_4.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_3 = abs(q_3 - 0.5f) * 2.0f;
        }
        if((p_14.direction_0) == u32(3))
        {
            q_3 = 1.0f - q_3;
        }
    }
    c_4.raw_0 = q_3;
    var _S96 : f32 = q_3 * _S71;
    var _S97 : f32 = _S71 - 1.0f;
    c_4.index_1 = min(floor(_S96), _S97);
    var edge_1 : f32 = round(_S96);
    if(((abs(_S96 - edge_1)) < 9.9999997473787516e-05f))
    {
        c_4.raw_0 = edge_1 / _S71;
        c_4.index_1 = min(edge_1, _S97);
    }
    if(isStripe42_0(p_14))
    {
        _S76 = ((p_14.reserved0_0) <= 0.0f);
    }
    else
    {
        _S76 = false;
    }
    if(_S76)
    {
        var _S98 : bool = (p_14.shape_0) == u32(1);
        if(_S98)
        {
            lengthPx_1 = p_14.sampleH_0;
        }
        else
        {
            lengthPx_1 = p_14.sampleW_0;
        }
        var _S99 : f32;
        if(_S98)
        {
            _S99 = uv_4.y;
        }
        else
        {
            _S99 = _S70;
        }
        var pixel_4 : f32 = floor(_S99 * lengthPx_1);
        if(_S95)
        {
            _S99 = lengthPx_1 - 1.0f - pixel_4;
        }
        else
        {
            _S99 = pixel_4;
        }
        var _S100 : f32 = rasterStripeIndex42_0(_S99, lengthPx_1, _S71);
        c_4.index_1 = _S100;
    }
    if(((p_14.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_3 = c_4.index_1 / _S97;
    }
    c_4.q_2 = q_3;
    return c_4;
}

fn play3_0( x_5 : f32,  mode_0 : u32) -> f32
{
    var _S101 : f32;
    if(mode_0 == u32(0))
    {
        _S101 = clamp(x_5, 0.0f, 1.0f);
    }
    else
    {
        if(mode_0 == u32(2))
        {
            _S101 = fract(x_5);
        }
        else
        {
            _S101 = bounce3_0(x_5);
        }
    }
    return _S101;
}

fn creative3_0( uv_5 : vec2<f32>,  c_5 : Coord_0,  p_15 : TFParams_0) -> Field_0
{
    var clock_1 : f32 = 2.0f * p_15.cycles_0 * p_15.u_0;
    var _S102 : f32 = max(2.0f, p_15.slices_0);
    var center_2 : vec2<f32> = vec2<f32>(p_15.cx_0, p_15.cy_0);
    var metric_1 : vec2<f32> = vec2<f32>(p_15.aspect_0, 1.0f);
    var v_4 : vec2<f32> = (uv_5 - center_2) * metric_1;
    var _S103 : f32 = bounce3_0(clock_1);
    var f_6 : Field_0 = single3_0(uv_5, _S103);
    var band_2 : f32;
    var phase_2 : f32;
    var lateral_0 : f32;
    var q_6 : f32;
    var i_1 : i32;
    var horizontal_0 : bool;
    switch(p_15.design_0)
    {
    case u32(9):
        {
            var _S104 : f32 = length(v_4);
            var phase_3 : f32 = fract(2.0f * (axisAngle3_0(v_4.x, - v_4.y) / 6.2831854820251465f) + _S104 / max(length(metric_1 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * p_15.span_0);
            var _S105 : bool = ((p_15.pixel_0) > 0.0f);
            if(_S105)
            {
                band_2 = phase_3 - p_15.cycles_0 * p_15.u_0;
            }
            else
            {
                band_2 = phase_3 * _S102;
            }
            if((p_15.pixel_0) == 0.0f)
            {
                phase_2 = floor(band_2) / (_S102 - 1.0f);
            }
            else
            {
                phase_2 = phase_3;
            }
            var _S106 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(p_15.cycles_0 * p_15.u_0 - phase_2);
            f_6.b_7 = _S106;
            f_6.a_3 = _S106;
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                var _S107 : f32 = fract(band_2);
                var _S108 : f32 = min(3.1415927410125732f * _S104 * p_15.sampleH_0, p_15.sampleH_0);
                if(_S105)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = _S102;
                }
                f_6.light_0 = tiledLight42_0(_S107, _S108 / band_2, 1.0f, p_15);
            }
        }
    case u32(10):
        {
            var q_7 : f32 = clamp(1.0f - abs(uv_5.x - p_15.cx_0) * 2.0f, 0.0f, 1.0f);
            var _S109 : f32 = _S102 - 1.0f;
            var band_3 : f32 = q_7 * _S109;
            if((p_15.pixel_0) == 0.0f)
            {
                q_6 = floor(band_3) / _S109;
            }
            else
            {
                q_6 = q_7;
            }
            var _S110 : f32 = 0.80000001192092896f * p_15.span_0;
            var _S111 : f32 = _S110 * q_6;
            var _S112 : f32 = bounce3_0(clock_1 - _S111);
            f_6.b_7 = _S112;
            f_6.a_3 = _S112;
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                var _S113 : bool = ((p_15.pixel_0) > 0.0f);
                if(_S113)
                {
                    band_2 = _S111 - clock_1;
                }
                else
                {
                    band_2 = band_3;
                }
                var _S114 : f32 = fract(band_2);
                var _S115 : f32 = 0.5f * p_15.sampleW_0;
                if(_S113)
                {
                    band_2 = _S110;
                }
                else
                {
                    band_2 = _S109;
                }
                f_6.light_0 = tiledLight42_0(_S114, _S115 / band_2, 1.0f, p_15);
            }
        }
    case u32(11):
        {
            var _S116 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, p_15.softness_0 * 0.15999999642372131f);
            var _S117 : f32 = c_5.frac_0.y;
            var ah_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S116, abs(_S117 - 0.5f));
            var _S118 : f32 = c_5.frac_0.x;
            var av_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S116, abs(_S118 - 0.5f));
            var _S119 : f32 = c_5.cell_3.y;
            var over_0 : bool = (i32(floor(c_5.cell_3.x) + floor(_S119)) % i32(2)) == i32(0);
            var ht_0 : f32 = bounce3_0(clock_1 - uv_5.x * p_15.span_0);
            var vt_0 : f32 = bounce3_0(clock_1 + uv_5.y * p_15.span_0 + 1.0f);
            var _S120 : bool = (ah_0 > 0.0f);
            if(_S120)
            {
                horizontal_0 = true;
            }
            else
            {
                horizontal_0 = (av_0 > 0.0f);
            }
            if(horizontal_0)
            {
                if(over_0)
                {
                    band_2 = vt_0;
                }
                else
                {
                    band_2 = ht_0;
                }
                f_6.a_3 = band_2;
                if(over_0)
                {
                    band_2 = ht_0;
                }
                else
                {
                    band_2 = vt_0;
                }
                f_6.b_7 = band_2;
                if(over_0)
                {
                    band_2 = ah_0;
                }
                else
                {
                    band_2 = av_0;
                }
                f_6.weight_0 = band_2;
                if(ah_0 == 0.0f)
                {
                    f_6.b_7 = vt_0;
                    f_6.a_3 = vt_0;
                }
                if(av_0 == 0.0f)
                {
                    f_6.b_7 = ht_0;
                    f_6.a_3 = ht_0;
                }
            }
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                if(_S120)
                {
                    horizontal_0 = true;
                }
                else
                {
                    horizontal_0 = (av_0 > 0.0f);
                }
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                if(av_0 == 0.0f)
                {
                    horizontal_0 = true;
                }
                else
                {
                    if(_S120)
                    {
                        horizontal_0 = over_0;
                    }
                    else
                    {
                        horizontal_0 = false;
                    }
                }
                if(horizontal_0)
                {
                    band_2 = ah_0;
                }
                else
                {
                    band_2 = av_0;
                }
                if(horizontal_0)
                {
                    phase_2 = _S117;
                }
                else
                {
                    phase_2 = _S118;
                }
                var phase_4 : f32 = clamp((phase_2 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_0 : vec2<f32> = gridSize3_0(_S102, vec2<f32>(p_15.outputW_0, p_15.outputH_0));
                var _S121 : f32 = grid_0.x;
                var _S122 : f32 = grid_0.y;
                if((_S119 < (_S102 - _S121 * _S122)))
                {
                    i_1 = i32(1);
                }
                else
                {
                    i_1 = i32(0);
                }
                var cols_2 : f32 = _S121 + f32(i_1);
                if(horizontal_0)
                {
                    phase_2 = p_15.sampleH_0 / _S122;
                }
                else
                {
                    phase_2 = p_15.sampleW_0 / cols_2;
                }
                f_6.light_0 = edgeLight42_0(phase_4, 0.47999998927116394f * phase_2, band_2, p_15);
            }
        }
    case u32(12):
        {
            var sources_0 : u32 = clamp(p_15.waveSources_0, u32(2), u32(4));
            var i_2 : u32 = u32(0);
            band_2 = 0.0f;
            loop
            {
                if((i_2 < sources_0))
                {
                }
                else
                {
                    break;
                }
                var a_7 : f32 = 6.2831854820251465f * f32(i_2) / f32(sources_0);
                var r_7 : f32 = length((uv_5 - (center_2 + vec2<f32>(0.18000000715255737f * cos(a_7), 0.18000000715255737f * sin(a_7)))) * metric_1);
                var band_4 : f32 = r_7 * _S102;
                if((p_15.pixel_0) == 0.0f)
                {
                    phase_2 = floor(band_4) / _S102;
                }
                else
                {
                    phase_2 = r_7;
                }
                var _S123 : f32 = phase_2 * 1.2999999523162842f * p_15.span_0;
                var sum_0 : f32 = band_2 + bounce3_0(clock_1 - _S123);
                if(((p_15.shadowStrength_0) > 0.0f))
                {
                    var _S124 : bool = ((p_15.pixel_0) > 0.0f);
                    if(_S124)
                    {
                        lateral_0 = _S123 - clock_1;
                    }
                    else
                    {
                        lateral_0 = band_4;
                    }
                    var phase_5 : f32 = fract(lateral_0);
                    var _S125 : f32 = f_6.light_0;
                    if(_S124)
                    {
                        q_6 = 1.2999999523162842f * p_15.span_0;
                    }
                    else
                    {
                        q_6 = _S102;
                    }
                    f_6.light_0 = min(_S125, tiledLight42_0(phase_5, p_15.sampleH_0 / q_6, 1.0f, p_15));
                }
                i_2 = i_2 + u32(1);
                band_2 = sum_0;
            }
            var _S126 : f32 = band_2 / f32(sources_0);
            f_6.b_7 = _S126;
            f_6.a_3 = _S126;
        }
    case u32(13):
        {
            var _S127 : f32 = 6.2831854820251465f * p_15.u_0;
            var _S128 : f32 = sin(_S127);
            var local_1 : vec2<f32> = (uv_5 - (center_2 + vec2<f32>(0.2199999988079071f * _S128, 0.12999999523162842f * cos(_S127)))) * metric_1;
            var r_8 : f32 = length(local_1);
            var radius_0 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S128;
            var _S129 : f32 = max(0.0020000000949949026f, p_15.softness_0 * 0.15999999642372131f);
            f_6.b_7 = bounce3_0(clock_1 + 0.80000001192092896f * p_15.span_0);
            f_6.weight_0 = 1.0f - smoothstep(radius_0 - _S129, radius_0 + _S129, r_8);
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                horizontal_0 = ((f_6.weight_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S130 : f32 = local_1.y;
                var halfWidth_0 : f32 = sqrt(max(9.99999997475242708e-07f, radius_0 * radius_0 - _S130 * _S130));
                f_6.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * local_1.x / halfWidth_0, 0.0f, 1.0f), 2.0f * halfWidth_0 * p_15.sampleH_0, f_6.weight_0, p_15);
            }
        }
    case u32(400):
        {
            var _S131 : f32 = max(_S102, 2.0f);
            var gap_0 : f32 = 0.64999997615814209f / _S131;
            var d_1 : f32 = fract(p_15.u_0 * p_15.cycles_0) * 1.6499999761581421f - uv_5.x;
            var j_0 : f32 = floor(d_1 / gap_0);
            var local_2 : f32 = fract(d_1 / gap_0);
            if((j_0 >= 0.0f))
            {
                horizontal_0 = (j_0 < _S131);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S132 : f32 = max(0.014999999664723873f, p_15.softness_0 * 0.15000000596046448f);
                var a_8 : f32 = smoothstep(0.0f, _S132, local_2) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S132, local_2));
                f_6.b_7 = clamp(1.0f - j_0 / _S131, 0.0f, 1.0f);
                f_6.weight_0 = a_8 * (1.0f - 0.64999997615814209f * j_0 / _S131);
            }
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_0(clamp(1.0f - local_2 / 0.64999997615814209f, 0.0f, 1.0f), gap_0 * 0.64999997615814209f * p_15.sampleW_0, f_6.weight_0, p_15);
            }
        }
    case u32(401):
        {
            var _S133 : f32 = uv_5.y;
            if((i32(floor(_S133 * _S102)) % i32(2)) == i32(0))
            {
                band_2 = 1.0f;
            }
            else
            {
                band_2 = -1.0f;
            }
            var gap_1 : f32 = 0.34999999403953552f * smoothstep(_S103 - 0.059999998658895493f, _S103 + 0.059999998658895493f, _S133);
            var seam_0 : f32 = p_15.cx_0 + band_2 * 0.02500000037252903f;
            var _S134 : f32 = uv_5.x;
            var _S135 : f32 = _S134 - seam_0;
            var outside_0 : bool = ((abs(_S135)) > gap_1);
            if(outside_0)
            {
                if((_S134 < seam_0))
                {
                    band_2 = 0.079999998211860657f;
                }
                else
                {
                    band_2 = 0.94999998807907104f;
                }
                f_6.b_7 = band_2;
                f_6.a_3 = band_2;
            }
            var _S136 : bool = ((p_15.shadowStrength_0) > 0.0f);
            if(_S136)
            {
                var _S137 : f32 = clamp((_S135 + gap_1) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S138 : f32 = 0.2199999988079071f * p_15.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S134 < seam_0);
                }
                else
                {
                    horizontal_0 = false;
                }
                if(horizontal_0)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = 0.0f;
                }
                f_6.light_0 = edgeLight42_0(_S137, _S138, band_2, p_15);
            }
            if(_S136)
            {
                horizontal_0 = ((p_15.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S139 : f32 = clamp((_S135 - gap_1) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S140 : f32 = 0.2199999988079071f * p_15.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S134 > seam_0);
                }
                else
                {
                    horizontal_0 = false;
                }
                if(horizontal_0)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = 0.0f;
                }
                f_6.light_0 = edgeLight42_0(_S139, _S140, band_2, p_15);
            }
        }
    case u32(402):
        {
            var a_9 : f32 = axisAngle3_0(v_4.y, v_4.x);
            var r_9 : f32 = length(v_4);
            var radius_1 : f32 = 0.4699999988079071f * min(p_15.aspect_0, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * p_15.u_0 * p_15.cycles_0)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_9 * _S102));
            var _S141 : f32 = max(0.0010000000474974513f, p_15.softness_0 * 0.019999999552965164f);
            var _S142 : f32 = fract((a_9 + 3.1415927410125732f) / 6.2831854820251465f) * _S102;
            f_6.b_7 = bounce3_0(clock_1 + floor(_S142) / _S102 * p_15.span_0);
            f_6.weight_0 = 1.0f - smoothstep(radius_1 - _S141, radius_1 + _S141, r_9);
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_0(fract(_S142), 6.2831854820251465f * r_9 * p_15.sampleH_0 / _S102, f_6.weight_0, p_15);
            }
        }
    case u32(403):
        {
            var r_10 : f32 = length(v_4);
            var _S143 : f32 = max(3.0f, _S102);
            var sector_0 : f32 = 6.2831854820251465f / _S143;
            var _S144 : f32 = axisAngle3_0(v_4.y, v_4.x) + p_15.u_0 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_0 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * p_15.u_0 * p_15.cycles_0))) * min(p_15.aspect_0, 1.0f) * cos(3.1415927410125732f / _S143) / max(0.0010000000474974513f, cos(fract(_S144 / sector_0) * sector_0 - sector_0 * 0.5f));
            f_6.a_3 = bounce3_0(clock_1 - p_15.span_0 * floor(fract(_S144 / 6.2831854820251465f) * _S143) / _S143);
            f_6.b_7 = bounce3_0(clock_1 + 1.0f);
            f_6.weight_0 = 1.0f - smoothstep(aperture_0 - 0.0020000000949949026f, aperture_0 + 0.0020000000949949026f, r_10);
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_0(fract(_S144 / sector_0), sector_0 * r_10 * p_15.sampleH_0, 1.0f - f_6.weight_0, p_15);
            }
        }
    case u32(404):
        {
            var _S145 : f32 = fract(p_15.u_0 * p_15.cycles_0);
            band_2 = 1.0e+09f;
            phase_2 = 0.0f;
            lateral_0 = 0.0f;
            i_1 = i32(0);
            loop
            {
                if((i_1 < i32(32)))
                {
                }
                else
                {
                    break;
                }
                var _S146 : f32 = f32(i_1);
                var a0_0 : f32 = 6.2831854820251465f * _S146 / 32.0f;
                var _S147 : i32 = i_1 + i32(1);
                var a1_0 : f32 = 6.2831854820251465f * f32(_S147) / 32.0f;
                var a_10 : vec2<f32> = center_2 + vec2<f32>(0.34000000357627869f * sin(a0_0), 0.2199999988079071f * sin(2.0f * a0_0));
                var segment_0 : vec2<f32> = (center_2 + vec2<f32>(0.34000000357627869f * sin(a1_0), 0.2199999988079071f * sin(2.0f * a1_0)) - a_10) * metric_1;
                var point_1 : vec2<f32> = (uv_5 - a_10) * metric_1;
                var k_0 : f32 = clamp(dot(point_1, segment_0) / max(dot(segment_0, segment_0), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_0 : vec2<f32> = point_1 - vec2<f32>(k_0) * segment_0;
                var distance_3 : f32 = dot(delta_0, delta_0);
                var trail_0 : f32 = fract(_S145 - (_S146 + k_0) / 32.0f + 1.0f);
                if((trail_0 < 0.60000002384185791f))
                {
                    horizontal_0 = (distance_3 < band_2);
                }
                else
                {
                    horizontal_0 = false;
                }
                if(horizontal_0)
                {
                    if(((p_15.shadowStrength_0) > 0.0f))
                    {
                        if(((dot(delta_0, vec2<f32>(segment_0.y, - segment_0.x))) >= 0.0f))
                        {
                            q_6 = 1.0f;
                        }
                        else
                        {
                            q_6 = -1.0f;
                        }
                    }
                    else
                    {
                        q_6 = lateral_0;
                    }
                    band_2 = distance_3;
                    phase_2 = trail_0;
                    lateral_0 = q_6;
                }
                i_1 = _S147;
            }
            var _S148 : f32 = max(0.0020000000949949026f, p_15.softness_0 * 0.039999999105930328f);
            var best_0 : f32 = sqrt(band_2);
            f_6.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S148, 0.035000000149011612f + _S148, best_0);
            var q_8 : f32 = phase_2 / 0.60000002384185791f;
            if((p_15.pixel_0) == 0.0f)
            {
                q_6 = floor(q_8 * _S102) / (_S102 - 1.0f);
            }
            else
            {
                q_6 = q_8;
            }
            f_6.b_7 = 0.15000000596046448f + 0.85000002384185791f * q_6;
            if(((p_15.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_0(clamp(0.5f + best_0 * lateral_0 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * p_15.sampleH_0, f_6.weight_0, p_15);
            }
        }
    default :
        {
        }
    }
    return f_6;
}

fn frozen3_0( uv_6 : vec2<f32>,  c_6 : Coord_0,  p_16 : TFParams_0) -> Field_0
{
    var build_1 : f32 = clamp(p_16.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var _S149 : bool = ((p_16.pixel_0) > 0.0f);
    var held_0 : f32;
    if(_S149)
    {
        held_0 = c_6.raw_0;
    }
    else
    {
        held_0 = min(1.0f, (c_6.index_1 + 1.0f) / max(2.0f, p_16.slices_0));
    }
    if((((p_16.flags_0) & (u32(1024)))) != u32(0))
    {
        var skip_0 : f32 = clamp(p_16.reserved1_0, 0.0f, 1.0f);
        var _S150 : f32 = held_0 * (1.0f - skip_0);
        if((held_0 > 0.5f))
        {
            held_0 = skip_0;
        }
        else
        {
            held_0 = 0.0f;
        }
        held_0 = _S150 + held_0;
    }
    var a_11 : f32;
    if(((p_16.u_0) < build_1))
    {
        var progress_0 : f32 = p_16.u_0 / build_1;
        var _S151 : bool;
        if(_S149)
        {
            _S151 = true;
        }
        else
        {
            _S151 = (((p_16.flags_0) & (u32(1)))) != u32(0);
        }
        if(_S151)
        {
            var _S152 : f32 = max(1.0f / max(p_16.outputW_0, p_16.outputH_0), p_16.softness_0 * 0.0030000000260770321f);
            a_11 = 1.0f - smoothstep(progress_0 - _S152, progress_0 + _S152, c_6.raw_0);
        }
        else
        {
            var _S153 : i32;
            if((progress_0 >= (c_6.q_2)))
            {
                _S153 = i32(1);
            }
            else
            {
                _S153 = i32(0);
            }
            a_11 = f32(_S153);
        }
        var f_7 : Field_0 = single3_0(uv_6, progress_0);
        f_7.b_7 = held_0;
        f_7.weight_0 = a_11;
        return f_7;
    }
    var after_0 : f32 = clamp((p_16.u_0 - build_1) / (1.0f - build_1), 0.0f, 1.0f);
    switch(p_16.ending_0)
    {
    case u32(0):
        {
            a_11 = held_0;
        }
    case u32(1):
        {
            a_11 = clamp(held_0 + after_0, 0.0f, 1.0f);
        }
    case u32(2):
        {
            var release_0 : f32 = c_6.q_2 * 0.64999997615814209f;
            a_11 = clamp(held_0 + max(0.0f, after_0 - release_0) / max(0.05000000074505806f, 1.0f - release_0), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_0 > 0.0f))
            {
                held_0 = play3_0(held_0 - 2.0f * p_16.cycles_0 * after_0, p_16.playback_0);
            }
            a_11 = held_0;
        }
    case u32(4):
        {
            a_11 = bounce3_0(held_0 - 2.0f * p_16.cycles_0 * after_0);
        }
    default :
        {
            a_11 = held_0;
        }
    }
    return single3_0(uv_6, a_11);
}

fn relative3_0( c_7 : Coord_0,  p_17 : TFParams_0) -> f32
{
    var d_2 : f32;
    if((((p_17.flags_0) & (u32(4)))) != u32(0))
    {
        d_2 = (c_7.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if((((p_17.flags_0) & (u32(8)))) != u32(0))
        {
            d_2 = (c_7.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_2 = 2.0f * c_7.raw_0 - 1.0f;
        }
    }
    if((p_17.pixel_0) == 0.0f)
    {
        var _S154 : f32 = p_17.slices_0 - 1.0f;
        var positive_0 : f32 = ceil(_S154 / 2.0f);
        var negative_0 : f32 = floor(_S154 / 2.0f);
        var _S155 : f32;
        if((d_2 < 0.0f))
        {
            _S155 = negative_0;
        }
        else
        {
            _S155 = positive_0;
        }
        var _S156 : f32 = max(1.0f, _S155);
        d_2 = round(d_2 * _S156) / _S156;
    }
    return p_17.span_0 * d_2;
}

fn basic3_0( uv_7 : vec2<f32>,  c_8 : Coord_0,  p_18 : TFParams_0) -> Field_0
{
    var clock_2 : f32 = 2.0f * p_18.cycles_0 * p_18.u_0;
    var t_7 : f32;
    if((p_18.customMap_0) != u32(0))
    {
        if((((p_18.flags_0) & (u32(2)))) != u32(0))
        {
            t_7 = p_18.u_0 + relative3_0(c_8, p_18);
        }
        else
        {
            t_7 = c_8.q_2 + clock_2;
        }
        return single3_0(uv_7, play3_0(t_7, p_18.playback_0));
    }
    if((p_18.design_0) == u32(0))
    {
        t_7 = 0.20000000298023224f + 0.80000001192092896f * fract(p_18.cycles_0 * p_18.u_0 - c_8.q_2);
    }
    else
    {
        if((p_18.design_0) == u32(5))
        {
            t_7 = bounce3_0(1.0f - clock_2 - p_18.span_0 * c_8.q_2);
        }
        else
        {
            if((p_18.shape_0) == u32(11))
            {
                if((i32(c_8.index_1) % i32(2)) == i32(0))
                {
                    t_7 = 1.0f;
                }
                else
                {
                    t_7 = -1.0f;
                }
                t_7 = play3_0(1.0f + clock_2 * t_7 - p_18.span_0 * c_8.q_2, p_18.playback_0);
            }
            else
            {
                t_7 = play3_0(1.0f + clock_2 - p_18.span_0 * c_8.q_2, p_18.playback_0);
            }
        }
    }
    return single3_0(uv_7, t_7);
}

fn wave3_0( uv_8 : vec2<f32>,  c_9 : Coord_0,  p_19 : TFParams_0) -> Field_0
{
    var _S157 : bool;
    if((p_19.customMap_0) != u32(0))
    {
        _S157 = (((p_19.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S157 = false;
    }
    var phase_6 : f32;
    if(_S157)
    {
        phase_6 = 2.0f * p_19.cycles_0 * p_19.u_0 + relative3_0(c_9, p_19);
    }
    else
    {
        phase_6 = 2.0f * p_19.cycles_0 * p_19.u_0 - 2.0f * p_19.density_0 * c_9.q_2;
    }
    return single3_0(uv_8, play3_0(phase_6, p_19.playback_0));
}

fn coordSpan42_0( uv_9 : vec2<f32>,  p_20 : TFParams_0) -> f32
{
    var size_1 : vec2<f32> = vec2<f32>(p_20.sampleW_0, p_20.sampleH_0);
    var _S158 : vec2<f32> = vec2<f32>(p_20.cx_0, p_20.cy_0);
    var v_5 : vec2<f32> = (uv_9 - _S158) * size_1;
    var _S159 : vec2<f32> = vec2<f32>(1.0f);
    var radii_1 : vec2<f32> = max(_S158, _S159 - _S158) * size_1;
    if((p_20.customMap_0) != u32(0))
    {
        return min(p_20.sampleW_0, p_20.sampleH_0);
    }
    switch(p_20.shape_0)
    {
    case u32(1):
        {
            return p_20.sampleH_0;
        }
    case u32(2), u32(12):
        {
            var a_12 : f32 = p_20.angle_0 * 3.1415927410125732f / 180.0f;
            return p_20.sampleW_0 * abs(cos(a_12)) + p_20.sampleH_0 * abs(sin(a_12));
        }
    case u32(3):
        {
            return 3.1415927410125732f * length(v_5);
        }
    case u32(4):
        {
            return 6.2831854820251465f * length(v_5);
        }
    case u32(5), u32(14):
        {
            return length(radii_1) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S158), _S158 - _S159)) * size_1);
        }
    case u32(6):
        {
            return (radii_1.x + radii_1.y) * 0.70710700750350952f;
        }
    case u32(7):
        {
            return min(radii_1.x, radii_1.y);
        }
    case u32(9):
        {
            return min(6.2831854820251465f * length(v_5), length(radii_1) / 1.5f);
        }
    case u32(13):
        {
            return length(radii_1) * 0.56000000238418579f;
        }
    default :
        {
            return p_20.sampleW_0;
        }
    }
}

fn frozenShadow53_0( uv_10 : vec2<f32>,  p_21 : TFParams_0,  coverage_4 : f32) -> f32
{
    var geometry_0 : TFParams_0 = p_21;
    geometry_0.direction_0 = u32(0);
    var _S160 : bool;
    if(((p_21.direction_0) >= u32(2)))
    {
        _S160 = (p_21.shape_0) != u32(8);
    }
    else
    {
        _S160 = false;
    }
    if(_S160)
    {
        _S160 = (p_21.shape_0) != u32(10);
    }
    else
    {
        _S160 = false;
    }
    if(_S160)
    {
        geometry_0.slices_0 = geometry_0.slices_0 * 2.0f;
    }
    var c_10 : Coord_0 = coordinate3_0(uv_10, geometry_0, 0.0f);
    var _S161 : f32 = max(2.0f, geometry_0.slices_0);
    if((p_21.shape_0) == u32(8))
    {
        _S160 = true;
    }
    else
    {
        _S160 = (p_21.shape_0) == u32(10);
    }
    var cells_0 : f32;
    if(_S160)
    {
        var _S162 : bool = (p_21.shape_0) == u32(10);
        if(_S162)
        {
            cells_0 = ceil(_S161 / 2.0f);
        }
        else
        {
            cells_0 = _S161;
        }
        var grid_1 : vec2<f32> = gridSize3_0(cells_0, vec2<f32>(p_21.outputW_0, p_21.outputH_0));
        var _S163 : f32 = grid_1.x;
        var _S164 : i32;
        if(((c_10.cell_3.y) < (cells_0 - _S163 * grid_1.y)))
        {
            _S164 = i32(1);
        }
        else
        {
            _S164 = i32(0);
        }
        var phase_7 : f32 = c_10.frac_0.x;
        var span_4 : f32 = p_21.sampleW_0 / (_S163 + f32(_S164));
        var phase_8 : f32;
        var span_5 : f32;
        if(_S162)
        {
            var cut_0 : f32 = 1.0f - c_10.frac_0.y;
            var first_2 : bool = (phase_7 < cut_0);
            if(first_2)
            {
                cells_0 = cut_0;
            }
            else
            {
                cells_0 = 1.0f - cut_0;
            }
            var span_6 : f32 = span_4 * cells_0;
            if(first_2)
            {
                cells_0 = phase_7 / max(cut_0, 9.99999997475242708e-07f);
            }
            else
            {
                cells_0 = (phase_7 - cut_0) / max(1.0f - cut_0, 9.99999997475242708e-07f);
            }
            phase_8 = cells_0;
            span_5 = span_6;
        }
        else
        {
            phase_8 = phase_7;
            span_5 = span_4;
        }
        if(((p_21.shadowSide_0) > 0.0f))
        {
            cells_0 = phase_8;
        }
        else
        {
            cells_0 = 1.0f - phase_8;
        }
        return filteredLight42_0(cells_0, span_5, coverage_4, 1.0f, false, p_21);
    }
    var phase_9 : f32 = clamp(c_10.raw_0 * _S161 - c_10.index_1, 0.0f, 1.0f);
    var span_7 : f32 = coordSpan42_0(uv_10, geometry_0) / _S161;
    if(((p_21.shadowSide_0) > 0.0f))
    {
        cells_0 = phase_9;
    }
    else
    {
        cells_0 = 1.0f - phase_9;
    }
    return filteredLight42_0(cells_0, span_7, coverage_4, 1.0f, false, p_21);
}

fn stripeBorder42_0( cut_1 : f32,  lengthPx_2 : f32,  count_3 : f32) -> f32
{
    if(((max(lengthPx_2, count_3)) <= 32768.0f))
    {
        var n_3 : u32 = u32(count_3);
        var numerator_0 : u32 = u32(2) * u32(cut_1) * u32(lengthPx_2);
        var _S165 : f32;
        if((numerator_0 <= n_3))
        {
            _S165 = 0.0f;
        }
        else
        {
            var _S166 : u32 = (numerator_0 + n_3 - u32(1)) / (u32(2) * n_3);
            _S165 = f32(_S166);
        }
        return _S165;
    }
    return clamp(ceil(cut_1 * lengthPx_2 / count_3 - 0.5f), 0.0f, lengthPx_2);
}

fn stripeLight42_0( axis_0 : f32,  index_3 : f32,  lengthPx_3 : f32,  count_4 : f32,  reverse_0 : bool,  coverage_5 : f32,  p_22 : TFParams_0) -> f32
{
    var span_8 : f32 = lengthPx_3 / count_4;
    if((span_8 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_0 : bool = ((p_22.shadowSide_0) > 0.0f);
    var center_3 : f32;
    if(leading_0)
    {
        center_3 = 0.0f;
    }
    else
    {
        center_3 = 1.0f;
    }
    var edge_2 : f32 = stripeBorder42_0(index_3 + center_3, lengthPx_3, count_4);
    var center_4 : f32 = floor(axis_0 * lengthPx_3) + 0.5f;
    if(reverse_0)
    {
        center_3 = lengthPx_3 - center_4;
    }
    else
    {
        center_3 = center_4;
    }
    if(leading_0)
    {
        center_3 = center_3 - edge_2;
    }
    else
    {
        center_3 = edge_2 - center_3;
    }
    return filteredLight42_0(max(0.5f, center_3) / span_8, span_8, coverage_5, 1.0f, false, p_22);
}

fn sliceLight42_0( uv_11 : vec2<f32>,  c_11 : Coord_0,  p_23 : TFParams_0,  coverage_6 : f32) -> f32
{
    var _S167 : bool;
    if((p_23.family_0) == u32(0))
    {
        _S167 = (p_23.customMap_0) == u32(0);
    }
    else
    {
        _S167 = false;
    }
    if(_S167)
    {
        var _S168 : f32 = frozenShadow53_0(uv_11, p_23, coverage_6);
        return _S168;
    }
    var _S169 : f32 = max(2.0f, p_23.slices_0);
    var _S170 : bool = (p_23.shape_0) == u32(8);
    if(_S170)
    {
        _S167 = true;
    }
    else
    {
        _S167 = (p_23.shape_0) == u32(10);
    }
    if(_S167)
    {
        _S167 = (p_23.customMap_0) == u32(0);
    }
    else
    {
        _S167 = false;
    }
    if(_S167)
    {
        _S167 = ((p_23.direction_0) < u32(2));
    }
    else
    {
        _S167 = false;
    }
    var cells_1 : f32;
    var x_6 : f32;
    if(_S167)
    {
        var _S171 : bool = (p_23.shape_0) == u32(10);
        if(_S171)
        {
            cells_1 = ceil(_S169 / 2.0f);
        }
        else
        {
            cells_1 = _S169;
        }
        var grid_2 : vec2<f32> = gridSize3_0(cells_1, vec2<f32>(p_23.outputW_0, p_23.outputH_0));
        var _S172 : f32 = grid_2.x;
        var _S173 : i32;
        if(((c_11.cell_3.y) < (cells_1 - _S172 * grid_2.y)))
        {
            _S173 = i32(1);
        }
        else
        {
            _S173 = i32(0);
        }
        var x_7 : f32 = c_11.frac_0.x;
        var span_9 : f32 = p_23.sampleW_0 / (_S172 + f32(_S173));
        var span_10 : f32;
        if(_S171)
        {
            var cut_2 : f32 = 1.0f - c_11.frac_0.y;
            var first_3 : bool = (x_7 < cut_2);
            if(first_3)
            {
                cells_1 = cut_2;
            }
            else
            {
                cells_1 = 1.0f - cut_2;
            }
            var span_11 : f32 = span_9 * cells_1;
            if(first_3)
            {
                cells_1 = x_7 / max(cut_2, 9.99999997475242708e-07f);
            }
            else
            {
                cells_1 = (x_7 - cut_2) / max(1.0f - cut_2, 9.99999997475242708e-07f);
            }
            x_6 = cells_1;
            span_10 = span_11;
        }
        else
        {
            x_6 = x_7;
            span_10 = span_9;
        }
        var phase_10 : f32;
        if((p_23.direction_0) == u32(1))
        {
            phase_10 = 1.0f - x_6;
        }
        else
        {
            phase_10 = x_6;
        }
        if(_S170)
        {
            cells_1 = tiledLight42_0(phase_10, span_10, coverage_6, p_23);
        }
        else
        {
            cells_1 = edgeLight42_0(phase_10, span_10, coverage_6, p_23);
        }
        return cells_1;
    }
    var span_12 : f32 = coordSpan42_0(uv_11, p_23);
    if(((p_23.direction_0) >= u32(2)))
    {
        cells_1 = span_12 * 0.5f;
    }
    else
    {
        cells_1 = span_12;
    }
    if(((p_23.pixel_0) > 0.0f))
    {
        _S167 = (p_23.family_0) == u32(2);
    }
    else
    {
        _S167 = false;
    }
    if(_S167)
    {
        if((p_23.customMap_0) != u32(0))
        {
            _S167 = (((p_23.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S167 = false;
        }
        if(_S167)
        {
            x_6 = 2.0f * p_23.span_0;
        }
        else
        {
            x_6 = 2.0f * p_23.density_0;
        }
        var _S174 : f32 = max(0.0099999997764825821f, x_6);
        return tiledLight42_0(fract(_S174 * c_11.raw_0 - 2.0f * p_23.cycles_0 * p_23.u_0), cells_1 / _S174, coverage_6, p_23);
    }
    if(isStripe42_0(p_23))
    {
        if((p_23.shape_0) == u32(1))
        {
            x_6 = uv_11.y;
        }
        else
        {
            x_6 = uv_11.x;
        }
        var _S175 : f32 = stripeLight42_0(x_6, c_11.index_1, cells_1, _S169, (p_23.direction_0) == u32(1), coverage_6, p_23);
        return _S175;
    }
    return tiledLight42_0(clamp(c_11.raw_0 * _S169 - c_11.index_1, 0.0f, 1.0f), cells_1 / _S169, coverage_6, p_23);
}

fn evaluate3_0( uv_12 : vec2<f32>,  p_24 : TFParams_0,  mapValue_1 : f32) -> Field_0
{
    if(((p_24.design_0) >= u32(407)))
    {
        return creative42_0(uv_12, p_24);
    }
    var c_12 : Coord_0 = coordinate3_0(uv_12, p_24, mapValue_1);
    var base_2 : f32;
    if((c_12.coverage_3) == 0.0f)
    {
        if((p_24.family_0) == u32(0))
        {
            base_2 = play3_0(p_24.u_0 / max(0.10000000149011612f, p_24.build_0), p_24.playback_0);
        }
        else
        {
            if((p_24.family_0) == u32(1))
            {
                base_2 = 1.0f;
            }
            else
            {
                base_2 = 0.0f;
            }
            base_2 = play3_0(base_2 + 2.0f * p_24.cycles_0 * p_24.u_0, p_24.playback_0);
        }
        return single3_0(uv_12, base_2);
    }
    if((p_24.family_0) == u32(3))
    {
        return creative3_0(uv_12, c_12, p_24);
    }
    var f_8 : Field_0;
    var _S176 : bool = (p_24.family_0) == u32(0);
    var _S177 : Field_0;
    if(_S176)
    {
        _S177 = frozen3_0(uv_12, c_12, p_24);
    }
    else
    {
        if((p_24.family_0) == u32(1))
        {
            _S177 = basic3_0(uv_12, c_12, p_24);
        }
        else
        {
            _S177 = wave3_0(uv_12, c_12, p_24);
        }
    }
    f_8 = _S177;
    if(((p_24.shadowStrength_0) > 0.0f))
    {
        var _S178 : bool;
        if(_S176)
        {
            _S178 = ((p_24.u_0) < (clamp(p_24.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S178 = false;
        }
        if(_S178)
        {
            base_2 = f_8.weight_0;
        }
        else
        {
            base_2 = 1.0f;
        }
        if((base_2 > 0.0f))
        {
            var _S179 : f32 = sliceLight42_0(uv_12, c_12, p_24, base_2);
            f_8.light_0 = _S179;
        }
    }
    return f_8;
}

fn shadowTentPart52_0( low_2 : f32,  high_2 : f32,  feathered_0 : bool,  solid_3 : f32,  feather_3 : f32,  mid_0 : f32,  center_5 : f32,  step_1 : f32,  distance_4 : f32,  sign_0 : f32,  slope_0 : f32) -> f32
{
    if((high_2 <= low_2))
    {
        return 0.0f;
    }
    var m_0 : f32 = (low_2 + high_2) * 0.5f;
    var r_11 : f32 = (high_2 - low_2) * 0.5f;
    var w0_0 : f32 = max(0.0f, 1.0f + slope_0 * (mid_0 - center_5 + sign_0 * (m_0 - distance_4)) / step_1) / step_1;
    if(!feathered_0)
    {
        return 2.0f * r_11 * w0_0;
    }
    var t_8 : f32 = clamp((m_0 - solid_3) / feather_3, 0.0f, 1.0f);
    var _S180 : f32 = 6.0f * t_8;
    var _S181 : f32 = feather_3 * feather_3;
    var w1_0 : f32 = slope_0 * sign_0 / (step_1 * step_1);
    var r2_0 : f32 = r_11 * r_11;
    return max(0.0f, 2.0f * r_11 * (w0_0 * (1.0f - t_8 * t_8 * (3.0f - 2.0f * t_8)) + (w0_0 * ((_S180 - 3.0f) / _S181) + w1_0 * (_S180 * (t_8 - 1.0f) / feather_3)) * r2_0 / 3.0f + w1_0 * (2.0f / (_S181 * feather_3)) * r2_0 * r2_0 / 5.0f));
}

fn shadowTentSide52_0( low_3 : f32,  high_3 : f32,  mid_1 : f32,  center_6 : f32,  step_2 : f32,  distance_5 : f32,  sign_1 : f32,  slope_1 : f32,  p_25 : TFParams_0) -> f32
{
    if((high_3 <= low_3))
    {
        return 0.0f;
    }
    var a_13 : f32 = distance_5 + sign_1 * (low_3 - mid_1);
    var b_9 : f32 = distance_5 + sign_1 * (high_3 - mid_1);
    var lo_1 : f32 = clamp(min(a_13, b_9), 0.0f, 1.0f);
    var hi_1 : f32 = clamp(max(a_13, b_9), 0.0f, 1.0f);
    var width_0 : f32 = clamp(p_25.shadowWidth_0, 0.019999999552965164f, 0.75f);
    var feather_4 : f32 = width_0 * max(0.02500000037252903f, p_25.shadowSoftness_0);
    var solid_4 : f32 = width_0 - feather_4;
    return shadowTentPart52_0(lo_1, min(hi_1, solid_4), false, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1) + shadowTentPart52_0(max(lo_1, solid_4), min(hi_1, width_0), true, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1);
}

fn stripeSample52_0( uv_13 : vec2<f32>,  p_26 : TFParams_0,  footprint_0 : StripeFootprint52_0,  low_4 : f32,  high_4 : f32,  weight_1 : f32) -> Field_0
{
    var _S182 : TFParams_0 = p_26;
    var mid_2 : f32 = (low_4 + high_4) * 0.5f;
    var axis_1 : f32 = mid_2 / footprint_0.count_1;
    var gradient_2 : vec2<f32> = stripeGradient52_0(p_26);
    var _S183 : vec2<f32> = uv_13 + gradient_2 * vec2<f32>(((axis_1 - stripeAxis52_0(uv_13, p_26)) / max(9.99999993922529029e-09f, dot(gradient_2, gradient_2))));
    _S182.reserved0_0 = 1.0f;
    var _S184 : Field_0 = evaluate3_0(_S183, _S182, 0.0f);
    var f_9 : Field_0 = _S184;
    if(((_S182.shadowStrength_0) <= 0.0f))
    {
        return f_9;
    }
    var c_13 : Coord_0 = coordinate3_0(_S183, _S182, 0.0f);
    var phase_11 : f32 = clamp(c_13.raw_0 * max(2.0f, _S182.slices_0) - c_13.index_1, 0.0f, 1.0f);
    var sign_2 : f32;
    if((_S182.direction_0) == u32(1))
    {
        sign_2 = -1.0f;
    }
    else
    {
        sign_2 = 1.0f;
    }
    var phase_12 : f32;
    if(((_S182.direction_0) >= u32(2)))
    {
        if((axis_1 < 0.5f))
        {
            sign_2 = -1.0f;
        }
        else
        {
            sign_2 = 1.0f;
        }
        if((_S182.direction_0) == u32(3))
        {
            phase_12 = -1.0f;
        }
        else
        {
            phase_12 = 1.0f;
        }
        sign_2 = sign_2 * phase_12;
    }
    if((sign_2 < 0.0f))
    {
        phase_12 = 1.0f - phase_11;
    }
    else
    {
        phase_12 = phase_11;
    }
    var distance_6 : f32;
    if(((_S182.shadowSide_0) > 0.0f))
    {
        distance_6 = phase_12;
    }
    else
    {
        distance_6 = 1.0f - phase_12;
    }
    if((_S182.shadowSide_0) == 0.0f)
    {
        sign_2 = -1.0f;
    }
    else
    {
        sign_2 = 1.0f;
    }
    var mass_0 : f32 = shadowTentSide52_0(low_4, min(high_4, footprint_0.center_0), mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, 1.0f, _S182) + shadowTentSide52_0(max(low_4, footprint_0.center_0), high_4, mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, -1.0f, _S182);
    var gradient_3 : vec2<f32> = abs(gradient_2);
    var fade_0 : f32 = smoothstep(1.0f, 2.5f, 1.0f / max(9.99999993922529029e-09f, gradient_3.x / _S182.outputW_0 + gradient_3.y / _S182.outputH_0) / footprint_0.count_1);
    var coverage_7 : f32;
    if(((_S182.u_0) < (clamp(_S182.build_0, 0.10000000149011612f, 0.89999997615814209f))))
    {
        coverage_7 = f_9.weight_0;
    }
    else
    {
        coverage_7 = 1.0f;
    }
    f_9.light_0 = 1.0f - _S182.shadowStrength_0 * coverage_7 * fade_0 * clamp(mass_0 / max(weight_1, 9.99999993922529029e-09f), 0.0f, 1.0f);
    return f_9;
}

fn filteredStripeColor52_0( uv_14 : vec2<f32>,  local_3 : u32,  p_27 : TFParams_0) -> vec4<f32>
{
    var footprint_1 : StripeFootprint52_0 = stripeFootprint52_0(uv_14, p_27);
    var _S185 : vec4<f32> = vec4<f32>(vec4<i32>(i32(0)));
    var cell_4 : i32 = i32(footprint_1.first_0);
    var result_0 : vec4<f32> = _S185;
    loop
    {
        if((cell_4 <= i32(footprint_1.last_0)))
        {
        }
        else
        {
            break;
        }
        var _S186 : f32 = max(footprint_1.low_0, f32(cell_4));
        var _S187 : i32 = cell_4 + i32(1);
        var _S188 : f32 = min(footprint_1.high_0, f32(_S187));
        var weight_2 : f32 = stripeWeight52_0(_S186, _S188, footprint_1);
        if((weight_2 <= 9.99999993922529029e-09f))
        {
            cell_4 = _S187;
            continue;
        }
        var f_10 : Field_0 = stripeSample52_0(uv_14, p_27, footprint_1, _S186, _S188, weight_2);
        var blend_0 : f32 = clamp(f_10.weight_0, 0.0f, 1.0f);
        var color_0 : vec4<f32>;
        if((p_27.viewMode_0) == u32(2))
        {
            var t_9 : f32 = adjusted3_0(mix(clamp(f_10.a_3, 0.0f, 1.0f), clamp(f_10.b_7, 0.0f, 1.0f), blend_0), p_27);
            color_0 = vec4<f32>(t_9, t_9, t_9, 1.0f);
        }
        else
        {
            if(blend_0 == 1.0f)
            {
                var _S189 : vec4<f32> = sampleSource_0(f_10.b_7, local_3, p_27);
                color_0 = _S189 * vec4<f32>(f_10.shade_0);
            }
            else
            {
                var _S190 : vec4<f32> = sampleSource_0(f_10.a_3, local_3, p_27);
                color_0 = _S190;
                if((blend_0 > 0.0f))
                {
                    var _S191 : vec4<f32> = sampleSource_0(f_10.b_7, local_3, p_27);
                    color_0 = mix(color_0, _S191 * vec4<f32>(f_10.shade_0), vec4<f32>(blend_0));
                }
            }
            var _S192 : vec3<f32> = color_0.xyz * vec3<f32>(f_10.light_0);
            color_0.x = _S192.x;
            color_0.y = _S192.y;
            color_0.z = _S192.z;
        }
        result_0 = result_0 + color_0 * vec4<f32>(weight_2) / vec4<f32>(footprint_1.normalization_0);
        cell_4 = _S187;
    }
    return result_0;
}

fn needsAA53_0( uv_15 : vec2<f32>,  p_28 : TFParams_0,  mapValue_2 : f32) -> bool
{
    if((p_28.customMap_0) != u32(0))
    {
        return false;
    }
    var _S193 : bool;
    if(((p_28.pixel_0) > 0.0f))
    {
        _S193 = (p_28.family_0) != u32(3);
    }
    else
    {
        _S193 = false;
    }
    if(_S193)
    {
        _S193 = ((p_28.shadowStrength_0) <= 0.0f);
    }
    else
    {
        _S193 = false;
    }
    if(_S193)
    {
        return false;
    }
    if((p_28.shape_0) == u32(0))
    {
        _S193 = true;
    }
    else
    {
        _S193 = (p_28.shape_0) == u32(1);
    }
    if(_S193)
    {
        _S193 = true;
    }
    else
    {
        _S193 = (p_28.shape_0) == u32(11);
    }
    if(_S193)
    {
        _S193 = ((p_28.direction_0) < u32(2));
    }
    else
    {
        _S193 = false;
    }
    var _S194 : f32;
    if(_S193)
    {
        if((p_28.shape_0) == u32(1))
        {
            _S194 = p_28.sampleH_0;
        }
        else
        {
            _S194 = p_28.sampleW_0;
        }
        var pitch_2 : f32 = _S194 / max(2.0f, p_28.slices_0);
        if(((abs(pitch_2 - round(pitch_2))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    var q_9 : TFParams_0 = p_28;
    q_9.reserved0_0 = 0.25f;
    var delta_1 : vec2<f32> = vec2<f32>(0.49000000953674316f) / vec2<f32>(p_28.sampleW_0, p_28.sampleH_0);
    var _S195 : vec2<f32> = uv_15 - delta_1;
    var _S196 : Coord_0 = coordinate3_0(_S195, q_9, mapValue_2);
    var _S197 : Field_0 = evaluate3_0(_S195, q_9, mapValue_2);
    var i_3 : i32 = i32(1);
    loop
    {
        if((i_3 < i32(4)))
        {
        }
        else
        {
            break;
        }
        if(((i_3 & (i32(1)))) != i32(0))
        {
            _S194 = delta_1.x;
        }
        else
        {
            _S194 = - delta_1.x;
        }
        var _S198 : f32;
        if(((i_3 & (i32(2)))) != i32(0))
        {
            _S198 = delta_1.y;
        }
        else
        {
            _S198 = - delta_1.y;
        }
        var v_6 : vec2<f32> = uv_15 + vec2<f32>(_S194, _S198);
        var other_0 : Coord_0 = coordinate3_0(v_6, q_9, mapValue_2);
        var f_11 : Field_0 = evaluate3_0(v_6, q_9, mapValue_2);
        if((other_0.index_1) != (_S196.index_1))
        {
            _S193 = true;
        }
        else
        {
            _S193 = ((abs(other_0.coverage_3 - _S196.coverage_3)) > 0.0010000000474974513f);
        }
        var _S199 : bool;
        if(_S193)
        {
            _S199 = true;
        }
        else
        {
            _S199 = ((abs(_S197.weight_0 - f_11.weight_0)) > 0.0099999997764825821f);
        }
        if(_S199)
        {
            return true;
        }
        var _S200 : bool;
        if((p_28.family_0) == u32(3))
        {
            if(((abs(_S197.a_3 - f_11.a_3)) > 0.019999999552965164f))
            {
                _S200 = true;
            }
            else
            {
                _S200 = ((abs(_S197.b_7 - f_11.b_7)) > 0.019999999552965164f);
            }
        }
        else
        {
            _S200 = false;
        }
        if(_S200)
        {
            return true;
        }
        i_3 = i_3 + i32(1);
    }
    return false;
}

fn fieldColor53_0( f_12 : Field_0,  local_4 : u32,  p_29 : TFParams_0) -> vec4<f32>
{
    var weight_3 : f32 = clamp(f_12.weight_0, 0.0f, 1.0f);
    if((p_29.viewMode_0) == u32(2))
    {
        var n_4 : f32 = adjusted3_0(mix(clamp(f_12.a_3, 0.0f, 1.0f), clamp(f_12.b_7, 0.0f, 1.0f), weight_3), p_29);
        return vec4<f32>(n_4, n_4, n_4, 1.0f);
    }
    var color_1 : vec4<f32>;
    var _S201 : bool = weight_3 == 1.0f;
    var _S202 : f32;
    if(_S201)
    {
        _S202 = f_12.b_7;
    }
    else
    {
        _S202 = f_12.a_3;
    }
    var _S203 : vec4<f32> = sampleSource_0(_S202, local_4, p_29);
    color_1 = _S203;
    if(_S201)
    {
        color_1 = color_1 * vec4<f32>(f_12.shade_0);
    }
    else
    {
        if((weight_3 > 0.0f))
        {
            var _S204 : vec4<f32> = sampleSource_0(f_12.b_7, local_4, p_29);
            color_1 = mix(color_1, _S204 * vec4<f32>(f_12.shade_0), vec4<f32>(weight_3));
        }
    }
    var _S205 : vec3<f32> = color_1.xyz * vec3<f32>(f_12.light_0);
    color_1.x = _S205.x;
    color_1.y = _S205.y;
    color_1.z = _S205.z;
    return color_1;
}

fn gradientOffset105_0( x_8 : u32,  y_3 : u32) -> f32
{
    var _S206 : u32 = (y_3 >> (u32(1)));
    var _S207 : u32 = (y_3 >> (u32(2)));
    return (f32((((((((((((((((x_8 ^ (y_3))) & (u32(1)))) << (u32(5)))) | (((((y_3 & (u32(1)))) << (u32(4))))))) | (((((((((x_8 >> (u32(1)))) ^ (_S206))) & (u32(1)))) << (u32(3))))))) | (((((_S206 & (u32(1)))) << (u32(2))))))) | (((((((((x_8 >> (u32(2)))) ^ (_S207))) & (u32(1)))) << (u32(1))))))) | (((_S207 & (u32(1))))))) + 0.5f) / 64.0f - 0.5f;
}

fn pack_0( c_14 : vec4<f32>) -> u32
{
    var _S208 : vec4<u32> = vec4<u32>(round(clamp(c_14, vec4<f32>(0.0f), vec4<f32>(1.0f)) * vec4<f32>(255.0f)));
    return ((((((_S208.x) | ((((_S208.y) << (u32(8))))))) | ((((_S208.z) << (u32(16))))))) | (u32(4278190080)));
}

@compute
@workgroup_size(8, 8, 1)
fn render(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S209 : u32 = id_0.x;
    var _S210 : bool;
    if((_S209 >= cfg_0[i32(2)]))
    {
        _S210 = true;
    }
    else
    {
        _S210 = ((id_0.y) >= cfg_0[i32(3)]);
    }
    if(_S210)
    {
        _S210 = true;
    }
    else
    {
        _S210 = ((id_0.z) >= cfg_0[i32(8)]);
    }
    if(_S210)
    {
        return;
    }
    var _S211 : u32 = id_0.y;
    var local_5 : u32 = _S211 * cfg_0[i32(2)] + _S209;
    var uv_16 : vec2<f32> = (vec2<f32>(id_0.xy + vec2<u32>(cfg_0[i32(0)], cfg_0[i32(1)])) + vec2<f32>(0.5f)) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)]));
    var p_30 : TFParams_0;
    p_30.outTime_0 = param_0.outTime_0;
    p_30.u_0 = param_0.u_0;
    p_30.sourceDuration_0 = param_0.sourceDuration_0;
    p_30.aspect_0 = param_0.aspect_0;
    p_30.slices_0 = param_0.slices_0;
    p_30.pixel_0 = param_0.pixel_0;
    p_30.span_0 = param_0.span_0;
    p_30.cycles_0 = param_0.cycles_0;
    p_30.cx_0 = param_0.cx_0;
    p_30.cy_0 = param_0.cy_0;
    p_30.angle_0 = param_0.angle_0;
    p_30.turns_0 = param_0.turns_0;
    p_30.build_0 = param_0.build_0;
    p_30.softness_0 = param_0.softness_0;
    p_30.density_0 = param_0.density_0;
    p_30.sourceReverse_0 = param_0.sourceReverse_0;
    p_30.sourceStart_0 = param_0.sourceStart_0;
    p_30.sourceEnd_0 = param_0.sourceEnd_0;
    p_30.outputW_0 = param_0.outputW_0;
    p_30.outputH_0 = param_0.outputH_0;
    p_30.family_0 = param_0.family_0;
    p_30.shape_0 = param_0.shape_0;
    p_30.design_0 = param_0.design_0;
    p_30.ending_0 = param_0.ending_0;
    p_30.direction_0 = param_0.direction_0;
    p_30.playback_0 = param_0.playback_0;
    p_30.origin_0 = param_0.origin_0;
    p_30.viewMode_0 = param_0.viewMode_0;
    p_30.frames_0 = param_0.frames_0;
    p_30.customMap_0 = param_0.customMap_0;
    p_30.waveSources_0 = param_0.waveSources_0;
    p_30.flags_0 = param_0.flags_0;
    p_30.shadowStrength_0 = param_0.shadowStrength_0;
    p_30.shadowWidth_0 = param_0.shadowWidth_0;
    p_30.shadowSoftness_0 = param_0.shadowSoftness_0;
    p_30.shadowSide_0 = param_0.shadowSide_0;
    p_30.sampleW_0 = param_0.sampleW_0;
    p_30.sampleH_0 = param_0.sampleH_0;
    p_30.reserved0_0 = param_0.reserved0_0;
    p_30.reserved1_0 = param_0.reserved1_0;
    var _S212 : u32 = id_0.z;
    var _S213 : f32 = f32(cfg_0[i32(7)] + _S212) / f32(max(u32(1), cfg_0[i32(9)]));
    p_30.u_0 = _S213;
    p_30.outTime_0 = _S213;
    if((((p_30.flags_0) & (u32(1024)))) != u32(0))
    {
        var build_2 : f32 = clamp(p_30.build_0, 0.10000000149011612f, 0.89999997615814209f);
        p_30.u_0 = clamp(p_30.u_0 * build_2, 0.0f, build_2);
    }
    var color_2 : vec4<f32>;
    var map_0 : f32;
    if((p_30.viewMode_0) == u32(1))
    {
        if((((p_30.flags_0) & (u32(1024)))) != u32(0))
        {
            map_0 = p_30.u_0 / max(0.10000000149011612f, p_30.build_0);
        }
        else
        {
            map_0 = p_30.u_0;
        }
        var _S214 : vec4<f32> = sampleSource_0(map_0, local_5, p_30);
        color_2 = _S214;
    }
    else
    {
        if(filteredFreeze52_0(p_30))
        {
            var _S215 : vec4<f32> = filteredStripeColor52_0(uv_16, local_5, p_30);
            color_2 = _S215;
        }
        else
        {
            if((p_30.customMap_0) != u32(0))
            {
                map_0 = timeMap_0[local_5];
            }
            else
            {
                map_0 = 0.0f;
            }
            var _S216 : bool = needsAA53_0(uv_16, p_30, map_0);
            if(_S216)
            {
                var q_10 : TFParams_0 = p_30;
                q_10.reserved0_0 = 0.25f;
                color_2 = vec4<f32>(vec4<i32>(i32(0)));
                var yy_0 : i32 = i32(0);
                loop
                {
                    if((yy_0 < i32(4)))
                    {
                    }
                    else
                    {
                        break;
                    }
                    var xx_0 : i32 = i32(0);
                    loop
                    {
                        if((xx_0 < i32(4)))
                        {
                        }
                        else
                        {
                            break;
                        }
                        var _S217 : Field_0 = evaluate3_0(uv_16 + vec2<f32>((f32(xx_0) + 0.5f) / 4.0f - 0.5f, (f32(yy_0) + 0.5f) / 4.0f - 0.5f) / vec2<f32>(p_30.sampleW_0, p_30.sampleH_0), q_10, map_0);
                        var _S218 : vec4<f32> = fieldColor53_0(_S217, local_5, p_30);
                        color_2 = color_2 + _S218 / vec4<f32>(16.0f);
                        xx_0 = xx_0 + i32(1);
                    }
                    yy_0 = yy_0 + i32(1);
                }
            }
            else
            {
                var _S219 : Field_0 = evaluate3_0(uv_16, p_30, map_0);
                var _S220 : vec4<f32> = fieldColor53_0(_S219, local_5, p_30);
                color_2 = _S220;
            }
        }
    }
    if((((p_30.flags_0) & (u32(4096)))) != u32(0))
    {
        var _S221 : vec3<f32> = clamp(color_2.xyz, vec3<f32>(0.0f), vec3<f32>(1.0f)) + vec3<f32>((gradientOffset105_0(_S209 + cfg_0[i32(0)], _S211 + cfg_0[i32(1)]) / 255.0f));
        color_2.x = _S221.x;
        color_2.y = _S221.y;
        color_2.z = _S221.z;
    }
    output_0[(_S212 * cfg_0[i32(3)] + _S211) * cfg_0[i32(2)] + _S209] = pack_0(color_2);
    return;
}

