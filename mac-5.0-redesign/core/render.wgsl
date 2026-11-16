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
    @align(16) sourcePeak_0 : f32,
    @align(4) paperWhite_0 : f32,
    @align(8) displayPeak_0 : f32,
    @align(4) colorReserved_0 : f32,
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
     sourcePeak_0 : f32,
     paperWhite_0 : f32,
     displayPeak_0 : f32,
     colorReserved_0 : f32,
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

fn linearColor106_0( p_1 : TFParams_0) -> bool
{
    return (((p_1.flags_0) & (u32(2064384)))) != u32(0);
}

fn pqLinear106_0( v_0 : f32) -> f32
{
    var q_0 : f32 = pow(max(v_0, 0.0f), 0.012683313339948654f);
    return 10000.0f * pow(max(q_0 - 0.8359375f, 0.0f) / max(18.8515625f - 18.6875f * q_0, 9.99999971718068537e-10f), 6.2773947715759277f) / 203.0f;
}

fn hlgScene106_0( v_1 : f32) -> f32
{
    var _S3 : f32;
    if((v_1 <= 0.5f))
    {
        _S3 = v_1 * v_1 / 3.0f;
    }
    else
    {
        _S3 = (exp((v_1 - 0.55991071462631226f) / 0.1788327693939209f) + 0.28466892242431641f) / 12.0f;
    }
    return _S3;
}

fn linear53_0( c_1 : f32) -> f32
{
    var _S4 : f32;
    if((c_1 <= 0.040449999272823334f))
    {
        _S4 = c_1 / 12.920000076293945f;
    }
    else
    {
        _S4 = pow((c_1 + 0.054999999701976776f) / 1.0549999475479126f, 2.4000000953674316f);
    }
    return _S4;
}

fn btLinear106_0( v_2 : f32) -> f32
{
    var _S5 : f32;
    if((v_2 <= 0.081000000238418579f))
    {
        _S5 = v_2 / 4.5f;
    }
    else
    {
        _S5 = pow((v_2 + 0.098999999463558197f) / 1.0989999771118164f, 2.2222223281860352f);
    }
    return _S5;
}

fn sourceTransfer106_0( v_3 : f32,  flags_1 : u32) -> f32
{
    var _S6 : f32;
    if(((flags_1 & (u32(32768)))) != u32(0))
    {
        _S6 = pqLinear106_0(v_3);
    }
    else
    {
        if(((flags_1 & (u32(65536)))) != u32(0))
        {
            _S6 = hlgScene106_0(v_3);
        }
        else
        {
            if(((flags_1 & (u32(1048576)))) != u32(0))
            {
                _S6 = linear53_0(v_3);
            }
            else
            {
                _S6 = btLinear106_0(v_3);
            }
        }
    }
    return _S6;
}

fn to2020_106_0( c_2 : Color53_0) -> Color53_0
{
    return color53_0(0.62740397453308105f * c_2.r_0 + 0.32928198575973511f * c_2.g_0 + 0.043313600122928619f * c_2.b_0, 0.069096997380256653f * c_2.r_0 + 0.91953998804092407f * c_2.g_0 + 0.011361200362443924f * c_2.b_0, 0.016391599550843239f * c_2.r_0 + 0.088013201951980591f * c_2.g_0 + 0.8955950140953064f * c_2.b_0);
}

fn to709_106_0( c_3 : Color53_0) -> Color53_0
{
    return color53_0(1.6604909896850586f * c_3.r_0 - 0.58764100074768066f * c_3.g_0 - 0.072849996387958527f * c_3.b_0, -0.12454999983310699f * c_3.r_0 + 1.1328999996185303f * c_3.g_0 - 0.0083499997854232788f * c_3.b_0, -0.018151000142097473f * c_3.r_0 - 0.10057900100946426f * c_3.g_0 + 1.1187299489974976f * c_3.b_0);
}

fn rawColor106_0( _S7 : u32) -> Color53_0
{
    var _S8 : Color53_0;
    if((((param_0.flags_0) & (u32(8192)))) != u32(0))
    {
        _S8 = color53_0(f32((((_S7 >> (u32(20)))) & (u32(1023)))) / 1023.0f, f32((((_S7 >> (u32(10)))) & (u32(1023)))) / 1023.0f, f32((_S7 & (u32(1023)))) / 1023.0f);
    }
    else
    {
        _S8 = color53_0(f32((_S7 & (u32(255)))) / 255.0f, f32((((_S7 >> (u32(8)))) & (u32(255)))) / 255.0f, f32((((_S7 >> (u32(16)))) & (u32(255)))) / 255.0f);
    }
    return _S8;
}

fn linearColor106_1() -> bool
{
    return (((param_0.flags_0) & (u32(2064384)))) != u32(0);
}

fn sourceLinear106_0( _S9 : Color53_0) -> Color53_0
{
    var _S10 : u32 = param_0.flags_0;
    if((((param_0.flags_0) & (u32(32768)))) != u32(0))
    {
        return color53_0(sourceTransfer106_0(_S9.r_0, _S10), sourceTransfer106_0(_S9.g_0, _S10), sourceTransfer106_0(_S9.b_0, _S10));
    }
    if(((_S10 & (u32(65536)))) != u32(0))
    {
        var _S11 : Color53_0 = color53_0(sourceTransfer106_0(_S9.r_0, _S10), sourceTransfer106_0(_S9.g_0, _S10), sourceTransfer106_0(_S9.b_0, _S10));
        var gain_0 : f32 = pow(max(_S11.r_0 * 0.26269999146461487f + _S11.g_0 * 0.67799997329711914f + _S11.b_0 * 0.059300001710653305f, 9.999999960041972e-13f), 0.20000000298023224f) * 1000.0f / 203.0f;
        return color53_0(_S11.r_0 * gain_0, _S11.g_0 * gain_0, _S11.b_0 * gain_0);
    }
    return color53_0(sourceTransfer106_0(_S9.r_0, _S10), sourceTransfer106_0(_S9.g_0, _S10), sourceTransfer106_0(_S9.b_0, _S10));
}

fn inputColor106_0( _S12 : Color53_0) -> Color53_0
{
    if(!linearColor106_1())
    {
        return _S12;
    }
    var _S13 : Color53_0 = sourceLinear106_0(_S12);
    var wide_0 : bool = (((param_0.flags_0) & (u32(393216)))) != u32(0);
    var srcWide_0 : bool = (((param_0.flags_0) & (u32(524288)))) != u32(0);
    var _S14 : bool;
    if(wide_0)
    {
        _S14 = !srcWide_0;
    }
    else
    {
        _S14 = false;
    }
    var _S15 : Color53_0;
    if(_S14)
    {
        _S15 = to2020_106_0(_S13);
    }
    else
    {
        if(!wide_0)
        {
            _S14 = srcWide_0;
        }
        else
        {
            _S14 = false;
        }
        if(_S14)
        {
            _S15 = to709_106_0(_S13);
        }
        else
        {
            _S15 = _S13;
        }
    }
    return _S15;
}

fn unpackSource106_0( v_4 : u32) -> vec4<f32>
{
    var _S16 : Color53_0 = inputColor106_0(rawColor106_0(v_4));
    return vec4<f32>(_S16.r_0, _S16.g_0, _S16.b_0, 1.0f);
}

fn srgb53_0( c_4 : f32) -> f32
{
    var _S17 : f32 = max(c_4, 0.0f);
    var _S18 : f32;
    if((_S17 <= 0.0031308000907301903f))
    {
        _S18 = 12.920000076293945f * _S17;
    }
    else
    {
        _S18 = 1.0549999475479126f * pow(_S17, 0.4166666567325592f) - 0.054999999701976776f;
    }
    return _S18;
}

fn hue53_0( p_2 : f32,  q_1 : f32,  t_0 : f32) -> f32
{
    var _S19 : f32 = fract(t_0);
    if((_S19 < 0.1666666716337204f))
    {
        return p_2 + (q_1 - p_2) * 6.0f * _S19;
    }
    if((_S19 < 0.5f))
    {
        return q_1;
    }
    if((_S19 < 0.66666668653488159f))
    {
        return p_2 + (q_1 - p_2) * (0.66666668653488159f - _S19) * 6.0f;
    }
    return p_2;
}

fn gradeLinear106_0( rgb_0 : Color53_0,  frame_0 : i32,  p_3 : TFParams_0) -> Color53_0
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
    var ev_0 : f32 = mix(gradeData_0[i32(5)], gradeData_0[i32(10)], t_1);
    var contrast_0 : f32 = mix(gradeData_0[i32(6)], gradeData_0[i32(11)], t_1);
    var wide_1 : bool = (((p_3.flags_0) & (u32(393216)))) != u32(0);
    var wr_0 : f32;
    if(wide_1)
    {
        wr_0 = 0.26269999146461487f;
    }
    else
    {
        wr_0 = 0.2125999927520752f;
    }
    var wg_0 : f32;
    if(wide_1)
    {
        wg_0 = 0.67799997329711914f;
    }
    else
    {
        wg_0 = 0.71520000696182251f;
    }
    var wb_0 : f32;
    if(wide_1)
    {
        wb_0 = 0.059300001710653305f;
    }
    else
    {
        wb_0 = 0.072200000286102295f;
    }
    var _S20 : f32 = tint_0 * 0.0020000000949949026f;
    var gr_0 : f32 = exp2(temperature_0 * 0.0060000000521540642f + _S20);
    var gg_0 : f32 = exp2(- tint_0 * 0.0040000001899898052f);
    var gb_0 : f32 = exp2(- temperature_0 * 0.0060000000521540642f + _S20);
    var norm_0 : f32 = gr_0 * wr_0 + gg_0 * wg_0 + gb_0 * wb_0;
    var r_2 : f32 = rgb_0.r_0 * gr_0 / norm_0;
    var g_2 : f32 = rgb_0.g_0 * gg_0 / norm_0;
    var b_2 : f32 = rgb_0.b_0 * gb_0 / norm_0;
    var scale_0 : f32 = pow(max(9.9999997473787516e-05f, r_2 * wr_0 + g_2 * wg_0 + b_2 * wb_0) / 0.18000000715255737f, contrast_0 - 1.0f);
    var r_3 : f32 = r_2 * scale_0;
    var g_3 : f32 = g_2 * scale_0;
    var b_3 : f32 = b_2 * scale_0;
    var y_0 : f32 = r_3 * wr_0 + g_3 * wg_0 + b_3 * wb_0;
    var gain_1 : f32 = exp2(ev_0);
    var _S21 : f32 = max(0.0f, (y_0 + sat_0 * (r_3 - y_0)) * gain_1);
    var _S22 : f32 = max(0.0f, (y_0 + sat_0 * (g_3 - y_0)) * gain_1);
    var _S23 : f32 = max(0.0f, (y_0 + sat_0 * (b_3 - y_0)) * gain_1);
    var r_4 : f32;
    var g_4 : f32;
    var b_4 : f32;
    if((gradeData_0[i32(12)] > 0.5f))
    {
        var _S24 : f32 = max(1.0f, max(_S21, max(_S22, _S23)));
        var r_5 : f32 = clamp(srgb53_0(_S21 / _S24), 0.0f, 1.0f);
        var g_5 : f32 = clamp(srgb53_0(_S22 / _S24), 0.0f, 1.0f);
        var b_5 : f32 = clamp(srgb53_0(_S23 / _S24), 0.0f, 1.0f);
        var _S25 : f32 = max(r_5, max(g_5, b_5));
        var _S26 : f32 = min(r_5, min(g_5, b_5));
        var d_0 : f32 = _S25 - _S26;
        var l_0 : f32 = (_S25 + _S26) * 0.5f;
        if((d_0 > 1.00000001168609742e-07f))
        {
            var saturation_0 : f32 = d_0 / max(1.00000001168609742e-07f, 1.0f - abs(2.0f * l_0 - 1.0f));
            if(_S25 == r_5)
            {
                wr_0 = (g_5 - b_5) / d_0;
            }
            else
            {
                if(_S25 == g_5)
                {
                    wr_0 = (b_5 - r_5) / d_0 + 2.0f;
                }
                else
                {
                    wr_0 = (r_5 - g_5) / d_0 + 4.0f;
                }
            }
            var h_0 : f32 = fract(wr_0 / 6.0f);
            var pos_0 : f32 = h_0 * 1024.0f;
            var i_0 : i32 = i32(floor(pos_0));
            var f_0 : f32 = fract(pos_0);
            var offset_0 : i32 = i32(16) + count_0;
            var a_0 : i32 = offset_0 + i_0 % i32(1024) * i32(3);
            var bb_0 : i32 = offset_0 + (i_0 + i32(1)) % i32(1024) * i32(3);
            var chroma_0 : f32 = clamp(saturation_0 / 0.11999999731779099f, 0.0f, 1.0f);
            var h_1 : f32 = fract(h_0 + mix(gradeData_0[a_0], gradeData_0[bb_0], f_0) * chroma_0 / 360.0f);
            var saturation_1 : f32 = clamp(saturation_0 * (1.0f + mix(gradeData_0[a_0 + i32(1)], gradeData_0[bb_0 + i32(1)], f_0) * chroma_0), 0.0f, 1.0f);
            var dl_0 : f32 = mix(gradeData_0[a_0 + i32(2)], gradeData_0[bb_0 + i32(2)], f_0) * chroma_0;
            if((dl_0 >= 0.0f))
            {
                wr_0 = (1.0f - l_0) * dl_0;
            }
            else
            {
                wr_0 = l_0 * dl_0;
            }
            var l_1 : f32 = l_0 + wr_0;
            if((l_1 < 0.5f))
            {
                r_4 = l_1 * (1.0f + saturation_1);
            }
            else
            {
                r_4 = l_1 + saturation_1 - l_1 * saturation_1;
            }
            var pp_0 : f32 = 2.0f * l_1 - r_4;
            var _S27 : f32 = hue53_0(pp_0, r_4, h_1);
            var _S28 : f32 = hue53_0(pp_0, r_4, h_1 - 0.3333333432674408f);
            r_4 = hue53_0(pp_0, r_4, h_1 + 0.3333333432674408f);
            g_4 = _S27;
            b_4 = _S28;
        }
        else
        {
            r_4 = r_5;
            g_4 = g_5;
            b_4 = b_5;
        }
        var _S29 : f32 = linear53_0(g_4) * _S24;
        var _S30 : f32 = linear53_0(b_4) * _S24;
        r_4 = linear53_0(r_4) * _S24;
        g_4 = _S29;
        b_4 = _S30;
    }
    else
    {
        r_4 = _S21;
        g_4 = _S22;
        b_4 = _S23;
    }
    return color53_0(r_4, g_4, b_4);
}

fn grade53_0( rgb_1 : Color53_0,  frame_1 : i32) -> Color53_0
{
    if((gradeData_0[i32(0)] < 0.5f))
    {
        return rgb_1;
    }
    var count_1 : i32 = i32(gradeData_0[i32(1)]);
    var t_2 : f32 = gradeData_0[i32(16.0f + min(f32(frame_1), f32(count_1 - i32(1))))];
    var temperature_1 : f32 = mix(gradeData_0[i32(2)], gradeData_0[i32(7)], t_2);
    var tint_1 : f32 = mix(gradeData_0[i32(3)], gradeData_0[i32(8)], t_2);
    var sat_1 : f32 = mix(gradeData_0[i32(4)], gradeData_0[i32(9)], t_2);
    var _S31 : f32 = tint_1 * 0.0020000000949949026f;
    var gr_1 : f32 = exp2(temperature_1 * 0.0060000000521540642f + _S31);
    var gg_1 : f32 = exp2(- tint_1 * 0.0040000001899898052f);
    var gb_1 : f32 = exp2(- temperature_1 * 0.0060000000521540642f + _S31);
    var norm_1 : f32 = gr_1 * 0.2125999927520752f + gg_1 * 0.71520000696182251f + gb_1 * 0.072200000286102295f;
    var r_6 : f32 = linear53_0(rgb_1.r_0) * (gr_1 / norm_1);
    var g_6 : f32 = linear53_0(rgb_1.g_0) * (gg_1 / norm_1);
    var b_6 : f32 = linear53_0(rgb_1.b_0) * (gb_1 / norm_1);
    var scale_1 : f32 = pow(max(9.9999997473787516e-05f, r_6 * 0.2125999927520752f + g_6 * 0.71520000696182251f + b_6 * 0.072200000286102295f) / 0.18000000715255737f, mix(gradeData_0[i32(6)], gradeData_0[i32(11)], t_2) - 1.0f);
    var r_7 : f32 = r_6 * scale_1;
    var g_7 : f32 = g_6 * scale_1;
    var b_7 : f32 = b_6 * scale_1;
    var y_1 : f32 = r_7 * 0.2125999927520752f + g_7 * 0.71520000696182251f + b_7 * 0.072200000286102295f;
    var _S32 : f32 = exp2(mix(gradeData_0[i32(5)], gradeData_0[i32(10)], t_2));
    var r_8 : f32 = (y_1 + sat_1 * (r_7 - y_1)) * _S32;
    var g_8 : f32 = (y_1 + sat_1 * (g_7 - y_1)) * _S32;
    var b_8 : f32 = (y_1 + sat_1 * (b_7 - y_1)) * _S32;
    var _S33 : f32 = max(1.0f, max(r_8, max(g_8, b_8)));
    var r_9 : f32 = clamp(srgb53_0(r_8 / _S33), 0.0f, 1.0f);
    var g_9 : f32 = clamp(srgb53_0(g_8 / _S33), 0.0f, 1.0f);
    var b_9 : f32 = clamp(srgb53_0(b_8 / _S33), 0.0f, 1.0f);
    var r_10 : f32;
    var g_10 : f32;
    var b_10 : f32;
    if((gradeData_0[i32(12)] > 0.5f))
    {
        var _S34 : f32 = max(r_9, max(g_9, b_9));
        var _S35 : f32 = min(r_9, min(g_9, b_9));
        var d_1 : f32 = _S34 - _S35;
        var l_2 : f32 = (_S34 + _S35) * 0.5f;
        if((d_1 > 1.00000001168609742e-07f))
        {
            var saturation_2 : f32 = d_1 / max(1.00000001168609742e-07f, 1.0f - abs(2.0f * l_2 - 1.0f));
            if(_S34 == r_9)
            {
                r_10 = (g_9 - b_9) / d_1;
            }
            else
            {
                if(_S34 == g_9)
                {
                    r_10 = (b_9 - r_9) / d_1 + 2.0f;
                }
                else
                {
                    r_10 = (r_9 - g_9) / d_1 + 4.0f;
                }
            }
            var h_2 : f32 = fract(r_10 / 6.0f);
            var position_0 : f32 = h_2 * 1024.0f;
            var i_1 : i32 = i32(floor(position_0));
            var f_1 : f32 = fract(position_0);
            var offset_1 : i32 = i32(16) + count_1;
            var a_1 : i32 = offset_1 + i_1 % i32(1024) * i32(3);
            var bb_1 : i32 = offset_1 + (i_1 + i32(1)) % i32(1024) * i32(3);
            var chroma_1 : f32 = clamp(saturation_2 / 0.11999999731779099f, 0.0f, 1.0f);
            var h_3 : f32 = fract(h_2 + mix(gradeData_0[a_1], gradeData_0[bb_1], f_1) * chroma_1 / 360.0f);
            var saturation_3 : f32 = clamp(saturation_2 * (1.0f + mix(gradeData_0[a_1 + i32(1)], gradeData_0[bb_1 + i32(1)], f_1) * chroma_1), 0.0f, 1.0f);
            var dl_1 : f32 = mix(gradeData_0[a_1 + i32(2)], gradeData_0[bb_1 + i32(2)], f_1) * chroma_1;
            if((dl_1 >= 0.0f))
            {
                r_10 = (1.0f - l_2) * dl_1;
            }
            else
            {
                r_10 = l_2 * dl_1;
            }
            var l_3 : f32 = l_2 + r_10;
            if((l_3 < 0.5f))
            {
                r_10 = l_3 * (1.0f + saturation_3);
            }
            else
            {
                r_10 = l_3 + saturation_3 - l_3 * saturation_3;
            }
            var p_4 : f32 = 2.0f * l_3 - r_10;
            var _S36 : f32 = hue53_0(p_4, r_10, h_3);
            var _S37 : f32 = hue53_0(p_4, r_10, h_3 - 0.3333333432674408f);
            r_10 = hue53_0(p_4, r_10, h_3 + 0.3333333432674408f);
            g_10 = _S36;
            b_10 = _S37;
        }
        else
        {
            r_10 = r_9;
            g_10 = g_9;
            b_10 = b_9;
        }
    }
    else
    {
        r_10 = r_9;
        g_10 = g_9;
        b_10 = b_9;
    }
    return color53_0(r_10, g_10, b_10);
}

fn sourceFrame53_0( frame_2 : u32,  pixel_1 : u32,  p_5 : TFParams_0) -> vec4<f32>
{
    var c_5 : vec4<f32>;
    if((((p_5.flags_0) & (u32(64)))) != u32(0))
    {
        var _S38 : u32 = pixel_1 % cfg_0[i32(2)];
        var x_0 : u32 = _S38 + cfg_0[i32(0)];
        var _S39 : u32 = pixel_1 / cfg_0[i32(2)];
        var _S40 : vec2<f32> = vec2<f32>(0.5f);
        var point_0 : vec2<f32> = clamp((vec2<f32>(f32(x_0), f32(_S39 + cfg_0[i32(1)])) + _S40) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)])) * vec2<f32>(f32(cfg_0[i32(10)]), f32(cfg_0[i32(11)])) - _S40, vec2<f32>(0.0f), vec2<f32>(f32(cfg_0[i32(10)] - u32(1)), f32(cfg_0[i32(11)] - u32(1))));
        var _S41 : vec2<u32> = vec2<u32>(floor(point_0));
        var _S42 : vec2<u32> = min(_S41 + vec2<u32>(u32(1)), vec2<u32>(cfg_0[i32(10)] - u32(1), cfg_0[i32(11)] - u32(1)));
        var t_3 : vec2<f32> = fract(point_0);
        var base_0 : u32 = frame_2 * cfg_0[i32(14)] * cfg_0[i32(15)];
        var xa_0 : u32 = _S41.x - cfg_0[i32(12)];
        var xb_0 : u32 = _S42.x - cfg_0[i32(12)];
        var ya_0 : u32 = _S41.y - cfg_0[i32(13)];
        var yb_0 : u32 = _S42.y - cfg_0[i32(13)];
        var _S43 : vec4<f32> = vec4<f32>(t_3.x);
        c_5 = mix(mix(unpackSource106_0(source_0[base_0 + ya_0 * cfg_0[i32(14)] + xa_0]), unpackSource106_0(source_0[base_0 + ya_0 * cfg_0[i32(14)] + xb_0]), _S43), mix(unpackSource106_0(source_0[base_0 + yb_0 * cfg_0[i32(14)] + xa_0]), unpackSource106_0(source_0[base_0 + yb_0 * cfg_0[i32(14)] + xb_0]), _S43), vec4<f32>(t_3.y));
    }
    else
    {
        c_5 = unpackSource106_0(source_0[frame_2 * cfg_0[i32(2)] * cfg_0[i32(3)] + pixel_1]);
    }
    if((((p_5.flags_0) & (u32(128)))) != u32(0))
    {
        var rgb_2 : Color53_0;
        if(linearColor106_0(p_5))
        {
            rgb_2 = gradeLinear106_0(color53_0(c_5.x, c_5.y, c_5.z), i32(frame_2), p_5);
        }
        else
        {
            rgb_2 = grade53_0(color53_0(c_5.x, c_5.y, c_5.z), i32(frame_2));
        }
        c_5 = vec4<f32>(rgb_2.r_0, rgb_2.g_0, rgb_2.b_0, 1.0f);
    }
    return c_5;
}

fn sampleSource_0( n_1 : f32,  pixel_2 : u32,  p_6 : TFParams_0) -> vec4<f32>
{
    var f_2 : f32 = clamp(adjusted3_0(n_1, p_6) * p_6.sourceDuration_0, 0.0f, f32(cfg_0[i32(6)] - u32(1)));
    var a_2 : u32 = u32(floor(f_2));
    var _S44 : u32 = min(a_2 + u32(1), cfg_0[i32(6)] - u32(1));
    var _S45 : vec4<f32> = sourceFrame53_0(a_2, pixel_2, p_6);
    var _S46 : vec4<f32> = sourceFrame53_0(_S44, pixel_2, p_6);
    return mix(_S45, _S46, vec4<f32>((f_2 - f32(a_2))));
}

fn filteredFreeze52_0( p_7 : TFParams_0) -> bool
{
    var _S47 : bool;
    if((p_7.family_0) != u32(0))
    {
        _S47 = true;
    }
    else
    {
        _S47 = (p_7.customMap_0) != u32(0);
    }
    if(_S47)
    {
        _S47 = true;
    }
    else
    {
        _S47 = ((p_7.pixel_0) > 0.0f);
    }
    if(_S47)
    {
        _S47 = true;
    }
    else
    {
        if((p_7.shape_0) != u32(0))
        {
            _S47 = (p_7.shape_0) != u32(1);
        }
        else
        {
            _S47 = false;
        }
        if(_S47)
        {
            _S47 = (p_7.shape_0) != u32(2);
        }
        else
        {
            _S47 = false;
        }
    }
    if(_S47)
    {
        return false;
    }
    if((p_7.shape_0) != u32(2))
    {
        _S47 = ((p_7.direction_0) < u32(2));
    }
    else
    {
        _S47 = false;
    }
    if(_S47)
    {
        _S47 = (p_7.outputW_0) == (p_7.sampleW_0);
    }
    else
    {
        _S47 = false;
    }
    if(_S47)
    {
        _S47 = (p_7.outputH_0) == (p_7.sampleH_0);
    }
    else
    {
        _S47 = false;
    }
    if(_S47)
    {
        var _S48 : f32;
        if((p_7.shape_0) == u32(1))
        {
            _S48 = p_7.sampleH_0;
        }
        else
        {
            _S48 = p_7.sampleW_0;
        }
        var pitch_0 : f32 = _S48 / max(2.0f, p_7.slices_0);
        if(((abs(pitch_0 - round(pitch_0))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    return true;
}

fn stripeGradient52_0( p_8 : TFParams_0) -> vec2<f32>
{
    if((p_8.shape_0) == u32(0))
    {
        return vec2<f32>(1.0f, 0.0f);
    }
    if((p_8.shape_0) == u32(1))
    {
        return vec2<f32>(0.0f, 1.0f);
    }
    var a_3 : f32 = p_8.angle_0 * 3.1415927410125732f / 180.0f;
    var _S49 : f32 = cos(a_3);
    var _S50 : f32 = sin(a_3);
    return vec2<f32>(p_8.outputW_0, p_8.outputH_0) * vec2<f32>(_S49, _S50) / vec2<f32>(max(1.0f, abs(p_8.outputW_0 * _S49) + abs(p_8.outputH_0 * _S50)));
}

fn stripeAxis52_0( uv_0 : vec2<f32>,  p_9 : TFParams_0) -> f32
{
    var gradient_0 : vec2<f32> = stripeGradient52_0(p_9);
    return clamp(dot(uv_0, gradient_0) - min(0.0f, gradient_0.x) - min(0.0f, gradient_0.y), 0.0f, 1.0f);
}

fn tentArea52_0( x_1 : f32) -> f32
{
    var _S51 : f32 = clamp(x_1, -1.0f, 1.0f);
    var _S52 : f32;
    if((_S51 <= 0.0f))
    {
        var _S53 : f32 = _S51 + 1.0f;
        _S52 = 0.5f * _S53 * _S53;
    }
    else
    {
        var _S54 : f32 = 1.0f - _S51;
        _S52 = 1.0f - 0.5f * _S54 * _S54;
    }
    return _S52;
}

struct StripeFootprint52_0
{
     first_0 : f32,
     last_0 : f32,
     low_0 : f32,
     high_0 : f32,
     center_0 : f32,
     step_0 : f32,
     count_2 : f32,
     normalization_0 : f32,
};

fn stripeFootprint52_0( uv_1 : vec2<f32>,  p_10 : TFParams_0) -> StripeFootprint52_0
{
    var gradient_1 : vec2<f32> = abs(stripeGradient52_0(p_10));
    var pixelStep_0 : f32 = gradient_1.x / p_10.sampleW_0 + gradient_1.y / p_10.sampleH_0;
    var f_3 : StripeFootprint52_0;
    var _S55 : f32 = max(2.0f, p_10.slices_0);
    var _S56 : f32;
    if(((p_10.direction_0) >= u32(2)))
    {
        _S56 = 2.0f;
    }
    else
    {
        _S56 = 1.0f;
    }
    var _S57 : f32 = _S55 * _S56;
    f_3.count_2 = _S57;
    var _S58 : f32 = stripeAxis52_0(uv_1, p_10) * _S57;
    f_3.center_0 = _S58;
    var _S59 : f32 = _S57 * pixelStep_0;
    f_3.step_0 = _S59;
    var _S60 : f32 = max(0.0f, _S58 - _S59);
    f_3.low_0 = _S60;
    var _S61 : f32 = min(_S57, _S58 + _S59);
    f_3.high_0 = _S61;
    f_3.first_0 = floor(_S60);
    f_3.last_0 = min(_S57 - 1.0f, ceil(_S61) - 1.0f);
    f_3.normalization_0 = max(9.99999993922529029e-09f, tentArea52_0((_S61 - _S58) / _S59) - tentArea52_0((_S60 - _S58) / _S59));
    return f_3;
}

fn stripeWeight52_0( low_1 : f32,  high_1 : f32,  f_4 : StripeFootprint52_0) -> f32
{
    return max(0.0f, tentArea52_0((high_1 - f_4.center_0) / f_4.step_0) - tentArea52_0((low_1 - f_4.center_0) / f_4.step_0));
}

fn bounce3_0( x_2 : f32) -> f32
{
    return 1.0f - abs(2.0f * fract(x_2 * 0.5f) - 1.0f);
}

struct Field_0
{
     a_4 : f32,
     b_11 : f32,
     weight_0 : f32,
     shade_0 : f32,
     uvA_0 : vec2<f32>,
     uvB_0 : vec2<f32>,
     light_0 : f32,
};

fn single3_0( uv_2 : vec2<f32>,  t_4 : f32) -> Field_0
{
    var f_5 : Field_0;
    f_5.a_4 = t_4;
    f_5.b_11 = t_4;
    f_5.weight_0 = 0.0f;
    f_5.shade_0 = 1.0f;
    f_5.uvA_0 = uv_2;
    f_5.uvB_0 = uv_2;
    f_5.light_0 = 1.0f;
    return f_5;
}

fn creativeAxis42_0( q_2 : f32,  direction_1 : u32) -> f32
{
    if(direction_1 == u32(1))
    {
        return 1.0f - q_2;
    }
    if((direction_1 >= u32(2)))
    {
        var _S62 : f32 = abs(q_2 - 0.5f) * 2.0f;
        var _S63 : f32;
        if(direction_1 == u32(3))
        {
            _S63 = 1.0f - _S62;
        }
        else
        {
            _S63 = _S62;
        }
        return _S63;
    }
    return q_2;
}

fn shadowArea42_0( distance_0 : f32,  solid_0 : f32,  feather_0 : f32) -> f32
{
    var _S64 : f32 = max(0.0f, distance_0);
    var t_5 : f32 = clamp((_S64 - solid_0) / feather_0, 0.0f, 1.0f);
    return min(_S64, solid_0) + feather_0 * t_5 * (1.0f - t_5 * t_5 * (1.0f - 0.5f * t_5));
}

fn repeatedShadowArea42_0( distance_1 : f32,  solid_1 : f32,  feather_1 : f32) -> f32
{
    return floor(distance_1) * (solid_1 + 0.5f * feather_1) + shadowArea42_0(fract(distance_1), solid_1, feather_1);
}

fn filteredLight42_0( distance_2 : f32,  span_1 : f32,  coverage_0 : f32,  filterWidth_0 : f32,  repeat_0 : bool,  p_11 : TFParams_0) -> f32
{
    var _S65 : bool;
    if((span_1 <= 1.0f))
    {
        _S65 = true;
    }
    else
    {
        _S65 = (coverage_0 <= 0.0f);
    }
    if(_S65)
    {
        return 1.0f;
    }
    var _S66 : f32 = min(0.77999997138977051f, max(p_11.shadowWidth_0, 1.5f / span_1));
    var halfPixel_0 : f32 = 0.5f * filterWidth_0 / span_1;
    if((distance_2 > (_S66 + halfPixel_0)))
    {
        if(!repeat_0)
        {
            _S65 = true;
        }
        else
        {
            _S65 = (distance_2 < (1.0f - halfPixel_0));
        }
    }
    else
    {
        _S65 = false;
    }
    if(_S65)
    {
        return 1.0f;
    }
    var feather_2 : f32 = _S66 * max(0.02500000037252903f, p_11.shadowSoftness_0);
    var solid_2 : f32 = _S66 - feather_2;
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
    return 1.0f - p_11.shadowStrength_0 * coverage_0 * (clamp(area_0 / (2.0f * halfPixel_0), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, span_1));
}

fn tiledLight42_0( phase_0 : f32,  span_2 : f32,  coverage_1 : f32,  p_12 : TFParams_0) -> f32
{
    var _S67 : f32;
    if(((p_12.shadowSide_0) > 0.0f))
    {
        _S67 = phase_0;
    }
    else
    {
        _S67 = 1.0f - phase_0;
    }
    return filteredLight42_0(_S67, span_2, coverage_1, 1.2999999523162842f, true, p_12);
}

fn rot3_0( v_5 : vec2<f32>,  a_5 : f32) -> vec2<f32>
{
    var _S68 : f32 = cos(a_5);
    var _S69 : f32 = v_5.x;
    var _S70 : f32 = sin(a_5);
    var _S71 : f32 = v_5.y;
    return vec2<f32>(_S68 * _S69 + _S70 * _S71, - _S70 * _S69 + _S68 * _S71);
}

fn edgeLight42_0( phase_1 : f32,  span_3 : f32,  coverage_2 : f32,  p_13 : TFParams_0) -> f32
{
    var _S72 : f32;
    if(((p_13.shadowSide_0) > 0.0f))
    {
        _S72 = phase_1;
    }
    else
    {
        _S72 = 1.0f - phase_1;
    }
    return filteredLight42_0(_S72, span_3, coverage_2, 1.0f, false, p_13);
}

fn creative42_0( uv_3 : vec2<f32>,  p_14 : TFParams_0) -> Field_0
{
    var center_1 : vec2<f32> = vec2<f32>(p_14.cx_0, p_14.cy_0);
    var metric_0 : vec2<f32> = vec2<f32>(p_14.aspect_0, 1.0f);
    var _S73 : vec2<f32> = uv_3 - center_1;
    var v_6 : vec2<f32> = _S73 * metric_0;
    var clock_0 : f32 = 2.0f * p_14.cycles_0 * p_14.u_0;
    var _S74 : f32 = max(2.0f, p_14.slices_0);
    var f_6 : Field_0 = single3_0(uv_3, bounce3_0(clock_0 + 1.0f));
    switch(p_14.design_0)
    {
    case u32(407):
        {
            var y_2 : f32 = uv_3.y - p_14.cy_0;
            var band_0 : f32 = (creativeAxis42_0(uv_3.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_2 + 0.34999999403953552f * p_14.u_0)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_2 - 0.69999998807907104f * p_14.u_0))), p_14.direction_0) - 0.51999998092651367f * p_14.cycles_0 * p_14.u_0) * _S74;
            var cell_0 : f32 = floor(band_0);
            var t_6 : f32 = bounce3_0(clock_0 - 0.75f * cell_0 / _S74);
            var _S75 : f32 = mix(t_6, 1.0f - t_6, fract(cell_0 * 0.5f) * 2.0f * p_14.span_0);
            f_6.b_11 = _S75;
            f_6.a_4 = _S75;
            if(((p_14.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_0(fract(band_0), p_14.sampleW_0 / _S74, 1.0f, p_14);
            }
        }
    case u32(408):
        {
            var pitch_1 : f32 = sqrt(2.0f * p_14.aspect_0 / (1.7320507764816284f * _S74));
            const basis_0 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_1 : vec2<f32> = rot3_0(v_6, 0.15999999642372131f * sin(6.2831854820251465f * p_14.u_0)) / vec2<f32>(pitch_1);
            var _S76 : vec2<f32> = vec2<f32>(0.5f);
            var a_6 : vec2<f32> = floor(pos_1 / basis_0 + _S76) * basis_0;
            var b_12 : vec2<f32> = floor(pos_1 / basis_0) * basis_0 + basis_0 * _S76;
            var da_0 : vec2<f32> = pos_1 - a_6;
            var db_0 : vec2<f32> = pos_1 - b_12;
            var first_1 : bool = ((dot(da_0, da_0)) <= (dot(db_0, db_0)));
            var cell_1 : vec2<f32>;
            if(first_1)
            {
                cell_1 = a_6;
            }
            else
            {
                cell_1 = b_12;
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
            var _S77 : f32 = cell_1.x;
            var _S78 : f32 = cell_1.y;
            var row_0 : f32 = round(2.0f * _S78 / 1.7320507764816284f);
            var _S79 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_0 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S77 * pitch_1 / p_14.aspect_0, p_14.direction_0) + 0.34000000357627869f * _S78 * pitch_1 + 1.1000000238418579f * fract((round(_S77 - 0.5f * row_0) - row_0) / 3.0f)) * p_14.span_0));
            f_6.b_11 = _S79;
            f_6.a_4 = _S79;
            var _S80 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_0.y)));
            if(((p_14.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_0(0.5f + 0.5f * local_0.x / _S80, 2.0f * _S80 * pitch_1 * p_14.sampleH_0, 1.0f, p_14);
            }
        }
    case u32(409):
        {
            var swing_0 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * p_14.u_0);
            var focal_0 : f32 = 0.2199999988079071f * min(p_14.aspect_0, 1.0f);
            var focus_0 : vec2<f32> = vec2<f32>(cos(swing_0), sin(swing_0)) * vec2<f32>(focal_0);
            var range_0 : f32 = 2.0f * (max(length(max(center_1, vec2<f32>(1.0f) - center_1) * metric_0), 0.0010000000474974513f) - focal_0) + 0.039999999105930328f;
            var band_1 : f32 = creativeAxis42_0(clamp((length(v_6 - focus_0) + length(v_6 + focus_0) - 2.0f * focal_0) / max(0.019999999552965164f, range_0), 0.0f, 1.0f), p_14.direction_0) * _S74 - 0.77999997138977051f * p_14.cycles_0 * p_14.u_0;
            var cell_2 : f32 = floor(band_1);
            var t_7 : f32 = bounce3_0(clock_0 - p_14.span_0 * cell_2 / _S74);
            var _S81 : f32 = mix(t_7, 1.0f - t_7, 0.80000001192092896f * fract(cell_2 * 0.5f) * 2.0f);
            f_6.b_11 = _S81;
            f_6.a_4 = _S81;
            if(((p_14.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_0(fract(band_1), range_0 * 0.5f * p_14.sampleH_0 / _S74, 1.0f, p_14);
            }
        }
    case u32(410):
        {
            var _S82 : f32 = min(3.0f, _S74);
            var shift_0 : vec2<f32> = _S73 + vec2<f32>(0.5f);
            var _S83 : f32 = shift_0.y * _S82;
            var row_1 : f32 = floor(_S83);
            var base_1 : f32 = floor(_S74 / _S82);
            var _S84 : i32;
            if(((clamp(row_1, 0.0f, _S82 - 1.0f)) < (_S74 - base_1 * _S82)))
            {
                _S84 = i32(1);
            }
            else
            {
                _S84 = i32(0);
            }
            var cols_0 : f32 = base_1 + f32(_S84);
            var x_3 : f32 = shift_0.x * cols_0 - (0.62999999523162842f + 0.12999999523162842f * row_1) * p_14.cycles_0 * creativeAxis42_0(p_14.u_0, p_14.direction_0) + 0.36000001430511475f * row_1;
            var col_0 : f32 = floor(x_3);
            var _S85 : f32 = fract(x_3) - 0.5f;
            var _S86 : f32 = fract(_S83) - 0.5f;
            var roundBox_0 : vec2<f32> = abs(vec2<f32>(_S85, _S86)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_0 : f32 = length(max(roundBox_0, vec2<f32>(0.0f))) + min(max(roundBox_0.x, roundBox_0.y), 0.0f) - 0.075000002980232239f;
            var aa_0 : f32 = max(cols_0 / p_14.sampleW_0, _S82 / p_14.sampleH_0) * 1.1000000238418579f;
            f_6.a_4 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_0 + 0.69999998807907104f);
            f_6.b_11 = bounce3_0(clock_0 - 0.40999999642372131f * col_0 - 0.28999999165534973f * row_1) * p_14.span_0 + 0.039999999105930328f;
            f_6.weight_0 = 1.0f - smoothstep(- aa_0, aa_0, edge_0);
            var _S87 : f32 = max(0.0f, abs(_S86) - 0.33000001311302185f);
            var bound_0 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S87 * _S87));
            if(((p_14.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * _S85 / bound_0, 0.0f, 1.0f), 2.0f * bound_0 * p_14.sampleW_0 / cols_0, f_6.weight_0, p_14);
            }
        }
    default :
        {
        }
    }
    return f_6;
}

fn axisAngle3_0( y_3 : f32,  x_4 : f32) -> f32
{
    var _S88 : f32 = abs(x_4);
    var _S89 : f32 = abs(y_3);
    if(((_S88 + _S89) < 9.99999997475242708e-07f))
    {
        return 0.0f;
    }
    var _S90 : f32;
    if((_S89 < 9.99999997475242708e-07f))
    {
        if((x_4 < 0.0f))
        {
            _S90 = 3.1415927410125732f;
        }
        else
        {
            _S90 = 0.0f;
        }
        return _S90;
    }
    if((_S88 < 9.99999997475242708e-07f))
    {
        if((y_3 > 0.0f))
        {
            _S90 = 1.5707963705062866f;
        }
        else
        {
            _S90 = -1.5707963705062866f;
        }
        return _S90;
    }
    return atan2(y_3, x_4);
}

fn gridSize3_0( n_2 : f32,  size_0 : vec2<f32>) -> vec2<f32>
{
    var _S91 : f32 = size_0.y;
    var rows_0 : f32 = clamp(round(sqrt(n_2 * _S91 / size_0.x)), 1.0f, min(_S91, n_2));
    return vec2<f32>(floor(n_2 / rows_0), rows_0);
}

fn isStripe42_0( p_15 : TFParams_0) -> bool
{
    var _S92 : bool;
    if((p_15.customMap_0) == u32(0))
    {
        _S92 = ((p_15.direction_0) < u32(2));
    }
    else
    {
        _S92 = false;
    }
    if(_S92)
    {
        if((p_15.shape_0) == u32(0))
        {
            _S92 = true;
        }
        else
        {
            _S92 = (p_15.shape_0) == u32(1);
        }
        if(_S92)
        {
            _S92 = true;
        }
        else
        {
            _S92 = (p_15.shape_0) == u32(11);
        }
    }
    else
    {
        _S92 = false;
    }
    return _S92;
}

fn rasterStripeIndex42_0( pixel_3 : f32,  lengthPx_0 : f32,  count_3 : f32) -> f32
{
    if(((max(lengthPx_0, count_3)) <= 32768.0f))
    {
        var index_0 : u32 = (u32(2) * u32(pixel_3) + u32(1)) * u32(count_3) / (u32(2) * u32(lengthPx_0));
        return min(f32(index_0), count_3 - 1.0f);
    }
    return min(floor((pixel_3 + 0.5f) * count_3 / lengthPx_0), count_3 - 1.0f);
}

struct Coord_0
{
     raw_0 : f32,
     q_3 : f32,
     index_1 : f32,
     coverage_3 : f32,
     cell_3 : vec2<f32>,
     frac_0 : vec2<f32>,
};

fn coordinate3_0( uv_4 : vec2<f32>,  p_16 : TFParams_0,  mapValue_0 : f32) -> Coord_0
{
    var c_6 : Coord_0;
    var _S93 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_6.cell_3 = _S93;
    c_6.frac_0 = _S93;
    c_6.index_1 = 0.0f;
    c_6.coverage_3 = 1.0f;
    var _S94 : f32 = uv_4.x;
    var _S95 : f32 = max(2.0f, p_16.slices_0);
    var dim_0 : vec2<f32> = vec2<f32>(p_16.outputW_0, p_16.outputH_0);
    var _S96 : vec2<f32> = vec2<f32>(p_16.cx_0, p_16.cy_0);
    var v_7 : vec2<f32> = (uv_4 - _S96) * dim_0;
    var _S97 : vec2<f32> = vec2<f32>(1.0f);
    var radii_0 : vec2<f32> = max(_S96, _S97 - _S96) * dim_0;
    var _S98 : f32 = max(length(radii_0), 1.0f);
    var rmin_0 : f32 = length(max(_S93, max((vec2<f32>(0) - _S96), _S96 - _S97)) * dim_0);
    var q_4 : f32;
    var lengthPx_1 : f32;
    var _S99 : i32;
    var _S100 : bool;
    switch(p_16.shape_0)
    {
    case u32(0):
        {
            q_4 = _S94;
        }
    case u32(1):
        {
            q_4 = uv_4.y;
        }
    case u32(2), u32(12):
        {
            var a_7 : f32 = p_16.angle_0 * 3.1415927410125732f / 180.0f;
            var _S101 : f32 = cos(a_7);
            var _S102 : f32 = sin(a_7);
            var _S103 : f32 = p_16.outputW_0 * _S101;
            var _S104 : f32 = p_16.outputH_0 * _S102;
            var q_5 : f32 = (dot(uv_4 * dim_0, vec2<f32>(_S101, _S102)) - (min(0.0f, _S103) + min(0.0f, _S104))) / max(1.0f, abs(_S103) + abs(_S104));
            if((p_16.shape_0) == u32(12))
            {
                q_4 = q_5 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(uv_4.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_4 = q_5;
            }
        }
    case u32(3):
        {
            switch(p_16.origin_0)
            {
            case u32(1):
                {
                    q_4 = axisAngle3_0(v_7.y, v_7.x);
                }
            case u32(2):
                {
                    q_4 = axisAngle3_0(v_7.x, - v_7.y);
                }
            case u32(3):
                {
                    q_4 = axisAngle3_0(- v_7.x, v_7.y);
                }
            default :
                {
                    q_4 = axisAngle3_0(- v_7.y, - v_7.x);
                }
            }
            if((q_4 >= 0.0f))
            {
                _S100 = (q_4 <= 3.1415927410125732f);
            }
            else
            {
                _S100 = false;
            }
            if(_S100)
            {
                _S99 = i32(1);
            }
            else
            {
                _S99 = i32(0);
            }
            c_6.coverage_3 = f32(_S99);
            q_4 = clamp(q_4 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            var startAngle_0 : f32 = p_16.angle_0 / 360.0f;
            var _S105 : f32 = v_7.x;
            var _S106 : f32 = v_7.y;
            var _S107 : f32 = axisAngle3_0(_S105, - _S106);
            var _S108 : f32 = abs(_S105);
            var _S109 : f32 = abs(_S106);
            if(((_S108 + _S109) < 9.99999997475242708e-07f))
            {
                q_4 = 0.0f;
            }
            else
            {
                if((_S109 < 9.99999997475242708e-07f))
                {
                    if((_S105 > 0.0f))
                    {
                        q_4 = 1.5707963705062866f;
                    }
                    else
                    {
                        q_4 = -1.5707963705062866f;
                    }
                }
                else
                {
                    if((_S108 < 9.99999997475242708e-07f))
                    {
                        if((_S106 < 0.0f))
                        {
                            q_4 = 0.0f;
                        }
                        else
                        {
                            q_4 = 3.1415927410125732f;
                        }
                    }
                    else
                    {
                        q_4 = _S107;
                    }
                }
            }
            q_4 = fract(q_4 / 6.2831854820251465f + 1.0f - p_16.turns_0 * p_16.u_0 - startAngle_0);
        }
    case u32(5), u32(14):
        {
            q_4 = (length(v_7) - rmin_0) / max(1.0f, _S98 - rmin_0);
        }
    case u32(6), u32(7):
        {
            var vr_0 : vec2<f32> = rot3_0(v_7, p_16.angle_0 * 3.1415927410125732f / 180.0f + p_16.turns_0 * 2.0f * 3.1415927410125732f * p_16.u_0);
            if((p_16.shape_0) == u32(6))
            {
                q_4 = (abs(vr_0.x) + abs(vr_0.y)) / max(1.0f, radii_0.x + radii_0.y);
            }
            else
            {
                q_4 = max(abs(vr_0.x) / max(radii_0.x, 1.0f), abs(vr_0.y) / max(radii_0.y, 1.0f));
            }
        }
    case u32(8), u32(10):
        {
            var _S110 : bool = (p_16.shape_0) == u32(10);
            if(_S110)
            {
                q_4 = max(1.0f, ceil(_S95 / 2.0f));
            }
            else
            {
                q_4 = _S95;
            }
            var gs_0 : vec2<f32> = gridSize3_0(q_4, dim_0);
            var _S111 : f32 = gs_0.y;
            var _S112 : f32 = uv_4.y * _S111;
            var _S113 : f32 = min(floor(_S112), _S111 - 1.0f);
            var _S114 : f32 = gs_0.x;
            var extra_0 : f32 = q_4 - _S114 * _S111;
            if((_S113 < extra_0))
            {
                _S99 = i32(1);
            }
            else
            {
                _S99 = i32(0);
            }
            var cols_1 : f32 = _S114 + f32(_S99);
            var _S115 : f32 = _S94 * cols_1;
            var _S116 : f32 = min(floor(_S115), cols_1 - 1.0f);
            var index_2 : f32 = _S113 * _S114 + min(_S113, extra_0) + _S116;
            c_6.cell_3 = vec2<f32>(_S116, _S113);
            c_6.frac_0 = fract(vec2<f32>(_S115, _S112));
            if(_S110)
            {
                var _S117 : f32 = _S95 - 1.0f;
                var _S118 : f32 = index_2 * 2.0f;
                if(((c_6.frac_0.x + c_6.frac_0.y) >= 1.0f))
                {
                    _S99 = i32(1);
                }
                else
                {
                    _S99 = i32(0);
                }
                lengthPx_1 = min(_S117, _S118 + f32(_S99));
            }
            else
            {
                lengthPx_1 = index_2;
            }
            q_4 = lengthPx_1 / max(1.0f, _S95 - 1.0f);
        }
    case u32(9):
        {
            q_4 = fract(axisAngle3_0(v_7.y, v_7.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_7) / _S98));
        }
    case u32(11):
        {
            q_4 = _S94;
        }
    case u32(13):
        {
            q_4 = length(v_7) / max(1.0f, _S98 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * axisAngle3_0(v_7.y, v_7.x))));
        }
    default :
        {
            q_4 = _S94;
        }
    }
    if((p_16.customMap_0) != u32(0))
    {
        c_6.coverage_3 = 1.0f;
        q_4 = mapValue_0;
    }
    var q_6 : f32 = clamp(q_4, 0.0f, 1.0f);
    var _S119 : bool = (p_16.direction_0) == u32(1);
    if(_S119)
    {
        q_4 = 1.0f - q_6;
    }
    else
    {
        q_4 = q_6;
    }
    if(((p_16.direction_0) >= u32(2)))
    {
        if((p_16.shape_0) == u32(8))
        {
            _S100 = true;
        }
        else
        {
            _S100 = (p_16.shape_0) == u32(10);
        }
        if(_S100)
        {
            q_4 = max(abs(_S94 - 0.5f), abs(uv_4.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_4 = abs(q_4 - 0.5f) * 2.0f;
        }
        if((p_16.direction_0) == u32(3))
        {
            q_4 = 1.0f - q_4;
        }
    }
    c_6.raw_0 = q_4;
    var _S120 : f32 = q_4 * _S95;
    var _S121 : f32 = _S95 - 1.0f;
    c_6.index_1 = min(floor(_S120), _S121);
    var edge_1 : f32 = round(_S120);
    if(((abs(_S120 - edge_1)) < 9.9999997473787516e-05f))
    {
        c_6.raw_0 = edge_1 / _S95;
        c_6.index_1 = min(edge_1, _S121);
    }
    if(isStripe42_0(p_16))
    {
        _S100 = ((p_16.reserved0_0) <= 0.0f);
    }
    else
    {
        _S100 = false;
    }
    if(_S100)
    {
        var _S122 : bool = (p_16.shape_0) == u32(1);
        if(_S122)
        {
            lengthPx_1 = p_16.sampleH_0;
        }
        else
        {
            lengthPx_1 = p_16.sampleW_0;
        }
        var _S123 : f32;
        if(_S122)
        {
            _S123 = uv_4.y;
        }
        else
        {
            _S123 = _S94;
        }
        var pixel_4 : f32 = floor(_S123 * lengthPx_1);
        if(_S119)
        {
            _S123 = lengthPx_1 - 1.0f - pixel_4;
        }
        else
        {
            _S123 = pixel_4;
        }
        var _S124 : f32 = rasterStripeIndex42_0(_S123, lengthPx_1, _S95);
        c_6.index_1 = _S124;
    }
    if(((p_16.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_4 = c_6.index_1 / _S121;
    }
    c_6.q_3 = q_4;
    return c_6;
}

fn play3_0( x_5 : f32,  mode_0 : u32) -> f32
{
    var _S125 : f32;
    if(mode_0 == u32(0))
    {
        _S125 = clamp(x_5, 0.0f, 1.0f);
    }
    else
    {
        if(mode_0 == u32(2))
        {
            _S125 = fract(x_5);
        }
        else
        {
            _S125 = bounce3_0(x_5);
        }
    }
    return _S125;
}

fn creative3_0( uv_5 : vec2<f32>,  c_7 : Coord_0,  p_17 : TFParams_0) -> Field_0
{
    var clock_1 : f32 = 2.0f * p_17.cycles_0 * p_17.u_0;
    var _S126 : f32 = max(2.0f, p_17.slices_0);
    var center_2 : vec2<f32> = vec2<f32>(p_17.cx_0, p_17.cy_0);
    var metric_1 : vec2<f32> = vec2<f32>(p_17.aspect_0, 1.0f);
    var v_8 : vec2<f32> = (uv_5 - center_2) * metric_1;
    var _S127 : f32 = bounce3_0(clock_1);
    var f_7 : Field_0 = single3_0(uv_5, _S127);
    var band_2 : f32;
    var phase_2 : f32;
    var lateral_0 : f32;
    var q_7 : f32;
    var i_2 : i32;
    var horizontal_0 : bool;
    switch(p_17.design_0)
    {
    case u32(9):
        {
            var _S128 : f32 = length(v_8);
            var phase_3 : f32 = fract(2.0f * (axisAngle3_0(v_8.x, - v_8.y) / 6.2831854820251465f) + _S128 / max(length(metric_1 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * p_17.span_0);
            var _S129 : bool = ((p_17.pixel_0) > 0.0f);
            if(_S129)
            {
                band_2 = phase_3 - p_17.cycles_0 * p_17.u_0;
            }
            else
            {
                band_2 = phase_3 * _S126;
            }
            if((p_17.pixel_0) == 0.0f)
            {
                phase_2 = floor(band_2) / (_S126 - 1.0f);
            }
            else
            {
                phase_2 = phase_3;
            }
            var _S130 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(p_17.cycles_0 * p_17.u_0 - phase_2);
            f_7.b_11 = _S130;
            f_7.a_4 = _S130;
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                var _S131 : f32 = fract(band_2);
                var _S132 : f32 = min(3.1415927410125732f * _S128 * p_17.sampleH_0, p_17.sampleH_0);
                if(_S129)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = _S126;
                }
                f_7.light_0 = tiledLight42_0(_S131, _S132 / band_2, 1.0f, p_17);
            }
        }
    case u32(10):
        {
            var q_8 : f32 = clamp(1.0f - abs(uv_5.x - p_17.cx_0) * 2.0f, 0.0f, 1.0f);
            var _S133 : f32 = _S126 - 1.0f;
            var band_3 : f32 = q_8 * _S133;
            if((p_17.pixel_0) == 0.0f)
            {
                q_7 = floor(band_3) / _S133;
            }
            else
            {
                q_7 = q_8;
            }
            var _S134 : f32 = 0.80000001192092896f * p_17.span_0;
            var _S135 : f32 = _S134 * q_7;
            var _S136 : f32 = bounce3_0(clock_1 - _S135);
            f_7.b_11 = _S136;
            f_7.a_4 = _S136;
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                var _S137 : bool = ((p_17.pixel_0) > 0.0f);
                if(_S137)
                {
                    band_2 = _S135 - clock_1;
                }
                else
                {
                    band_2 = band_3;
                }
                var _S138 : f32 = fract(band_2);
                var _S139 : f32 = 0.5f * p_17.sampleW_0;
                if(_S137)
                {
                    band_2 = _S134;
                }
                else
                {
                    band_2 = _S133;
                }
                f_7.light_0 = tiledLight42_0(_S138, _S139 / band_2, 1.0f, p_17);
            }
        }
    case u32(11):
        {
            var _S140 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, p_17.softness_0 * 0.15999999642372131f);
            var _S141 : f32 = c_7.frac_0.y;
            var ah_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S140, abs(_S141 - 0.5f));
            var _S142 : f32 = c_7.frac_0.x;
            var av_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S140, abs(_S142 - 0.5f));
            var _S143 : f32 = c_7.cell_3.y;
            var over_0 : bool = (i32(floor(c_7.cell_3.x) + floor(_S143)) % i32(2)) == i32(0);
            var ht_0 : f32 = bounce3_0(clock_1 - uv_5.x * p_17.span_0);
            var vt_0 : f32 = bounce3_0(clock_1 + uv_5.y * p_17.span_0 + 1.0f);
            var _S144 : bool = (ah_0 > 0.0f);
            if(_S144)
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
                f_7.a_4 = band_2;
                if(over_0)
                {
                    band_2 = ht_0;
                }
                else
                {
                    band_2 = vt_0;
                }
                f_7.b_11 = band_2;
                if(over_0)
                {
                    band_2 = ah_0;
                }
                else
                {
                    band_2 = av_0;
                }
                f_7.weight_0 = band_2;
                if(ah_0 == 0.0f)
                {
                    f_7.b_11 = vt_0;
                    f_7.a_4 = vt_0;
                }
                if(av_0 == 0.0f)
                {
                    f_7.b_11 = ht_0;
                    f_7.a_4 = ht_0;
                }
            }
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                if(_S144)
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
                    if(_S144)
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
                    phase_2 = _S141;
                }
                else
                {
                    phase_2 = _S142;
                }
                var phase_4 : f32 = clamp((phase_2 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_0 : vec2<f32> = gridSize3_0(_S126, vec2<f32>(p_17.outputW_0, p_17.outputH_0));
                var _S145 : f32 = grid_0.x;
                var _S146 : f32 = grid_0.y;
                if((_S143 < (_S126 - _S145 * _S146)))
                {
                    i_2 = i32(1);
                }
                else
                {
                    i_2 = i32(0);
                }
                var cols_2 : f32 = _S145 + f32(i_2);
                if(horizontal_0)
                {
                    phase_2 = p_17.sampleH_0 / _S146;
                }
                else
                {
                    phase_2 = p_17.sampleW_0 / cols_2;
                }
                f_7.light_0 = edgeLight42_0(phase_4, 0.47999998927116394f * phase_2, band_2, p_17);
            }
        }
    case u32(12):
        {
            var sources_0 : u32 = clamp(p_17.waveSources_0, u32(2), u32(4));
            var i_3 : u32 = u32(0);
            band_2 = 0.0f;
            loop
            {
                if((i_3 < sources_0))
                {
                }
                else
                {
                    break;
                }
                var a_8 : f32 = 6.2831854820251465f * f32(i_3) / f32(sources_0);
                var r_11 : f32 = length((uv_5 - (center_2 + vec2<f32>(0.18000000715255737f * cos(a_8), 0.18000000715255737f * sin(a_8)))) * metric_1);
                var band_4 : f32 = r_11 * _S126;
                if((p_17.pixel_0) == 0.0f)
                {
                    phase_2 = floor(band_4) / _S126;
                }
                else
                {
                    phase_2 = r_11;
                }
                var _S147 : f32 = phase_2 * 1.2999999523162842f * p_17.span_0;
                var sum_0 : f32 = band_2 + bounce3_0(clock_1 - _S147);
                if(((p_17.shadowStrength_0) > 0.0f))
                {
                    var _S148 : bool = ((p_17.pixel_0) > 0.0f);
                    if(_S148)
                    {
                        lateral_0 = _S147 - clock_1;
                    }
                    else
                    {
                        lateral_0 = band_4;
                    }
                    var phase_5 : f32 = fract(lateral_0);
                    var _S149 : f32 = f_7.light_0;
                    if(_S148)
                    {
                        q_7 = 1.2999999523162842f * p_17.span_0;
                    }
                    else
                    {
                        q_7 = _S126;
                    }
                    f_7.light_0 = min(_S149, tiledLight42_0(phase_5, p_17.sampleH_0 / q_7, 1.0f, p_17));
                }
                i_3 = i_3 + u32(1);
                band_2 = sum_0;
            }
            var _S150 : f32 = band_2 / f32(sources_0);
            f_7.b_11 = _S150;
            f_7.a_4 = _S150;
        }
    case u32(13):
        {
            var _S151 : f32 = 6.2831854820251465f * p_17.u_0;
            var _S152 : f32 = sin(_S151);
            var local_1 : vec2<f32> = (uv_5 - (center_2 + vec2<f32>(0.2199999988079071f * _S152, 0.12999999523162842f * cos(_S151)))) * metric_1;
            var r_12 : f32 = length(local_1);
            var radius_0 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S152;
            var _S153 : f32 = max(0.0020000000949949026f, p_17.softness_0 * 0.15999999642372131f);
            f_7.b_11 = bounce3_0(clock_1 + 0.80000001192092896f * p_17.span_0);
            f_7.weight_0 = 1.0f - smoothstep(radius_0 - _S153, radius_0 + _S153, r_12);
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                horizontal_0 = ((f_7.weight_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S154 : f32 = local_1.y;
                var halfWidth_0 : f32 = sqrt(max(9.99999997475242708e-07f, radius_0 * radius_0 - _S154 * _S154));
                f_7.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * local_1.x / halfWidth_0, 0.0f, 1.0f), 2.0f * halfWidth_0 * p_17.sampleH_0, f_7.weight_0, p_17);
            }
        }
    case u32(400):
        {
            var _S155 : f32 = max(_S126, 2.0f);
            var gap_0 : f32 = 0.64999997615814209f / _S155;
            var d_2 : f32 = fract(p_17.u_0 * p_17.cycles_0) * 1.6499999761581421f - uv_5.x;
            var j_0 : f32 = floor(d_2 / gap_0);
            var local_2 : f32 = fract(d_2 / gap_0);
            if((j_0 >= 0.0f))
            {
                horizontal_0 = (j_0 < _S155);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S156 : f32 = max(0.014999999664723873f, p_17.softness_0 * 0.15000000596046448f);
                var a_9 : f32 = smoothstep(0.0f, _S156, local_2) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S156, local_2));
                f_7.b_11 = clamp(1.0f - j_0 / _S155, 0.0f, 1.0f);
                f_7.weight_0 = a_9 * (1.0f - 0.64999997615814209f * j_0 / _S155);
            }
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                f_7.light_0 = edgeLight42_0(clamp(1.0f - local_2 / 0.64999997615814209f, 0.0f, 1.0f), gap_0 * 0.64999997615814209f * p_17.sampleW_0, f_7.weight_0, p_17);
            }
        }
    case u32(401):
        {
            var _S157 : f32 = uv_5.y;
            if((i32(floor(_S157 * _S126)) % i32(2)) == i32(0))
            {
                band_2 = 1.0f;
            }
            else
            {
                band_2 = -1.0f;
            }
            var gap_1 : f32 = 0.34999999403953552f * smoothstep(_S127 - 0.059999998658895493f, _S127 + 0.059999998658895493f, _S157);
            var seam_0 : f32 = p_17.cx_0 + band_2 * 0.02500000037252903f;
            var _S158 : f32 = uv_5.x;
            var _S159 : f32 = _S158 - seam_0;
            var outside_0 : bool = ((abs(_S159)) > gap_1);
            if(outside_0)
            {
                if((_S158 < seam_0))
                {
                    band_2 = 0.079999998211860657f;
                }
                else
                {
                    band_2 = 0.94999998807907104f;
                }
                f_7.b_11 = band_2;
                f_7.a_4 = band_2;
            }
            var _S160 : bool = ((p_17.shadowStrength_0) > 0.0f);
            if(_S160)
            {
                var _S161 : f32 = clamp((_S159 + gap_1) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S162 : f32 = 0.2199999988079071f * p_17.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S158 < seam_0);
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
                f_7.light_0 = edgeLight42_0(_S161, _S162, band_2, p_17);
            }
            if(_S160)
            {
                horizontal_0 = ((p_17.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S163 : f32 = clamp((_S159 - gap_1) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S164 : f32 = 0.2199999988079071f * p_17.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S158 > seam_0);
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
                f_7.light_0 = edgeLight42_0(_S163, _S164, band_2, p_17);
            }
        }
    case u32(402):
        {
            var a_10 : f32 = axisAngle3_0(v_8.y, v_8.x);
            var r_13 : f32 = length(v_8);
            var radius_1 : f32 = 0.4699999988079071f * min(p_17.aspect_0, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * p_17.u_0 * p_17.cycles_0)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_10 * _S126));
            var _S165 : f32 = max(0.0010000000474974513f, p_17.softness_0 * 0.019999999552965164f);
            var _S166 : f32 = fract((a_10 + 3.1415927410125732f) / 6.2831854820251465f) * _S126;
            f_7.b_11 = bounce3_0(clock_1 + floor(_S166) / _S126 * p_17.span_0);
            f_7.weight_0 = 1.0f - smoothstep(radius_1 - _S165, radius_1 + _S165, r_13);
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                f_7.light_0 = tiledLight42_0(fract(_S166), 6.2831854820251465f * r_13 * p_17.sampleH_0 / _S126, f_7.weight_0, p_17);
            }
        }
    case u32(403):
        {
            var r_14 : f32 = length(v_8);
            var _S167 : f32 = max(3.0f, _S126);
            var sector_0 : f32 = 6.2831854820251465f / _S167;
            var _S168 : f32 = axisAngle3_0(v_8.y, v_8.x) + p_17.u_0 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_0 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * p_17.u_0 * p_17.cycles_0))) * min(p_17.aspect_0, 1.0f) * cos(3.1415927410125732f / _S167) / max(0.0010000000474974513f, cos(fract(_S168 / sector_0) * sector_0 - sector_0 * 0.5f));
            f_7.a_4 = bounce3_0(clock_1 - p_17.span_0 * floor(fract(_S168 / 6.2831854820251465f) * _S167) / _S167);
            f_7.b_11 = bounce3_0(clock_1 + 1.0f);
            f_7.weight_0 = 1.0f - smoothstep(aperture_0 - 0.0020000000949949026f, aperture_0 + 0.0020000000949949026f, r_14);
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                f_7.light_0 = tiledLight42_0(fract(_S168 / sector_0), sector_0 * r_14 * p_17.sampleH_0, 1.0f - f_7.weight_0, p_17);
            }
        }
    case u32(404):
        {
            var _S169 : f32 = fract(p_17.u_0 * p_17.cycles_0);
            band_2 = 1.0e+09f;
            phase_2 = 0.0f;
            lateral_0 = 0.0f;
            i_2 = i32(0);
            loop
            {
                if((i_2 < i32(32)))
                {
                }
                else
                {
                    break;
                }
                var _S170 : f32 = f32(i_2);
                var a0_0 : f32 = 6.2831854820251465f * _S170 / 32.0f;
                var _S171 : i32 = i_2 + i32(1);
                var a1_0 : f32 = 6.2831854820251465f * f32(_S171) / 32.0f;
                var a_11 : vec2<f32> = center_2 + vec2<f32>(0.34000000357627869f * sin(a0_0), 0.2199999988079071f * sin(2.0f * a0_0));
                var segment_0 : vec2<f32> = (center_2 + vec2<f32>(0.34000000357627869f * sin(a1_0), 0.2199999988079071f * sin(2.0f * a1_0)) - a_11) * metric_1;
                var point_1 : vec2<f32> = (uv_5 - a_11) * metric_1;
                var k_0 : f32 = clamp(dot(point_1, segment_0) / max(dot(segment_0, segment_0), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_0 : vec2<f32> = point_1 - vec2<f32>(k_0) * segment_0;
                var distance_3 : f32 = dot(delta_0, delta_0);
                var trail_0 : f32 = fract(_S169 - (_S170 + k_0) / 32.0f + 1.0f);
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
                    if(((p_17.shadowStrength_0) > 0.0f))
                    {
                        if(((dot(delta_0, vec2<f32>(segment_0.y, - segment_0.x))) >= 0.0f))
                        {
                            q_7 = 1.0f;
                        }
                        else
                        {
                            q_7 = -1.0f;
                        }
                    }
                    else
                    {
                        q_7 = lateral_0;
                    }
                    band_2 = distance_3;
                    phase_2 = trail_0;
                    lateral_0 = q_7;
                }
                i_2 = _S171;
            }
            var _S172 : f32 = max(0.0020000000949949026f, p_17.softness_0 * 0.039999999105930328f);
            var best_0 : f32 = sqrt(band_2);
            f_7.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S172, 0.035000000149011612f + _S172, best_0);
            var q_9 : f32 = phase_2 / 0.60000002384185791f;
            if((p_17.pixel_0) == 0.0f)
            {
                q_7 = floor(q_9 * _S126) / (_S126 - 1.0f);
            }
            else
            {
                q_7 = q_9;
            }
            f_7.b_11 = 0.15000000596046448f + 0.85000002384185791f * q_7;
            if(((p_17.shadowStrength_0) > 0.0f))
            {
                f_7.light_0 = edgeLight42_0(clamp(0.5f + best_0 * lateral_0 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * p_17.sampleH_0, f_7.weight_0, p_17);
            }
        }
    default :
        {
        }
    }
    return f_7;
}

fn frozen3_0( uv_6 : vec2<f32>,  c_8 : Coord_0,  p_18 : TFParams_0) -> Field_0
{
    var build_1 : f32 = clamp(p_18.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var _S173 : bool = ((p_18.pixel_0) > 0.0f);
    var held_0 : f32;
    if(_S173)
    {
        held_0 = c_8.raw_0;
    }
    else
    {
        held_0 = min(1.0f, (c_8.index_1 + 1.0f) / max(2.0f, p_18.slices_0));
    }
    if((((p_18.flags_0) & (u32(1024)))) != u32(0))
    {
        var skip_0 : f32 = clamp(p_18.reserved1_0, 0.0f, 1.0f);
        var _S174 : f32 = held_0 * (1.0f - skip_0);
        if((held_0 > 0.5f))
        {
            held_0 = skip_0;
        }
        else
        {
            held_0 = 0.0f;
        }
        held_0 = _S174 + held_0;
    }
    var a_12 : f32;
    if(((p_18.u_0) < build_1))
    {
        var progress_0 : f32 = p_18.u_0 / build_1;
        var _S175 : bool;
        if(_S173)
        {
            _S175 = true;
        }
        else
        {
            _S175 = (((p_18.flags_0) & (u32(1)))) != u32(0);
        }
        if(_S175)
        {
            var _S176 : f32 = max(1.0f / max(p_18.outputW_0, p_18.outputH_0), p_18.softness_0 * 0.0030000000260770321f);
            a_12 = 1.0f - smoothstep(progress_0 - _S176, progress_0 + _S176, c_8.raw_0);
        }
        else
        {
            var _S177 : i32;
            if((progress_0 >= (c_8.q_3)))
            {
                _S177 = i32(1);
            }
            else
            {
                _S177 = i32(0);
            }
            a_12 = f32(_S177);
        }
        var f_8 : Field_0 = single3_0(uv_6, progress_0);
        f_8.b_11 = held_0;
        f_8.weight_0 = a_12;
        return f_8;
    }
    var after_0 : f32 = clamp((p_18.u_0 - build_1) / (1.0f - build_1), 0.0f, 1.0f);
    switch(p_18.ending_0)
    {
    case u32(0):
        {
            a_12 = held_0;
        }
    case u32(1):
        {
            a_12 = clamp(held_0 + after_0, 0.0f, 1.0f);
        }
    case u32(2):
        {
            var release_0 : f32 = c_8.q_3 * 0.64999997615814209f;
            a_12 = clamp(held_0 + max(0.0f, after_0 - release_0) / max(0.05000000074505806f, 1.0f - release_0), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_0 > 0.0f))
            {
                held_0 = play3_0(held_0 - 2.0f * p_18.cycles_0 * after_0, p_18.playback_0);
            }
            a_12 = held_0;
        }
    case u32(4):
        {
            a_12 = bounce3_0(held_0 - 2.0f * p_18.cycles_0 * after_0);
        }
    default :
        {
            a_12 = held_0;
        }
    }
    return single3_0(uv_6, a_12);
}

fn relative3_0( c_9 : Coord_0,  p_19 : TFParams_0) -> f32
{
    var d_3 : f32;
    if((((p_19.flags_0) & (u32(4)))) != u32(0))
    {
        d_3 = (c_9.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if((((p_19.flags_0) & (u32(8)))) != u32(0))
        {
            d_3 = (c_9.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_3 = 2.0f * c_9.raw_0 - 1.0f;
        }
    }
    if((p_19.pixel_0) == 0.0f)
    {
        var _S178 : f32 = p_19.slices_0 - 1.0f;
        var positive_0 : f32 = ceil(_S178 / 2.0f);
        var negative_0 : f32 = floor(_S178 / 2.0f);
        var _S179 : f32;
        if((d_3 < 0.0f))
        {
            _S179 = negative_0;
        }
        else
        {
            _S179 = positive_0;
        }
        var _S180 : f32 = max(1.0f, _S179);
        d_3 = round(d_3 * _S180) / _S180;
    }
    return p_19.span_0 * d_3;
}

fn basic3_0( uv_7 : vec2<f32>,  c_10 : Coord_0,  p_20 : TFParams_0) -> Field_0
{
    var clock_2 : f32 = 2.0f * p_20.cycles_0 * p_20.u_0;
    var t_8 : f32;
    if((p_20.customMap_0) != u32(0))
    {
        if((((p_20.flags_0) & (u32(2)))) != u32(0))
        {
            t_8 = p_20.u_0 + relative3_0(c_10, p_20);
        }
        else
        {
            t_8 = c_10.q_3 + clock_2;
        }
        return single3_0(uv_7, play3_0(t_8, p_20.playback_0));
    }
    if((p_20.design_0) == u32(0))
    {
        t_8 = 0.20000000298023224f + 0.80000001192092896f * fract(p_20.cycles_0 * p_20.u_0 - c_10.q_3);
    }
    else
    {
        if((p_20.design_0) == u32(5))
        {
            t_8 = bounce3_0(1.0f - clock_2 - p_20.span_0 * c_10.q_3);
        }
        else
        {
            if((p_20.shape_0) == u32(11))
            {
                if((i32(c_10.index_1) % i32(2)) == i32(0))
                {
                    t_8 = 1.0f;
                }
                else
                {
                    t_8 = -1.0f;
                }
                t_8 = play3_0(1.0f + clock_2 * t_8 - p_20.span_0 * c_10.q_3, p_20.playback_0);
            }
            else
            {
                t_8 = play3_0(1.0f + clock_2 - p_20.span_0 * c_10.q_3, p_20.playback_0);
            }
        }
    }
    return single3_0(uv_7, t_8);
}

fn wave3_0( uv_8 : vec2<f32>,  c_11 : Coord_0,  p_21 : TFParams_0) -> Field_0
{
    var _S181 : bool;
    if((p_21.customMap_0) != u32(0))
    {
        _S181 = (((p_21.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S181 = false;
    }
    var phase_6 : f32;
    if(_S181)
    {
        phase_6 = 2.0f * p_21.cycles_0 * p_21.u_0 + relative3_0(c_11, p_21);
    }
    else
    {
        phase_6 = 2.0f * p_21.cycles_0 * p_21.u_0 - 2.0f * p_21.density_0 * c_11.q_3;
    }
    return single3_0(uv_8, play3_0(phase_6, p_21.playback_0));
}

fn coordSpan42_0( uv_9 : vec2<f32>,  p_22 : TFParams_0) -> f32
{
    var size_1 : vec2<f32> = vec2<f32>(p_22.sampleW_0, p_22.sampleH_0);
    var _S182 : vec2<f32> = vec2<f32>(p_22.cx_0, p_22.cy_0);
    var v_9 : vec2<f32> = (uv_9 - _S182) * size_1;
    var _S183 : vec2<f32> = vec2<f32>(1.0f);
    var radii_1 : vec2<f32> = max(_S182, _S183 - _S182) * size_1;
    if((p_22.customMap_0) != u32(0))
    {
        return min(p_22.sampleW_0, p_22.sampleH_0);
    }
    switch(p_22.shape_0)
    {
    case u32(1):
        {
            return p_22.sampleH_0;
        }
    case u32(2), u32(12):
        {
            var a_13 : f32 = p_22.angle_0 * 3.1415927410125732f / 180.0f;
            return p_22.sampleW_0 * abs(cos(a_13)) + p_22.sampleH_0 * abs(sin(a_13));
        }
    case u32(3):
        {
            return 3.1415927410125732f * length(v_9);
        }
    case u32(4):
        {
            return 6.2831854820251465f * length(v_9);
        }
    case u32(5), u32(14):
        {
            return length(radii_1) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S182), _S182 - _S183)) * size_1);
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
            return min(6.2831854820251465f * length(v_9), length(radii_1) / 1.5f);
        }
    case u32(13):
        {
            return length(radii_1) * 0.56000000238418579f;
        }
    default :
        {
            return p_22.sampleW_0;
        }
    }
}

fn frozenShadow53_0( uv_10 : vec2<f32>,  p_23 : TFParams_0,  coverage_4 : f32) -> f32
{
    var geometry_0 : TFParams_0 = p_23;
    geometry_0.direction_0 = u32(0);
    var _S184 : bool;
    if(((p_23.direction_0) >= u32(2)))
    {
        _S184 = (p_23.shape_0) != u32(8);
    }
    else
    {
        _S184 = false;
    }
    if(_S184)
    {
        _S184 = (p_23.shape_0) != u32(10);
    }
    else
    {
        _S184 = false;
    }
    if(_S184)
    {
        geometry_0.slices_0 = geometry_0.slices_0 * 2.0f;
    }
    var c_12 : Coord_0 = coordinate3_0(uv_10, geometry_0, 0.0f);
    var _S185 : f32 = max(2.0f, geometry_0.slices_0);
    if((p_23.shape_0) == u32(8))
    {
        _S184 = true;
    }
    else
    {
        _S184 = (p_23.shape_0) == u32(10);
    }
    var cells_0 : f32;
    if(_S184)
    {
        var _S186 : bool = (p_23.shape_0) == u32(10);
        if(_S186)
        {
            cells_0 = ceil(_S185 / 2.0f);
        }
        else
        {
            cells_0 = _S185;
        }
        var grid_1 : vec2<f32> = gridSize3_0(cells_0, vec2<f32>(p_23.outputW_0, p_23.outputH_0));
        var _S187 : f32 = grid_1.x;
        var _S188 : i32;
        if(((c_12.cell_3.y) < (cells_0 - _S187 * grid_1.y)))
        {
            _S188 = i32(1);
        }
        else
        {
            _S188 = i32(0);
        }
        var phase_7 : f32 = c_12.frac_0.x;
        var span_4 : f32 = p_23.sampleW_0 / (_S187 + f32(_S188));
        var phase_8 : f32;
        var span_5 : f32;
        if(_S186)
        {
            var cut_0 : f32 = 1.0f - c_12.frac_0.y;
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
        if(((p_23.shadowSide_0) > 0.0f))
        {
            cells_0 = phase_8;
        }
        else
        {
            cells_0 = 1.0f - phase_8;
        }
        return filteredLight42_0(cells_0, span_5, coverage_4, 1.0f, false, p_23);
    }
    var phase_9 : f32 = clamp(c_12.raw_0 * _S185 - c_12.index_1, 0.0f, 1.0f);
    var span_7 : f32 = coordSpan42_0(uv_10, geometry_0) / _S185;
    if(((p_23.shadowSide_0) > 0.0f))
    {
        cells_0 = phase_9;
    }
    else
    {
        cells_0 = 1.0f - phase_9;
    }
    return filteredLight42_0(cells_0, span_7, coverage_4, 1.0f, false, p_23);
}

fn stripeBorder42_0( cut_1 : f32,  lengthPx_2 : f32,  count_4 : f32) -> f32
{
    if(((max(lengthPx_2, count_4)) <= 32768.0f))
    {
        var n_3 : u32 = u32(count_4);
        var numerator_0 : u32 = u32(2) * u32(cut_1) * u32(lengthPx_2);
        var _S189 : f32;
        if((numerator_0 <= n_3))
        {
            _S189 = 0.0f;
        }
        else
        {
            var _S190 : u32 = (numerator_0 + n_3 - u32(1)) / (u32(2) * n_3);
            _S189 = f32(_S190);
        }
        return _S189;
    }
    return clamp(ceil(cut_1 * lengthPx_2 / count_4 - 0.5f), 0.0f, lengthPx_2);
}

fn stripeLight42_0( axis_0 : f32,  index_3 : f32,  lengthPx_3 : f32,  count_5 : f32,  reverse_0 : bool,  coverage_5 : f32,  p_24 : TFParams_0) -> f32
{
    var span_8 : f32 = lengthPx_3 / count_5;
    if((span_8 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_0 : bool = ((p_24.shadowSide_0) > 0.0f);
    var center_3 : f32;
    if(leading_0)
    {
        center_3 = 0.0f;
    }
    else
    {
        center_3 = 1.0f;
    }
    var edge_2 : f32 = stripeBorder42_0(index_3 + center_3, lengthPx_3, count_5);
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
    return filteredLight42_0(max(0.5f, center_3) / span_8, span_8, coverage_5, 1.0f, false, p_24);
}

fn sliceLight42_0( uv_11 : vec2<f32>,  c_13 : Coord_0,  p_25 : TFParams_0,  coverage_6 : f32) -> f32
{
    var _S191 : bool;
    if((p_25.family_0) == u32(0))
    {
        _S191 = (p_25.customMap_0) == u32(0);
    }
    else
    {
        _S191 = false;
    }
    if(_S191)
    {
        var _S192 : f32 = frozenShadow53_0(uv_11, p_25, coverage_6);
        return _S192;
    }
    var _S193 : f32 = max(2.0f, p_25.slices_0);
    var _S194 : bool = (p_25.shape_0) == u32(8);
    if(_S194)
    {
        _S191 = true;
    }
    else
    {
        _S191 = (p_25.shape_0) == u32(10);
    }
    if(_S191)
    {
        _S191 = (p_25.customMap_0) == u32(0);
    }
    else
    {
        _S191 = false;
    }
    if(_S191)
    {
        _S191 = ((p_25.direction_0) < u32(2));
    }
    else
    {
        _S191 = false;
    }
    var cells_1 : f32;
    var x_6 : f32;
    if(_S191)
    {
        var _S195 : bool = (p_25.shape_0) == u32(10);
        if(_S195)
        {
            cells_1 = ceil(_S193 / 2.0f);
        }
        else
        {
            cells_1 = _S193;
        }
        var grid_2 : vec2<f32> = gridSize3_0(cells_1, vec2<f32>(p_25.outputW_0, p_25.outputH_0));
        var _S196 : f32 = grid_2.x;
        var _S197 : i32;
        if(((c_13.cell_3.y) < (cells_1 - _S196 * grid_2.y)))
        {
            _S197 = i32(1);
        }
        else
        {
            _S197 = i32(0);
        }
        var x_7 : f32 = c_13.frac_0.x;
        var span_9 : f32 = p_25.sampleW_0 / (_S196 + f32(_S197));
        var span_10 : f32;
        if(_S195)
        {
            var cut_2 : f32 = 1.0f - c_13.frac_0.y;
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
        if((p_25.direction_0) == u32(1))
        {
            phase_10 = 1.0f - x_6;
        }
        else
        {
            phase_10 = x_6;
        }
        if(_S194)
        {
            cells_1 = tiledLight42_0(phase_10, span_10, coverage_6, p_25);
        }
        else
        {
            cells_1 = edgeLight42_0(phase_10, span_10, coverage_6, p_25);
        }
        return cells_1;
    }
    var span_12 : f32 = coordSpan42_0(uv_11, p_25);
    if(((p_25.direction_0) >= u32(2)))
    {
        cells_1 = span_12 * 0.5f;
    }
    else
    {
        cells_1 = span_12;
    }
    if(((p_25.pixel_0) > 0.0f))
    {
        _S191 = (p_25.family_0) == u32(2);
    }
    else
    {
        _S191 = false;
    }
    if(_S191)
    {
        if((p_25.customMap_0) != u32(0))
        {
            _S191 = (((p_25.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S191 = false;
        }
        if(_S191)
        {
            x_6 = 2.0f * p_25.span_0;
        }
        else
        {
            x_6 = 2.0f * p_25.density_0;
        }
        var _S198 : f32 = max(0.0099999997764825821f, x_6);
        return tiledLight42_0(fract(_S198 * c_13.raw_0 - 2.0f * p_25.cycles_0 * p_25.u_0), cells_1 / _S198, coverage_6, p_25);
    }
    if(isStripe42_0(p_25))
    {
        if((p_25.shape_0) == u32(1))
        {
            x_6 = uv_11.y;
        }
        else
        {
            x_6 = uv_11.x;
        }
        var _S199 : f32 = stripeLight42_0(x_6, c_13.index_1, cells_1, _S193, (p_25.direction_0) == u32(1), coverage_6, p_25);
        return _S199;
    }
    return tiledLight42_0(clamp(c_13.raw_0 * _S193 - c_13.index_1, 0.0f, 1.0f), cells_1 / _S193, coverage_6, p_25);
}

fn evaluate3_0( uv_12 : vec2<f32>,  p_26 : TFParams_0,  mapValue_1 : f32) -> Field_0
{
    if(((p_26.design_0) >= u32(407)))
    {
        return creative42_0(uv_12, p_26);
    }
    var c_14 : Coord_0 = coordinate3_0(uv_12, p_26, mapValue_1);
    var base_2 : f32;
    if((c_14.coverage_3) == 0.0f)
    {
        if((p_26.family_0) == u32(0))
        {
            base_2 = play3_0(p_26.u_0 / max(0.10000000149011612f, p_26.build_0), p_26.playback_0);
        }
        else
        {
            if((p_26.family_0) == u32(1))
            {
                base_2 = 1.0f;
            }
            else
            {
                base_2 = 0.0f;
            }
            base_2 = play3_0(base_2 + 2.0f * p_26.cycles_0 * p_26.u_0, p_26.playback_0);
        }
        return single3_0(uv_12, base_2);
    }
    if((p_26.family_0) == u32(3))
    {
        return creative3_0(uv_12, c_14, p_26);
    }
    var f_9 : Field_0;
    var _S200 : bool = (p_26.family_0) == u32(0);
    var _S201 : Field_0;
    if(_S200)
    {
        _S201 = frozen3_0(uv_12, c_14, p_26);
    }
    else
    {
        if((p_26.family_0) == u32(1))
        {
            _S201 = basic3_0(uv_12, c_14, p_26);
        }
        else
        {
            _S201 = wave3_0(uv_12, c_14, p_26);
        }
    }
    f_9 = _S201;
    if(((p_26.shadowStrength_0) > 0.0f))
    {
        var _S202 : bool;
        if(_S200)
        {
            _S202 = ((p_26.u_0) < (clamp(p_26.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S202 = false;
        }
        if(_S202)
        {
            base_2 = f_9.weight_0;
        }
        else
        {
            base_2 = 1.0f;
        }
        if((base_2 > 0.0f))
        {
            var _S203 : f32 = sliceLight42_0(uv_12, c_14, p_26, base_2);
            f_9.light_0 = _S203;
        }
    }
    return f_9;
}

fn shadowTentPart52_0( low_2 : f32,  high_2 : f32,  feathered_0 : bool,  solid_3 : f32,  feather_3 : f32,  mid_0 : f32,  center_5 : f32,  step_1 : f32,  distance_4 : f32,  sign_0 : f32,  slope_0 : f32) -> f32
{
    if((high_2 <= low_2))
    {
        return 0.0f;
    }
    var m_0 : f32 = (low_2 + high_2) * 0.5f;
    var r_15 : f32 = (high_2 - low_2) * 0.5f;
    var w0_0 : f32 = max(0.0f, 1.0f + slope_0 * (mid_0 - center_5 + sign_0 * (m_0 - distance_4)) / step_1) / step_1;
    if(!feathered_0)
    {
        return 2.0f * r_15 * w0_0;
    }
    var t_9 : f32 = clamp((m_0 - solid_3) / feather_3, 0.0f, 1.0f);
    var _S204 : f32 = 6.0f * t_9;
    var _S205 : f32 = feather_3 * feather_3;
    var w1_0 : f32 = slope_0 * sign_0 / (step_1 * step_1);
    var r2_0 : f32 = r_15 * r_15;
    return max(0.0f, 2.0f * r_15 * (w0_0 * (1.0f - t_9 * t_9 * (3.0f - 2.0f * t_9)) + (w0_0 * ((_S204 - 3.0f) / _S205) + w1_0 * (_S204 * (t_9 - 1.0f) / feather_3)) * r2_0 / 3.0f + w1_0 * (2.0f / (_S205 * feather_3)) * r2_0 * r2_0 / 5.0f));
}

fn shadowTentSide52_0( low_3 : f32,  high_3 : f32,  mid_1 : f32,  center_6 : f32,  step_2 : f32,  distance_5 : f32,  sign_1 : f32,  slope_1 : f32,  p_27 : TFParams_0) -> f32
{
    if((high_3 <= low_3))
    {
        return 0.0f;
    }
    var a_14 : f32 = distance_5 + sign_1 * (low_3 - mid_1);
    var b_13 : f32 = distance_5 + sign_1 * (high_3 - mid_1);
    var lo_1 : f32 = clamp(min(a_14, b_13), 0.0f, 1.0f);
    var hi_1 : f32 = clamp(max(a_14, b_13), 0.0f, 1.0f);
    var width_0 : f32 = clamp(p_27.shadowWidth_0, 0.019999999552965164f, 0.75f);
    var feather_4 : f32 = width_0 * max(0.02500000037252903f, p_27.shadowSoftness_0);
    var solid_4 : f32 = width_0 - feather_4;
    return shadowTentPart52_0(lo_1, min(hi_1, solid_4), false, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1) + shadowTentPart52_0(max(lo_1, solid_4), min(hi_1, width_0), true, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1);
}

fn stripeSample52_0( uv_13 : vec2<f32>,  p_28 : TFParams_0,  footprint_0 : StripeFootprint52_0,  low_4 : f32,  high_4 : f32,  weight_1 : f32) -> Field_0
{
    var _S206 : TFParams_0 = p_28;
    var mid_2 : f32 = (low_4 + high_4) * 0.5f;
    var axis_1 : f32 = mid_2 / footprint_0.count_2;
    var gradient_2 : vec2<f32> = stripeGradient52_0(p_28);
    var _S207 : vec2<f32> = uv_13 + gradient_2 * vec2<f32>(((axis_1 - stripeAxis52_0(uv_13, p_28)) / max(9.99999993922529029e-09f, dot(gradient_2, gradient_2))));
    _S206.reserved0_0 = 1.0f;
    var _S208 : Field_0 = evaluate3_0(_S207, _S206, 0.0f);
    var f_10 : Field_0 = _S208;
    if(((_S206.shadowStrength_0) <= 0.0f))
    {
        return f_10;
    }
    var c_15 : Coord_0 = coordinate3_0(_S207, _S206, 0.0f);
    var phase_11 : f32 = clamp(c_15.raw_0 * max(2.0f, _S206.slices_0) - c_15.index_1, 0.0f, 1.0f);
    var sign_2 : f32;
    if((_S206.direction_0) == u32(1))
    {
        sign_2 = -1.0f;
    }
    else
    {
        sign_2 = 1.0f;
    }
    var phase_12 : f32;
    if(((_S206.direction_0) >= u32(2)))
    {
        if((axis_1 < 0.5f))
        {
            sign_2 = -1.0f;
        }
        else
        {
            sign_2 = 1.0f;
        }
        if((_S206.direction_0) == u32(3))
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
    if(((_S206.shadowSide_0) > 0.0f))
    {
        distance_6 = phase_12;
    }
    else
    {
        distance_6 = 1.0f - phase_12;
    }
    if((_S206.shadowSide_0) == 0.0f)
    {
        sign_2 = -1.0f;
    }
    else
    {
        sign_2 = 1.0f;
    }
    var mass_0 : f32 = shadowTentSide52_0(low_4, min(high_4, footprint_0.center_0), mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, 1.0f, _S206) + shadowTentSide52_0(max(low_4, footprint_0.center_0), high_4, mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, -1.0f, _S206);
    var gradient_3 : vec2<f32> = abs(gradient_2);
    var fade_0 : f32 = smoothstep(1.0f, 2.5f, 1.0f / max(9.99999993922529029e-09f, gradient_3.x / _S206.outputW_0 + gradient_3.y / _S206.outputH_0) / footprint_0.count_2);
    var coverage_7 : f32;
    if(((_S206.u_0) < (clamp(_S206.build_0, 0.10000000149011612f, 0.89999997615814209f))))
    {
        coverage_7 = f_10.weight_0;
    }
    else
    {
        coverage_7 = 1.0f;
    }
    f_10.light_0 = 1.0f - _S206.shadowStrength_0 * coverage_7 * fade_0 * clamp(mass_0 / max(weight_1, 9.99999993922529029e-09f), 0.0f, 1.0f);
    return f_10;
}

fn filteredStripeColor52_0( uv_14 : vec2<f32>,  local_3 : u32,  p_29 : TFParams_0) -> vec4<f32>
{
    var footprint_1 : StripeFootprint52_0 = stripeFootprint52_0(uv_14, p_29);
    var _S209 : vec4<f32> = vec4<f32>(vec4<i32>(i32(0)));
    var cell_4 : i32 = i32(footprint_1.first_0);
    var result_0 : vec4<f32> = _S209;
    loop
    {
        if((cell_4 <= i32(footprint_1.last_0)))
        {
        }
        else
        {
            break;
        }
        var _S210 : f32 = max(footprint_1.low_0, f32(cell_4));
        var _S211 : i32 = cell_4 + i32(1);
        var _S212 : f32 = min(footprint_1.high_0, f32(_S211));
        var weight_2 : f32 = stripeWeight52_0(_S210, _S212, footprint_1);
        if((weight_2 <= 9.99999993922529029e-09f))
        {
            cell_4 = _S211;
            continue;
        }
        var f_11 : Field_0 = stripeSample52_0(uv_14, p_29, footprint_1, _S210, _S212, weight_2);
        var blend_0 : f32 = clamp(f_11.weight_0, 0.0f, 1.0f);
        var color_0 : vec4<f32>;
        if((p_29.viewMode_0) == u32(2))
        {
            var t_10 : f32 = adjusted3_0(mix(clamp(f_11.a_4, 0.0f, 1.0f), clamp(f_11.b_11, 0.0f, 1.0f), blend_0), p_29);
            color_0 = vec4<f32>(t_10, t_10, t_10, 1.0f);
        }
        else
        {
            if(blend_0 == 1.0f)
            {
                var _S213 : vec4<f32> = sampleSource_0(f_11.b_11, local_3, p_29);
                color_0 = _S213 * vec4<f32>(f_11.shade_0);
            }
            else
            {
                var _S214 : vec4<f32> = sampleSource_0(f_11.a_4, local_3, p_29);
                color_0 = _S214;
                if((blend_0 > 0.0f))
                {
                    var _S215 : vec4<f32> = sampleSource_0(f_11.b_11, local_3, p_29);
                    color_0 = mix(color_0, _S215 * vec4<f32>(f_11.shade_0), vec4<f32>(blend_0));
                }
            }
            var _S216 : vec3<f32> = color_0.xyz * vec3<f32>(f_11.light_0);
            color_0.x = _S216.x;
            color_0.y = _S216.y;
            color_0.z = _S216.z;
        }
        result_0 = result_0 + color_0 * vec4<f32>(weight_2) / vec4<f32>(footprint_1.normalization_0);
        cell_4 = _S211;
    }
    return result_0;
}

fn needsAA53_0( uv_15 : vec2<f32>,  p_30 : TFParams_0,  mapValue_2 : f32) -> bool
{
    if((p_30.customMap_0) != u32(0))
    {
        return false;
    }
    var _S217 : bool;
    if(((p_30.pixel_0) > 0.0f))
    {
        _S217 = (p_30.family_0) != u32(3);
    }
    else
    {
        _S217 = false;
    }
    if(_S217)
    {
        _S217 = ((p_30.shadowStrength_0) <= 0.0f);
    }
    else
    {
        _S217 = false;
    }
    if(_S217)
    {
        return false;
    }
    if((p_30.shape_0) == u32(0))
    {
        _S217 = true;
    }
    else
    {
        _S217 = (p_30.shape_0) == u32(1);
    }
    if(_S217)
    {
        _S217 = true;
    }
    else
    {
        _S217 = (p_30.shape_0) == u32(11);
    }
    if(_S217)
    {
        _S217 = ((p_30.direction_0) < u32(2));
    }
    else
    {
        _S217 = false;
    }
    var _S218 : f32;
    if(_S217)
    {
        if((p_30.shape_0) == u32(1))
        {
            _S218 = p_30.sampleH_0;
        }
        else
        {
            _S218 = p_30.sampleW_0;
        }
        var pitch_2 : f32 = _S218 / max(2.0f, p_30.slices_0);
        if(((abs(pitch_2 - round(pitch_2))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    var q_10 : TFParams_0 = p_30;
    q_10.reserved0_0 = 0.25f;
    var delta_1 : vec2<f32> = vec2<f32>(0.49000000953674316f) / vec2<f32>(p_30.sampleW_0, p_30.sampleH_0);
    var _S219 : vec2<f32> = uv_15 - delta_1;
    var _S220 : Coord_0 = coordinate3_0(_S219, q_10, mapValue_2);
    var _S221 : Field_0 = evaluate3_0(_S219, q_10, mapValue_2);
    var i_4 : i32 = i32(1);
    loop
    {
        if((i_4 < i32(4)))
        {
        }
        else
        {
            break;
        }
        if(((i_4 & (i32(1)))) != i32(0))
        {
            _S218 = delta_1.x;
        }
        else
        {
            _S218 = - delta_1.x;
        }
        var _S222 : f32;
        if(((i_4 & (i32(2)))) != i32(0))
        {
            _S222 = delta_1.y;
        }
        else
        {
            _S222 = - delta_1.y;
        }
        var v_10 : vec2<f32> = uv_15 + vec2<f32>(_S218, _S222);
        var other_0 : Coord_0 = coordinate3_0(v_10, q_10, mapValue_2);
        var f_12 : Field_0 = evaluate3_0(v_10, q_10, mapValue_2);
        if((other_0.index_1) != (_S220.index_1))
        {
            _S217 = true;
        }
        else
        {
            _S217 = ((abs(other_0.coverage_3 - _S220.coverage_3)) > 0.0010000000474974513f);
        }
        var _S223 : bool;
        if(_S217)
        {
            _S223 = true;
        }
        else
        {
            _S223 = ((abs(_S221.weight_0 - f_12.weight_0)) > 0.0099999997764825821f);
        }
        if(_S223)
        {
            return true;
        }
        var _S224 : bool;
        if((p_30.family_0) == u32(3))
        {
            if(((abs(_S221.a_4 - f_12.a_4)) > 0.019999999552965164f))
            {
                _S224 = true;
            }
            else
            {
                _S224 = ((abs(_S221.b_11 - f_12.b_11)) > 0.019999999552965164f);
            }
        }
        else
        {
            _S224 = false;
        }
        if(_S224)
        {
            return true;
        }
        i_4 = i_4 + i32(1);
    }
    return false;
}

fn fieldColor53_0( f_13 : Field_0,  local_4 : u32,  p_31 : TFParams_0) -> vec4<f32>
{
    var weight_3 : f32 = clamp(f_13.weight_0, 0.0f, 1.0f);
    if((p_31.viewMode_0) == u32(2))
    {
        var n_4 : f32 = adjusted3_0(mix(clamp(f_13.a_4, 0.0f, 1.0f), clamp(f_13.b_11, 0.0f, 1.0f), weight_3), p_31);
        return vec4<f32>(n_4, n_4, n_4, 1.0f);
    }
    var color_1 : vec4<f32>;
    var _S225 : bool = weight_3 == 1.0f;
    var _S226 : f32;
    if(_S225)
    {
        _S226 = f_13.b_11;
    }
    else
    {
        _S226 = f_13.a_4;
    }
    var _S227 : vec4<f32> = sampleSource_0(_S226, local_4, p_31);
    color_1 = _S227;
    if(_S225)
    {
        color_1 = color_1 * vec4<f32>(f_13.shade_0);
    }
    else
    {
        if((weight_3 > 0.0f))
        {
            var _S228 : vec4<f32> = sampleSource_0(f_13.b_11, local_4, p_31);
            color_1 = mix(color_1, _S228 * vec4<f32>(f_13.shade_0), vec4<f32>(weight_3));
        }
    }
    var _S229 : vec3<f32> = color_1.xyz * vec3<f32>(f_13.light_0);
    color_1.x = _S229.x;
    color_1.y = _S229.y;
    color_1.z = _S229.z;
    return color_1;
}

fn pqSignal106_0( v_11 : f32) -> f32
{
    var q_11 : f32 = pow(max(v_11, 0.0f) * 203.0f / 10000.0f, 0.1593017578125f);
    return pow((0.8359375f + 18.8515625f * q_11) / (1.0f + 18.6875f * q_11), 78.84375f);
}

fn mobius106_0( x_8 : f32,  peak_0 : f32) -> f32
{
    var _S230 : bool;
    if((peak_0 <= 1.0000100135803223f))
    {
        _S230 = true;
    }
    else
    {
        _S230 = (x_8 <= 0.30000001192092896f);
    }
    if(_S230)
    {
        return x_8;
    }
    var _S231 : f32 = peak_0 - 1.0f;
    var a_15 : f32 = -0.090000003576278687f * _S231 / (-0.50999999046325684f + peak_0);
    var b_14 : f32 = (0.090000003576278687f - 0.60000002384185791f * peak_0 + peak_0) / _S231;
    var _S232 : f32 = b_14 + 0.30000001192092896f;
    return _S232 * _S232 / (b_14 - a_15) * (x_8 + a_15) / max(x_8 + b_14, 9.99999971718068537e-10f);
}

fn hlgSignal106_0( v_12 : f32) -> f32
{
    var _S233 : f32 = max(v_12, 0.0f);
    var _S234 : f32;
    if((_S233 <= 0.083333335816860199f))
    {
        _S234 = sqrt(3.0f * _S233);
    }
    else
    {
        _S234 = 0.1788327693939209f * log(max(12.0f * _S233 - 0.28466892242431641f, 9.99999971718068537e-10f)) + 0.55991071462631226f;
    }
    return _S234;
}

fn gamut709_106_0( c_16 : Color53_0) -> Color53_0
{
    var y_4 : f32 = clamp(c_16.r_0 * 0.2125999927520752f + c_16.g_0 * 0.71520000696182251f + c_16.b_0 * 0.072200000286102295f, 0.0f, 1.0f);
    var _S235 : f32 = min(c_16.r_0, min(c_16.g_0, c_16.b_0));
    var k_1 : f32;
    if((_S235 < 0.0f))
    {
        k_1 = min(1.0f, y_4 / max(y_4 - _S235, 9.99999971718068537e-10f));
    }
    else
    {
        k_1 = 1.0f;
    }
    var _S236 : Color53_0 = color53_0(y_4 + (c_16.r_0 - y_4) * k_1, y_4 + (c_16.g_0 - y_4) * k_1, y_4 + (c_16.b_0 - y_4) * k_1);
    var _S237 : f32 = max(_S236.r_0, max(_S236.g_0, _S236.b_0));
    if((_S237 > 1.0f))
    {
        k_1 = min(1.0f, (1.0f - y_4) / max(_S237 - y_4, 9.99999971718068537e-10f));
    }
    else
    {
        k_1 = 1.0f;
    }
    return color53_0(clamp(y_4 + (_S236.r_0 - y_4) * k_1, 0.0f, 1.0f), clamp(y_4 + (_S236.g_0 - y_4) * k_1, 0.0f, 1.0f), clamp(y_4 + (_S236.b_0 - y_4) * k_1, 0.0f, 1.0f));
}

fn btSignal106_0( v_13 : f32) -> f32
{
    var _S238 : f32 = max(v_13, 0.0f);
    var _S239 : f32;
    if((_S238 < 0.017999999225139618f))
    {
        _S239 = _S238 * 4.5f;
    }
    else
    {
        _S239 = 1.0989999771118164f * pow(_S238, 0.44999998807907104f) - 0.098999999463558197f;
    }
    return _S239;
}

fn outputColor106_0( c_17 : Color53_0,  p_32 : TFParams_0) -> Color53_0
{
    if(!linearColor106_0(p_32))
    {
        return c_17;
    }
    if((((p_32.flags_0) & (u32(131072)))) != u32(0))
    {
        return color53_0(pqSignal106_0(c_17.r_0), pqSignal106_0(c_17.g_0), pqSignal106_0(c_17.b_0));
    }
    var gain_2 : f32;
    if((((p_32.flags_0) & (u32(262144)))) != u32(0))
    {
        var level_0 : f32 = max(c_17.r_0, max(c_17.g_0, c_17.b_0)) * 203.0f / 1000.0f;
        var peak_1 : f32 = max(1000.0f, p_32.sourcePeak_0) / 1000.0f;
        if((level_0 > 9.99999971718068537e-10f))
        {
            gain_2 = mobius106_0(level_0, peak_1) / level_0;
        }
        else
        {
            gain_2 = 1.0f;
        }
        var _S240 : Color53_0 = color53_0(c_17.r_0 * gain_2, c_17.g_0 * gain_2, c_17.b_0 * gain_2);
        var gain_3 : f32 = pow(max((_S240.r_0 * 0.26269999146461487f + _S240.g_0 * 0.67799997329711914f + _S240.b_0 * 0.059300001710653305f) * 203.0f / 1000.0f, 9.999999960041972e-13f), -0.1666666716337204f) * 203.0f / 1000.0f;
        return color53_0(hlgSignal106_0(_S240.r_0 * gain_3), hlgSignal106_0(_S240.g_0 * gain_3), hlgSignal106_0(_S240.b_0 * gain_3));
    }
    var _S241 : Color53_0;
    if((((p_32.flags_0) & (u32(98304)))) != u32(0))
    {
        var _S242 : f32 = max(c_17.r_0, max(c_17.g_0, c_17.b_0));
        if((_S242 > 9.99999971718068537e-10f))
        {
            gain_2 = mobius106_0(_S242, max(203.0f, p_32.sourcePeak_0) / 203.0f) / _S242;
        }
        else
        {
            gain_2 = 1.0f;
        }
        _S241 = color53_0(c_17.r_0 * gain_2, c_17.g_0 * gain_2, c_17.b_0 * gain_2);
    }
    else
    {
        _S241 = c_17;
    }
    var _S243 : Color53_0 = gamut709_106_0(_S241);
    return color53_0(btSignal106_0(_S243.r_0), btSignal106_0(_S243.g_0), btSignal106_0(_S243.b_0));
}

fn gradientOffset105_0( x_9 : u32,  y_5 : u32) -> f32
{
    var _S244 : u32 = (y_5 >> (u32(1)));
    var _S245 : u32 = (y_5 >> (u32(2)));
    return (f32((((((((((((((((x_9 ^ (y_5))) & (u32(1)))) << (u32(5)))) | (((((y_5 & (u32(1)))) << (u32(4))))))) | (((((((((x_9 >> (u32(1)))) ^ (_S244))) & (u32(1)))) << (u32(3))))))) | (((((_S244 & (u32(1)))) << (u32(2))))))) | (((((((((x_9 >> (u32(2)))) ^ (_S245))) & (u32(1)))) << (u32(1))))))) | (((_S245 & (u32(1))))))) + 0.5f) / 64.0f - 0.5f;
}

fn quantizeColor105_0( value_0 : f32,  x_10 : u32,  y_6 : u32,  flags_2 : u32) -> f32
{
    var noise_0 : f32;
    if(((flags_2 & (u32(4096)))) != u32(0))
    {
        noise_0 = gradientOffset105_0(x_10, y_6);
    }
    else
    {
        noise_0 = 0.0f;
    }
    return round(clamp(value_0, 0.0f, 1.0f) * 255.0f + noise_0);
}

fn packColor106_0( c_18 : Color53_0,  x_11 : u32,  y_7 : u32,  p_33 : TFParams_0) -> u32
{
    var _S246 : Color53_0;
    if((p_33.viewMode_0) != u32(2))
    {
        _S246 = outputColor106_0(c_18, p_33);
    }
    else
    {
        _S246 = c_18;
    }
    var noise_1 : f32;
    if((((p_33.flags_0) & (u32(4096)))) != u32(0))
    {
        noise_1 = gradientOffset105_0(x_11, y_7);
    }
    else
    {
        noise_1 = 0.0f;
    }
    if((((p_33.flags_0) & (u32(16384)))) != u32(0))
    {
        return (((((u32(3221225472) | (((u32(round(clamp(_S246.r_0, 0.0f, 1.0f) * 1023.0f + noise_1)) << (u32(20))))))) | (((u32(round(clamp(_S246.g_0, 0.0f, 1.0f) * 1023.0f + noise_1)) << (u32(10))))))) | (u32(round(clamp(_S246.b_0, 0.0f, 1.0f) * 1023.0f + noise_1))));
    }
    return (((((u32(quantizeColor105_0(_S246.r_0, x_11, y_7, p_33.flags_0)) | (((u32(quantizeColor105_0(_S246.g_0, x_11, y_7, p_33.flags_0)) << (u32(8))))))) | (((u32(quantizeColor105_0(_S246.b_0, x_11, y_7, p_33.flags_0)) << (u32(16))))))) | (u32(4278190080)));
}

@compute
@workgroup_size(8, 8, 1)
fn render(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S247 : u32 = id_0.x;
    var _S248 : bool;
    if((_S247 >= cfg_0[i32(2)]))
    {
        _S248 = true;
    }
    else
    {
        _S248 = ((id_0.y) >= cfg_0[i32(3)]);
    }
    if(_S248)
    {
        _S248 = true;
    }
    else
    {
        _S248 = ((id_0.z) >= cfg_0[i32(8)]);
    }
    if(_S248)
    {
        return;
    }
    var _S249 : u32 = id_0.y;
    var local_5 : u32 = _S249 * cfg_0[i32(2)] + _S247;
    var uv_16 : vec2<f32> = (vec2<f32>(id_0.xy + vec2<u32>(cfg_0[i32(0)], cfg_0[i32(1)])) + vec2<f32>(0.5f)) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)]));
    var p_34 : TFParams_0;
    p_34.outTime_0 = param_0.outTime_0;
    p_34.u_0 = param_0.u_0;
    p_34.sourceDuration_0 = param_0.sourceDuration_0;
    p_34.aspect_0 = param_0.aspect_0;
    p_34.slices_0 = param_0.slices_0;
    p_34.pixel_0 = param_0.pixel_0;
    p_34.span_0 = param_0.span_0;
    p_34.cycles_0 = param_0.cycles_0;
    p_34.cx_0 = param_0.cx_0;
    p_34.cy_0 = param_0.cy_0;
    p_34.angle_0 = param_0.angle_0;
    p_34.turns_0 = param_0.turns_0;
    p_34.build_0 = param_0.build_0;
    p_34.softness_0 = param_0.softness_0;
    p_34.density_0 = param_0.density_0;
    p_34.sourceReverse_0 = param_0.sourceReverse_0;
    p_34.sourceStart_0 = param_0.sourceStart_0;
    p_34.sourceEnd_0 = param_0.sourceEnd_0;
    p_34.outputW_0 = param_0.outputW_0;
    p_34.outputH_0 = param_0.outputH_0;
    p_34.family_0 = param_0.family_0;
    p_34.shape_0 = param_0.shape_0;
    p_34.design_0 = param_0.design_0;
    p_34.ending_0 = param_0.ending_0;
    p_34.direction_0 = param_0.direction_0;
    p_34.playback_0 = param_0.playback_0;
    p_34.origin_0 = param_0.origin_0;
    p_34.viewMode_0 = param_0.viewMode_0;
    p_34.frames_0 = param_0.frames_0;
    p_34.customMap_0 = param_0.customMap_0;
    p_34.waveSources_0 = param_0.waveSources_0;
    p_34.flags_0 = param_0.flags_0;
    p_34.shadowStrength_0 = param_0.shadowStrength_0;
    p_34.shadowWidth_0 = param_0.shadowWidth_0;
    p_34.shadowSoftness_0 = param_0.shadowSoftness_0;
    p_34.shadowSide_0 = param_0.shadowSide_0;
    p_34.sampleW_0 = param_0.sampleW_0;
    p_34.sampleH_0 = param_0.sampleH_0;
    p_34.reserved0_0 = param_0.reserved0_0;
    p_34.reserved1_0 = param_0.reserved1_0;
    p_34.sourcePeak_0 = param_0.sourcePeak_0;
    p_34.paperWhite_0 = param_0.paperWhite_0;
    p_34.displayPeak_0 = param_0.displayPeak_0;
    p_34.colorReserved_0 = param_0.colorReserved_0;
    var _S250 : u32 = id_0.z;
    var _S251 : f32 = f32(cfg_0[i32(7)] + _S250) / f32(max(u32(1), cfg_0[i32(9)]));
    p_34.u_0 = _S251;
    p_34.outTime_0 = _S251;
    if((((p_34.flags_0) & (u32(1024)))) != u32(0))
    {
        var build_2 : f32 = clamp(p_34.build_0, 0.10000000149011612f, 0.89999997615814209f);
        p_34.u_0 = clamp(p_34.u_0 * build_2, 0.0f, build_2);
    }
    var map_0 : f32;
    var color_2 : vec4<f32>;
    if((p_34.viewMode_0) == u32(1))
    {
        if((((p_34.flags_0) & (u32(1024)))) != u32(0))
        {
            map_0 = p_34.u_0 / max(0.10000000149011612f, p_34.build_0);
        }
        else
        {
            map_0 = p_34.u_0;
        }
        var _S252 : vec4<f32> = sampleSource_0(map_0, local_5, p_34);
        color_2 = _S252;
    }
    else
    {
        if(filteredFreeze52_0(p_34))
        {
            var _S253 : vec4<f32> = filteredStripeColor52_0(uv_16, local_5, p_34);
            color_2 = _S253;
        }
        else
        {
            if((p_34.customMap_0) != u32(0))
            {
                map_0 = timeMap_0[local_5];
            }
            else
            {
                map_0 = 0.0f;
            }
            var _S254 : bool = needsAA53_0(uv_16, p_34, map_0);
            if(_S254)
            {
                var q_12 : TFParams_0 = p_34;
                q_12.reserved0_0 = 0.25f;
                var _S255 : vec4<f32> = vec4<f32>(vec4<i32>(i32(0)));
                var yy_0 : i32 = i32(0);
                color_2 = _S255;
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
                        var _S256 : Field_0 = evaluate3_0(uv_16 + vec2<f32>((f32(xx_0) + 0.5f) / 4.0f - 0.5f, (f32(yy_0) + 0.5f) / 4.0f - 0.5f) / vec2<f32>(p_34.sampleW_0, p_34.sampleH_0), q_12, map_0);
                        var _S257 : vec4<f32> = fieldColor53_0(_S256, local_5, p_34);
                        var color_3 : vec4<f32> = color_2 + _S257 / vec4<f32>(16.0f);
                        xx_0 = xx_0 + i32(1);
                        color_2 = color_3;
                    }
                    yy_0 = yy_0 + i32(1);
                }
            }
            else
            {
                var _S258 : Field_0 = evaluate3_0(uv_16, p_34, map_0);
                var _S259 : vec4<f32> = fieldColor53_0(_S258, local_5, p_34);
                color_2 = _S259;
            }
        }
    }
    output_0[(_S250 * cfg_0[i32(3)] + _S249) * cfg_0[i32(2)] + _S247] = packColor106_0(color53_0(color_2.x, color_2.y, color_2.z), _S247 + cfg_0[i32(0)], _S249 + cfg_0[i32(1)], p_34);
    return;
}

