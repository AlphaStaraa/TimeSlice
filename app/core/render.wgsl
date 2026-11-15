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

fn sampleSource_0( n_1 : f32,  pixel_1 : u32,  p_1 : TFParams_0) -> vec4<f32>
{
    var f_0 : f32 = clamp(adjusted3_0(n_1, p_1) * p_1.sourceDuration_0, 0.0f, f32(cfg_0[i32(6)] - u32(1)));
    var a_0 : u32 = u32(floor(f_0));
    var area_0 : u32 = cfg_0[i32(2)] * cfg_0[i32(3)];
    return mix(unpack_0(source_0[a_0 * area_0 + pixel_1]), unpack_0(source_0[min(a_0 + u32(1), cfg_0[i32(6)] - u32(1)) * area_0 + pixel_1]), vec4<f32>((f_0 - f32(a_0))));
}

fn filteredFreeze52_0( p_2 : TFParams_0) -> bool
{
    var _S3 : bool;
    if((p_2.family_0) != u32(0))
    {
        _S3 = true;
    }
    else
    {
        _S3 = (p_2.customMap_0) != u32(0);
    }
    if(_S3)
    {
        _S3 = true;
    }
    else
    {
        _S3 = ((p_2.pixel_0) > 0.0f);
    }
    if(_S3)
    {
        _S3 = true;
    }
    else
    {
        if((p_2.shape_0) != u32(0))
        {
            _S3 = (p_2.shape_0) != u32(1);
        }
        else
        {
            _S3 = false;
        }
        if(_S3)
        {
            _S3 = (p_2.shape_0) != u32(2);
        }
        else
        {
            _S3 = false;
        }
    }
    if(_S3)
    {
        return false;
    }
    if((p_2.shape_0) != u32(2))
    {
        _S3 = ((p_2.direction_0) < u32(2));
    }
    else
    {
        _S3 = false;
    }
    if(_S3)
    {
        _S3 = (p_2.outputW_0) == (p_2.sampleW_0);
    }
    else
    {
        _S3 = false;
    }
    if(_S3)
    {
        _S3 = (p_2.outputH_0) == (p_2.sampleH_0);
    }
    else
    {
        _S3 = false;
    }
    if(_S3)
    {
        var _S4 : f32;
        if((p_2.shape_0) == u32(1))
        {
            _S4 = p_2.sampleH_0;
        }
        else
        {
            _S4 = p_2.sampleW_0;
        }
        var pitch_0 : f32 = _S4 / max(2.0f, p_2.slices_0);
        if(((abs(pitch_0 - round(pitch_0))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    return true;
}

fn stripeGradient52_0( p_3 : TFParams_0) -> vec2<f32>
{
    if((p_3.shape_0) == u32(0))
    {
        return vec2<f32>(1.0f, 0.0f);
    }
    if((p_3.shape_0) == u32(1))
    {
        return vec2<f32>(0.0f, 1.0f);
    }
    var a_1 : f32 = p_3.angle_0 * 3.1415927410125732f / 180.0f;
    var _S5 : f32 = cos(a_1);
    var _S6 : f32 = sin(a_1);
    return vec2<f32>(p_3.outputW_0, p_3.outputH_0) * vec2<f32>(_S5, _S6) / vec2<f32>(max(1.0f, abs(p_3.outputW_0 * _S5) + abs(p_3.outputH_0 * _S6)));
}

fn stripeAxis52_0( uv_0 : vec2<f32>,  p_4 : TFParams_0) -> f32
{
    var gradient_0 : vec2<f32> = stripeGradient52_0(p_4);
    return clamp(dot(uv_0, gradient_0) - min(0.0f, gradient_0.x) - min(0.0f, gradient_0.y), 0.0f, 1.0f);
}

fn tentArea52_0( x_0 : f32) -> f32
{
    var _S7 : f32 = clamp(x_0, -1.0f, 1.0f);
    var _S8 : f32;
    if((_S7 <= 0.0f))
    {
        var _S9 : f32 = _S7 + 1.0f;
        _S8 = 0.5f * _S9 * _S9;
    }
    else
    {
        var _S10 : f32 = 1.0f - _S7;
        _S8 = 1.0f - 0.5f * _S10 * _S10;
    }
    return _S8;
}

struct StripeFootprint52_0
{
     first_0 : f32,
     last_0 : f32,
     low_0 : f32,
     high_0 : f32,
     center_0 : f32,
     step_0 : f32,
     count_0 : f32,
     normalization_0 : f32,
};

fn stripeFootprint52_0( uv_1 : vec2<f32>,  p_5 : TFParams_0) -> StripeFootprint52_0
{
    var gradient_1 : vec2<f32> = abs(stripeGradient52_0(p_5));
    var pixelStep_0 : f32 = gradient_1.x / p_5.sampleW_0 + gradient_1.y / p_5.sampleH_0;
    var f_1 : StripeFootprint52_0;
    var _S11 : f32 = max(2.0f, p_5.slices_0);
    var _S12 : f32;
    if(((p_5.direction_0) >= u32(2)))
    {
        _S12 = 2.0f;
    }
    else
    {
        _S12 = 1.0f;
    }
    var _S13 : f32 = _S11 * _S12;
    f_1.count_0 = _S13;
    var _S14 : f32 = stripeAxis52_0(uv_1, p_5) * _S13;
    f_1.center_0 = _S14;
    var _S15 : f32 = _S13 * pixelStep_0;
    f_1.step_0 = _S15;
    var _S16 : f32 = max(0.0f, _S14 - _S15);
    f_1.low_0 = _S16;
    var _S17 : f32 = min(_S13, _S14 + _S15);
    f_1.high_0 = _S17;
    f_1.first_0 = floor(_S16);
    f_1.last_0 = min(_S13 - 1.0f, ceil(_S17) - 1.0f);
    f_1.normalization_0 = max(9.99999993922529029e-09f, tentArea52_0((_S17 - _S14) / _S15) - tentArea52_0((_S16 - _S14) / _S15));
    return f_1;
}

fn stripeWeight52_0( low_1 : f32,  high_1 : f32,  f_2 : StripeFootprint52_0) -> f32
{
    return max(0.0f, tentArea52_0((high_1 - f_2.center_0) / f_2.step_0) - tentArea52_0((low_1 - f_2.center_0) / f_2.step_0));
}

fn bounce3_0( x_1 : f32) -> f32
{
    return 1.0f - abs(2.0f * fract(x_1 * 0.5f) - 1.0f);
}

struct Field_0
{
     a_2 : f32,
     b_0 : f32,
     weight_0 : f32,
     shade_0 : f32,
     uvA_0 : vec2<f32>,
     uvB_0 : vec2<f32>,
     light_0 : f32,
};

fn single3_0( uv_2 : vec2<f32>,  t_0 : f32) -> Field_0
{
    var f_3 : Field_0;
    f_3.a_2 = t_0;
    f_3.b_0 = t_0;
    f_3.weight_0 = 0.0f;
    f_3.shade_0 = 1.0f;
    f_3.uvA_0 = uv_2;
    f_3.uvB_0 = uv_2;
    f_3.light_0 = 1.0f;
    return f_3;
}

fn creativeAxis42_0( q_0 : f32,  direction_1 : u32) -> f32
{
    if(direction_1 == u32(1))
    {
        return 1.0f - q_0;
    }
    if((direction_1 >= u32(2)))
    {
        var _S18 : f32 = abs(q_0 - 0.5f) * 2.0f;
        var _S19 : f32;
        if(direction_1 == u32(3))
        {
            _S19 = 1.0f - _S18;
        }
        else
        {
            _S19 = _S18;
        }
        return _S19;
    }
    return q_0;
}

fn shadowArea42_0( distance_0 : f32,  solid_0 : f32,  feather_0 : f32) -> f32
{
    var _S20 : f32 = max(0.0f, distance_0);
    var t_1 : f32 = clamp((_S20 - solid_0) / feather_0, 0.0f, 1.0f);
    return min(_S20, solid_0) + feather_0 * t_1 * (1.0f - t_1 * t_1 * (1.0f - 0.5f * t_1));
}

fn repeatedShadowArea42_0( distance_1 : f32,  solid_1 : f32,  feather_1 : f32) -> f32
{
    return floor(distance_1) * (solid_1 + 0.5f * feather_1) + shadowArea42_0(fract(distance_1), solid_1, feather_1);
}

fn filteredLight42_0( distance_2 : f32,  span_1 : f32,  coverage_0 : f32,  filterWidth_0 : f32,  repeat_0 : bool,  p_6 : TFParams_0) -> f32
{
    var _S21 : bool;
    if((span_1 <= 1.0f))
    {
        _S21 = true;
    }
    else
    {
        _S21 = (coverage_0 <= 0.0f);
    }
    if(_S21)
    {
        return 1.0f;
    }
    var _S22 : f32 = min(0.77999997138977051f, max(p_6.shadowWidth_0, 1.5f / span_1));
    var halfPixel_0 : f32 = 0.5f * filterWidth_0 / span_1;
    if((distance_2 > (_S22 + halfPixel_0)))
    {
        if(!repeat_0)
        {
            _S21 = true;
        }
        else
        {
            _S21 = (distance_2 < (1.0f - halfPixel_0));
        }
    }
    else
    {
        _S21 = false;
    }
    if(_S21)
    {
        return 1.0f;
    }
    var feather_2 : f32 = _S22 * max(0.02500000037252903f, p_6.shadowSoftness_0);
    var solid_2 : f32 = _S22 - feather_2;
    var lo_0 : f32 = distance_2 - halfPixel_0;
    var hi_0 : f32 = distance_2 + halfPixel_0;
    var area_1 : f32;
    if(repeat_0)
    {
        area_1 = repeatedShadowArea42_0(hi_0, solid_2, feather_2) - repeatedShadowArea42_0(lo_0, solid_2, feather_2);
    }
    else
    {
        area_1 = shadowArea42_0(hi_0, solid_2, feather_2) - shadowArea42_0(lo_0, solid_2, feather_2);
    }
    return 1.0f - p_6.shadowStrength_0 * coverage_0 * (clamp(area_1 / (2.0f * halfPixel_0), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, span_1));
}

fn tiledLight42_0( phase_0 : f32,  span_2 : f32,  coverage_1 : f32,  p_7 : TFParams_0) -> f32
{
    var _S23 : f32;
    if(((p_7.shadowSide_0) > 0.0f))
    {
        _S23 = phase_0;
    }
    else
    {
        _S23 = 1.0f - phase_0;
    }
    return filteredLight42_0(_S23, span_2, coverage_1, 1.2999999523162842f, true, p_7);
}

fn rot3_0( v_1 : vec2<f32>,  a_3 : f32) -> vec2<f32>
{
    var _S24 : f32 = cos(a_3);
    var _S25 : f32 = v_1.x;
    var _S26 : f32 = sin(a_3);
    var _S27 : f32 = v_1.y;
    return vec2<f32>(_S24 * _S25 + _S26 * _S27, - _S26 * _S25 + _S24 * _S27);
}

fn edgeLight42_0( phase_1 : f32,  span_3 : f32,  coverage_2 : f32,  p_8 : TFParams_0) -> f32
{
    var _S28 : f32;
    if(((p_8.shadowSide_0) > 0.0f))
    {
        _S28 = phase_1;
    }
    else
    {
        _S28 = 1.0f - phase_1;
    }
    return filteredLight42_0(_S28, span_3, coverage_2, 1.0f, false, p_8);
}

fn creative42_0( uv_3 : vec2<f32>,  p_9 : TFParams_0) -> Field_0
{
    var center_1 : vec2<f32> = vec2<f32>(p_9.cx_0, p_9.cy_0);
    var metric_0 : vec2<f32> = vec2<f32>(p_9.aspect_0, 1.0f);
    var _S29 : vec2<f32> = uv_3 - center_1;
    var v_2 : vec2<f32> = _S29 * metric_0;
    var clock_0 : f32 = 2.0f * p_9.cycles_0 * p_9.u_0;
    var _S30 : f32 = max(2.0f, p_9.slices_0);
    var f_4 : Field_0 = single3_0(uv_3, bounce3_0(clock_0 + 1.0f));
    switch(p_9.design_0)
    {
    case u32(407):
        {
            var y_0 : f32 = uv_3.y - p_9.cy_0;
            var band_0 : f32 = (creativeAxis42_0(uv_3.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_0 + 0.34999999403953552f * p_9.u_0)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_0 - 0.69999998807907104f * p_9.u_0))), p_9.direction_0) - 0.51999998092651367f * p_9.cycles_0 * p_9.u_0) * _S30;
            var cell_0 : f32 = floor(band_0);
            var t_2 : f32 = bounce3_0(clock_0 - 0.75f * cell_0 / _S30);
            var _S31 : f32 = mix(t_2, 1.0f - t_2, fract(cell_0 * 0.5f) * 2.0f * p_9.span_0);
            f_4.b_0 = _S31;
            f_4.a_2 = _S31;
            if(((p_9.shadowStrength_0) > 0.0f))
            {
                f_4.light_0 = tiledLight42_0(fract(band_0), p_9.sampleW_0 / _S30, 1.0f, p_9);
            }
        }
    case u32(408):
        {
            var pitch_1 : f32 = sqrt(2.0f * p_9.aspect_0 / (1.7320507764816284f * _S30));
            const basis_0 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_0 : vec2<f32> = rot3_0(v_2, 0.15999999642372131f * sin(6.2831854820251465f * p_9.u_0)) / vec2<f32>(pitch_1);
            var _S32 : vec2<f32> = vec2<f32>(0.5f);
            var a_4 : vec2<f32> = floor(pos_0 / basis_0 + _S32) * basis_0;
            var b_1 : vec2<f32> = floor(pos_0 / basis_0) * basis_0 + basis_0 * _S32;
            var da_0 : vec2<f32> = pos_0 - a_4;
            var db_0 : vec2<f32> = pos_0 - b_1;
            var first_1 : bool = ((dot(da_0, da_0)) <= (dot(db_0, db_0)));
            var cell_1 : vec2<f32>;
            if(first_1)
            {
                cell_1 = a_4;
            }
            else
            {
                cell_1 = b_1;
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
            var _S33 : f32 = cell_1.x;
            var _S34 : f32 = cell_1.y;
            var row_0 : f32 = round(2.0f * _S34 / 1.7320507764816284f);
            var _S35 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_0 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S33 * pitch_1 / p_9.aspect_0, p_9.direction_0) + 0.34000000357627869f * _S34 * pitch_1 + 1.1000000238418579f * fract((round(_S33 - 0.5f * row_0) - row_0) / 3.0f)) * p_9.span_0));
            f_4.b_0 = _S35;
            f_4.a_2 = _S35;
            var _S36 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_0.y)));
            if(((p_9.shadowStrength_0) > 0.0f))
            {
                f_4.light_0 = edgeLight42_0(0.5f + 0.5f * local_0.x / _S36, 2.0f * _S36 * pitch_1 * p_9.sampleH_0, 1.0f, p_9);
            }
        }
    case u32(409):
        {
            var swing_0 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * p_9.u_0);
            var focal_0 : f32 = 0.2199999988079071f * min(p_9.aspect_0, 1.0f);
            var focus_0 : vec2<f32> = vec2<f32>(cos(swing_0), sin(swing_0)) * vec2<f32>(focal_0);
            var range_0 : f32 = 2.0f * (max(length(max(center_1, vec2<f32>(1.0f) - center_1) * metric_0), 0.0010000000474974513f) - focal_0) + 0.039999999105930328f;
            var band_1 : f32 = creativeAxis42_0(clamp((length(v_2 - focus_0) + length(v_2 + focus_0) - 2.0f * focal_0) / max(0.019999999552965164f, range_0), 0.0f, 1.0f), p_9.direction_0) * _S30 - 0.77999997138977051f * p_9.cycles_0 * p_9.u_0;
            var cell_2 : f32 = floor(band_1);
            var t_3 : f32 = bounce3_0(clock_0 - p_9.span_0 * cell_2 / _S30);
            var _S37 : f32 = mix(t_3, 1.0f - t_3, 0.80000001192092896f * fract(cell_2 * 0.5f) * 2.0f);
            f_4.b_0 = _S37;
            f_4.a_2 = _S37;
            if(((p_9.shadowStrength_0) > 0.0f))
            {
                f_4.light_0 = tiledLight42_0(fract(band_1), range_0 * 0.5f * p_9.sampleH_0 / _S30, 1.0f, p_9);
            }
        }
    case u32(410):
        {
            var _S38 : f32 = min(3.0f, _S30);
            var shift_0 : vec2<f32> = _S29 + vec2<f32>(0.5f);
            var _S39 : f32 = shift_0.y * _S38;
            var row_1 : f32 = floor(_S39);
            var base_0 : f32 = floor(_S30 / _S38);
            var _S40 : i32;
            if(((clamp(row_1, 0.0f, _S38 - 1.0f)) < (_S30 - base_0 * _S38)))
            {
                _S40 = i32(1);
            }
            else
            {
                _S40 = i32(0);
            }
            var cols_0 : f32 = base_0 + f32(_S40);
            var x_2 : f32 = shift_0.x * cols_0 - (0.62999999523162842f + 0.12999999523162842f * row_1) * p_9.cycles_0 * creativeAxis42_0(p_9.u_0, p_9.direction_0) + 0.36000001430511475f * row_1;
            var col_0 : f32 = floor(x_2);
            var _S41 : f32 = fract(x_2) - 0.5f;
            var _S42 : f32 = fract(_S39) - 0.5f;
            var roundBox_0 : vec2<f32> = abs(vec2<f32>(_S41, _S42)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_0 : f32 = length(max(roundBox_0, vec2<f32>(0.0f))) + min(max(roundBox_0.x, roundBox_0.y), 0.0f) - 0.075000002980232239f;
            var aa_0 : f32 = max(cols_0 / p_9.sampleW_0, _S38 / p_9.sampleH_0) * 1.1000000238418579f;
            f_4.a_2 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_0 + 0.69999998807907104f);
            f_4.b_0 = bounce3_0(clock_0 - 0.40999999642372131f * col_0 - 0.28999999165534973f * row_1) * p_9.span_0 + 0.039999999105930328f;
            f_4.weight_0 = 1.0f - smoothstep(- aa_0, aa_0, edge_0);
            var _S43 : f32 = max(0.0f, abs(_S42) - 0.33000001311302185f);
            var bound_0 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S43 * _S43));
            if(((p_9.shadowStrength_0) > 0.0f))
            {
                f_4.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * _S41 / bound_0, 0.0f, 1.0f), 2.0f * bound_0 * p_9.sampleW_0 / cols_0, f_4.weight_0, p_9);
            }
        }
    default :
        {
        }
    }
    return f_4;
}

fn gridSize3_0( n_2 : f32,  size_0 : vec2<f32>) -> vec2<f32>
{
    var _S44 : f32 = size_0.y;
    var rows_0 : f32 = clamp(round(sqrt(n_2 * _S44 / size_0.x)), 1.0f, min(_S44, n_2));
    return vec2<f32>(floor(n_2 / rows_0), rows_0);
}

fn isStripe42_0( p_10 : TFParams_0) -> bool
{
    var _S45 : bool;
    if((p_10.customMap_0) == u32(0))
    {
        _S45 = ((p_10.direction_0) < u32(2));
    }
    else
    {
        _S45 = false;
    }
    if(_S45)
    {
        if((p_10.shape_0) == u32(0))
        {
            _S45 = true;
        }
        else
        {
            _S45 = (p_10.shape_0) == u32(1);
        }
        if(_S45)
        {
            _S45 = true;
        }
        else
        {
            _S45 = (p_10.shape_0) == u32(11);
        }
    }
    else
    {
        _S45 = false;
    }
    return _S45;
}

fn rasterStripeIndex42_0( pixel_2 : f32,  lengthPx_0 : f32,  count_1 : f32) -> f32
{
    if(((max(lengthPx_0, count_1)) <= 32768.0f))
    {
        var index_0 : u32 = (u32(2) * u32(pixel_2) + u32(1)) * u32(count_1) / (u32(2) * u32(lengthPx_0));
        return min(f32(index_0), count_1 - 1.0f);
    }
    return min(floor((pixel_2 + 0.5f) * count_1 / lengthPx_0), count_1 - 1.0f);
}

struct Coord_0
{
     raw_0 : f32,
     q_1 : f32,
     index_1 : f32,
     coverage_3 : f32,
     cell_3 : vec2<f32>,
     frac_0 : vec2<f32>,
};

fn coordinate3_0( uv_4 : vec2<f32>,  p_11 : TFParams_0,  mapValue_0 : f32) -> Coord_0
{
    var c_0 : Coord_0;
    var _S46 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_0.cell_3 = _S46;
    c_0.frac_0 = _S46;
    c_0.index_1 = 0.0f;
    c_0.coverage_3 = 1.0f;
    var _S47 : f32 = uv_4.x;
    var _S48 : f32 = max(2.0f, p_11.slices_0);
    var dim_0 : vec2<f32> = vec2<f32>(p_11.outputW_0, p_11.outputH_0);
    var _S49 : vec2<f32> = vec2<f32>(p_11.cx_0, p_11.cy_0);
    var v_3 : vec2<f32> = (uv_4 - _S49) * dim_0;
    var _S50 : vec2<f32> = vec2<f32>(1.0f);
    var radii_0 : vec2<f32> = max(_S49, _S50 - _S49) * dim_0;
    var _S51 : f32 = max(length(radii_0), 1.0f);
    var rmin_0 : f32 = length(max(_S46, max((vec2<f32>(0) - _S49), _S49 - _S50)) * dim_0);
    var q_2 : f32;
    var lengthPx_1 : f32;
    var _S52 : i32;
    var _S53 : bool;
    switch(p_11.shape_0)
    {
    case u32(0):
        {
            q_2 = _S47;
        }
    case u32(1):
        {
            q_2 = uv_4.y;
        }
    case u32(2), u32(12):
        {
            var a_5 : f32 = p_11.angle_0 * 3.1415927410125732f / 180.0f;
            var _S54 : f32 = cos(a_5);
            var _S55 : f32 = sin(a_5);
            var _S56 : f32 = p_11.outputW_0 * _S54;
            var _S57 : f32 = p_11.outputH_0 * _S55;
            var q_3 : f32 = (dot(uv_4 * dim_0, vec2<f32>(_S54, _S55)) - (min(0.0f, _S56) + min(0.0f, _S57))) / max(1.0f, abs(_S56) + abs(_S57));
            if((p_11.shape_0) == u32(12))
            {
                q_2 = q_3 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(uv_4.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_2 = q_3;
            }
        }
    case u32(3):
        {
            switch(p_11.origin_0)
            {
            case u32(1):
                {
                    q_2 = atan2(v_3.y, v_3.x);
                }
            case u32(2):
                {
                    q_2 = atan2(v_3.x, - v_3.y);
                }
            case u32(3):
                {
                    q_2 = atan2(- v_3.x, v_3.y);
                }
            default :
                {
                    q_2 = atan2(- v_3.y, - v_3.x);
                }
            }
            if((q_2 >= 0.0f))
            {
                _S53 = (q_2 <= 3.1415927410125732f);
            }
            else
            {
                _S53 = false;
            }
            if(_S53)
            {
                _S52 = i32(1);
            }
            else
            {
                _S52 = i32(0);
            }
            c_0.coverage_3 = f32(_S52);
            q_2 = clamp(q_2 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            q_2 = fract(atan2(v_3.x, - v_3.y) / 6.2831854820251465f + 1.0f - p_11.turns_0 * p_11.u_0);
        }
    case u32(5), u32(14):
        {
            q_2 = (length(v_3) - rmin_0) / max(1.0f, _S51 - rmin_0);
        }
    case u32(6), u32(7):
        {
            var vr_0 : vec2<f32> = rot3_0(v_3, p_11.angle_0 * 3.1415927410125732f / 180.0f + p_11.turns_0 * 2.0f * 3.1415927410125732f * p_11.u_0);
            if((p_11.shape_0) == u32(6))
            {
                q_2 = (abs(vr_0.x) + abs(vr_0.y)) / max(1.0f, radii_0.x + radii_0.y);
            }
            else
            {
                q_2 = max(abs(vr_0.x) / max(radii_0.x, 1.0f), abs(vr_0.y) / max(radii_0.y, 1.0f));
            }
        }
    case u32(8), u32(10):
        {
            var _S58 : bool = (p_11.shape_0) == u32(10);
            if(_S58)
            {
                q_2 = max(1.0f, ceil(_S48 / 2.0f));
            }
            else
            {
                q_2 = _S48;
            }
            var gs_0 : vec2<f32> = gridSize3_0(q_2, dim_0);
            var _S59 : f32 = gs_0.y;
            var _S60 : f32 = uv_4.y * _S59;
            var _S61 : f32 = min(floor(_S60), _S59 - 1.0f);
            var _S62 : f32 = gs_0.x;
            var extra_0 : f32 = q_2 - _S62 * _S59;
            if((_S61 < extra_0))
            {
                _S52 = i32(1);
            }
            else
            {
                _S52 = i32(0);
            }
            var cols_1 : f32 = _S62 + f32(_S52);
            var _S63 : f32 = _S47 * cols_1;
            var _S64 : f32 = min(floor(_S63), cols_1 - 1.0f);
            var index_2 : f32 = _S61 * _S62 + min(_S61, extra_0) + _S64;
            c_0.cell_3 = vec2<f32>(_S64, _S61);
            c_0.frac_0 = fract(vec2<f32>(_S63, _S60));
            if(_S58)
            {
                var _S65 : f32 = _S48 - 1.0f;
                var _S66 : f32 = index_2 * 2.0f;
                if(((c_0.frac_0.x + c_0.frac_0.y) >= 1.0f))
                {
                    _S52 = i32(1);
                }
                else
                {
                    _S52 = i32(0);
                }
                lengthPx_1 = min(_S65, _S66 + f32(_S52));
            }
            else
            {
                lengthPx_1 = index_2;
            }
            q_2 = lengthPx_1 / max(1.0f, _S48 - 1.0f);
        }
    case u32(9):
        {
            q_2 = fract(atan2(v_3.y, v_3.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_3) / _S51));
        }
    case u32(11):
        {
            q_2 = _S47;
        }
    case u32(13):
        {
            q_2 = length(v_3) / max(1.0f, _S51 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * atan2(v_3.y, v_3.x))));
        }
    default :
        {
            q_2 = _S47;
        }
    }
    if((p_11.customMap_0) != u32(0))
    {
        c_0.coverage_3 = 1.0f;
        q_2 = mapValue_0;
    }
    var q_4 : f32 = clamp(q_2, 0.0f, 1.0f);
    var _S67 : bool = (p_11.direction_0) == u32(1);
    if(_S67)
    {
        q_2 = 1.0f - q_4;
    }
    else
    {
        q_2 = q_4;
    }
    if(((p_11.direction_0) >= u32(2)))
    {
        if((p_11.shape_0) == u32(8))
        {
            _S53 = true;
        }
        else
        {
            _S53 = (p_11.shape_0) == u32(10);
        }
        if(_S53)
        {
            q_2 = max(abs(_S47 - 0.5f), abs(uv_4.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_2 = abs(q_2 - 0.5f) * 2.0f;
        }
        if((p_11.direction_0) == u32(3))
        {
            q_2 = 1.0f - q_2;
        }
    }
    c_0.raw_0 = q_2;
    var _S68 : f32 = _S48 - 1.0f;
    c_0.index_1 = min(floor(q_2 * _S48), _S68);
    if(isStripe42_0(p_11))
    {
        if(filteredFreeze52_0(p_11))
        {
            _S53 = ((p_11.reserved0_0) > 0.0f);
        }
        else
        {
            _S53 = false;
        }
        _S53 = !_S53;
    }
    else
    {
        _S53 = false;
    }
    if(_S53)
    {
        var _S69 : bool = (p_11.shape_0) == u32(1);
        if(_S69)
        {
            lengthPx_1 = p_11.sampleH_0;
        }
        else
        {
            lengthPx_1 = p_11.sampleW_0;
        }
        var _S70 : f32;
        if(_S69)
        {
            _S70 = uv_4.y;
        }
        else
        {
            _S70 = _S47;
        }
        var pixel_3 : f32 = floor(_S70 * lengthPx_1);
        if(_S67)
        {
            _S70 = lengthPx_1 - 1.0f - pixel_3;
        }
        else
        {
            _S70 = pixel_3;
        }
        var _S71 : f32 = rasterStripeIndex42_0(_S70, lengthPx_1, _S48);
        c_0.index_1 = _S71;
    }
    if(((p_11.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_2 = c_0.index_1 / _S68;
    }
    c_0.q_1 = q_2;
    return c_0;
}

fn play3_0( x_3 : f32,  mode_0 : u32) -> f32
{
    var _S72 : f32;
    if(mode_0 == u32(0))
    {
        _S72 = clamp(x_3, 0.0f, 1.0f);
    }
    else
    {
        if(mode_0 == u32(2))
        {
            _S72 = fract(x_3);
        }
        else
        {
            _S72 = bounce3_0(x_3);
        }
    }
    return _S72;
}

fn creative3_0( uv_5 : vec2<f32>,  c_1 : Coord_0,  p_12 : TFParams_0) -> Field_0
{
    var clock_1 : f32 = 2.0f * p_12.cycles_0 * p_12.u_0;
    var _S73 : f32 = max(2.0f, p_12.slices_0);
    var center_2 : vec2<f32> = vec2<f32>(p_12.cx_0, p_12.cy_0);
    var metric_1 : vec2<f32> = vec2<f32>(p_12.aspect_0, 1.0f);
    var v_4 : vec2<f32> = (uv_5 - center_2) * metric_1;
    var _S74 : f32 = bounce3_0(clock_1);
    var f_5 : Field_0 = single3_0(uv_5, _S74);
    var band_2 : f32;
    var phase_2 : f32;
    var lateral_0 : f32;
    var q_5 : f32;
    var i_0 : i32;
    var horizontal_0 : bool;
    switch(p_12.design_0)
    {
    case u32(9):
        {
            var _S75 : f32 = length(v_4);
            var phase_3 : f32 = fract(2.0f * (atan2(v_4.x, - v_4.y) / 6.2831854820251465f) + _S75 / max(length(metric_1 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * p_12.span_0);
            var _S76 : bool = ((p_12.pixel_0) > 0.0f);
            if(_S76)
            {
                band_2 = phase_3 - p_12.cycles_0 * p_12.u_0;
            }
            else
            {
                band_2 = phase_3 * _S73;
            }
            if((p_12.pixel_0) == 0.0f)
            {
                phase_2 = floor(band_2) / (_S73 - 1.0f);
            }
            else
            {
                phase_2 = phase_3;
            }
            var _S77 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(p_12.cycles_0 * p_12.u_0 - phase_2);
            f_5.b_0 = _S77;
            f_5.a_2 = _S77;
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                var _S78 : f32 = fract(band_2);
                var _S79 : f32 = min(3.1415927410125732f * _S75 * p_12.sampleH_0, p_12.sampleH_0);
                if(_S76)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = _S73;
                }
                f_5.light_0 = tiledLight42_0(_S78, _S79 / band_2, 1.0f, p_12);
            }
        }
    case u32(10):
        {
            var q_6 : f32 = clamp(1.0f - abs(uv_5.x - p_12.cx_0) * 2.0f, 0.0f, 1.0f);
            var _S80 : f32 = _S73 - 1.0f;
            var band_3 : f32 = q_6 * _S80;
            if((p_12.pixel_0) == 0.0f)
            {
                q_5 = floor(band_3) / _S80;
            }
            else
            {
                q_5 = q_6;
            }
            var _S81 : f32 = 0.80000001192092896f * p_12.span_0;
            var _S82 : f32 = _S81 * q_5;
            var _S83 : f32 = bounce3_0(clock_1 - _S82);
            f_5.b_0 = _S83;
            f_5.a_2 = _S83;
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                var _S84 : bool = ((p_12.pixel_0) > 0.0f);
                if(_S84)
                {
                    band_2 = _S82 - clock_1;
                }
                else
                {
                    band_2 = band_3;
                }
                var _S85 : f32 = fract(band_2);
                var _S86 : f32 = 0.5f * p_12.sampleW_0;
                if(_S84)
                {
                    band_2 = _S81;
                }
                else
                {
                    band_2 = _S80;
                }
                f_5.light_0 = tiledLight42_0(_S85, _S86 / band_2, 1.0f, p_12);
            }
        }
    case u32(11):
        {
            var _S87 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, p_12.softness_0 * 0.15999999642372131f);
            var _S88 : f32 = c_1.frac_0.y;
            var ah_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S87, abs(_S88 - 0.5f));
            var _S89 : f32 = c_1.frac_0.x;
            var av_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S87, abs(_S89 - 0.5f));
            var _S90 : f32 = c_1.cell_3.y;
            var over_0 : bool = (i32(floor(c_1.cell_3.x) + floor(_S90)) % i32(2)) == i32(0);
            var ht_0 : f32 = bounce3_0(clock_1 - uv_5.x * p_12.span_0);
            var vt_0 : f32 = bounce3_0(clock_1 + uv_5.y * p_12.span_0 + 1.0f);
            var _S91 : bool = (ah_0 > 0.0f);
            if(_S91)
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
                f_5.a_2 = band_2;
                if(over_0)
                {
                    band_2 = ht_0;
                }
                else
                {
                    band_2 = vt_0;
                }
                f_5.b_0 = band_2;
                if(over_0)
                {
                    band_2 = ah_0;
                }
                else
                {
                    band_2 = av_0;
                }
                f_5.weight_0 = band_2;
                if(ah_0 == 0.0f)
                {
                    f_5.b_0 = vt_0;
                    f_5.a_2 = vt_0;
                }
                if(av_0 == 0.0f)
                {
                    f_5.b_0 = ht_0;
                    f_5.a_2 = ht_0;
                }
            }
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                if(_S91)
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
                    if(_S91)
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
                    phase_2 = _S88;
                }
                else
                {
                    phase_2 = _S89;
                }
                var phase_4 : f32 = clamp((phase_2 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_0 : vec2<f32> = gridSize3_0(_S73, vec2<f32>(p_12.outputW_0, p_12.outputH_0));
                var _S92 : f32 = grid_0.x;
                var _S93 : f32 = grid_0.y;
                if((_S90 < (_S73 - _S92 * _S93)))
                {
                    i_0 = i32(1);
                }
                else
                {
                    i_0 = i32(0);
                }
                var cols_2 : f32 = _S92 + f32(i_0);
                if(horizontal_0)
                {
                    phase_2 = p_12.sampleH_0 / _S93;
                }
                else
                {
                    phase_2 = p_12.sampleW_0 / cols_2;
                }
                f_5.light_0 = edgeLight42_0(phase_4, 0.47999998927116394f * phase_2, band_2, p_12);
            }
        }
    case u32(12):
        {
            var sources_0 : u32 = clamp(p_12.waveSources_0, u32(2), u32(4));
            var i_1 : u32 = u32(0);
            band_2 = 0.0f;
            loop
            {
                if((i_1 < sources_0))
                {
                }
                else
                {
                    break;
                }
                var a_6 : f32 = 6.2831854820251465f * f32(i_1) / f32(sources_0);
                var r_0 : f32 = length((uv_5 - (center_2 + vec2<f32>(0.18000000715255737f * cos(a_6), 0.18000000715255737f * sin(a_6)))) * metric_1);
                var band_4 : f32 = r_0 * _S73;
                if((p_12.pixel_0) == 0.0f)
                {
                    phase_2 = floor(band_4) / _S73;
                }
                else
                {
                    phase_2 = r_0;
                }
                var _S94 : f32 = phase_2 * 1.2999999523162842f * p_12.span_0;
                var sum_0 : f32 = band_2 + bounce3_0(clock_1 - _S94);
                if(((p_12.shadowStrength_0) > 0.0f))
                {
                    var _S95 : bool = ((p_12.pixel_0) > 0.0f);
                    if(_S95)
                    {
                        lateral_0 = _S94 - clock_1;
                    }
                    else
                    {
                        lateral_0 = band_4;
                    }
                    var phase_5 : f32 = fract(lateral_0);
                    var _S96 : f32 = f_5.light_0;
                    if(_S95)
                    {
                        q_5 = 1.2999999523162842f * p_12.span_0;
                    }
                    else
                    {
                        q_5 = _S73;
                    }
                    f_5.light_0 = min(_S96, tiledLight42_0(phase_5, p_12.sampleH_0 / q_5, 1.0f, p_12));
                }
                i_1 = i_1 + u32(1);
                band_2 = sum_0;
            }
            var _S97 : f32 = band_2 / f32(sources_0);
            f_5.b_0 = _S97;
            f_5.a_2 = _S97;
        }
    case u32(13):
        {
            var _S98 : f32 = 6.2831854820251465f * p_12.u_0;
            var _S99 : f32 = sin(_S98);
            var local_1 : vec2<f32> = (uv_5 - (center_2 + vec2<f32>(0.2199999988079071f * _S99, 0.12999999523162842f * cos(_S98)))) * metric_1;
            var r_1 : f32 = length(local_1);
            var radius_0 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S99;
            var _S100 : f32 = max(0.0020000000949949026f, p_12.softness_0 * 0.15999999642372131f);
            f_5.b_0 = bounce3_0(clock_1 + 0.80000001192092896f * p_12.span_0);
            f_5.weight_0 = 1.0f - smoothstep(radius_0 - _S100, radius_0 + _S100, r_1);
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                horizontal_0 = ((f_5.weight_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S101 : f32 = local_1.y;
                var halfWidth_0 : f32 = sqrt(max(9.99999997475242708e-07f, radius_0 * radius_0 - _S101 * _S101));
                f_5.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * local_1.x / halfWidth_0, 0.0f, 1.0f), 2.0f * halfWidth_0 * p_12.sampleH_0, f_5.weight_0, p_12);
            }
        }
    case u32(400):
        {
            var _S102 : f32 = max(_S73, 2.0f);
            var gap_0 : f32 = 0.64999997615814209f / _S102;
            var d_0 : f32 = fract(p_12.u_0 * p_12.cycles_0) * 1.6499999761581421f - uv_5.x;
            var j_0 : f32 = floor(d_0 / gap_0);
            var local_2 : f32 = fract(d_0 / gap_0);
            if((j_0 >= 0.0f))
            {
                horizontal_0 = (j_0 < _S102);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S103 : f32 = max(0.014999999664723873f, p_12.softness_0 * 0.15000000596046448f);
                var a_7 : f32 = smoothstep(0.0f, _S103, local_2) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S103, local_2));
                f_5.b_0 = clamp(1.0f - j_0 / _S102, 0.0f, 1.0f);
                f_5.weight_0 = a_7 * (1.0f - 0.64999997615814209f * j_0 / _S102);
            }
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_0(clamp(1.0f - local_2 / 0.64999997615814209f, 0.0f, 1.0f), gap_0 * 0.64999997615814209f * p_12.sampleW_0, f_5.weight_0, p_12);
            }
        }
    case u32(401):
        {
            var _S104 : f32 = uv_5.y;
            if((i32(floor(_S104 * _S73)) % i32(2)) == i32(0))
            {
                band_2 = 1.0f;
            }
            else
            {
                band_2 = -1.0f;
            }
            var gap_1 : f32 = 0.34999999403953552f * smoothstep(_S74 - 0.059999998658895493f, _S74 + 0.059999998658895493f, _S104);
            var seam_0 : f32 = p_12.cx_0 + band_2 * 0.02500000037252903f;
            var _S105 : f32 = uv_5.x;
            var _S106 : f32 = _S105 - seam_0;
            var outside_0 : bool = ((abs(_S106)) > gap_1);
            if(outside_0)
            {
                if((_S105 < seam_0))
                {
                    band_2 = 0.079999998211860657f;
                }
                else
                {
                    band_2 = 0.94999998807907104f;
                }
                f_5.b_0 = band_2;
                f_5.a_2 = band_2;
            }
            var _S107 : bool = ((p_12.shadowStrength_0) > 0.0f);
            if(_S107)
            {
                var _S108 : f32 = clamp((_S106 + gap_1) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S109 : f32 = 0.2199999988079071f * p_12.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S105 < seam_0);
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
                f_5.light_0 = edgeLight42_0(_S108, _S109, band_2, p_12);
            }
            if(_S107)
            {
                horizontal_0 = ((p_12.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S110 : f32 = clamp((_S106 - gap_1) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S111 : f32 = 0.2199999988079071f * p_12.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S105 > seam_0);
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
                f_5.light_0 = edgeLight42_0(_S110, _S111, band_2, p_12);
            }
        }
    case u32(402):
        {
            var a_8 : f32 = atan2(v_4.y, v_4.x);
            var r_2 : f32 = length(v_4);
            var radius_1 : f32 = 0.4699999988079071f * min(p_12.aspect_0, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * p_12.u_0 * p_12.cycles_0)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_8 * _S73));
            var _S112 : f32 = max(0.0010000000474974513f, p_12.softness_0 * 0.019999999552965164f);
            var _S113 : f32 = fract((a_8 + 3.1415927410125732f) / 6.2831854820251465f) * _S73;
            f_5.b_0 = bounce3_0(clock_1 + floor(_S113) / _S73 * p_12.span_0);
            f_5.weight_0 = 1.0f - smoothstep(radius_1 - _S112, radius_1 + _S112, r_2);
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_0(fract(_S113), 6.2831854820251465f * r_2 * p_12.sampleH_0 / _S73, f_5.weight_0, p_12);
            }
        }
    case u32(403):
        {
            var r_3 : f32 = length(v_4);
            var _S114 : f32 = max(3.0f, _S73);
            var sector_0 : f32 = 6.2831854820251465f / _S114;
            var _S115 : f32 = atan2(v_4.y, v_4.x) + p_12.u_0 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_0 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * p_12.u_0 * p_12.cycles_0))) * min(p_12.aspect_0, 1.0f) * cos(3.1415927410125732f / _S114) / max(0.0010000000474974513f, cos(fract(_S115 / sector_0) * sector_0 - sector_0 * 0.5f));
            f_5.a_2 = bounce3_0(clock_1 - p_12.span_0 * floor(fract(_S115 / 6.2831854820251465f) * _S114) / _S114);
            f_5.b_0 = bounce3_0(clock_1 + 1.0f);
            f_5.weight_0 = 1.0f - smoothstep(aperture_0 - 0.0020000000949949026f, aperture_0 + 0.0020000000949949026f, r_3);
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_0(fract(_S115 / sector_0), sector_0 * r_3 * p_12.sampleH_0, 1.0f - f_5.weight_0, p_12);
            }
        }
    case u32(404):
        {
            var _S116 : f32 = fract(p_12.u_0 * p_12.cycles_0);
            band_2 = 1.0e+09f;
            phase_2 = 0.0f;
            lateral_0 = 0.0f;
            i_0 = i32(0);
            loop
            {
                if((i_0 < i32(32)))
                {
                }
                else
                {
                    break;
                }
                var _S117 : f32 = f32(i_0);
                var a0_0 : f32 = 6.2831854820251465f * _S117 / 32.0f;
                var _S118 : i32 = i_0 + i32(1);
                var a1_0 : f32 = 6.2831854820251465f * f32(_S118) / 32.0f;
                var a_9 : vec2<f32> = center_2 + vec2<f32>(0.34000000357627869f * sin(a0_0), 0.2199999988079071f * sin(2.0f * a0_0));
                var segment_0 : vec2<f32> = (center_2 + vec2<f32>(0.34000000357627869f * sin(a1_0), 0.2199999988079071f * sin(2.0f * a1_0)) - a_9) * metric_1;
                var point_0 : vec2<f32> = (uv_5 - a_9) * metric_1;
                var k_0 : f32 = clamp(dot(point_0, segment_0) / max(dot(segment_0, segment_0), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_0 : vec2<f32> = point_0 - vec2<f32>(k_0) * segment_0;
                var distance_3 : f32 = dot(delta_0, delta_0);
                var trail_0 : f32 = fract(_S116 - (_S117 + k_0) / 32.0f + 1.0f);
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
                    if(((p_12.shadowStrength_0) > 0.0f))
                    {
                        if(((dot(delta_0, vec2<f32>(segment_0.y, - segment_0.x))) >= 0.0f))
                        {
                            q_5 = 1.0f;
                        }
                        else
                        {
                            q_5 = -1.0f;
                        }
                    }
                    else
                    {
                        q_5 = lateral_0;
                    }
                    band_2 = distance_3;
                    phase_2 = trail_0;
                    lateral_0 = q_5;
                }
                i_0 = _S118;
            }
            var _S119 : f32 = max(0.0020000000949949026f, p_12.softness_0 * 0.039999999105930328f);
            var best_0 : f32 = sqrt(band_2);
            f_5.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S119, 0.035000000149011612f + _S119, best_0);
            var q_7 : f32 = phase_2 / 0.60000002384185791f;
            if((p_12.pixel_0) == 0.0f)
            {
                q_5 = floor(q_7 * _S73) / (_S73 - 1.0f);
            }
            else
            {
                q_5 = q_7;
            }
            f_5.b_0 = 0.15000000596046448f + 0.85000002384185791f * q_5;
            if(((p_12.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_0(clamp(0.5f + best_0 * lateral_0 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * p_12.sampleH_0, f_5.weight_0, p_12);
            }
        }
    default :
        {
        }
    }
    return f_5;
}

fn frozen3_0( uv_6 : vec2<f32>,  c_2 : Coord_0,  p_13 : TFParams_0) -> Field_0
{
    var build_1 : f32 = clamp(p_13.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var _S120 : bool = ((p_13.pixel_0) > 0.0f);
    var held_0 : f32;
    if(_S120)
    {
        held_0 = c_2.raw_0;
    }
    else
    {
        held_0 = min(1.0f, (c_2.index_1 + 1.0f) / max(2.0f, p_13.slices_0));
    }
    var a_10 : f32;
    if(((p_13.u_0) < build_1))
    {
        var progress_0 : f32 = p_13.u_0 / build_1;
        var _S121 : bool;
        if(_S120)
        {
            _S121 = true;
        }
        else
        {
            _S121 = (((p_13.flags_0) & (u32(1)))) != u32(0);
        }
        if(_S121)
        {
            var _S122 : f32 = max(1.0f / max(p_13.outputW_0, p_13.outputH_0), p_13.softness_0 * 0.0030000000260770321f);
            a_10 = 1.0f - smoothstep(progress_0 - _S122, progress_0 + _S122, c_2.raw_0);
        }
        else
        {
            var _S123 : i32;
            if((progress_0 >= (c_2.q_1)))
            {
                _S123 = i32(1);
            }
            else
            {
                _S123 = i32(0);
            }
            a_10 = f32(_S123);
        }
        var f_6 : Field_0 = single3_0(uv_6, progress_0);
        f_6.b_0 = held_0;
        f_6.weight_0 = a_10;
        return f_6;
    }
    var after_0 : f32 = clamp((p_13.u_0 - build_1) / (1.0f - build_1), 0.0f, 1.0f);
    switch(p_13.ending_0)
    {
    case u32(0):
        {
            a_10 = held_0;
        }
    case u32(1):
        {
            a_10 = clamp(held_0 + after_0, 0.0f, 1.0f);
        }
    case u32(2):
        {
            var release_0 : f32 = c_2.q_1 * 0.64999997615814209f;
            a_10 = clamp(held_0 + max(0.0f, after_0 - release_0) / max(0.05000000074505806f, 1.0f - release_0), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_0 > 0.0f))
            {
                held_0 = play3_0(held_0 - 2.0f * p_13.cycles_0 * after_0, p_13.playback_0);
            }
            a_10 = held_0;
        }
    case u32(4):
        {
            a_10 = bounce3_0(held_0 - 2.0f * p_13.cycles_0 * after_0);
        }
    default :
        {
            a_10 = held_0;
        }
    }
    return single3_0(uv_6, a_10);
}

fn relative3_0( c_3 : Coord_0,  p_14 : TFParams_0) -> f32
{
    var d_1 : f32;
    if((((p_14.flags_0) & (u32(4)))) != u32(0))
    {
        d_1 = (c_3.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if((((p_14.flags_0) & (u32(8)))) != u32(0))
        {
            d_1 = (c_3.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_1 = 2.0f * c_3.raw_0 - 1.0f;
        }
    }
    if((p_14.pixel_0) == 0.0f)
    {
        var _S124 : f32 = p_14.slices_0 - 1.0f;
        var positive_0 : f32 = ceil(_S124 / 2.0f);
        var negative_0 : f32 = floor(_S124 / 2.0f);
        var _S125 : f32;
        if((d_1 < 0.0f))
        {
            _S125 = negative_0;
        }
        else
        {
            _S125 = positive_0;
        }
        var _S126 : f32 = max(1.0f, _S125);
        d_1 = round(d_1 * _S126) / _S126;
    }
    return p_14.span_0 * d_1;
}

fn basic3_0( uv_7 : vec2<f32>,  c_4 : Coord_0,  p_15 : TFParams_0) -> Field_0
{
    var clock_2 : f32 = 2.0f * p_15.cycles_0 * p_15.u_0;
    var t_4 : f32;
    if((p_15.customMap_0) != u32(0))
    {
        if((((p_15.flags_0) & (u32(2)))) != u32(0))
        {
            t_4 = p_15.u_0 + relative3_0(c_4, p_15);
        }
        else
        {
            t_4 = c_4.q_1 + clock_2;
        }
        return single3_0(uv_7, play3_0(t_4, p_15.playback_0));
    }
    if((p_15.design_0) == u32(0))
    {
        t_4 = 0.20000000298023224f + 0.80000001192092896f * fract(p_15.cycles_0 * p_15.u_0 - c_4.q_1);
    }
    else
    {
        if((p_15.design_0) == u32(5))
        {
            t_4 = bounce3_0(1.0f - clock_2 - p_15.span_0 * c_4.q_1);
        }
        else
        {
            if((p_15.shape_0) == u32(11))
            {
                if((i32(c_4.index_1) % i32(2)) == i32(0))
                {
                    t_4 = 1.0f;
                }
                else
                {
                    t_4 = -1.0f;
                }
                t_4 = play3_0(1.0f + clock_2 * t_4 - p_15.span_0 * c_4.q_1, p_15.playback_0);
            }
            else
            {
                t_4 = play3_0(1.0f + clock_2 - p_15.span_0 * c_4.q_1, p_15.playback_0);
            }
        }
    }
    return single3_0(uv_7, t_4);
}

fn wave3_0( uv_8 : vec2<f32>,  c_5 : Coord_0,  p_16 : TFParams_0) -> Field_0
{
    var _S127 : bool;
    if((p_16.customMap_0) != u32(0))
    {
        _S127 = (((p_16.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S127 = false;
    }
    var phase_6 : f32;
    if(_S127)
    {
        phase_6 = 2.0f * p_16.cycles_0 * p_16.u_0 + relative3_0(c_5, p_16);
    }
    else
    {
        phase_6 = 2.0f * p_16.cycles_0 * p_16.u_0 - 2.0f * p_16.density_0 * c_5.q_1;
    }
    return single3_0(uv_8, play3_0(phase_6, p_16.playback_0));
}

fn coordSpan42_0( uv_9 : vec2<f32>,  p_17 : TFParams_0) -> f32
{
    var size_1 : vec2<f32> = vec2<f32>(p_17.sampleW_0, p_17.sampleH_0);
    var _S128 : vec2<f32> = vec2<f32>(p_17.cx_0, p_17.cy_0);
    var v_5 : vec2<f32> = (uv_9 - _S128) * size_1;
    var _S129 : vec2<f32> = vec2<f32>(1.0f);
    var radii_1 : vec2<f32> = max(_S128, _S129 - _S128) * size_1;
    if((p_17.customMap_0) != u32(0))
    {
        return min(p_17.sampleW_0, p_17.sampleH_0);
    }
    switch(p_17.shape_0)
    {
    case u32(1):
        {
            return p_17.sampleH_0;
        }
    case u32(2), u32(12):
        {
            var a_11 : f32 = p_17.angle_0 * 3.1415927410125732f / 180.0f;
            return p_17.sampleW_0 * abs(cos(a_11)) + p_17.sampleH_0 * abs(sin(a_11));
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
            return length(radii_1) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S128), _S128 - _S129)) * size_1);
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
            return p_17.sampleW_0;
        }
    }
}

fn stripeBorder42_0( cut_0 : f32,  lengthPx_2 : f32,  count_2 : f32) -> f32
{
    if(((max(lengthPx_2, count_2)) <= 32768.0f))
    {
        var n_3 : u32 = u32(count_2);
        var numerator_0 : u32 = u32(2) * u32(cut_0) * u32(lengthPx_2);
        var _S130 : f32;
        if((numerator_0 <= n_3))
        {
            _S130 = 0.0f;
        }
        else
        {
            var _S131 : u32 = (numerator_0 + n_3 - u32(1)) / (u32(2) * n_3);
            _S130 = f32(_S131);
        }
        return _S130;
    }
    return clamp(ceil(cut_0 * lengthPx_2 / count_2 - 0.5f), 0.0f, lengthPx_2);
}

fn stripeLight42_0( axis_0 : f32,  index_3 : f32,  lengthPx_3 : f32,  count_3 : f32,  reverse_0 : bool,  coverage_4 : f32,  p_18 : TFParams_0) -> f32
{
    var span_4 : f32 = lengthPx_3 / count_3;
    if((span_4 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_0 : bool = ((p_18.shadowSide_0) > 0.0f);
    var center_3 : f32;
    if(leading_0)
    {
        center_3 = 0.0f;
    }
    else
    {
        center_3 = 1.0f;
    }
    var edge_1 : f32 = stripeBorder42_0(index_3 + center_3, lengthPx_3, count_3);
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
        center_3 = center_3 - edge_1;
    }
    else
    {
        center_3 = edge_1 - center_3;
    }
    return filteredLight42_0(max(0.5f, center_3) / span_4, span_4, coverage_4, 1.0f, false, p_18);
}

fn sliceLight42_0( uv_10 : vec2<f32>,  c_6 : Coord_0,  p_19 : TFParams_0,  coverage_5 : f32) -> f32
{
    var _S132 : f32 = max(2.0f, p_19.slices_0);
    var _S133 : bool = (p_19.shape_0) == u32(8);
    var _S134 : bool;
    if(_S133)
    {
        _S134 = true;
    }
    else
    {
        _S134 = (p_19.shape_0) == u32(10);
    }
    if(_S134)
    {
        _S134 = (p_19.customMap_0) == u32(0);
    }
    else
    {
        _S134 = false;
    }
    if(_S134)
    {
        _S134 = ((p_19.direction_0) < u32(2));
    }
    else
    {
        _S134 = false;
    }
    var cells_0 : f32;
    var x_4 : f32;
    if(_S134)
    {
        var _S135 : bool = (p_19.shape_0) == u32(10);
        if(_S135)
        {
            cells_0 = ceil(_S132 / 2.0f);
        }
        else
        {
            cells_0 = _S132;
        }
        var grid_1 : vec2<f32> = gridSize3_0(cells_0, vec2<f32>(p_19.outputW_0, p_19.outputH_0));
        var _S136 : f32 = grid_1.x;
        var _S137 : i32;
        if(((c_6.cell_3.y) < (cells_0 - _S136 * grid_1.y)))
        {
            _S137 = i32(1);
        }
        else
        {
            _S137 = i32(0);
        }
        var x_5 : f32 = c_6.frac_0.x;
        var span_5 : f32 = p_19.sampleW_0 / (_S136 + f32(_S137));
        var span_6 : f32;
        if(_S135)
        {
            var cut_1 : f32 = 1.0f - c_6.frac_0.y;
            var first_2 : bool = (x_5 < cut_1);
            if(first_2)
            {
                cells_0 = cut_1;
            }
            else
            {
                cells_0 = 1.0f - cut_1;
            }
            var span_7 : f32 = span_5 * cells_0;
            if(first_2)
            {
                cells_0 = x_5 / max(cut_1, 9.99999997475242708e-07f);
            }
            else
            {
                cells_0 = (x_5 - cut_1) / max(1.0f - cut_1, 9.99999997475242708e-07f);
            }
            x_4 = cells_0;
            span_6 = span_7;
        }
        else
        {
            x_4 = x_5;
            span_6 = span_5;
        }
        var phase_7 : f32;
        if((p_19.direction_0) == u32(1))
        {
            phase_7 = 1.0f - x_4;
        }
        else
        {
            phase_7 = x_4;
        }
        if(_S133)
        {
            cells_0 = tiledLight42_0(phase_7, span_6, coverage_5, p_19);
        }
        else
        {
            cells_0 = edgeLight42_0(phase_7, span_6, coverage_5, p_19);
        }
        return cells_0;
    }
    var span_8 : f32 = coordSpan42_0(uv_10, p_19);
    if(((p_19.direction_0) >= u32(2)))
    {
        cells_0 = span_8 * 0.5f;
    }
    else
    {
        cells_0 = span_8;
    }
    if(((p_19.pixel_0) > 0.0f))
    {
        _S134 = (p_19.family_0) == u32(2);
    }
    else
    {
        _S134 = false;
    }
    if(_S134)
    {
        if((p_19.customMap_0) != u32(0))
        {
            _S134 = (((p_19.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S134 = false;
        }
        if(_S134)
        {
            x_4 = 2.0f * p_19.span_0;
        }
        else
        {
            x_4 = 2.0f * p_19.density_0;
        }
        var _S138 : f32 = max(0.0099999997764825821f, x_4);
        return tiledLight42_0(fract(_S138 * c_6.raw_0 - 2.0f * p_19.cycles_0 * p_19.u_0), cells_0 / _S138, coverage_5, p_19);
    }
    if(isStripe42_0(p_19))
    {
        if((p_19.shape_0) == u32(1))
        {
            x_4 = uv_10.y;
        }
        else
        {
            x_4 = uv_10.x;
        }
        var _S139 : f32 = stripeLight42_0(x_4, c_6.index_1, cells_0, _S132, (p_19.direction_0) == u32(1), coverage_5, p_19);
        return _S139;
    }
    return tiledLight42_0(clamp(c_6.raw_0 * _S132 - c_6.index_1, 0.0f, 1.0f), cells_0 / _S132, coverage_5, p_19);
}

fn evaluate3_0( uv_11 : vec2<f32>,  p_20 : TFParams_0,  mapValue_1 : f32) -> Field_0
{
    if(((p_20.design_0) >= u32(407)))
    {
        return creative42_0(uv_11, p_20);
    }
    var c_7 : Coord_0 = coordinate3_0(uv_11, p_20, mapValue_1);
    var base_1 : f32;
    if((c_7.coverage_3) == 0.0f)
    {
        if((p_20.family_0) == u32(0))
        {
            base_1 = play3_0(p_20.u_0 / max(0.10000000149011612f, p_20.build_0), p_20.playback_0);
        }
        else
        {
            if((p_20.family_0) == u32(1))
            {
                base_1 = 1.0f;
            }
            else
            {
                base_1 = 0.0f;
            }
            base_1 = play3_0(base_1 + 2.0f * p_20.cycles_0 * p_20.u_0, p_20.playback_0);
        }
        return single3_0(uv_11, base_1);
    }
    if((p_20.family_0) == u32(3))
    {
        return creative3_0(uv_11, c_7, p_20);
    }
    var f_7 : Field_0;
    var _S140 : bool = (p_20.family_0) == u32(0);
    var _S141 : Field_0;
    if(_S140)
    {
        _S141 = frozen3_0(uv_11, c_7, p_20);
    }
    else
    {
        if((p_20.family_0) == u32(1))
        {
            _S141 = basic3_0(uv_11, c_7, p_20);
        }
        else
        {
            _S141 = wave3_0(uv_11, c_7, p_20);
        }
    }
    f_7 = _S141;
    if(((p_20.shadowStrength_0) > 0.0f))
    {
        var _S142 : bool;
        if(_S140)
        {
            _S142 = ((p_20.u_0) < (clamp(p_20.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S142 = false;
        }
        if(_S142)
        {
            base_1 = f_7.weight_0;
        }
        else
        {
            base_1 = 1.0f;
        }
        if((base_1 > 0.0f))
        {
            var _S143 : f32 = sliceLight42_0(uv_11, c_7, p_20, base_1);
            f_7.light_0 = _S143;
        }
    }
    return f_7;
}

fn shadowTentPart52_0( low_2 : f32,  high_2 : f32,  feathered_0 : bool,  solid_3 : f32,  feather_3 : f32,  mid_0 : f32,  center_5 : f32,  step_1 : f32,  distance_4 : f32,  sign_0 : f32,  slope_0 : f32) -> f32
{
    if((high_2 <= low_2))
    {
        return 0.0f;
    }
    var m_0 : f32 = (low_2 + high_2) * 0.5f;
    var r_4 : f32 = (high_2 - low_2) * 0.5f;
    var w0_0 : f32 = max(0.0f, 1.0f + slope_0 * (mid_0 - center_5 + sign_0 * (m_0 - distance_4)) / step_1) / step_1;
    if(!feathered_0)
    {
        return 2.0f * r_4 * w0_0;
    }
    var t_5 : f32 = clamp((m_0 - solid_3) / feather_3, 0.0f, 1.0f);
    var _S144 : f32 = 6.0f * t_5;
    var _S145 : f32 = feather_3 * feather_3;
    var w1_0 : f32 = slope_0 * sign_0 / (step_1 * step_1);
    var r2_0 : f32 = r_4 * r_4;
    return max(0.0f, 2.0f * r_4 * (w0_0 * (1.0f - t_5 * t_5 * (3.0f - 2.0f * t_5)) + (w0_0 * ((_S144 - 3.0f) / _S145) + w1_0 * (_S144 * (t_5 - 1.0f) / feather_3)) * r2_0 / 3.0f + w1_0 * (2.0f / (_S145 * feather_3)) * r2_0 * r2_0 / 5.0f));
}

fn shadowTentSide52_0( low_3 : f32,  high_3 : f32,  mid_1 : f32,  center_6 : f32,  step_2 : f32,  distance_5 : f32,  sign_1 : f32,  slope_1 : f32,  p_21 : TFParams_0) -> f32
{
    if((high_3 <= low_3))
    {
        return 0.0f;
    }
    var a_12 : f32 = distance_5 + sign_1 * (low_3 - mid_1);
    var b_2 : f32 = distance_5 + sign_1 * (high_3 - mid_1);
    var lo_1 : f32 = clamp(min(a_12, b_2), 0.0f, 1.0f);
    var hi_1 : f32 = clamp(max(a_12, b_2), 0.0f, 1.0f);
    var width_0 : f32 = clamp(p_21.shadowWidth_0, 0.019999999552965164f, 0.75f);
    var feather_4 : f32 = width_0 * max(0.02500000037252903f, p_21.shadowSoftness_0);
    var solid_4 : f32 = width_0 - feather_4;
    return shadowTentPart52_0(lo_1, min(hi_1, solid_4), false, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1) + shadowTentPart52_0(max(lo_1, solid_4), min(hi_1, width_0), true, solid_4, feather_4, mid_1, center_6, step_2, distance_5, sign_1, slope_1);
}

fn stripeSample52_0( uv_12 : vec2<f32>,  p_22 : TFParams_0,  footprint_0 : StripeFootprint52_0,  low_4 : f32,  high_4 : f32,  weight_1 : f32) -> Field_0
{
    var _S146 : TFParams_0 = p_22;
    var mid_2 : f32 = (low_4 + high_4) * 0.5f;
    var axis_1 : f32 = mid_2 / footprint_0.count_0;
    var gradient_2 : vec2<f32> = stripeGradient52_0(p_22);
    var _S147 : vec2<f32> = uv_12 + gradient_2 * vec2<f32>(((axis_1 - stripeAxis52_0(uv_12, p_22)) / max(9.99999993922529029e-09f, dot(gradient_2, gradient_2))));
    _S146.reserved0_0 = 1.0f;
    var _S148 : Field_0 = evaluate3_0(_S147, _S146, 0.0f);
    var f_8 : Field_0 = _S148;
    if(((_S146.shadowStrength_0) <= 0.0f))
    {
        return f_8;
    }
    var c_8 : Coord_0 = coordinate3_0(_S147, _S146, 0.0f);
    var phase_8 : f32 = clamp(c_8.raw_0 * max(2.0f, _S146.slices_0) - c_8.index_1, 0.0f, 1.0f);
    var distance_6 : f32;
    if(((_S146.shadowSide_0) > 0.0f))
    {
        distance_6 = phase_8;
    }
    else
    {
        distance_6 = 1.0f - phase_8;
    }
    var sign_2 : f32;
    if((_S146.direction_0) == u32(1))
    {
        sign_2 = -1.0f;
    }
    else
    {
        sign_2 = 1.0f;
    }
    var coverage_6 : f32;
    if(((_S146.direction_0) >= u32(2)))
    {
        if((axis_1 < 0.5f))
        {
            sign_2 = -1.0f;
        }
        else
        {
            sign_2 = 1.0f;
        }
        if((_S146.direction_0) == u32(3))
        {
            coverage_6 = -1.0f;
        }
        else
        {
            coverage_6 = 1.0f;
        }
        sign_2 = sign_2 * coverage_6;
    }
    if((_S146.shadowSide_0) == 0.0f)
    {
        sign_2 = - sign_2;
    }
    var mass_0 : f32 = shadowTentSide52_0(low_4, min(high_4, footprint_0.center_0), mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, 1.0f, _S146) + shadowTentSide52_0(max(low_4, footprint_0.center_0), high_4, mid_2, footprint_0.center_0, footprint_0.step_0, distance_6, sign_2, -1.0f, _S146);
    var gradient_3 : vec2<f32> = abs(gradient_2);
    var fade_0 : f32 = smoothstep(1.0f, 2.5f, 1.0f / max(9.99999993922529029e-09f, gradient_3.x / _S146.outputW_0 + gradient_3.y / _S146.outputH_0) / footprint_0.count_0);
    if(((_S146.u_0) < (clamp(_S146.build_0, 0.10000000149011612f, 0.89999997615814209f))))
    {
        coverage_6 = f_8.weight_0;
    }
    else
    {
        coverage_6 = 1.0f;
    }
    f_8.light_0 = 1.0f - _S146.shadowStrength_0 * coverage_6 * fade_0 * clamp(mass_0 / max(weight_1, 9.99999993922529029e-09f), 0.0f, 1.0f);
    return f_8;
}

fn filteredStripeColor52_0( uv_13 : vec2<f32>,  local_3 : u32,  p_23 : TFParams_0) -> vec4<f32>
{
    var footprint_1 : StripeFootprint52_0 = stripeFootprint52_0(uv_13, p_23);
    var _S149 : vec4<f32> = vec4<f32>(vec4<i32>(i32(0)));
    var cell_4 : i32 = i32(footprint_1.first_0);
    var result_0 : vec4<f32> = _S149;
    loop
    {
        if((cell_4 <= i32(footprint_1.last_0)))
        {
        }
        else
        {
            break;
        }
        var _S150 : f32 = max(footprint_1.low_0, f32(cell_4));
        var _S151 : i32 = cell_4 + i32(1);
        var _S152 : f32 = min(footprint_1.high_0, f32(_S151));
        var weight_2 : f32 = stripeWeight52_0(_S150, _S152, footprint_1);
        if((weight_2 <= 9.99999993922529029e-09f))
        {
            cell_4 = _S151;
            continue;
        }
        var f_9 : Field_0 = stripeSample52_0(uv_13, p_23, footprint_1, _S150, _S152, weight_2);
        var blend_0 : f32 = clamp(f_9.weight_0, 0.0f, 1.0f);
        var color_0 : vec4<f32>;
        if((p_23.viewMode_0) == u32(2))
        {
            var t_6 : f32 = adjusted3_0(mix(clamp(f_9.a_2, 0.0f, 1.0f), clamp(f_9.b_0, 0.0f, 1.0f), blend_0), p_23);
            color_0 = vec4<f32>(t_6, t_6, t_6, 1.0f);
        }
        else
        {
            if(blend_0 == 1.0f)
            {
                color_0 = sampleSource_0(f_9.b_0, local_3, p_23) * vec4<f32>(f_9.shade_0);
            }
            else
            {
                color_0 = sampleSource_0(f_9.a_2, local_3, p_23);
                if((blend_0 > 0.0f))
                {
                    color_0 = mix(color_0, sampleSource_0(f_9.b_0, local_3, p_23) * vec4<f32>(f_9.shade_0), vec4<f32>(blend_0));
                }
            }
            var _S153 : vec3<f32> = color_0.xyz * vec3<f32>(f_9.light_0);
            color_0.x = _S153.x;
            color_0.y = _S153.y;
            color_0.z = _S153.z;
        }
        result_0 = result_0 + color_0 * vec4<f32>(weight_2) / vec4<f32>(footprint_1.normalization_0);
        cell_4 = _S151;
    }
    return result_0;
}

fn pack_0( c_9 : vec4<f32>) -> u32
{
    var _S154 : vec4<u32> = vec4<u32>(round(clamp(c_9, vec4<f32>(0.0f), vec4<f32>(1.0f)) * vec4<f32>(255.0f)));
    return ((((((_S154.x) | ((((_S154.y) << (u32(8))))))) | ((((_S154.z) << (u32(16))))))) | (u32(4278190080)));
}

@compute
@workgroup_size(8, 8, 1)
fn render(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S155 : u32 = id_0.x;
    var _S156 : bool;
    if((_S155 >= cfg_0[i32(2)]))
    {
        _S156 = true;
    }
    else
    {
        _S156 = ((id_0.y) >= cfg_0[i32(3)]);
    }
    if(_S156)
    {
        _S156 = true;
    }
    else
    {
        _S156 = ((id_0.z) >= cfg_0[i32(8)]);
    }
    if(_S156)
    {
        return;
    }
    var _S157 : u32 = id_0.y;
    var local_4 : u32 = _S157 * cfg_0[i32(2)] + _S155;
    var uv_14 : vec2<f32> = (vec2<f32>(id_0.xy + vec2<u32>(cfg_0[i32(0)], cfg_0[i32(1)])) + vec2<f32>(0.5f)) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)]));
    var p_24 : TFParams_0;
    p_24.outTime_0 = param_0.outTime_0;
    p_24.u_0 = param_0.u_0;
    p_24.sourceDuration_0 = param_0.sourceDuration_0;
    p_24.aspect_0 = param_0.aspect_0;
    p_24.slices_0 = param_0.slices_0;
    p_24.pixel_0 = param_0.pixel_0;
    p_24.span_0 = param_0.span_0;
    p_24.cycles_0 = param_0.cycles_0;
    p_24.cx_0 = param_0.cx_0;
    p_24.cy_0 = param_0.cy_0;
    p_24.angle_0 = param_0.angle_0;
    p_24.turns_0 = param_0.turns_0;
    p_24.build_0 = param_0.build_0;
    p_24.softness_0 = param_0.softness_0;
    p_24.density_0 = param_0.density_0;
    p_24.sourceReverse_0 = param_0.sourceReverse_0;
    p_24.sourceStart_0 = param_0.sourceStart_0;
    p_24.sourceEnd_0 = param_0.sourceEnd_0;
    p_24.outputW_0 = param_0.outputW_0;
    p_24.outputH_0 = param_0.outputH_0;
    p_24.family_0 = param_0.family_0;
    p_24.shape_0 = param_0.shape_0;
    p_24.design_0 = param_0.design_0;
    p_24.ending_0 = param_0.ending_0;
    p_24.direction_0 = param_0.direction_0;
    p_24.playback_0 = param_0.playback_0;
    p_24.origin_0 = param_0.origin_0;
    p_24.viewMode_0 = param_0.viewMode_0;
    p_24.frames_0 = param_0.frames_0;
    p_24.customMap_0 = param_0.customMap_0;
    p_24.waveSources_0 = param_0.waveSources_0;
    p_24.flags_0 = param_0.flags_0;
    p_24.shadowStrength_0 = param_0.shadowStrength_0;
    p_24.shadowWidth_0 = param_0.shadowWidth_0;
    p_24.shadowSoftness_0 = param_0.shadowSoftness_0;
    p_24.shadowSide_0 = param_0.shadowSide_0;
    p_24.sampleW_0 = param_0.sampleW_0;
    p_24.sampleH_0 = param_0.sampleH_0;
    p_24.reserved0_0 = param_0.reserved0_0;
    p_24.reserved1_0 = param_0.reserved1_0;
    var _S158 : u32 = id_0.z;
    var _S159 : f32 = f32(cfg_0[i32(7)] + _S158) / f32(max(u32(1), cfg_0[i32(9)]));
    p_24.u_0 = _S159;
    p_24.outTime_0 = _S159;
    var color_1 : vec4<f32>;
    if((p_24.viewMode_0) == u32(1))
    {
        color_1 = sampleSource_0(p_24.u_0, local_4, p_24);
    }
    else
    {
        if(filteredFreeze52_0(p_24))
        {
            var _S160 : vec4<f32> = filteredStripeColor52_0(uv_14, local_4, p_24);
            color_1 = _S160;
        }
        else
        {
            var _S161 : TFParams_0 = p_24;
            var _S162 : f32;
            if((p_24.customMap_0) != u32(0))
            {
                _S162 = timeMap_0[local_4];
            }
            else
            {
                _S162 = 0.0f;
            }
            var f_10 : Field_0 = evaluate3_0(uv_14, _S161, _S162);
            var weight_3 : f32 = clamp(f_10.weight_0, 0.0f, 1.0f);
            if((p_24.viewMode_0) == u32(2))
            {
                var n_4 : f32 = adjusted3_0(mix(clamp(f_10.a_2, 0.0f, 1.0f), clamp(f_10.b_0, 0.0f, 1.0f), weight_3), p_24);
                color_1 = vec4<f32>(n_4, n_4, n_4, 1.0f);
            }
            else
            {
                if(weight_3 == 1.0f)
                {
                    color_1 = sampleSource_0(f_10.b_0, local_4, p_24) * vec4<f32>(f_10.shade_0);
                }
                else
                {
                    color_1 = sampleSource_0(f_10.a_2, local_4, p_24);
                    if((weight_3 > 0.0f))
                    {
                        color_1 = mix(color_1, sampleSource_0(f_10.b_0, local_4, p_24) * vec4<f32>(f_10.shade_0), vec4<f32>(weight_3));
                    }
                }
                var _S163 : vec3<f32> = color_1.xyz * vec3<f32>(f_10.light_0);
                color_1.x = _S163.x;
                color_1.y = _S163.y;
                color_1.z = _S163.z;
            }
        }
    }
    output_0[(_S158 * cfg_0[i32(3)] + _S157) * cfg_0[i32(2)] + _S155] = pack_0(color_1);
    return;
}

