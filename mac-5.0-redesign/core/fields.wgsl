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
@binding(3) @group(0) var<storage, read> timeMap_0 : array<f32>;

@binding(5) @group(0) var<storage, read_write> diagnostics_0 : array<vec4<f32>>;

fn bounce3_0( x_0 : f32) -> f32
{
    return 1.0f - abs(2.0f * fract(x_0 * 0.5f) - 1.0f);
}

struct Field_0
{
     a_0 : f32,
     b_0 : f32,
     weight_0 : f32,
     shade_0 : f32,
     uvA_0 : vec2<f32>,
     uvB_0 : vec2<f32>,
     light_0 : f32,
};

fn single3_0( uv_0 : vec2<f32>,  t_0 : f32) -> Field_0
{
    var f_0 : Field_0;
    f_0.a_0 = t_0;
    f_0.b_0 = t_0;
    f_0.weight_0 = 0.0f;
    f_0.shade_0 = 1.0f;
    f_0.uvA_0 = uv_0;
    f_0.uvB_0 = uv_0;
    f_0.light_0 = 1.0f;
    return f_0;
}

fn creativeAxis42_0( q_0 : f32,  direction_1 : u32) -> f32
{
    if(direction_1 == u32(1))
    {
        return 1.0f - q_0;
    }
    if((direction_1 >= u32(2)))
    {
        var _S1 : f32 = abs(q_0 - 0.5f) * 2.0f;
        var _S2 : f32;
        if(direction_1 == u32(3))
        {
            _S2 = 1.0f - _S1;
        }
        else
        {
            _S2 = _S1;
        }
        return _S2;
    }
    return q_0;
}

fn shadowArea42_0( distance_0 : f32,  solid_0 : f32,  feather_0 : f32) -> f32
{
    var _S3 : f32 = max(0.0f, distance_0);
    var t_1 : f32 = clamp((_S3 - solid_0) / feather_0, 0.0f, 1.0f);
    return min(_S3, solid_0) + feather_0 * t_1 * (1.0f - t_1 * t_1 * (1.0f - 0.5f * t_1));
}

fn repeatedShadowArea42_0( distance_1 : f32,  solid_1 : f32,  feather_1 : f32) -> f32
{
    return floor(distance_1) * (solid_1 + 0.5f * feather_1) + shadowArea42_0(fract(distance_1), solid_1, feather_1);
}

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

fn filteredLight42_0( distance_2 : f32,  span_1 : f32,  coverage_0 : f32,  filterWidth_0 : f32,  repeat_0 : bool,  p_0 : TFParams_0) -> f32
{
    var _S4 : bool;
    if((span_1 <= 1.0f))
    {
        _S4 = true;
    }
    else
    {
        _S4 = (coverage_0 <= 0.0f);
    }
    if(_S4)
    {
        return 1.0f;
    }
    var _S5 : f32 = min(0.77999997138977051f, max(p_0.shadowWidth_0, 1.5f / span_1));
    var halfPixel_0 : f32 = 0.5f * filterWidth_0 / span_1;
    if((distance_2 > (_S5 + halfPixel_0)))
    {
        if(!repeat_0)
        {
            _S4 = true;
        }
        else
        {
            _S4 = (distance_2 < (1.0f - halfPixel_0));
        }
    }
    else
    {
        _S4 = false;
    }
    if(_S4)
    {
        return 1.0f;
    }
    var feather_2 : f32 = _S5 * max(0.02500000037252903f, p_0.shadowSoftness_0);
    var solid_2 : f32 = _S5 - feather_2;
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
    return 1.0f - p_0.shadowStrength_0 * coverage_0 * (clamp(area_0 / (2.0f * halfPixel_0), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, span_1));
}

fn tiledLight42_0( phase_0 : f32,  span_2 : f32,  coverage_1 : f32,  p_1 : TFParams_0) -> f32
{
    var _S6 : f32;
    if(((p_1.shadowSide_0) > 0.0f))
    {
        _S6 = phase_0;
    }
    else
    {
        _S6 = 1.0f - phase_0;
    }
    return filteredLight42_0(_S6, span_2, coverage_1, 1.2999999523162842f, true, p_1);
}

fn rot3_0( v_0 : vec2<f32>,  a_1 : f32) -> vec2<f32>
{
    var _S7 : f32 = cos(a_1);
    var _S8 : f32 = v_0.x;
    var _S9 : f32 = sin(a_1);
    var _S10 : f32 = v_0.y;
    return vec2<f32>(_S7 * _S8 + _S9 * _S10, - _S9 * _S8 + _S7 * _S10);
}

fn edgeLight42_0( phase_1 : f32,  span_3 : f32,  coverage_2 : f32,  p_2 : TFParams_0) -> f32
{
    var _S11 : f32;
    if(((p_2.shadowSide_0) > 0.0f))
    {
        _S11 = phase_1;
    }
    else
    {
        _S11 = 1.0f - phase_1;
    }
    return filteredLight42_0(_S11, span_3, coverage_2, 1.0f, false, p_2);
}

fn creative42_0( uv_1 : vec2<f32>,  p_3 : TFParams_0) -> Field_0
{
    var center_0 : vec2<f32> = vec2<f32>(p_3.cx_0, p_3.cy_0);
    var metric_0 : vec2<f32> = vec2<f32>(p_3.aspect_0, 1.0f);
    var _S12 : vec2<f32> = uv_1 - center_0;
    var v_1 : vec2<f32> = _S12 * metric_0;
    var clock_0 : f32 = 2.0f * p_3.cycles_0 * p_3.u_0;
    var _S13 : f32 = max(2.0f, p_3.slices_0);
    var f_1 : Field_0 = single3_0(uv_1, bounce3_0(clock_0 + 1.0f));
    switch(p_3.design_0)
    {
    case u32(407):
        {
            var y_0 : f32 = uv_1.y - p_3.cy_0;
            var band_0 : f32 = (creativeAxis42_0(uv_1.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_0 + 0.34999999403953552f * p_3.u_0)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_0 - 0.69999998807907104f * p_3.u_0))), p_3.direction_0) - 0.51999998092651367f * p_3.cycles_0 * p_3.u_0) * _S13;
            var cell_0 : f32 = floor(band_0);
            var t_2 : f32 = bounce3_0(clock_0 - 0.75f * cell_0 / _S13);
            var _S14 : f32 = mix(t_2, 1.0f - t_2, fract(cell_0 * 0.5f) * 2.0f * p_3.span_0);
            f_1.b_0 = _S14;
            f_1.a_0 = _S14;
            if(((p_3.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = tiledLight42_0(fract(band_0), p_3.sampleW_0 / _S13, 1.0f, p_3);
            }
        }
    case u32(408):
        {
            var pitch_0 : f32 = sqrt(2.0f * p_3.aspect_0 / (1.7320507764816284f * _S13));
            const basis_0 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_0 : vec2<f32> = rot3_0(v_1, 0.15999999642372131f * sin(6.2831854820251465f * p_3.u_0)) / vec2<f32>(pitch_0);
            var _S15 : vec2<f32> = vec2<f32>(0.5f);
            var a_2 : vec2<f32> = floor(pos_0 / basis_0 + _S15) * basis_0;
            var b_1 : vec2<f32> = floor(pos_0 / basis_0) * basis_0 + basis_0 * _S15;
            var da_0 : vec2<f32> = pos_0 - a_2;
            var db_0 : vec2<f32> = pos_0 - b_1;
            var first_0 : bool = ((dot(da_0, da_0)) <= (dot(db_0, db_0)));
            var cell_1 : vec2<f32>;
            if(first_0)
            {
                cell_1 = a_2;
            }
            else
            {
                cell_1 = b_1;
            }
            var local_0 : vec2<f32>;
            if(first_0)
            {
                local_0 = da_0;
            }
            else
            {
                local_0 = db_0;
            }
            var _S16 : f32 = cell_1.x;
            var _S17 : f32 = cell_1.y;
            var row_0 : f32 = round(2.0f * _S17 / 1.7320507764816284f);
            var _S18 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_0 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S16 * pitch_0 / p_3.aspect_0, p_3.direction_0) + 0.34000000357627869f * _S17 * pitch_0 + 1.1000000238418579f * fract((round(_S16 - 0.5f * row_0) - row_0) / 3.0f)) * p_3.span_0));
            f_1.b_0 = _S18;
            f_1.a_0 = _S18;
            var _S19 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_0.y)));
            if(((p_3.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = edgeLight42_0(0.5f + 0.5f * local_0.x / _S19, 2.0f * _S19 * pitch_0 * p_3.sampleH_0, 1.0f, p_3);
            }
        }
    case u32(409):
        {
            var swing_0 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * p_3.u_0);
            var focal_0 : f32 = 0.2199999988079071f * min(p_3.aspect_0, 1.0f);
            var focus_0 : vec2<f32> = vec2<f32>(cos(swing_0), sin(swing_0)) * vec2<f32>(focal_0);
            var range_0 : f32 = 2.0f * (max(length(max(center_0, vec2<f32>(1.0f) - center_0) * metric_0), 0.0010000000474974513f) - focal_0) + 0.039999999105930328f;
            var band_1 : f32 = creativeAxis42_0(clamp((length(v_1 - focus_0) + length(v_1 + focus_0) - 2.0f * focal_0) / max(0.019999999552965164f, range_0), 0.0f, 1.0f), p_3.direction_0) * _S13 - 0.77999997138977051f * p_3.cycles_0 * p_3.u_0;
            var cell_2 : f32 = floor(band_1);
            var t_3 : f32 = bounce3_0(clock_0 - p_3.span_0 * cell_2 / _S13);
            var _S20 : f32 = mix(t_3, 1.0f - t_3, 0.80000001192092896f * fract(cell_2 * 0.5f) * 2.0f);
            f_1.b_0 = _S20;
            f_1.a_0 = _S20;
            if(((p_3.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = tiledLight42_0(fract(band_1), range_0 * 0.5f * p_3.sampleH_0 / _S13, 1.0f, p_3);
            }
        }
    case u32(410):
        {
            var _S21 : f32 = min(3.0f, _S13);
            var shift_0 : vec2<f32> = _S12 + vec2<f32>(0.5f);
            var _S22 : f32 = shift_0.y * _S21;
            var row_1 : f32 = floor(_S22);
            var base_0 : f32 = floor(_S13 / _S21);
            var _S23 : i32;
            if(((clamp(row_1, 0.0f, _S21 - 1.0f)) < (_S13 - base_0 * _S21)))
            {
                _S23 = i32(1);
            }
            else
            {
                _S23 = i32(0);
            }
            var cols_0 : f32 = base_0 + f32(_S23);
            var x_1 : f32 = shift_0.x * cols_0 - (0.62999999523162842f + 0.12999999523162842f * row_1) * p_3.cycles_0 * creativeAxis42_0(p_3.u_0, p_3.direction_0) + 0.36000001430511475f * row_1;
            var col_0 : f32 = floor(x_1);
            var _S24 : f32 = fract(x_1) - 0.5f;
            var _S25 : f32 = fract(_S22) - 0.5f;
            var roundBox_0 : vec2<f32> = abs(vec2<f32>(_S24, _S25)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_0 : f32 = length(max(roundBox_0, vec2<f32>(0.0f))) + min(max(roundBox_0.x, roundBox_0.y), 0.0f) - 0.075000002980232239f;
            var aa_0 : f32 = max(cols_0 / p_3.sampleW_0, _S21 / p_3.sampleH_0) * 1.1000000238418579f;
            f_1.a_0 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_0 + 0.69999998807907104f);
            f_1.b_0 = bounce3_0(clock_0 - 0.40999999642372131f * col_0 - 0.28999999165534973f * row_1) * p_3.span_0 + 0.039999999105930328f;
            f_1.weight_0 = 1.0f - smoothstep(- aa_0, aa_0, edge_0);
            var _S26 : f32 = max(0.0f, abs(_S25) - 0.33000001311302185f);
            var bound_0 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S26 * _S26));
            if(((p_3.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * _S24 / bound_0, 0.0f, 1.0f), 2.0f * bound_0 * p_3.sampleW_0 / cols_0, f_1.weight_0, p_3);
            }
        }
    default :
        {
        }
    }
    return f_1;
}

fn axisAngle3_0( y_1 : f32,  x_2 : f32) -> f32
{
    var _S27 : f32 = abs(x_2);
    var _S28 : f32 = abs(y_1);
    if(((_S27 + _S28) < 9.99999997475242708e-07f))
    {
        return 0.0f;
    }
    var _S29 : f32;
    if((_S28 < 9.99999997475242708e-07f))
    {
        if((x_2 < 0.0f))
        {
            _S29 = 3.1415927410125732f;
        }
        else
        {
            _S29 = 0.0f;
        }
        return _S29;
    }
    if((_S27 < 9.99999997475242708e-07f))
    {
        if((y_1 > 0.0f))
        {
            _S29 = 1.5707963705062866f;
        }
        else
        {
            _S29 = -1.5707963705062866f;
        }
        return _S29;
    }
    return atan2(y_1, x_2);
}

fn gridSize3_0( n_0 : f32,  size_0 : vec2<f32>) -> vec2<f32>
{
    var _S30 : f32 = size_0.y;
    var rows_0 : f32 = clamp(round(sqrt(n_0 * _S30 / size_0.x)), 1.0f, min(_S30, n_0));
    return vec2<f32>(floor(n_0 / rows_0), rows_0);
}

fn isStripe42_0( p_4 : TFParams_0) -> bool
{
    var _S31 : bool;
    if((p_4.customMap_0) == u32(0))
    {
        _S31 = ((p_4.direction_0) < u32(2));
    }
    else
    {
        _S31 = false;
    }
    if(_S31)
    {
        if((p_4.shape_0) == u32(0))
        {
            _S31 = true;
        }
        else
        {
            _S31 = (p_4.shape_0) == u32(1);
        }
        if(_S31)
        {
            _S31 = true;
        }
        else
        {
            _S31 = (p_4.shape_0) == u32(11);
        }
    }
    else
    {
        _S31 = false;
    }
    return _S31;
}

fn rasterStripeIndex42_0( pixel_1 : f32,  lengthPx_0 : f32,  count_0 : f32) -> f32
{
    if(((max(lengthPx_0, count_0)) <= 32768.0f))
    {
        var index_0 : u32 = (u32(2) * u32(pixel_1) + u32(1)) * u32(count_0) / (u32(2) * u32(lengthPx_0));
        return min(f32(index_0), count_0 - 1.0f);
    }
    return min(floor((pixel_1 + 0.5f) * count_0 / lengthPx_0), count_0 - 1.0f);
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

fn coordinate3_0( uv_2 : vec2<f32>,  p_5 : TFParams_0,  mapValue_0 : f32) -> Coord_0
{
    var c_0 : Coord_0;
    var _S32 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_0.cell_3 = _S32;
    c_0.frac_0 = _S32;
    c_0.index_1 = 0.0f;
    c_0.coverage_3 = 1.0f;
    var _S33 : f32 = uv_2.x;
    var _S34 : f32 = max(2.0f, p_5.slices_0);
    var dim_0 : vec2<f32> = vec2<f32>(p_5.outputW_0, p_5.outputH_0);
    var _S35 : vec2<f32> = vec2<f32>(p_5.cx_0, p_5.cy_0);
    var v_2 : vec2<f32> = (uv_2 - _S35) * dim_0;
    var _S36 : vec2<f32> = vec2<f32>(1.0f);
    var radii_0 : vec2<f32> = max(_S35, _S36 - _S35) * dim_0;
    var _S37 : f32 = max(length(radii_0), 1.0f);
    var rmin_0 : f32 = length(max(_S32, max((vec2<f32>(0) - _S35), _S35 - _S36)) * dim_0);
    var q_2 : f32;
    var lengthPx_1 : f32;
    var _S38 : i32;
    var _S39 : bool;
    switch(p_5.shape_0)
    {
    case u32(0):
        {
            q_2 = _S33;
        }
    case u32(1):
        {
            q_2 = uv_2.y;
        }
    case u32(2), u32(12):
        {
            var a_3 : f32 = p_5.angle_0 * 3.1415927410125732f / 180.0f;
            var _S40 : f32 = cos(a_3);
            var _S41 : f32 = sin(a_3);
            var _S42 : f32 = p_5.outputW_0 * _S40;
            var _S43 : f32 = p_5.outputH_0 * _S41;
            var q_3 : f32 = (dot(uv_2 * dim_0, vec2<f32>(_S40, _S41)) - (min(0.0f, _S42) + min(0.0f, _S43))) / max(1.0f, abs(_S42) + abs(_S43));
            if((p_5.shape_0) == u32(12))
            {
                q_2 = q_3 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(uv_2.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_2 = q_3;
            }
        }
    case u32(3):
        {
            switch(p_5.origin_0)
            {
            case u32(1):
                {
                    q_2 = axisAngle3_0(v_2.y, v_2.x);
                }
            case u32(2):
                {
                    q_2 = axisAngle3_0(v_2.x, - v_2.y);
                }
            case u32(3):
                {
                    q_2 = axisAngle3_0(- v_2.x, v_2.y);
                }
            default :
                {
                    q_2 = axisAngle3_0(- v_2.y, - v_2.x);
                }
            }
            if((q_2 >= 0.0f))
            {
                _S39 = (q_2 <= 3.1415927410125732f);
            }
            else
            {
                _S39 = false;
            }
            if(_S39)
            {
                _S38 = i32(1);
            }
            else
            {
                _S38 = i32(0);
            }
            c_0.coverage_3 = f32(_S38);
            q_2 = clamp(q_2 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            var startAngle_0 : f32 = p_5.angle_0 / 360.0f;
            var _S44 : f32 = v_2.x;
            var _S45 : f32 = v_2.y;
            var _S46 : f32 = axisAngle3_0(_S44, - _S45);
            var _S47 : f32 = abs(_S44);
            var _S48 : f32 = abs(_S45);
            if(((_S47 + _S48) < 9.99999997475242708e-07f))
            {
                q_2 = 0.0f;
            }
            else
            {
                if((_S48 < 9.99999997475242708e-07f))
                {
                    if((_S44 > 0.0f))
                    {
                        q_2 = 1.5707963705062866f;
                    }
                    else
                    {
                        q_2 = -1.5707963705062866f;
                    }
                }
                else
                {
                    if((_S47 < 9.99999997475242708e-07f))
                    {
                        if((_S45 < 0.0f))
                        {
                            q_2 = 0.0f;
                        }
                        else
                        {
                            q_2 = 3.1415927410125732f;
                        }
                    }
                    else
                    {
                        q_2 = _S46;
                    }
                }
            }
            q_2 = fract(q_2 / 6.2831854820251465f + 1.0f - p_5.turns_0 * p_5.u_0 - startAngle_0);
        }
    case u32(5), u32(14):
        {
            q_2 = (length(v_2) - rmin_0) / max(1.0f, _S37 - rmin_0);
        }
    case u32(6), u32(7):
        {
            var vr_0 : vec2<f32> = rot3_0(v_2, p_5.angle_0 * 3.1415927410125732f / 180.0f + p_5.turns_0 * 2.0f * 3.1415927410125732f * p_5.u_0);
            if((p_5.shape_0) == u32(6))
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
            var _S49 : bool = (p_5.shape_0) == u32(10);
            if(_S49)
            {
                q_2 = max(1.0f, ceil(_S34 / 2.0f));
            }
            else
            {
                q_2 = _S34;
            }
            var gs_0 : vec2<f32> = gridSize3_0(q_2, dim_0);
            var _S50 : f32 = gs_0.y;
            var _S51 : f32 = uv_2.y * _S50;
            var _S52 : f32 = min(floor(_S51), _S50 - 1.0f);
            var _S53 : f32 = gs_0.x;
            var extra_0 : f32 = q_2 - _S53 * _S50;
            if((_S52 < extra_0))
            {
                _S38 = i32(1);
            }
            else
            {
                _S38 = i32(0);
            }
            var cols_1 : f32 = _S53 + f32(_S38);
            var _S54 : f32 = _S33 * cols_1;
            var _S55 : f32 = min(floor(_S54), cols_1 - 1.0f);
            var index_2 : f32 = _S52 * _S53 + min(_S52, extra_0) + _S55;
            c_0.cell_3 = vec2<f32>(_S55, _S52);
            c_0.frac_0 = fract(vec2<f32>(_S54, _S51));
            if(_S49)
            {
                var _S56 : f32 = _S34 - 1.0f;
                var _S57 : f32 = index_2 * 2.0f;
                if(((c_0.frac_0.x + c_0.frac_0.y) >= 1.0f))
                {
                    _S38 = i32(1);
                }
                else
                {
                    _S38 = i32(0);
                }
                lengthPx_1 = min(_S56, _S57 + f32(_S38));
            }
            else
            {
                lengthPx_1 = index_2;
            }
            q_2 = lengthPx_1 / max(1.0f, _S34 - 1.0f);
        }
    case u32(9):
        {
            q_2 = fract(axisAngle3_0(v_2.y, v_2.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_2) / _S37));
        }
    case u32(11):
        {
            q_2 = _S33;
        }
    case u32(13):
        {
            q_2 = length(v_2) / max(1.0f, _S37 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * axisAngle3_0(v_2.y, v_2.x))));
        }
    default :
        {
            q_2 = _S33;
        }
    }
    if((p_5.customMap_0) != u32(0))
    {
        c_0.coverage_3 = 1.0f;
        q_2 = mapValue_0;
    }
    var q_4 : f32 = clamp(q_2, 0.0f, 1.0f);
    var _S58 : bool = (p_5.direction_0) == u32(1);
    if(_S58)
    {
        q_2 = 1.0f - q_4;
    }
    else
    {
        q_2 = q_4;
    }
    if(((p_5.direction_0) >= u32(2)))
    {
        if((p_5.shape_0) == u32(8))
        {
            _S39 = true;
        }
        else
        {
            _S39 = (p_5.shape_0) == u32(10);
        }
        if(_S39)
        {
            q_2 = max(abs(_S33 - 0.5f), abs(uv_2.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_2 = abs(q_2 - 0.5f) * 2.0f;
        }
        if((p_5.direction_0) == u32(3))
        {
            q_2 = 1.0f - q_2;
        }
    }
    c_0.raw_0 = q_2;
    var _S59 : f32 = q_2 * _S34;
    var _S60 : f32 = _S34 - 1.0f;
    c_0.index_1 = min(floor(_S59), _S60);
    var edge_1 : f32 = round(_S59);
    if(((abs(_S59 - edge_1)) < 9.9999997473787516e-05f))
    {
        c_0.raw_0 = edge_1 / _S34;
        c_0.index_1 = min(edge_1, _S60);
    }
    if(isStripe42_0(p_5))
    {
        _S39 = ((p_5.reserved0_0) <= 0.0f);
    }
    else
    {
        _S39 = false;
    }
    if(_S39)
    {
        var _S61 : bool = (p_5.shape_0) == u32(1);
        if(_S61)
        {
            lengthPx_1 = p_5.sampleH_0;
        }
        else
        {
            lengthPx_1 = p_5.sampleW_0;
        }
        var _S62 : f32;
        if(_S61)
        {
            _S62 = uv_2.y;
        }
        else
        {
            _S62 = _S33;
        }
        var pixel_2 : f32 = floor(_S62 * lengthPx_1);
        if(_S58)
        {
            _S62 = lengthPx_1 - 1.0f - pixel_2;
        }
        else
        {
            _S62 = pixel_2;
        }
        var _S63 : f32 = rasterStripeIndex42_0(_S62, lengthPx_1, _S34);
        c_0.index_1 = _S63;
    }
    if(((p_5.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_2 = c_0.index_1 / _S60;
    }
    c_0.q_1 = q_2;
    return c_0;
}

fn play3_0( x_3 : f32,  mode_0 : u32) -> f32
{
    var _S64 : f32;
    if(mode_0 == u32(0))
    {
        _S64 = clamp(x_3, 0.0f, 1.0f);
    }
    else
    {
        if(mode_0 == u32(2))
        {
            _S64 = fract(x_3);
        }
        else
        {
            _S64 = bounce3_0(x_3);
        }
    }
    return _S64;
}

fn creative3_0( uv_3 : vec2<f32>,  c_1 : Coord_0,  p_6 : TFParams_0) -> Field_0
{
    var clock_1 : f32 = 2.0f * p_6.cycles_0 * p_6.u_0;
    var _S65 : f32 = max(2.0f, p_6.slices_0);
    var center_1 : vec2<f32> = vec2<f32>(p_6.cx_0, p_6.cy_0);
    var metric_1 : vec2<f32> = vec2<f32>(p_6.aspect_0, 1.0f);
    var v_3 : vec2<f32> = (uv_3 - center_1) * metric_1;
    var _S66 : f32 = bounce3_0(clock_1);
    var f_2 : Field_0 = single3_0(uv_3, _S66);
    var band_2 : f32;
    var phase_2 : f32;
    var lateral_0 : f32;
    var q_5 : f32;
    var i_0 : i32;
    var horizontal_0 : bool;
    switch(p_6.design_0)
    {
    case u32(9):
        {
            var _S67 : f32 = length(v_3);
            var phase_3 : f32 = fract(2.0f * (axisAngle3_0(v_3.x, - v_3.y) / 6.2831854820251465f) + _S67 / max(length(metric_1 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * p_6.span_0);
            var _S68 : bool = ((p_6.pixel_0) > 0.0f);
            if(_S68)
            {
                band_2 = phase_3 - p_6.cycles_0 * p_6.u_0;
            }
            else
            {
                band_2 = phase_3 * _S65;
            }
            if((p_6.pixel_0) == 0.0f)
            {
                phase_2 = floor(band_2) / (_S65 - 1.0f);
            }
            else
            {
                phase_2 = phase_3;
            }
            var _S69 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(p_6.cycles_0 * p_6.u_0 - phase_2);
            f_2.b_0 = _S69;
            f_2.a_0 = _S69;
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                var _S70 : f32 = fract(band_2);
                var _S71 : f32 = min(3.1415927410125732f * _S67 * p_6.sampleH_0, p_6.sampleH_0);
                if(_S68)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = _S65;
                }
                f_2.light_0 = tiledLight42_0(_S70, _S71 / band_2, 1.0f, p_6);
            }
        }
    case u32(10):
        {
            var q_6 : f32 = clamp(1.0f - abs(uv_3.x - p_6.cx_0) * 2.0f, 0.0f, 1.0f);
            var _S72 : f32 = _S65 - 1.0f;
            var band_3 : f32 = q_6 * _S72;
            if((p_6.pixel_0) == 0.0f)
            {
                q_5 = floor(band_3) / _S72;
            }
            else
            {
                q_5 = q_6;
            }
            var _S73 : f32 = 0.80000001192092896f * p_6.span_0;
            var _S74 : f32 = _S73 * q_5;
            var _S75 : f32 = bounce3_0(clock_1 - _S74);
            f_2.b_0 = _S75;
            f_2.a_0 = _S75;
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                var _S76 : bool = ((p_6.pixel_0) > 0.0f);
                if(_S76)
                {
                    band_2 = _S74 - clock_1;
                }
                else
                {
                    band_2 = band_3;
                }
                var _S77 : f32 = fract(band_2);
                var _S78 : f32 = 0.5f * p_6.sampleW_0;
                if(_S76)
                {
                    band_2 = _S73;
                }
                else
                {
                    band_2 = _S72;
                }
                f_2.light_0 = tiledLight42_0(_S77, _S78 / band_2, 1.0f, p_6);
            }
        }
    case u32(11):
        {
            var _S79 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, p_6.softness_0 * 0.15999999642372131f);
            var _S80 : f32 = c_1.frac_0.y;
            var ah_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S79, abs(_S80 - 0.5f));
            var _S81 : f32 = c_1.frac_0.x;
            var av_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S79, abs(_S81 - 0.5f));
            var _S82 : f32 = c_1.cell_3.y;
            var over_0 : bool = (i32(floor(c_1.cell_3.x) + floor(_S82)) % i32(2)) == i32(0);
            var ht_0 : f32 = bounce3_0(clock_1 - uv_3.x * p_6.span_0);
            var vt_0 : f32 = bounce3_0(clock_1 + uv_3.y * p_6.span_0 + 1.0f);
            var _S83 : bool = (ah_0 > 0.0f);
            if(_S83)
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
                f_2.a_0 = band_2;
                if(over_0)
                {
                    band_2 = ht_0;
                }
                else
                {
                    band_2 = vt_0;
                }
                f_2.b_0 = band_2;
                if(over_0)
                {
                    band_2 = ah_0;
                }
                else
                {
                    band_2 = av_0;
                }
                f_2.weight_0 = band_2;
                if(ah_0 == 0.0f)
                {
                    f_2.b_0 = vt_0;
                    f_2.a_0 = vt_0;
                }
                if(av_0 == 0.0f)
                {
                    f_2.b_0 = ht_0;
                    f_2.a_0 = ht_0;
                }
            }
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                if(_S83)
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
                    if(_S83)
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
                    phase_2 = _S80;
                }
                else
                {
                    phase_2 = _S81;
                }
                var phase_4 : f32 = clamp((phase_2 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_0 : vec2<f32> = gridSize3_0(_S65, vec2<f32>(p_6.outputW_0, p_6.outputH_0));
                var _S84 : f32 = grid_0.x;
                var _S85 : f32 = grid_0.y;
                if((_S82 < (_S65 - _S84 * _S85)))
                {
                    i_0 = i32(1);
                }
                else
                {
                    i_0 = i32(0);
                }
                var cols_2 : f32 = _S84 + f32(i_0);
                if(horizontal_0)
                {
                    phase_2 = p_6.sampleH_0 / _S85;
                }
                else
                {
                    phase_2 = p_6.sampleW_0 / cols_2;
                }
                f_2.light_0 = edgeLight42_0(phase_4, 0.47999998927116394f * phase_2, band_2, p_6);
            }
        }
    case u32(12):
        {
            var sources_0 : u32 = clamp(p_6.waveSources_0, u32(2), u32(4));
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
                var a_4 : f32 = 6.2831854820251465f * f32(i_1) / f32(sources_0);
                var r_0 : f32 = length((uv_3 - (center_1 + vec2<f32>(0.18000000715255737f * cos(a_4), 0.18000000715255737f * sin(a_4)))) * metric_1);
                var band_4 : f32 = r_0 * _S65;
                if((p_6.pixel_0) == 0.0f)
                {
                    phase_2 = floor(band_4) / _S65;
                }
                else
                {
                    phase_2 = r_0;
                }
                var _S86 : f32 = phase_2 * 1.2999999523162842f * p_6.span_0;
                var sum_0 : f32 = band_2 + bounce3_0(clock_1 - _S86);
                if(((p_6.shadowStrength_0) > 0.0f))
                {
                    var _S87 : bool = ((p_6.pixel_0) > 0.0f);
                    if(_S87)
                    {
                        lateral_0 = _S86 - clock_1;
                    }
                    else
                    {
                        lateral_0 = band_4;
                    }
                    var phase_5 : f32 = fract(lateral_0);
                    var _S88 : f32 = f_2.light_0;
                    if(_S87)
                    {
                        q_5 = 1.2999999523162842f * p_6.span_0;
                    }
                    else
                    {
                        q_5 = _S65;
                    }
                    f_2.light_0 = min(_S88, tiledLight42_0(phase_5, p_6.sampleH_0 / q_5, 1.0f, p_6));
                }
                i_1 = i_1 + u32(1);
                band_2 = sum_0;
            }
            var _S89 : f32 = band_2 / f32(sources_0);
            f_2.b_0 = _S89;
            f_2.a_0 = _S89;
        }
    case u32(13):
        {
            var _S90 : f32 = 6.2831854820251465f * p_6.u_0;
            var _S91 : f32 = sin(_S90);
            var local_1 : vec2<f32> = (uv_3 - (center_1 + vec2<f32>(0.2199999988079071f * _S91, 0.12999999523162842f * cos(_S90)))) * metric_1;
            var r_1 : f32 = length(local_1);
            var radius_0 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S91;
            var _S92 : f32 = max(0.0020000000949949026f, p_6.softness_0 * 0.15999999642372131f);
            f_2.b_0 = bounce3_0(clock_1 + 0.80000001192092896f * p_6.span_0);
            f_2.weight_0 = 1.0f - smoothstep(radius_0 - _S92, radius_0 + _S92, r_1);
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                horizontal_0 = ((f_2.weight_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S93 : f32 = local_1.y;
                var halfWidth_0 : f32 = sqrt(max(9.99999997475242708e-07f, radius_0 * radius_0 - _S93 * _S93));
                f_2.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * local_1.x / halfWidth_0, 0.0f, 1.0f), 2.0f * halfWidth_0 * p_6.sampleH_0, f_2.weight_0, p_6);
            }
        }
    case u32(400):
        {
            var _S94 : f32 = max(_S65, 2.0f);
            var gap_0 : f32 = 0.64999997615814209f / _S94;
            var d_0 : f32 = fract(p_6.u_0 * p_6.cycles_0) * 1.6499999761581421f - uv_3.x;
            var j_0 : f32 = floor(d_0 / gap_0);
            var local_2 : f32 = fract(d_0 / gap_0);
            if((j_0 >= 0.0f))
            {
                horizontal_0 = (j_0 < _S94);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S95 : f32 = max(0.014999999664723873f, p_6.softness_0 * 0.15000000596046448f);
                var a_5 : f32 = smoothstep(0.0f, _S95, local_2) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S95, local_2));
                f_2.b_0 = clamp(1.0f - j_0 / _S94, 0.0f, 1.0f);
                f_2.weight_0 = a_5 * (1.0f - 0.64999997615814209f * j_0 / _S94);
            }
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = edgeLight42_0(clamp(1.0f - local_2 / 0.64999997615814209f, 0.0f, 1.0f), gap_0 * 0.64999997615814209f * p_6.sampleW_0, f_2.weight_0, p_6);
            }
        }
    case u32(401):
        {
            var _S96 : f32 = uv_3.y;
            if((i32(floor(_S96 * _S65)) % i32(2)) == i32(0))
            {
                band_2 = 1.0f;
            }
            else
            {
                band_2 = -1.0f;
            }
            var gap_1 : f32 = 0.34999999403953552f * smoothstep(_S66 - 0.059999998658895493f, _S66 + 0.059999998658895493f, _S96);
            var seam_0 : f32 = p_6.cx_0 + band_2 * 0.02500000037252903f;
            var _S97 : f32 = uv_3.x;
            var _S98 : f32 = _S97 - seam_0;
            var outside_0 : bool = ((abs(_S98)) > gap_1);
            if(outside_0)
            {
                if((_S97 < seam_0))
                {
                    band_2 = 0.079999998211860657f;
                }
                else
                {
                    band_2 = 0.94999998807907104f;
                }
                f_2.b_0 = band_2;
                f_2.a_0 = band_2;
            }
            var _S99 : bool = ((p_6.shadowStrength_0) > 0.0f);
            if(_S99)
            {
                var _S100 : f32 = clamp((_S98 + gap_1) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S101 : f32 = 0.2199999988079071f * p_6.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S97 < seam_0);
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
                f_2.light_0 = edgeLight42_0(_S100, _S101, band_2, p_6);
            }
            if(_S99)
            {
                horizontal_0 = ((p_6.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S102 : f32 = clamp((_S98 - gap_1) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S103 : f32 = 0.2199999988079071f * p_6.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S97 > seam_0);
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
                f_2.light_0 = edgeLight42_0(_S102, _S103, band_2, p_6);
            }
        }
    case u32(402):
        {
            var a_6 : f32 = axisAngle3_0(v_3.y, v_3.x);
            var r_2 : f32 = length(v_3);
            var radius_1 : f32 = 0.4699999988079071f * min(p_6.aspect_0, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * p_6.u_0 * p_6.cycles_0)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_6 * _S65));
            var _S104 : f32 = max(0.0010000000474974513f, p_6.softness_0 * 0.019999999552965164f);
            var _S105 : f32 = fract((a_6 + 3.1415927410125732f) / 6.2831854820251465f) * _S65;
            f_2.b_0 = bounce3_0(clock_1 + floor(_S105) / _S65 * p_6.span_0);
            f_2.weight_0 = 1.0f - smoothstep(radius_1 - _S104, radius_1 + _S104, r_2);
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = tiledLight42_0(fract(_S105), 6.2831854820251465f * r_2 * p_6.sampleH_0 / _S65, f_2.weight_0, p_6);
            }
        }
    case u32(403):
        {
            var r_3 : f32 = length(v_3);
            var _S106 : f32 = max(3.0f, _S65);
            var sector_0 : f32 = 6.2831854820251465f / _S106;
            var _S107 : f32 = axisAngle3_0(v_3.y, v_3.x) + p_6.u_0 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_0 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * p_6.u_0 * p_6.cycles_0))) * min(p_6.aspect_0, 1.0f) * cos(3.1415927410125732f / _S106) / max(0.0010000000474974513f, cos(fract(_S107 / sector_0) * sector_0 - sector_0 * 0.5f));
            f_2.a_0 = bounce3_0(clock_1 - p_6.span_0 * floor(fract(_S107 / 6.2831854820251465f) * _S106) / _S106);
            f_2.b_0 = bounce3_0(clock_1 + 1.0f);
            f_2.weight_0 = 1.0f - smoothstep(aperture_0 - 0.0020000000949949026f, aperture_0 + 0.0020000000949949026f, r_3);
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = tiledLight42_0(fract(_S107 / sector_0), sector_0 * r_3 * p_6.sampleH_0, 1.0f - f_2.weight_0, p_6);
            }
        }
    case u32(404):
        {
            var _S108 : f32 = fract(p_6.u_0 * p_6.cycles_0);
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
                var _S109 : f32 = f32(i_0);
                var a0_0 : f32 = 6.2831854820251465f * _S109 / 32.0f;
                var _S110 : i32 = i_0 + i32(1);
                var a1_0 : f32 = 6.2831854820251465f * f32(_S110) / 32.0f;
                var a_7 : vec2<f32> = center_1 + vec2<f32>(0.34000000357627869f * sin(a0_0), 0.2199999988079071f * sin(2.0f * a0_0));
                var segment_0 : vec2<f32> = (center_1 + vec2<f32>(0.34000000357627869f * sin(a1_0), 0.2199999988079071f * sin(2.0f * a1_0)) - a_7) * metric_1;
                var point_0 : vec2<f32> = (uv_3 - a_7) * metric_1;
                var k_0 : f32 = clamp(dot(point_0, segment_0) / max(dot(segment_0, segment_0), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_0 : vec2<f32> = point_0 - vec2<f32>(k_0) * segment_0;
                var distance_3 : f32 = dot(delta_0, delta_0);
                var trail_0 : f32 = fract(_S108 - (_S109 + k_0) / 32.0f + 1.0f);
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
                    if(((p_6.shadowStrength_0) > 0.0f))
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
                i_0 = _S110;
            }
            var _S111 : f32 = max(0.0020000000949949026f, p_6.softness_0 * 0.039999999105930328f);
            var best_0 : f32 = sqrt(band_2);
            f_2.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S111, 0.035000000149011612f + _S111, best_0);
            var q_7 : f32 = phase_2 / 0.60000002384185791f;
            if((p_6.pixel_0) == 0.0f)
            {
                q_5 = floor(q_7 * _S65) / (_S65 - 1.0f);
            }
            else
            {
                q_5 = q_7;
            }
            f_2.b_0 = 0.15000000596046448f + 0.85000002384185791f * q_5;
            if(((p_6.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = edgeLight42_0(clamp(0.5f + best_0 * lateral_0 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * p_6.sampleH_0, f_2.weight_0, p_6);
            }
        }
    default :
        {
        }
    }
    return f_2;
}

fn frozen3_0( uv_4 : vec2<f32>,  c_2 : Coord_0,  p_7 : TFParams_0) -> Field_0
{
    var build_1 : f32 = clamp(p_7.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var _S112 : bool = ((p_7.pixel_0) > 0.0f);
    var held_0 : f32;
    if(_S112)
    {
        held_0 = c_2.raw_0;
    }
    else
    {
        held_0 = min(1.0f, (c_2.index_1 + 1.0f) / max(2.0f, p_7.slices_0));
    }
    if((((p_7.flags_0) & (u32(1024)))) != u32(0))
    {
        var skip_0 : f32 = clamp(p_7.reserved1_0, 0.0f, 1.0f);
        var _S113 : f32 = held_0 * (1.0f - skip_0);
        if((held_0 > 0.5f))
        {
            held_0 = skip_0;
        }
        else
        {
            held_0 = 0.0f;
        }
        held_0 = _S113 + held_0;
    }
    var a_8 : f32;
    if(((p_7.u_0) < build_1))
    {
        var progress_0 : f32 = p_7.u_0 / build_1;
        var _S114 : bool;
        if(_S112)
        {
            _S114 = true;
        }
        else
        {
            _S114 = (((p_7.flags_0) & (u32(1)))) != u32(0);
        }
        if(_S114)
        {
            var _S115 : f32 = max(1.0f / max(p_7.outputW_0, p_7.outputH_0), p_7.softness_0 * 0.0030000000260770321f);
            a_8 = 1.0f - smoothstep(progress_0 - _S115, progress_0 + _S115, c_2.raw_0);
        }
        else
        {
            var _S116 : i32;
            if((progress_0 >= (c_2.q_1)))
            {
                _S116 = i32(1);
            }
            else
            {
                _S116 = i32(0);
            }
            a_8 = f32(_S116);
        }
        var f_3 : Field_0 = single3_0(uv_4, progress_0);
        f_3.b_0 = held_0;
        f_3.weight_0 = a_8;
        return f_3;
    }
    var after_0 : f32 = clamp((p_7.u_0 - build_1) / (1.0f - build_1), 0.0f, 1.0f);
    switch(p_7.ending_0)
    {
    case u32(0):
        {
            a_8 = held_0;
        }
    case u32(1):
        {
            a_8 = clamp(held_0 + after_0, 0.0f, 1.0f);
        }
    case u32(2):
        {
            var release_0 : f32 = c_2.q_1 * 0.64999997615814209f;
            a_8 = clamp(held_0 + max(0.0f, after_0 - release_0) / max(0.05000000074505806f, 1.0f - release_0), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_0 > 0.0f))
            {
                held_0 = play3_0(held_0 - 2.0f * p_7.cycles_0 * after_0, p_7.playback_0);
            }
            a_8 = held_0;
        }
    case u32(4):
        {
            a_8 = bounce3_0(held_0 - 2.0f * p_7.cycles_0 * after_0);
        }
    default :
        {
            a_8 = held_0;
        }
    }
    return single3_0(uv_4, a_8);
}

fn relative3_0( c_3 : Coord_0,  p_8 : TFParams_0) -> f32
{
    var d_1 : f32;
    if((((p_8.flags_0) & (u32(4)))) != u32(0))
    {
        d_1 = (c_3.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if((((p_8.flags_0) & (u32(8)))) != u32(0))
        {
            d_1 = (c_3.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_1 = 2.0f * c_3.raw_0 - 1.0f;
        }
    }
    if((p_8.pixel_0) == 0.0f)
    {
        var _S117 : f32 = p_8.slices_0 - 1.0f;
        var positive_0 : f32 = ceil(_S117 / 2.0f);
        var negative_0 : f32 = floor(_S117 / 2.0f);
        var _S118 : f32;
        if((d_1 < 0.0f))
        {
            _S118 = negative_0;
        }
        else
        {
            _S118 = positive_0;
        }
        var _S119 : f32 = max(1.0f, _S118);
        d_1 = round(d_1 * _S119) / _S119;
    }
    return p_8.span_0 * d_1;
}

fn basic3_0( uv_5 : vec2<f32>,  c_4 : Coord_0,  p_9 : TFParams_0) -> Field_0
{
    var clock_2 : f32 = 2.0f * p_9.cycles_0 * p_9.u_0;
    var t_4 : f32;
    if((p_9.customMap_0) != u32(0))
    {
        if((((p_9.flags_0) & (u32(2)))) != u32(0))
        {
            t_4 = p_9.u_0 + relative3_0(c_4, p_9);
        }
        else
        {
            t_4 = c_4.q_1 + clock_2;
        }
        return single3_0(uv_5, play3_0(t_4, p_9.playback_0));
    }
    if((p_9.design_0) == u32(0))
    {
        t_4 = 0.20000000298023224f + 0.80000001192092896f * fract(p_9.cycles_0 * p_9.u_0 - c_4.q_1);
    }
    else
    {
        if((p_9.design_0) == u32(5))
        {
            t_4 = bounce3_0(1.0f - clock_2 - p_9.span_0 * c_4.q_1);
        }
        else
        {
            if((p_9.shape_0) == u32(11))
            {
                if((i32(c_4.index_1) % i32(2)) == i32(0))
                {
                    t_4 = 1.0f;
                }
                else
                {
                    t_4 = -1.0f;
                }
                t_4 = play3_0(1.0f + clock_2 * t_4 - p_9.span_0 * c_4.q_1, p_9.playback_0);
            }
            else
            {
                t_4 = play3_0(1.0f + clock_2 - p_9.span_0 * c_4.q_1, p_9.playback_0);
            }
        }
    }
    return single3_0(uv_5, t_4);
}

fn wave3_0( uv_6 : vec2<f32>,  c_5 : Coord_0,  p_10 : TFParams_0) -> Field_0
{
    var _S120 : bool;
    if((p_10.customMap_0) != u32(0))
    {
        _S120 = (((p_10.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S120 = false;
    }
    var phase_6 : f32;
    if(_S120)
    {
        phase_6 = 2.0f * p_10.cycles_0 * p_10.u_0 + relative3_0(c_5, p_10);
    }
    else
    {
        phase_6 = 2.0f * p_10.cycles_0 * p_10.u_0 - 2.0f * p_10.density_0 * c_5.q_1;
    }
    return single3_0(uv_6, play3_0(phase_6, p_10.playback_0));
}

fn coordSpan42_0( uv_7 : vec2<f32>,  p_11 : TFParams_0) -> f32
{
    var size_1 : vec2<f32> = vec2<f32>(p_11.sampleW_0, p_11.sampleH_0);
    var _S121 : vec2<f32> = vec2<f32>(p_11.cx_0, p_11.cy_0);
    var v_4 : vec2<f32> = (uv_7 - _S121) * size_1;
    var _S122 : vec2<f32> = vec2<f32>(1.0f);
    var radii_1 : vec2<f32> = max(_S121, _S122 - _S121) * size_1;
    if((p_11.customMap_0) != u32(0))
    {
        return min(p_11.sampleW_0, p_11.sampleH_0);
    }
    switch(p_11.shape_0)
    {
    case u32(1):
        {
            return p_11.sampleH_0;
        }
    case u32(2), u32(12):
        {
            var a_9 : f32 = p_11.angle_0 * 3.1415927410125732f / 180.0f;
            return p_11.sampleW_0 * abs(cos(a_9)) + p_11.sampleH_0 * abs(sin(a_9));
        }
    case u32(3):
        {
            return 3.1415927410125732f * length(v_4);
        }
    case u32(4):
        {
            return 6.2831854820251465f * length(v_4);
        }
    case u32(5), u32(14):
        {
            return length(radii_1) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S121), _S121 - _S122)) * size_1);
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
            return min(6.2831854820251465f * length(v_4), length(radii_1) / 1.5f);
        }
    case u32(13):
        {
            return length(radii_1) * 0.56000000238418579f;
        }
    default :
        {
            return p_11.sampleW_0;
        }
    }
}

fn frozenShadow53_0( uv_8 : vec2<f32>,  p_12 : TFParams_0,  coverage_4 : f32) -> f32
{
    var geometry_0 : TFParams_0 = p_12;
    geometry_0.direction_0 = u32(0);
    var _S123 : bool;
    if(((p_12.direction_0) >= u32(2)))
    {
        _S123 = (p_12.shape_0) != u32(8);
    }
    else
    {
        _S123 = false;
    }
    if(_S123)
    {
        _S123 = (p_12.shape_0) != u32(10);
    }
    else
    {
        _S123 = false;
    }
    if(_S123)
    {
        geometry_0.slices_0 = geometry_0.slices_0 * 2.0f;
    }
    var c_6 : Coord_0 = coordinate3_0(uv_8, geometry_0, 0.0f);
    var _S124 : f32 = max(2.0f, geometry_0.slices_0);
    if((p_12.shape_0) == u32(8))
    {
        _S123 = true;
    }
    else
    {
        _S123 = (p_12.shape_0) == u32(10);
    }
    var cells_0 : f32;
    if(_S123)
    {
        var _S125 : bool = (p_12.shape_0) == u32(10);
        if(_S125)
        {
            cells_0 = ceil(_S124 / 2.0f);
        }
        else
        {
            cells_0 = _S124;
        }
        var grid_1 : vec2<f32> = gridSize3_0(cells_0, vec2<f32>(p_12.outputW_0, p_12.outputH_0));
        var _S126 : f32 = grid_1.x;
        var _S127 : i32;
        if(((c_6.cell_3.y) < (cells_0 - _S126 * grid_1.y)))
        {
            _S127 = i32(1);
        }
        else
        {
            _S127 = i32(0);
        }
        var phase_7 : f32 = c_6.frac_0.x;
        var span_4 : f32 = p_12.sampleW_0 / (_S126 + f32(_S127));
        var phase_8 : f32;
        var span_5 : f32;
        if(_S125)
        {
            var cut_0 : f32 = 1.0f - c_6.frac_0.y;
            var first_1 : bool = (phase_7 < cut_0);
            if(first_1)
            {
                cells_0 = cut_0;
            }
            else
            {
                cells_0 = 1.0f - cut_0;
            }
            var span_6 : f32 = span_4 * cells_0;
            if(first_1)
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
        if(((p_12.shadowSide_0) > 0.0f))
        {
            cells_0 = phase_8;
        }
        else
        {
            cells_0 = 1.0f - phase_8;
        }
        return filteredLight42_0(cells_0, span_5, coverage_4, 1.0f, false, p_12);
    }
    var phase_9 : f32 = clamp(c_6.raw_0 * _S124 - c_6.index_1, 0.0f, 1.0f);
    var span_7 : f32 = coordSpan42_0(uv_8, geometry_0) / _S124;
    if(((p_12.shadowSide_0) > 0.0f))
    {
        cells_0 = phase_9;
    }
    else
    {
        cells_0 = 1.0f - phase_9;
    }
    return filteredLight42_0(cells_0, span_7, coverage_4, 1.0f, false, p_12);
}

fn stripeBorder42_0( cut_1 : f32,  lengthPx_2 : f32,  count_1 : f32) -> f32
{
    if(((max(lengthPx_2, count_1)) <= 32768.0f))
    {
        var n_1 : u32 = u32(count_1);
        var numerator_0 : u32 = u32(2) * u32(cut_1) * u32(lengthPx_2);
        var _S128 : f32;
        if((numerator_0 <= n_1))
        {
            _S128 = 0.0f;
        }
        else
        {
            var _S129 : u32 = (numerator_0 + n_1 - u32(1)) / (u32(2) * n_1);
            _S128 = f32(_S129);
        }
        return _S128;
    }
    return clamp(ceil(cut_1 * lengthPx_2 / count_1 - 0.5f), 0.0f, lengthPx_2);
}

fn stripeLight42_0( axis_0 : f32,  index_3 : f32,  lengthPx_3 : f32,  count_2 : f32,  reverse_0 : bool,  coverage_5 : f32,  p_13 : TFParams_0) -> f32
{
    var span_8 : f32 = lengthPx_3 / count_2;
    if((span_8 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_0 : bool = ((p_13.shadowSide_0) > 0.0f);
    var center_2 : f32;
    if(leading_0)
    {
        center_2 = 0.0f;
    }
    else
    {
        center_2 = 1.0f;
    }
    var edge_2 : f32 = stripeBorder42_0(index_3 + center_2, lengthPx_3, count_2);
    var center_3 : f32 = floor(axis_0 * lengthPx_3) + 0.5f;
    if(reverse_0)
    {
        center_2 = lengthPx_3 - center_3;
    }
    else
    {
        center_2 = center_3;
    }
    if(leading_0)
    {
        center_2 = center_2 - edge_2;
    }
    else
    {
        center_2 = edge_2 - center_2;
    }
    return filteredLight42_0(max(0.5f, center_2) / span_8, span_8, coverage_5, 1.0f, false, p_13);
}

fn sliceLight42_0( uv_9 : vec2<f32>,  c_7 : Coord_0,  p_14 : TFParams_0,  coverage_6 : f32) -> f32
{
    var _S130 : bool;
    if((p_14.family_0) == u32(0))
    {
        _S130 = (p_14.customMap_0) == u32(0);
    }
    else
    {
        _S130 = false;
    }
    if(_S130)
    {
        var _S131 : f32 = frozenShadow53_0(uv_9, p_14, coverage_6);
        return _S131;
    }
    var _S132 : f32 = max(2.0f, p_14.slices_0);
    var _S133 : bool = (p_14.shape_0) == u32(8);
    if(_S133)
    {
        _S130 = true;
    }
    else
    {
        _S130 = (p_14.shape_0) == u32(10);
    }
    if(_S130)
    {
        _S130 = (p_14.customMap_0) == u32(0);
    }
    else
    {
        _S130 = false;
    }
    if(_S130)
    {
        _S130 = ((p_14.direction_0) < u32(2));
    }
    else
    {
        _S130 = false;
    }
    var cells_1 : f32;
    var x_4 : f32;
    if(_S130)
    {
        var _S134 : bool = (p_14.shape_0) == u32(10);
        if(_S134)
        {
            cells_1 = ceil(_S132 / 2.0f);
        }
        else
        {
            cells_1 = _S132;
        }
        var grid_2 : vec2<f32> = gridSize3_0(cells_1, vec2<f32>(p_14.outputW_0, p_14.outputH_0));
        var _S135 : f32 = grid_2.x;
        var _S136 : i32;
        if(((c_7.cell_3.y) < (cells_1 - _S135 * grid_2.y)))
        {
            _S136 = i32(1);
        }
        else
        {
            _S136 = i32(0);
        }
        var x_5 : f32 = c_7.frac_0.x;
        var span_9 : f32 = p_14.sampleW_0 / (_S135 + f32(_S136));
        var span_10 : f32;
        if(_S134)
        {
            var cut_2 : f32 = 1.0f - c_7.frac_0.y;
            var first_2 : bool = (x_5 < cut_2);
            if(first_2)
            {
                cells_1 = cut_2;
            }
            else
            {
                cells_1 = 1.0f - cut_2;
            }
            var span_11 : f32 = span_9 * cells_1;
            if(first_2)
            {
                cells_1 = x_5 / max(cut_2, 9.99999997475242708e-07f);
            }
            else
            {
                cells_1 = (x_5 - cut_2) / max(1.0f - cut_2, 9.99999997475242708e-07f);
            }
            x_4 = cells_1;
            span_10 = span_11;
        }
        else
        {
            x_4 = x_5;
            span_10 = span_9;
        }
        var phase_10 : f32;
        if((p_14.direction_0) == u32(1))
        {
            phase_10 = 1.0f - x_4;
        }
        else
        {
            phase_10 = x_4;
        }
        if(_S133)
        {
            cells_1 = tiledLight42_0(phase_10, span_10, coverage_6, p_14);
        }
        else
        {
            cells_1 = edgeLight42_0(phase_10, span_10, coverage_6, p_14);
        }
        return cells_1;
    }
    var span_12 : f32 = coordSpan42_0(uv_9, p_14);
    if(((p_14.direction_0) >= u32(2)))
    {
        cells_1 = span_12 * 0.5f;
    }
    else
    {
        cells_1 = span_12;
    }
    if(((p_14.pixel_0) > 0.0f))
    {
        _S130 = (p_14.family_0) == u32(2);
    }
    else
    {
        _S130 = false;
    }
    if(_S130)
    {
        if((p_14.customMap_0) != u32(0))
        {
            _S130 = (((p_14.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S130 = false;
        }
        if(_S130)
        {
            x_4 = 2.0f * p_14.span_0;
        }
        else
        {
            x_4 = 2.0f * p_14.density_0;
        }
        var _S137 : f32 = max(0.0099999997764825821f, x_4);
        return tiledLight42_0(fract(_S137 * c_7.raw_0 - 2.0f * p_14.cycles_0 * p_14.u_0), cells_1 / _S137, coverage_6, p_14);
    }
    if(isStripe42_0(p_14))
    {
        if((p_14.shape_0) == u32(1))
        {
            x_4 = uv_9.y;
        }
        else
        {
            x_4 = uv_9.x;
        }
        var _S138 : f32 = stripeLight42_0(x_4, c_7.index_1, cells_1, _S132, (p_14.direction_0) == u32(1), coverage_6, p_14);
        return _S138;
    }
    return tiledLight42_0(clamp(c_7.raw_0 * _S132 - c_7.index_1, 0.0f, 1.0f), cells_1 / _S132, coverage_6, p_14);
}

fn evaluate3_0( uv_10 : vec2<f32>,  p_15 : TFParams_0,  mapValue_1 : f32) -> Field_0
{
    if(((p_15.design_0) >= u32(407)))
    {
        return creative42_0(uv_10, p_15);
    }
    var c_8 : Coord_0 = coordinate3_0(uv_10, p_15, mapValue_1);
    var base_1 : f32;
    if((c_8.coverage_3) == 0.0f)
    {
        if((p_15.family_0) == u32(0))
        {
            base_1 = play3_0(p_15.u_0 / max(0.10000000149011612f, p_15.build_0), p_15.playback_0);
        }
        else
        {
            if((p_15.family_0) == u32(1))
            {
                base_1 = 1.0f;
            }
            else
            {
                base_1 = 0.0f;
            }
            base_1 = play3_0(base_1 + 2.0f * p_15.cycles_0 * p_15.u_0, p_15.playback_0);
        }
        return single3_0(uv_10, base_1);
    }
    if((p_15.family_0) == u32(3))
    {
        return creative3_0(uv_10, c_8, p_15);
    }
    var f_4 : Field_0;
    var _S139 : bool = (p_15.family_0) == u32(0);
    var _S140 : Field_0;
    if(_S139)
    {
        _S140 = frozen3_0(uv_10, c_8, p_15);
    }
    else
    {
        if((p_15.family_0) == u32(1))
        {
            _S140 = basic3_0(uv_10, c_8, p_15);
        }
        else
        {
            _S140 = wave3_0(uv_10, c_8, p_15);
        }
    }
    f_4 = _S140;
    if(((p_15.shadowStrength_0) > 0.0f))
    {
        var _S141 : bool;
        if(_S139)
        {
            _S141 = ((p_15.u_0) < (clamp(p_15.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S141 = false;
        }
        if(_S141)
        {
            base_1 = f_4.weight_0;
        }
        else
        {
            base_1 = 1.0f;
        }
        if((base_1 > 0.0f))
        {
            var _S142 : f32 = sliceLight42_0(uv_10, c_8, p_15, base_1);
            f_4.light_0 = _S142;
        }
    }
    return f_4;
}

fn filteredLight42_1( _S143 : f32,  _S144 : f32,  _S145 : f32,  _S146 : f32,  _S147 : bool) -> f32
{
    var _S148 : bool;
    if((_S144 <= 1.0f))
    {
        _S148 = true;
    }
    else
    {
        _S148 = (_S145 <= 0.0f);
    }
    if(_S148)
    {
        return 1.0f;
    }
    var _S149 : f32 = min(0.77999997138977051f, max(param_0.shadowWidth_0, 1.5f / _S144));
    var halfPixel_1 : f32 = 0.5f * _S146 / _S144;
    if((_S143 > (_S149 + halfPixel_1)))
    {
        if(!_S147)
        {
            _S148 = true;
        }
        else
        {
            _S148 = (_S143 < (1.0f - halfPixel_1));
        }
    }
    else
    {
        _S148 = false;
    }
    if(_S148)
    {
        return 1.0f;
    }
    var feather_3 : f32 = _S149 * max(0.02500000037252903f, param_0.shadowSoftness_0);
    var solid_3 : f32 = _S149 - feather_3;
    var lo_1 : f32 = _S143 - halfPixel_1;
    var hi_1 : f32 = _S143 + halfPixel_1;
    var area_1 : f32;
    if(_S147)
    {
        area_1 = repeatedShadowArea42_0(hi_1, solid_3, feather_3) - repeatedShadowArea42_0(lo_1, solid_3, feather_3);
    }
    else
    {
        area_1 = shadowArea42_0(hi_1, solid_3, feather_3) - shadowArea42_0(lo_1, solid_3, feather_3);
    }
    return 1.0f - param_0.shadowStrength_0 * _S145 * (clamp(area_1 / (2.0f * halfPixel_1), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, _S144));
}

fn tiledLight42_1( _S150 : f32,  _S151 : f32,  _S152 : f32) -> f32
{
    var _S153 : f32;
    if(((param_0.shadowSide_0) > 0.0f))
    {
        _S153 = _S150;
    }
    else
    {
        _S153 = 1.0f - _S150;
    }
    return filteredLight42_1(_S153, _S151, _S152, 1.2999999523162842f, true);
}

fn edgeLight42_1( _S154 : f32,  _S155 : f32,  _S156 : f32) -> f32
{
    var _S157 : f32;
    if(((param_0.shadowSide_0) > 0.0f))
    {
        _S157 = _S154;
    }
    else
    {
        _S157 = 1.0f - _S154;
    }
    return filteredLight42_1(_S157, _S155, _S156, 1.0f, false);
}

fn creative42_1( _S158 : vec2<f32>) -> Field_0
{
    var _S159 : f32 = param_0.cy_0;
    var center_4 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var _S160 : f32 = param_0.sampleW_0;
    var _S161 : f32 = param_0.sampleH_0;
    var _S162 : f32 = param_0.aspect_0;
    var metric_2 : vec2<f32> = vec2<f32>(param_0.aspect_0, 1.0f);
    var _S163 : vec2<f32> = _S158 - center_4;
    var v_5 : vec2<f32> = _S163 * metric_2;
    var u_1 : f32 = param_0.u_0;
    var _S164 : f32 = param_0.cycles_0;
    var clock_3 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var _S165 : f32 = max(2.0f, param_0.slices_0);
    var f_5 : Field_0 = single3_0(_S158, bounce3_0(clock_3 + 1.0f));
    switch(param_0.design_0)
    {
    case u32(407):
        {
            var y_2 : f32 = _S158.y - _S159;
            var band_5 : f32 = (creativeAxis42_0(_S158.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_2 + 0.34999999403953552f * u_1)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_2 - 0.69999998807907104f * u_1))), param_0.direction_0) - 0.51999998092651367f * _S164 * u_1) * _S165;
            var cell_4 : f32 = floor(band_5);
            var t_5 : f32 = bounce3_0(clock_3 - 0.75f * cell_4 / _S165);
            var _S166 : f32 = mix(t_5, 1.0f - t_5, fract(cell_4 * 0.5f) * 2.0f * param_0.span_0);
            f_5.b_0 = _S166;
            f_5.a_0 = _S166;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_1(fract(band_5), _S160 / _S165, 1.0f);
            }
        }
    case u32(408):
        {
            var pitch_1 : f32 = sqrt(2.0f * _S162 / (1.7320507764816284f * _S165));
            const basis_1 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_1 : vec2<f32> = rot3_0(v_5, 0.15999999642372131f * sin(6.2831854820251465f * u_1)) / vec2<f32>(pitch_1);
            var _S167 : vec2<f32> = vec2<f32>(0.5f);
            var a_10 : vec2<f32> = floor(pos_1 / basis_1 + _S167) * basis_1;
            var b_2 : vec2<f32> = floor(pos_1 / basis_1) * basis_1 + basis_1 * _S167;
            var da_1 : vec2<f32> = pos_1 - a_10;
            var db_1 : vec2<f32> = pos_1 - b_2;
            var first_3 : bool = ((dot(da_1, da_1)) <= (dot(db_1, db_1)));
            var cell_5 : vec2<f32>;
            if(first_3)
            {
                cell_5 = a_10;
            }
            else
            {
                cell_5 = b_2;
            }
            var local_3 : vec2<f32>;
            if(first_3)
            {
                local_3 = da_1;
            }
            else
            {
                local_3 = db_1;
            }
            var _S168 : f32 = cell_5.x;
            var _S169 : f32 = cell_5.y;
            var row_2 : f32 = round(2.0f * _S169 / 1.7320507764816284f);
            var _S170 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_3 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S168 * pitch_1 / _S162, param_0.direction_0) + 0.34000000357627869f * _S169 * pitch_1 + 1.1000000238418579f * fract((round(_S168 - 0.5f * row_2) - row_2) / 3.0f)) * param_0.span_0));
            f_5.b_0 = _S170;
            f_5.a_0 = _S170;
            var _S171 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_3.y)));
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_1(0.5f + 0.5f * local_3.x / _S171, 2.0f * _S171 * pitch_1 * _S161, 1.0f);
            }
        }
    case u32(409):
        {
            var swing_1 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * u_1);
            var focal_1 : f32 = 0.2199999988079071f * min(_S162, 1.0f);
            var focus_1 : vec2<f32> = vec2<f32>(cos(swing_1), sin(swing_1)) * vec2<f32>(focal_1);
            var range_1 : f32 = 2.0f * (max(length(max(center_4, vec2<f32>(1.0f) - center_4) * metric_2), 0.0010000000474974513f) - focal_1) + 0.039999999105930328f;
            var band_6 : f32 = creativeAxis42_0(clamp((length(v_5 - focus_1) + length(v_5 + focus_1) - 2.0f * focal_1) / max(0.019999999552965164f, range_1), 0.0f, 1.0f), param_0.direction_0) * _S165 - 0.77999997138977051f * _S164 * u_1;
            var cell_6 : f32 = floor(band_6);
            var t_6 : f32 = bounce3_0(clock_3 - param_0.span_0 * cell_6 / _S165);
            var _S172 : f32 = mix(t_6, 1.0f - t_6, 0.80000001192092896f * fract(cell_6 * 0.5f) * 2.0f);
            f_5.b_0 = _S172;
            f_5.a_0 = _S172;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = tiledLight42_1(fract(band_6), range_1 * 0.5f * _S161 / _S165, 1.0f);
            }
        }
    case u32(410):
        {
            var _S173 : f32 = min(3.0f, _S165);
            var shift_1 : vec2<f32> = _S163 + vec2<f32>(0.5f);
            var _S174 : f32 = shift_1.y * _S173;
            var row_3 : f32 = floor(_S174);
            var base_2 : f32 = floor(_S165 / _S173);
            var _S175 : i32;
            if(((clamp(row_3, 0.0f, _S173 - 1.0f)) < (_S165 - base_2 * _S173)))
            {
                _S175 = i32(1);
            }
            else
            {
                _S175 = i32(0);
            }
            var cols_3 : f32 = base_2 + f32(_S175);
            var x_6 : f32 = shift_1.x * cols_3 - (0.62999999523162842f + 0.12999999523162842f * row_3) * _S164 * creativeAxis42_0(u_1, param_0.direction_0) + 0.36000001430511475f * row_3;
            var col_1 : f32 = floor(x_6);
            var _S176 : f32 = fract(x_6) - 0.5f;
            var _S177 : f32 = fract(_S174) - 0.5f;
            var roundBox_1 : vec2<f32> = abs(vec2<f32>(_S176, _S177)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_3 : f32 = length(max(roundBox_1, vec2<f32>(0.0f))) + min(max(roundBox_1.x, roundBox_1.y), 0.0f) - 0.075000002980232239f;
            var aa_1 : f32 = max(cols_3 / _S160, _S173 / _S161) * 1.1000000238418579f;
            f_5.a_0 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_3 + 0.69999998807907104f);
            f_5.b_0 = bounce3_0(clock_3 - 0.40999999642372131f * col_1 - 0.28999999165534973f * row_3) * param_0.span_0 + 0.039999999105930328f;
            f_5.weight_0 = 1.0f - smoothstep(- aa_1, aa_1, edge_3);
            var _S178 : f32 = max(0.0f, abs(_S177) - 0.33000001311302185f);
            var bound_1 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S178 * _S178));
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_5.light_0 = edgeLight42_1(clamp(0.5f + 0.5f * _S176 / bound_1, 0.0f, 1.0f), 2.0f * bound_1 * _S160 / cols_3, f_5.weight_0);
            }
        }
    default :
        {
        }
    }
    return f_5;
}

fn isStripe42_1() -> bool
{
    var _S179 : bool;
    if((param_0.customMap_0) == u32(0))
    {
        _S179 = ((param_0.direction_0) < u32(2));
    }
    else
    {
        _S179 = false;
    }
    if(_S179)
    {
        var _S180 : u32 = param_0.shape_0;
        if((param_0.shape_0) == u32(0))
        {
            _S179 = true;
        }
        else
        {
            _S179 = _S180 == u32(1);
        }
        if(_S179)
        {
            _S179 = true;
        }
        else
        {
            _S179 = _S180 == u32(11);
        }
    }
    else
    {
        _S179 = false;
    }
    return _S179;
}

fn coordinate3_1( _S181 : vec2<f32>,  _S182 : f32) -> Coord_0
{
    var c_9 : Coord_0;
    var _S183 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_9.cell_3 = _S183;
    c_9.frac_0 = _S183;
    c_9.index_1 = 0.0f;
    c_9.coverage_3 = 1.0f;
    var _S184 : f32 = _S181.x;
    var _S185 : f32 = max(2.0f, param_0.slices_0);
    var _S186 : f32 = param_0.outputW_0;
    var _S187 : f32 = param_0.outputH_0;
    var dim_1 : vec2<f32> = vec2<f32>(param_0.outputW_0, param_0.outputH_0);
    var _S188 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var v_6 : vec2<f32> = (_S181 - _S188) * dim_1;
    var _S189 : vec2<f32> = vec2<f32>(1.0f);
    var radii_2 : vec2<f32> = max(_S188, _S189 - _S188) * dim_1;
    var _S190 : f32 = max(length(radii_2), 1.0f);
    var rmin_1 : f32 = length(max(_S183, max((vec2<f32>(0) - _S188), _S188 - _S189)) * dim_1);
    var _S191 : u32 = param_0.shape_0;
    var q_8 : f32;
    var lengthPx_4 : f32;
    var _S192 : i32;
    var _S193 : bool;
    switch(param_0.shape_0)
    {
    case u32(0):
        {
            q_8 = _S184;
        }
    case u32(1):
        {
            q_8 = _S181.y;
        }
    case u32(2), u32(12):
        {
            var a_11 : f32 = param_0.angle_0 * 3.1415927410125732f / 180.0f;
            var _S194 : f32 = cos(a_11);
            var _S195 : f32 = sin(a_11);
            var _S196 : f32 = _S186 * _S194;
            var _S197 : f32 = _S187 * _S195;
            var q_9 : f32 = (dot(_S181 * dim_1, vec2<f32>(_S194, _S195)) - (min(0.0f, _S196) + min(0.0f, _S197))) / max(1.0f, abs(_S196) + abs(_S197));
            if(_S191 == u32(12))
            {
                q_8 = q_9 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(_S181.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_8 = q_9;
            }
        }
    case u32(3):
        {
            switch(param_0.origin_0)
            {
            case u32(1):
                {
                    q_8 = axisAngle3_0(v_6.y, v_6.x);
                }
            case u32(2):
                {
                    q_8 = axisAngle3_0(v_6.x, - v_6.y);
                }
            case u32(3):
                {
                    q_8 = axisAngle3_0(- v_6.x, v_6.y);
                }
            default :
                {
                    q_8 = axisAngle3_0(- v_6.y, - v_6.x);
                }
            }
            if((q_8 >= 0.0f))
            {
                _S193 = (q_8 <= 3.1415927410125732f);
            }
            else
            {
                _S193 = false;
            }
            if(_S193)
            {
                _S192 = i32(1);
            }
            else
            {
                _S192 = i32(0);
            }
            c_9.coverage_3 = f32(_S192);
            q_8 = clamp(q_8 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            var startAngle_1 : f32 = param_0.angle_0 / 360.0f;
            var _S198 : f32 = v_6.x;
            var _S199 : f32 = v_6.y;
            var _S200 : f32 = axisAngle3_0(_S198, - _S199);
            var _S201 : f32 = abs(_S198);
            var _S202 : f32 = abs(_S199);
            if(((_S201 + _S202) < 9.99999997475242708e-07f))
            {
                q_8 = 0.0f;
            }
            else
            {
                if((_S202 < 9.99999997475242708e-07f))
                {
                    if((_S198 > 0.0f))
                    {
                        q_8 = 1.5707963705062866f;
                    }
                    else
                    {
                        q_8 = -1.5707963705062866f;
                    }
                }
                else
                {
                    if((_S201 < 9.99999997475242708e-07f))
                    {
                        if((_S199 < 0.0f))
                        {
                            q_8 = 0.0f;
                        }
                        else
                        {
                            q_8 = 3.1415927410125732f;
                        }
                    }
                    else
                    {
                        q_8 = _S200;
                    }
                }
            }
            q_8 = fract(q_8 / 6.2831854820251465f + 1.0f - param_0.turns_0 * param_0.u_0 - startAngle_1);
        }
    case u32(5), u32(14):
        {
            q_8 = (length(v_6) - rmin_1) / max(1.0f, _S190 - rmin_1);
        }
    case u32(6), u32(7):
        {
            var vr_1 : vec2<f32> = rot3_0(v_6, param_0.angle_0 * 3.1415927410125732f / 180.0f + param_0.turns_0 * 2.0f * 3.1415927410125732f * param_0.u_0);
            if(_S191 == u32(6))
            {
                q_8 = (abs(vr_1.x) + abs(vr_1.y)) / max(1.0f, radii_2.x + radii_2.y);
            }
            else
            {
                q_8 = max(abs(vr_1.x) / max(radii_2.x, 1.0f), abs(vr_1.y) / max(radii_2.y, 1.0f));
            }
        }
    case u32(8), u32(10):
        {
            var _S203 : bool = _S191 == u32(10);
            if(_S203)
            {
                q_8 = max(1.0f, ceil(_S185 / 2.0f));
            }
            else
            {
                q_8 = _S185;
            }
            var gs_1 : vec2<f32> = gridSize3_0(q_8, dim_1);
            var _S204 : f32 = gs_1.y;
            var _S205 : f32 = _S181.y * _S204;
            var _S206 : f32 = min(floor(_S205), _S204 - 1.0f);
            var _S207 : f32 = gs_1.x;
            var extra_1 : f32 = q_8 - _S207 * _S204;
            if((_S206 < extra_1))
            {
                _S192 = i32(1);
            }
            else
            {
                _S192 = i32(0);
            }
            var cols_4 : f32 = _S207 + f32(_S192);
            var _S208 : f32 = _S184 * cols_4;
            var _S209 : f32 = min(floor(_S208), cols_4 - 1.0f);
            var index_4 : f32 = _S206 * _S207 + min(_S206, extra_1) + _S209;
            c_9.cell_3 = vec2<f32>(_S209, _S206);
            c_9.frac_0 = fract(vec2<f32>(_S208, _S205));
            if(_S203)
            {
                var _S210 : f32 = _S185 - 1.0f;
                var _S211 : f32 = index_4 * 2.0f;
                if(((c_9.frac_0.x + c_9.frac_0.y) >= 1.0f))
                {
                    _S192 = i32(1);
                }
                else
                {
                    _S192 = i32(0);
                }
                lengthPx_4 = min(_S210, _S211 + f32(_S192));
            }
            else
            {
                lengthPx_4 = index_4;
            }
            q_8 = lengthPx_4 / max(1.0f, _S185 - 1.0f);
        }
    case u32(9):
        {
            q_8 = fract(axisAngle3_0(v_6.y, v_6.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_6) / _S190));
        }
    case u32(11):
        {
            q_8 = _S184;
        }
    case u32(13):
        {
            q_8 = length(v_6) / max(1.0f, _S190 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * axisAngle3_0(v_6.y, v_6.x))));
        }
    default :
        {
            q_8 = _S184;
        }
    }
    if((param_0.customMap_0) != u32(0))
    {
        c_9.coverage_3 = 1.0f;
        q_8 = _S182;
    }
    var q_10 : f32 = clamp(q_8, 0.0f, 1.0f);
    var _S212 : u32 = param_0.direction_0;
    var _S213 : bool = (param_0.direction_0) == u32(1);
    if(_S213)
    {
        q_8 = 1.0f - q_10;
    }
    else
    {
        q_8 = q_10;
    }
    if((_S212 >= u32(2)))
    {
        if(_S191 == u32(8))
        {
            _S193 = true;
        }
        else
        {
            _S193 = _S191 == u32(10);
        }
        if(_S193)
        {
            q_8 = max(abs(_S184 - 0.5f), abs(_S181.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_8 = abs(q_8 - 0.5f) * 2.0f;
        }
        if(_S212 == u32(3))
        {
            q_8 = 1.0f - q_8;
        }
    }
    c_9.raw_0 = q_8;
    var _S214 : f32 = q_8 * _S185;
    var _S215 : f32 = _S185 - 1.0f;
    c_9.index_1 = min(floor(_S214), _S215);
    var edge_4 : f32 = round(_S214);
    if(((abs(_S214 - edge_4)) < 9.9999997473787516e-05f))
    {
        c_9.raw_0 = edge_4 / _S185;
        c_9.index_1 = min(edge_4, _S215);
    }
    if(isStripe42_1())
    {
        _S193 = ((param_0.reserved0_0) <= 0.0f);
    }
    else
    {
        _S193 = false;
    }
    if(_S193)
    {
        var _S216 : bool = _S191 == u32(1);
        if(_S216)
        {
            lengthPx_4 = param_0.sampleH_0;
        }
        else
        {
            lengthPx_4 = param_0.sampleW_0;
        }
        var _S217 : f32;
        if(_S216)
        {
            _S217 = _S181.y;
        }
        else
        {
            _S217 = _S184;
        }
        var pixel_3 : f32 = floor(_S217 * lengthPx_4);
        if(_S213)
        {
            _S217 = lengthPx_4 - 1.0f - pixel_3;
        }
        else
        {
            _S217 = pixel_3;
        }
        var _S218 : f32 = rasterStripeIndex42_0(_S217, lengthPx_4, _S185);
        c_9.index_1 = _S218;
    }
    if(((param_0.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_8 = c_9.index_1 / _S215;
    }
    c_9.q_1 = q_8;
    return c_9;
}

fn creative3_1( _S219 : vec2<f32>,  _S220 : Coord_0) -> Field_0
{
    var u_2 : f32 = param_0.u_0;
    var _S221 : f32 = param_0.cycles_0;
    var clock_4 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var _S222 : f32 = max(2.0f, param_0.slices_0);
    var depth_0 : f32 = param_0.span_0;
    var _S223 : f32 = param_0.cx_0;
    var center_5 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var _S224 : f32 = param_0.aspect_0;
    var metric_3 : vec2<f32> = vec2<f32>(param_0.aspect_0, 1.0f);
    var v_7 : vec2<f32> = (_S219 - center_5) * metric_3;
    var _S225 : f32 = bounce3_0(clock_4);
    var f_6 : Field_0 = single3_0(_S219, _S225);
    var band_7 : f32;
    var phase_11 : f32;
    var lateral_1 : f32;
    var q_11 : f32;
    var i_2 : i32;
    var horizontal_1 : bool;
    switch(param_0.design_0)
    {
    case u32(9):
        {
            var _S226 : f32 = length(v_7);
            var phase_12 : f32 = fract(2.0f * (axisAngle3_0(v_7.x, - v_7.y) / 6.2831854820251465f) + _S226 / max(length(metric_3 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * depth_0);
            var _S227 : f32 = param_0.pixel_0;
            var _S228 : bool = ((param_0.pixel_0) > 0.0f);
            if(_S228)
            {
                band_7 = phase_12 - _S221 * u_2;
            }
            else
            {
                band_7 = phase_12 * _S222;
            }
            if(_S227 == 0.0f)
            {
                phase_11 = floor(band_7) / (_S222 - 1.0f);
            }
            else
            {
                phase_11 = phase_12;
            }
            var _S229 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(_S221 * u_2 - phase_11);
            f_6.b_0 = _S229;
            f_6.a_0 = _S229;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                var _S230 : f32 = fract(band_7);
                var _S231 : f32 = min(3.1415927410125732f * _S226 * param_0.sampleH_0, param_0.sampleH_0);
                if(_S228)
                {
                    band_7 = 1.0f;
                }
                else
                {
                    band_7 = _S222;
                }
                f_6.light_0 = tiledLight42_1(_S230, _S231 / band_7, 1.0f);
            }
        }
    case u32(10):
        {
            var q_12 : f32 = clamp(1.0f - abs(_S219.x - _S223) * 2.0f, 0.0f, 1.0f);
            var _S232 : f32 = _S222 - 1.0f;
            var band_8 : f32 = q_12 * _S232;
            var _S233 : f32 = param_0.pixel_0;
            if((param_0.pixel_0) == 0.0f)
            {
                q_11 = floor(band_8) / _S232;
            }
            else
            {
                q_11 = q_12;
            }
            var _S234 : f32 = 0.80000001192092896f * depth_0;
            var _S235 : f32 = _S234 * q_11;
            var _S236 : f32 = bounce3_0(clock_4 - _S235);
            f_6.b_0 = _S236;
            f_6.a_0 = _S236;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                var _S237 : bool = (_S233 > 0.0f);
                if(_S237)
                {
                    band_7 = _S235 - clock_4;
                }
                else
                {
                    band_7 = band_8;
                }
                var _S238 : f32 = fract(band_7);
                var _S239 : f32 = 0.5f * param_0.sampleW_0;
                if(_S237)
                {
                    band_7 = _S234;
                }
                else
                {
                    band_7 = _S232;
                }
                f_6.light_0 = tiledLight42_1(_S238, _S239 / band_7, 1.0f);
            }
        }
    case u32(11):
        {
            var _S240 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, param_0.softness_0 * 0.15999999642372131f);
            var _S241 : f32 = _S220.frac_0.y;
            var ah_1 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S240, abs(_S241 - 0.5f));
            var _S242 : f32 = _S220.frac_0.x;
            var av_1 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S240, abs(_S242 - 0.5f));
            var _S243 : f32 = _S220.cell_3.y;
            var over_1 : bool = (i32(floor(_S220.cell_3.x) + floor(_S243)) % i32(2)) == i32(0);
            var ht_1 : f32 = bounce3_0(clock_4 - _S219.x * depth_0);
            var vt_1 : f32 = bounce3_0(clock_4 + _S219.y * depth_0 + 1.0f);
            var _S244 : bool = (ah_1 > 0.0f);
            if(_S244)
            {
                horizontal_1 = true;
            }
            else
            {
                horizontal_1 = (av_1 > 0.0f);
            }
            if(horizontal_1)
            {
                if(over_1)
                {
                    band_7 = vt_1;
                }
                else
                {
                    band_7 = ht_1;
                }
                f_6.a_0 = band_7;
                if(over_1)
                {
                    band_7 = ht_1;
                }
                else
                {
                    band_7 = vt_1;
                }
                f_6.b_0 = band_7;
                if(over_1)
                {
                    band_7 = ah_1;
                }
                else
                {
                    band_7 = av_1;
                }
                f_6.weight_0 = band_7;
                if(ah_1 == 0.0f)
                {
                    f_6.b_0 = vt_1;
                    f_6.a_0 = vt_1;
                }
                if(av_1 == 0.0f)
                {
                    f_6.b_0 = ht_1;
                    f_6.a_0 = ht_1;
                }
            }
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                if(_S244)
                {
                    horizontal_1 = true;
                }
                else
                {
                    horizontal_1 = (av_1 > 0.0f);
                }
            }
            else
            {
                horizontal_1 = false;
            }
            if(horizontal_1)
            {
                if(av_1 == 0.0f)
                {
                    horizontal_1 = true;
                }
                else
                {
                    if(_S244)
                    {
                        horizontal_1 = over_1;
                    }
                    else
                    {
                        horizontal_1 = false;
                    }
                }
                if(horizontal_1)
                {
                    band_7 = ah_1;
                }
                else
                {
                    band_7 = av_1;
                }
                if(horizontal_1)
                {
                    phase_11 = _S241;
                }
                else
                {
                    phase_11 = _S242;
                }
                var phase_13 : f32 = clamp((phase_11 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_3 : vec2<f32> = gridSize3_0(_S222, vec2<f32>(param_0.outputW_0, param_0.outputH_0));
                var _S245 : f32 = grid_3.x;
                var _S246 : f32 = grid_3.y;
                if((_S243 < (_S222 - _S245 * _S246)))
                {
                    i_2 = i32(1);
                }
                else
                {
                    i_2 = i32(0);
                }
                var cols_5 : f32 = _S245 + f32(i_2);
                if(horizontal_1)
                {
                    phase_11 = param_0.sampleH_0 / _S246;
                }
                else
                {
                    phase_11 = param_0.sampleW_0 / cols_5;
                }
                f_6.light_0 = edgeLight42_1(phase_13, 0.47999998927116394f * phase_11, band_7);
            }
        }
    case u32(12):
        {
            var sources_1 : u32 = clamp(param_0.waveSources_0, u32(2), u32(4));
            var i_3 : u32 = u32(0);
            band_7 = 0.0f;
            loop
            {
                if((i_3 < sources_1))
                {
                }
                else
                {
                    break;
                }
                var a_12 : f32 = 6.2831854820251465f * f32(i_3) / f32(sources_1);
                var r_4 : f32 = length((_S219 - (center_5 + vec2<f32>(0.18000000715255737f * cos(a_12), 0.18000000715255737f * sin(a_12)))) * metric_3);
                var band_9 : f32 = r_4 * _S222;
                var _S247 : f32 = param_0.pixel_0;
                if((param_0.pixel_0) == 0.0f)
                {
                    phase_11 = floor(band_9) / _S222;
                }
                else
                {
                    phase_11 = r_4;
                }
                var _S248 : f32 = phase_11 * 1.2999999523162842f * depth_0;
                var sum_1 : f32 = band_7 + bounce3_0(clock_4 - _S248);
                if(((param_0.shadowStrength_0) > 0.0f))
                {
                    var _S249 : bool = (_S247 > 0.0f);
                    if(_S249)
                    {
                        lateral_1 = _S248 - clock_4;
                    }
                    else
                    {
                        lateral_1 = band_9;
                    }
                    var phase_14 : f32 = fract(lateral_1);
                    var _S250 : f32 = f_6.light_0;
                    var _S251 : f32 = param_0.sampleH_0;
                    if(_S249)
                    {
                        q_11 = 1.2999999523162842f * depth_0;
                    }
                    else
                    {
                        q_11 = _S222;
                    }
                    f_6.light_0 = min(_S250, tiledLight42_1(phase_14, _S251 / q_11, 1.0f));
                }
                i_3 = i_3 + u32(1);
                band_7 = sum_1;
            }
            var _S252 : f32 = band_7 / f32(sources_1);
            f_6.b_0 = _S252;
            f_6.a_0 = _S252;
        }
    case u32(13):
        {
            var _S253 : f32 = 6.2831854820251465f * u_2;
            var _S254 : f32 = sin(_S253);
            var local_4 : vec2<f32> = (_S219 - (center_5 + vec2<f32>(0.2199999988079071f * _S254, 0.12999999523162842f * cos(_S253)))) * metric_3;
            var r_5 : f32 = length(local_4);
            var radius_2 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S254;
            var _S255 : f32 = max(0.0020000000949949026f, param_0.softness_0 * 0.15999999642372131f);
            f_6.b_0 = bounce3_0(clock_4 + 0.80000001192092896f * depth_0);
            f_6.weight_0 = 1.0f - smoothstep(radius_2 - _S255, radius_2 + _S255, r_5);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                horizontal_1 = ((f_6.weight_0) > 0.0f);
            }
            else
            {
                horizontal_1 = false;
            }
            if(horizontal_1)
            {
                var _S256 : f32 = local_4.y;
                var halfWidth_1 : f32 = sqrt(max(9.99999997475242708e-07f, radius_2 * radius_2 - _S256 * _S256));
                f_6.light_0 = edgeLight42_1(clamp(0.5f + 0.5f * local_4.x / halfWidth_1, 0.0f, 1.0f), 2.0f * halfWidth_1 * param_0.sampleH_0, f_6.weight_0);
            }
        }
    case u32(400):
        {
            var _S257 : f32 = max(_S222, 2.0f);
            var gap_2 : f32 = 0.64999997615814209f / _S257;
            var d_2 : f32 = fract(u_2 * _S221) * 1.6499999761581421f - _S219.x;
            var j_1 : f32 = floor(d_2 / gap_2);
            var local_5 : f32 = fract(d_2 / gap_2);
            if((j_1 >= 0.0f))
            {
                horizontal_1 = (j_1 < _S257);
            }
            else
            {
                horizontal_1 = false;
            }
            if(horizontal_1)
            {
                var _S258 : f32 = max(0.014999999664723873f, param_0.softness_0 * 0.15000000596046448f);
                var a_13 : f32 = smoothstep(0.0f, _S258, local_5) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S258, local_5));
                f_6.b_0 = clamp(1.0f - j_1 / _S257, 0.0f, 1.0f);
                f_6.weight_0 = a_13 * (1.0f - 0.64999997615814209f * j_1 / _S257);
            }
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_1(clamp(1.0f - local_5 / 0.64999997615814209f, 0.0f, 1.0f), gap_2 * 0.64999997615814209f * param_0.sampleW_0, f_6.weight_0);
            }
        }
    case u32(401):
        {
            var _S259 : f32 = _S219.y;
            if((i32(floor(_S259 * _S222)) % i32(2)) == i32(0))
            {
                band_7 = 1.0f;
            }
            else
            {
                band_7 = -1.0f;
            }
            var gap_3 : f32 = 0.34999999403953552f * smoothstep(_S225 - 0.059999998658895493f, _S225 + 0.059999998658895493f, _S259);
            var seam_1 : f32 = _S223 + band_7 * 0.02500000037252903f;
            var _S260 : f32 = _S219.x;
            var _S261 : f32 = _S260 - seam_1;
            var outside_1 : bool = ((abs(_S261)) > gap_3);
            if(outside_1)
            {
                if((_S260 < seam_1))
                {
                    band_7 = 0.079999998211860657f;
                }
                else
                {
                    band_7 = 0.94999998807907104f;
                }
                f_6.b_0 = band_7;
                f_6.a_0 = band_7;
            }
            var _S262 : bool = ((param_0.shadowStrength_0) > 0.0f);
            if(_S262)
            {
                var _S263 : f32 = clamp((_S261 + gap_3) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S264 : f32 = 0.2199999988079071f * param_0.sampleW_0;
                if(outside_1)
                {
                    horizontal_1 = (_S260 < seam_1);
                }
                else
                {
                    horizontal_1 = false;
                }
                if(horizontal_1)
                {
                    band_7 = 1.0f;
                }
                else
                {
                    band_7 = 0.0f;
                }
                f_6.light_0 = edgeLight42_1(_S263, _S264, band_7);
            }
            if(_S262)
            {
                horizontal_1 = ((param_0.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_1 = false;
            }
            if(horizontal_1)
            {
                var _S265 : f32 = clamp((_S261 - gap_3) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S266 : f32 = 0.2199999988079071f * param_0.sampleW_0;
                if(outside_1)
                {
                    horizontal_1 = (_S260 > seam_1);
                }
                else
                {
                    horizontal_1 = false;
                }
                if(horizontal_1)
                {
                    band_7 = 1.0f;
                }
                else
                {
                    band_7 = 0.0f;
                }
                f_6.light_0 = edgeLight42_1(_S265, _S266, band_7);
            }
        }
    case u32(402):
        {
            var a_14 : f32 = axisAngle3_0(v_7.y, v_7.x);
            var r_6 : f32 = length(v_7);
            var radius_3 : f32 = 0.4699999988079071f * min(_S224, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * u_2 * _S221)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_14 * _S222));
            var _S267 : f32 = max(0.0010000000474974513f, param_0.softness_0 * 0.019999999552965164f);
            var _S268 : f32 = fract((a_14 + 3.1415927410125732f) / 6.2831854820251465f) * _S222;
            f_6.b_0 = bounce3_0(clock_4 + floor(_S268) / _S222 * depth_0);
            f_6.weight_0 = 1.0f - smoothstep(radius_3 - _S267, radius_3 + _S267, r_6);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_1(fract(_S268), 6.2831854820251465f * r_6 * param_0.sampleH_0 / _S222, f_6.weight_0);
            }
        }
    case u32(403):
        {
            var r_7 : f32 = length(v_7);
            var _S269 : f32 = max(3.0f, _S222);
            var sector_1 : f32 = 6.2831854820251465f / _S269;
            var _S270 : f32 = axisAngle3_0(v_7.y, v_7.x) + u_2 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_1 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * u_2 * _S221))) * min(_S224, 1.0f) * cos(3.1415927410125732f / _S269) / max(0.0010000000474974513f, cos(fract(_S270 / sector_1) * sector_1 - sector_1 * 0.5f));
            f_6.a_0 = bounce3_0(clock_4 - depth_0 * floor(fract(_S270 / 6.2831854820251465f) * _S269) / _S269);
            f_6.b_0 = bounce3_0(clock_4 + 1.0f);
            f_6.weight_0 = 1.0f - smoothstep(aperture_1 - 0.0020000000949949026f, aperture_1 + 0.0020000000949949026f, r_7);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = tiledLight42_1(fract(_S270 / sector_1), sector_1 * r_7 * param_0.sampleH_0, 1.0f - f_6.weight_0);
            }
        }
    case u32(404):
        {
            var _S271 : f32 = fract(u_2 * _S221);
            band_7 = 1.0e+09f;
            phase_11 = 0.0f;
            lateral_1 = 0.0f;
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
                var _S272 : f32 = f32(i_2);
                var a0_1 : f32 = 6.2831854820251465f * _S272 / 32.0f;
                var _S273 : i32 = i_2 + i32(1);
                var a1_1 : f32 = 6.2831854820251465f * f32(_S273) / 32.0f;
                var a_15 : vec2<f32> = center_5 + vec2<f32>(0.34000000357627869f * sin(a0_1), 0.2199999988079071f * sin(2.0f * a0_1));
                var segment_1 : vec2<f32> = (center_5 + vec2<f32>(0.34000000357627869f * sin(a1_1), 0.2199999988079071f * sin(2.0f * a1_1)) - a_15) * metric_3;
                var point_1 : vec2<f32> = (_S219 - a_15) * metric_3;
                var k_1 : f32 = clamp(dot(point_1, segment_1) / max(dot(segment_1, segment_1), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_1 : vec2<f32> = point_1 - vec2<f32>(k_1) * segment_1;
                var distance_4 : f32 = dot(delta_1, delta_1);
                var trail_1 : f32 = fract(_S271 - (_S272 + k_1) / 32.0f + 1.0f);
                if((trail_1 < 0.60000002384185791f))
                {
                    horizontal_1 = (distance_4 < band_7);
                }
                else
                {
                    horizontal_1 = false;
                }
                if(horizontal_1)
                {
                    if(((param_0.shadowStrength_0) > 0.0f))
                    {
                        if(((dot(delta_1, vec2<f32>(segment_1.y, - segment_1.x))) >= 0.0f))
                        {
                            q_11 = 1.0f;
                        }
                        else
                        {
                            q_11 = -1.0f;
                        }
                    }
                    else
                    {
                        q_11 = lateral_1;
                    }
                    band_7 = distance_4;
                    phase_11 = trail_1;
                    lateral_1 = q_11;
                }
                i_2 = _S273;
            }
            var _S274 : f32 = max(0.0020000000949949026f, param_0.softness_0 * 0.039999999105930328f);
            var best_1 : f32 = sqrt(band_7);
            f_6.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S274, 0.035000000149011612f + _S274, best_1);
            var q_13 : f32 = phase_11 / 0.60000002384185791f;
            if((param_0.pixel_0) == 0.0f)
            {
                q_11 = floor(q_13 * _S222) / (_S222 - 1.0f);
            }
            else
            {
                q_11 = q_13;
            }
            f_6.b_0 = 0.15000000596046448f + 0.85000002384185791f * q_11;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_6.light_0 = edgeLight42_1(clamp(0.5f + best_1 * lateral_1 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * param_0.sampleH_0, f_6.weight_0);
            }
        }
    default :
        {
        }
    }
    return f_6;
}

fn frozen3_1( _S275 : vec2<f32>,  _S276 : Coord_0) -> Field_0
{
    var build_2 : f32 = clamp(param_0.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var u_3 : f32 = param_0.u_0;
    var _S277 : bool = ((param_0.pixel_0) > 0.0f);
    var held_1 : f32;
    if(_S277)
    {
        held_1 = _S276.raw_0;
    }
    else
    {
        held_1 = min(1.0f, (_S276.index_1 + 1.0f) / max(2.0f, param_0.slices_0));
    }
    var _S278 : u32 = param_0.flags_0;
    if((((param_0.flags_0) & (u32(1024)))) != u32(0))
    {
        var skip_1 : f32 = clamp(param_0.reserved1_0, 0.0f, 1.0f);
        var _S279 : f32 = held_1 * (1.0f - skip_1);
        if((held_1 > 0.5f))
        {
            held_1 = skip_1;
        }
        else
        {
            held_1 = 0.0f;
        }
        held_1 = _S279 + held_1;
    }
    var a_16 : f32;
    if((u_3 < build_2))
    {
        var progress_1 : f32 = u_3 / build_2;
        var _S280 : bool;
        if(_S277)
        {
            _S280 = true;
        }
        else
        {
            _S280 = ((_S278 & (u32(1)))) != u32(0);
        }
        if(_S280)
        {
            var _S281 : f32 = max(1.0f / max(param_0.outputW_0, param_0.outputH_0), param_0.softness_0 * 0.0030000000260770321f);
            a_16 = 1.0f - smoothstep(progress_1 - _S281, progress_1 + _S281, _S276.raw_0);
        }
        else
        {
            var _S282 : i32;
            if((progress_1 >= (_S276.q_1)))
            {
                _S282 = i32(1);
            }
            else
            {
                _S282 = i32(0);
            }
            a_16 = f32(_S282);
        }
        var f_7 : Field_0 = single3_0(_S275, progress_1);
        f_7.b_0 = held_1;
        f_7.weight_0 = a_16;
        return f_7;
    }
    var after_1 : f32 = clamp((u_3 - build_2) / (1.0f - build_2), 0.0f, 1.0f);
    switch(param_0.ending_0)
    {
    case u32(0):
        {
            a_16 = held_1;
        }
    case u32(1):
        {
            a_16 = clamp(held_1 + after_1, 0.0f, 1.0f);
        }
    case u32(2):
        {
            var release_1 : f32 = _S276.q_1 * 0.64999997615814209f;
            a_16 = clamp(held_1 + max(0.0f, after_1 - release_1) / max(0.05000000074505806f, 1.0f - release_1), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_1 > 0.0f))
            {
                held_1 = play3_0(held_1 - 2.0f * param_0.cycles_0 * after_1, param_0.playback_0);
            }
            a_16 = held_1;
        }
    case u32(4):
        {
            a_16 = bounce3_0(held_1 - 2.0f * param_0.cycles_0 * after_1);
        }
    default :
        {
            a_16 = held_1;
        }
    }
    return single3_0(_S275, a_16);
}

fn relative3_1( _S283 : Coord_0) -> f32
{
    var _S284 : u32 = param_0.flags_0;
    var d_3 : f32;
    if((((param_0.flags_0) & (u32(4)))) != u32(0))
    {
        d_3 = (_S283.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if(((_S284 & (u32(8)))) != u32(0))
        {
            d_3 = (_S283.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_3 = 2.0f * _S283.raw_0 - 1.0f;
        }
    }
    if((param_0.pixel_0) == 0.0f)
    {
        var _S285 : f32 = param_0.slices_0 - 1.0f;
        var positive_1 : f32 = ceil(_S285 / 2.0f);
        var negative_1 : f32 = floor(_S285 / 2.0f);
        var _S286 : f32;
        if((d_3 < 0.0f))
        {
            _S286 = negative_1;
        }
        else
        {
            _S286 = positive_1;
        }
        var _S287 : f32 = max(1.0f, _S286);
        d_3 = round(d_3 * _S287) / _S287;
    }
    return param_0.span_0 * d_3;
}

fn basic3_1( _S288 : vec2<f32>,  _S289 : Coord_0) -> Field_0
{
    var _S290 : f32 = param_0.cycles_0;
    var _S291 : f32 = param_0.u_0;
    var clock_5 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var t_7 : f32;
    if((param_0.customMap_0) != u32(0))
    {
        if((((param_0.flags_0) & (u32(2)))) != u32(0))
        {
            t_7 = _S291 + relative3_1(_S289);
        }
        else
        {
            t_7 = _S289.q_1 + clock_5;
        }
        return single3_0(_S288, play3_0(t_7, param_0.playback_0));
    }
    var _S292 : u32 = param_0.design_0;
    if((param_0.design_0) == u32(0))
    {
        t_7 = 0.20000000298023224f + 0.80000001192092896f * fract(_S290 * _S291 - _S289.q_1);
    }
    else
    {
        if(_S292 == u32(5))
        {
            t_7 = bounce3_0(1.0f - clock_5 - param_0.span_0 * _S289.q_1);
        }
        else
        {
            if((param_0.shape_0) == u32(11))
            {
                if((i32(_S289.index_1) % i32(2)) == i32(0))
                {
                    t_7 = 1.0f;
                }
                else
                {
                    t_7 = -1.0f;
                }
                t_7 = play3_0(1.0f + clock_5 * t_7 - param_0.span_0 * _S289.q_1, param_0.playback_0);
            }
            else
            {
                t_7 = play3_0(1.0f + clock_5 - param_0.span_0 * _S289.q_1, param_0.playback_0);
            }
        }
    }
    return single3_0(_S288, t_7);
}

fn wave3_1( _S293 : vec2<f32>,  _S294 : Coord_0) -> Field_0
{
    var _S295 : bool;
    if((param_0.customMap_0) != u32(0))
    {
        _S295 = (((param_0.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S295 = false;
    }
    var phase_15 : f32;
    if(_S295)
    {
        phase_15 = 2.0f * param_0.cycles_0 * param_0.u_0 + relative3_1(_S294);
    }
    else
    {
        phase_15 = 2.0f * param_0.cycles_0 * param_0.u_0 - 2.0f * param_0.density_0 * _S294.q_1;
    }
    return single3_0(_S293, play3_0(phase_15, param_0.playback_0));
}

fn frozenShadow53_1( _S296 : vec2<f32>,  _S297 : f32) -> f32
{
    var _S298 : TFParams_std140_0 = param_0;
    var geometry_1 : TFParams_0;
    geometry_1.outTime_0 = param_0.outTime_0;
    geometry_1.u_0 = param_0.u_0;
    geometry_1.sourceDuration_0 = param_0.sourceDuration_0;
    geometry_1.aspect_0 = param_0.aspect_0;
    geometry_1.slices_0 = param_0.slices_0;
    geometry_1.pixel_0 = param_0.pixel_0;
    geometry_1.span_0 = param_0.span_0;
    geometry_1.cycles_0 = param_0.cycles_0;
    geometry_1.cx_0 = param_0.cx_0;
    geometry_1.cy_0 = param_0.cy_0;
    geometry_1.angle_0 = param_0.angle_0;
    geometry_1.turns_0 = param_0.turns_0;
    geometry_1.build_0 = param_0.build_0;
    geometry_1.softness_0 = param_0.softness_0;
    geometry_1.density_0 = param_0.density_0;
    geometry_1.sourceReverse_0 = param_0.sourceReverse_0;
    geometry_1.sourceStart_0 = param_0.sourceStart_0;
    geometry_1.sourceEnd_0 = param_0.sourceEnd_0;
    geometry_1.outputW_0 = param_0.outputW_0;
    geometry_1.outputH_0 = param_0.outputH_0;
    geometry_1.family_0 = param_0.family_0;
    geometry_1.shape_0 = param_0.shape_0;
    geometry_1.design_0 = param_0.design_0;
    geometry_1.ending_0 = param_0.ending_0;
    geometry_1.direction_0 = param_0.direction_0;
    geometry_1.playback_0 = param_0.playback_0;
    geometry_1.origin_0 = param_0.origin_0;
    geometry_1.viewMode_0 = param_0.viewMode_0;
    geometry_1.frames_0 = param_0.frames_0;
    geometry_1.customMap_0 = param_0.customMap_0;
    geometry_1.waveSources_0 = param_0.waveSources_0;
    geometry_1.flags_0 = param_0.flags_0;
    geometry_1.shadowStrength_0 = param_0.shadowStrength_0;
    geometry_1.shadowWidth_0 = param_0.shadowWidth_0;
    geometry_1.shadowSoftness_0 = param_0.shadowSoftness_0;
    geometry_1.shadowSide_0 = param_0.shadowSide_0;
    geometry_1.sampleW_0 = param_0.sampleW_0;
    geometry_1.sampleH_0 = param_0.sampleH_0;
    geometry_1.reserved0_0 = param_0.reserved0_0;
    geometry_1.reserved1_0 = param_0.reserved1_0;
    geometry_1.sourcePeak_0 = param_0.sourcePeak_0;
    geometry_1.paperWhite_0 = param_0.paperWhite_0;
    geometry_1.displayPeak_0 = param_0.displayPeak_0;
    geometry_1.colorReserved_0 = param_0.colorReserved_0;
    geometry_1.direction_0 = u32(0);
    var _S299 : bool;
    if(((param_0.direction_0) >= u32(2)))
    {
        _S299 = (_S298.shape_0) != u32(8);
    }
    else
    {
        _S299 = false;
    }
    if(_S299)
    {
        _S299 = (_S298.shape_0) != u32(10);
    }
    else
    {
        _S299 = false;
    }
    if(_S299)
    {
        geometry_1.slices_0 = geometry_1.slices_0 * 2.0f;
    }
    var c_10 : Coord_0 = coordinate3_0(_S296, geometry_1, 0.0f);
    var _S300 : f32 = max(2.0f, geometry_1.slices_0);
    if((_S298.shape_0) == u32(8))
    {
        _S299 = true;
    }
    else
    {
        _S299 = (_S298.shape_0) == u32(10);
    }
    var cells_2 : f32;
    if(_S299)
    {
        var _S301 : bool = (_S298.shape_0) == u32(10);
        if(_S301)
        {
            cells_2 = ceil(_S300 / 2.0f);
        }
        else
        {
            cells_2 = _S300;
        }
        var grid_4 : vec2<f32> = gridSize3_0(cells_2, vec2<f32>(_S298.outputW_0, _S298.outputH_0));
        var _S302 : f32 = grid_4.x;
        var _S303 : i32;
        if(((c_10.cell_3.y) < (cells_2 - _S302 * grid_4.y)))
        {
            _S303 = i32(1);
        }
        else
        {
            _S303 = i32(0);
        }
        var phase_16 : f32 = c_10.frac_0.x;
        var span_13 : f32 = _S298.sampleW_0 / (_S302 + f32(_S303));
        var phase_17 : f32;
        var span_14 : f32;
        if(_S301)
        {
            var cut_3 : f32 = 1.0f - c_10.frac_0.y;
            var first_4 : bool = (phase_16 < cut_3);
            if(first_4)
            {
                cells_2 = cut_3;
            }
            else
            {
                cells_2 = 1.0f - cut_3;
            }
            var span_15 : f32 = span_13 * cells_2;
            if(first_4)
            {
                cells_2 = phase_16 / max(cut_3, 9.99999997475242708e-07f);
            }
            else
            {
                cells_2 = (phase_16 - cut_3) / max(1.0f - cut_3, 9.99999997475242708e-07f);
            }
            phase_17 = cells_2;
            span_14 = span_15;
        }
        else
        {
            phase_17 = phase_16;
            span_14 = span_13;
        }
        if(((_S298.shadowSide_0) > 0.0f))
        {
            cells_2 = phase_17;
        }
        else
        {
            cells_2 = 1.0f - phase_17;
        }
        return filteredLight42_1(cells_2, span_14, _S297, 1.0f, false);
    }
    var phase_18 : f32 = clamp(c_10.raw_0 * _S300 - c_10.index_1, 0.0f, 1.0f);
    var span_16 : f32 = coordSpan42_0(_S296, geometry_1) / _S300;
    if(((_S298.shadowSide_0) > 0.0f))
    {
        cells_2 = phase_18;
    }
    else
    {
        cells_2 = 1.0f - phase_18;
    }
    return filteredLight42_1(cells_2, span_16, _S297, 1.0f, false);
}

fn coordSpan42_1( _S304 : vec2<f32>) -> f32
{
    var _S305 : f32 = param_0.sampleW_0;
    var _S306 : f32 = param_0.sampleH_0;
    var size_2 : vec2<f32> = vec2<f32>(param_0.sampleW_0, param_0.sampleH_0);
    var _S307 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var v_8 : vec2<f32> = (_S304 - _S307) * size_2;
    var _S308 : vec2<f32> = vec2<f32>(1.0f);
    var radii_3 : vec2<f32> = max(_S307, _S308 - _S307) * size_2;
    if((param_0.customMap_0) != u32(0))
    {
        return min(_S305, _S306);
    }
    switch(param_0.shape_0)
    {
    case u32(1):
        {
            return _S306;
        }
    case u32(2), u32(12):
        {
            var a_17 : f32 = param_0.angle_0 * 3.1415927410125732f / 180.0f;
            return _S305 * abs(cos(a_17)) + _S306 * abs(sin(a_17));
        }
    case u32(3):
        {
            return 3.1415927410125732f * length(v_8);
        }
    case u32(4):
        {
            return 6.2831854820251465f * length(v_8);
        }
    case u32(5), u32(14):
        {
            return length(radii_3) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S307), _S307 - _S308)) * size_2);
        }
    case u32(6):
        {
            return (radii_3.x + radii_3.y) * 0.70710700750350952f;
        }
    case u32(7):
        {
            return min(radii_3.x, radii_3.y);
        }
    case u32(9):
        {
            return min(6.2831854820251465f * length(v_8), length(radii_3) / 1.5f);
        }
    case u32(13):
        {
            return length(radii_3) * 0.56000000238418579f;
        }
    default :
        {
            return _S305;
        }
    }
}

fn stripeLight42_1( _S309 : f32,  _S310 : f32,  _S311 : f32,  _S312 : f32,  _S313 : bool,  _S314 : f32) -> f32
{
    var span_17 : f32 = _S311 / _S312;
    if((span_17 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_1 : bool = ((param_0.shadowSide_0) > 0.0f);
    var center_6 : f32;
    if(leading_1)
    {
        center_6 = 0.0f;
    }
    else
    {
        center_6 = 1.0f;
    }
    var edge_5 : f32 = stripeBorder42_0(_S310 + center_6, _S311, _S312);
    var center_7 : f32 = floor(_S309 * _S311) + 0.5f;
    if(_S313)
    {
        center_6 = _S311 - center_7;
    }
    else
    {
        center_6 = center_7;
    }
    if(leading_1)
    {
        center_6 = center_6 - edge_5;
    }
    else
    {
        center_6 = edge_5 - center_6;
    }
    return filteredLight42_1(max(0.5f, center_6) / span_17, span_17, _S314, 1.0f, false);
}

fn sliceLight42_1( _S315 : vec2<f32>,  _S316 : Coord_0,  _S317 : f32) -> f32
{
    var _S318 : u32 = param_0.family_0;
    var _S319 : bool;
    if((param_0.family_0) == u32(0))
    {
        _S319 = (param_0.customMap_0) == u32(0);
    }
    else
    {
        _S319 = false;
    }
    if(_S319)
    {
        var _S320 : f32 = frozenShadow53_1(_S315, _S317);
        return _S320;
    }
    var _S321 : f32 = max(2.0f, param_0.slices_0);
    var _S322 : u32 = param_0.shape_0;
    var _S323 : bool = (param_0.shape_0) == u32(8);
    if(_S323)
    {
        _S319 = true;
    }
    else
    {
        _S319 = _S322 == u32(10);
    }
    if(_S319)
    {
        _S319 = (param_0.customMap_0) == u32(0);
    }
    else
    {
        _S319 = false;
    }
    if(_S319)
    {
        _S319 = ((param_0.direction_0) < u32(2));
    }
    else
    {
        _S319 = false;
    }
    var cells_3 : f32;
    var x_7 : f32;
    if(_S319)
    {
        var _S324 : bool = _S322 == u32(10);
        if(_S324)
        {
            cells_3 = ceil(_S321 / 2.0f);
        }
        else
        {
            cells_3 = _S321;
        }
        var grid_5 : vec2<f32> = gridSize3_0(cells_3, vec2<f32>(param_0.outputW_0, param_0.outputH_0));
        var _S325 : f32 = grid_5.x;
        var _S326 : i32;
        if(((_S316.cell_3.y) < (cells_3 - _S325 * grid_5.y)))
        {
            _S326 = i32(1);
        }
        else
        {
            _S326 = i32(0);
        }
        var x_8 : f32 = _S316.frac_0.x;
        var span_18 : f32 = param_0.sampleW_0 / (_S325 + f32(_S326));
        var span_19 : f32;
        if(_S324)
        {
            var cut_4 : f32 = 1.0f - _S316.frac_0.y;
            var first_5 : bool = (x_8 < cut_4);
            if(first_5)
            {
                cells_3 = cut_4;
            }
            else
            {
                cells_3 = 1.0f - cut_4;
            }
            var span_20 : f32 = span_18 * cells_3;
            if(first_5)
            {
                cells_3 = x_8 / max(cut_4, 9.99999997475242708e-07f);
            }
            else
            {
                cells_3 = (x_8 - cut_4) / max(1.0f - cut_4, 9.99999997475242708e-07f);
            }
            x_7 = cells_3;
            span_19 = span_20;
        }
        else
        {
            x_7 = x_8;
            span_19 = span_18;
        }
        var phase_19 : f32;
        if((param_0.direction_0) == u32(1))
        {
            phase_19 = 1.0f - x_7;
        }
        else
        {
            phase_19 = x_7;
        }
        if(_S323)
        {
            cells_3 = tiledLight42_1(phase_19, span_19, _S317);
        }
        else
        {
            cells_3 = edgeLight42_1(phase_19, span_19, _S317);
        }
        return cells_3;
    }
    var _S327 : f32 = coordSpan42_1(_S315);
    var _S328 : u32 = param_0.direction_0;
    if(((param_0.direction_0) >= u32(2)))
    {
        cells_3 = _S327 * 0.5f;
    }
    else
    {
        cells_3 = _S327;
    }
    if(((param_0.pixel_0) > 0.0f))
    {
        _S319 = _S318 == u32(2);
    }
    else
    {
        _S319 = false;
    }
    if(_S319)
    {
        if((param_0.customMap_0) != u32(0))
        {
            _S319 = (((param_0.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S319 = false;
        }
        if(_S319)
        {
            x_7 = 2.0f * param_0.span_0;
        }
        else
        {
            x_7 = 2.0f * param_0.density_0;
        }
        var _S329 : f32 = max(0.0099999997764825821f, x_7);
        return tiledLight42_1(fract(_S329 * _S316.raw_0 - 2.0f * param_0.cycles_0 * param_0.u_0), cells_3 / _S329, _S317);
    }
    if(isStripe42_1())
    {
        if(_S322 == u32(1))
        {
            x_7 = _S315.y;
        }
        else
        {
            x_7 = _S315.x;
        }
        var _S330 : f32 = stripeLight42_1(x_7, _S316.index_1, cells_3, _S321, _S328 == u32(1), _S317);
        return _S330;
    }
    return tiledLight42_1(clamp(_S316.raw_0 * _S321 - _S316.index_1, 0.0f, 1.0f), cells_3 / _S321, _S317);
}

fn evaluate3_1( _S331 : vec2<f32>,  _S332 : f32) -> Field_0
{
    if(((param_0.design_0) >= u32(407)))
    {
        return creative42_1(_S331);
    }
    var _S333 : Coord_0 = coordinate3_1(_S331, _S332);
    var base_3 : f32;
    if((_S333.coverage_3) == 0.0f)
    {
        var _S334 : u32 = param_0.family_0;
        if((param_0.family_0) == u32(0))
        {
            base_3 = play3_0(param_0.u_0 / max(0.10000000149011612f, param_0.build_0), param_0.playback_0);
        }
        else
        {
            if(_S334 == u32(1))
            {
                base_3 = 1.0f;
            }
            else
            {
                base_3 = 0.0f;
            }
            base_3 = play3_0(base_3 + 2.0f * param_0.cycles_0 * param_0.u_0, param_0.playback_0);
        }
        return single3_0(_S331, base_3);
    }
    var _S335 : u32 = param_0.family_0;
    if((param_0.family_0) == u32(3))
    {
        return creative3_1(_S331, _S333);
    }
    var f_8 : Field_0;
    var _S336 : bool = _S335 == u32(0);
    var _S337 : Field_0;
    if(_S336)
    {
        _S337 = frozen3_1(_S331, _S333);
    }
    else
    {
        if(_S335 == u32(1))
        {
            _S337 = basic3_1(_S331, _S333);
        }
        else
        {
            _S337 = wave3_1(_S331, _S333);
        }
    }
    f_8 = _S337;
    if(((param_0.shadowStrength_0) > 0.0f))
    {
        var _S338 : bool;
        if(_S336)
        {
            _S338 = ((param_0.u_0) < (clamp(param_0.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S338 = false;
        }
        if(_S338)
        {
            base_3 = f_8.weight_0;
        }
        else
        {
            base_3 = 1.0f;
        }
        if((base_3 > 0.0f))
        {
            var _S339 : f32 = sliceLight42_1(_S331, _S333, base_3);
            f_8.light_0 = _S339;
        }
    }
    return f_8;
}

fn needsAA53_0( _S340 : vec2<f32>,  _S341 : f32) -> bool
{
    var _S342 : TFParams_std140_0 = param_0;
    if((param_0.customMap_0) != u32(0))
    {
        return false;
    }
    var _S343 : bool;
    if(((_S342.pixel_0) > 0.0f))
    {
        _S343 = (_S342.family_0) != u32(3);
    }
    else
    {
        _S343 = false;
    }
    if(_S343)
    {
        _S343 = ((_S342.shadowStrength_0) <= 0.0f);
    }
    else
    {
        _S343 = false;
    }
    if(_S343)
    {
        return false;
    }
    if((_S342.shape_0) == u32(0))
    {
        _S343 = true;
    }
    else
    {
        _S343 = (_S342.shape_0) == u32(1);
    }
    if(_S343)
    {
        _S343 = true;
    }
    else
    {
        _S343 = (_S342.shape_0) == u32(11);
    }
    if(_S343)
    {
        _S343 = ((_S342.direction_0) < u32(2));
    }
    else
    {
        _S343 = false;
    }
    var _S344 : f32;
    if(_S343)
    {
        if((_S342.shape_0) == u32(1))
        {
            _S344 = _S342.sampleH_0;
        }
        else
        {
            _S344 = _S342.sampleW_0;
        }
        var pitch_2 : f32 = _S344 / max(2.0f, _S342.slices_0);
        if(((abs(pitch_2 - round(pitch_2))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    var q_14 : TFParams_0;
    q_14.outTime_0 = _S342.outTime_0;
    q_14.u_0 = _S342.u_0;
    q_14.sourceDuration_0 = _S342.sourceDuration_0;
    q_14.aspect_0 = _S342.aspect_0;
    q_14.slices_0 = _S342.slices_0;
    q_14.pixel_0 = _S342.pixel_0;
    q_14.span_0 = _S342.span_0;
    q_14.cycles_0 = _S342.cycles_0;
    q_14.cx_0 = _S342.cx_0;
    q_14.cy_0 = _S342.cy_0;
    q_14.angle_0 = _S342.angle_0;
    q_14.turns_0 = _S342.turns_0;
    q_14.build_0 = _S342.build_0;
    q_14.softness_0 = _S342.softness_0;
    q_14.density_0 = _S342.density_0;
    q_14.sourceReverse_0 = _S342.sourceReverse_0;
    q_14.sourceStart_0 = _S342.sourceStart_0;
    q_14.sourceEnd_0 = _S342.sourceEnd_0;
    q_14.outputW_0 = _S342.outputW_0;
    q_14.outputH_0 = _S342.outputH_0;
    q_14.family_0 = _S342.family_0;
    q_14.shape_0 = _S342.shape_0;
    q_14.design_0 = _S342.design_0;
    q_14.ending_0 = _S342.ending_0;
    q_14.direction_0 = _S342.direction_0;
    q_14.playback_0 = _S342.playback_0;
    q_14.origin_0 = _S342.origin_0;
    q_14.viewMode_0 = _S342.viewMode_0;
    q_14.frames_0 = _S342.frames_0;
    q_14.customMap_0 = _S342.customMap_0;
    q_14.waveSources_0 = _S342.waveSources_0;
    q_14.flags_0 = _S342.flags_0;
    q_14.shadowStrength_0 = _S342.shadowStrength_0;
    q_14.shadowWidth_0 = _S342.shadowWidth_0;
    q_14.shadowSoftness_0 = _S342.shadowSoftness_0;
    q_14.shadowSide_0 = _S342.shadowSide_0;
    q_14.sampleW_0 = _S342.sampleW_0;
    q_14.sampleH_0 = _S342.sampleH_0;
    q_14.reserved0_0 = _S342.reserved0_0;
    q_14.reserved1_0 = _S342.reserved1_0;
    q_14.sourcePeak_0 = _S342.sourcePeak_0;
    q_14.paperWhite_0 = _S342.paperWhite_0;
    q_14.displayPeak_0 = _S342.displayPeak_0;
    q_14.colorReserved_0 = _S342.colorReserved_0;
    q_14.reserved0_0 = 0.25f;
    var delta_2 : vec2<f32> = vec2<f32>(0.49000000953674316f) / vec2<f32>(_S342.sampleW_0, _S342.sampleH_0);
    var _S345 : vec2<f32> = _S340 - delta_2;
    var _S346 : Coord_0 = coordinate3_0(_S345, q_14, _S341);
    var _S347 : Field_0 = evaluate3_0(_S345, q_14, _S341);
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
            _S344 = delta_2.x;
        }
        else
        {
            _S344 = - delta_2.x;
        }
        var _S348 : f32;
        if(((i_4 & (i32(2)))) != i32(0))
        {
            _S348 = delta_2.y;
        }
        else
        {
            _S348 = - delta_2.y;
        }
        var v_9 : vec2<f32> = _S340 + vec2<f32>(_S344, _S348);
        var other_0 : Coord_0 = coordinate3_0(v_9, q_14, _S341);
        var f_9 : Field_0 = evaluate3_0(v_9, q_14, _S341);
        if((other_0.index_1) != (_S346.index_1))
        {
            _S343 = true;
        }
        else
        {
            _S343 = ((abs(other_0.coverage_3 - _S346.coverage_3)) > 0.0010000000474974513f);
        }
        var _S349 : bool;
        if(_S343)
        {
            _S349 = true;
        }
        else
        {
            _S349 = ((abs(_S347.weight_0 - f_9.weight_0)) > 0.0099999997764825821f);
        }
        if(_S349)
        {
            return true;
        }
        var _S350 : bool;
        if((_S342.family_0) == u32(3))
        {
            if(((abs(_S347.a_0 - f_9.a_0)) > 0.019999999552965164f))
            {
                _S350 = true;
            }
            else
            {
                _S350 = ((abs(_S347.b_0 - f_9.b_0)) > 0.019999999552965164f);
            }
        }
        else
        {
            _S350 = false;
        }
        if(_S350)
        {
            return true;
        }
        i_4 = i_4 + i32(1);
    }
    return false;
}

fn adjusted3_0( _S351 : f32) -> f32
{
    var _S352 : f32 = clamp(_S351, 0.0f, 1.0f);
    var _S353 : f32;
    if(((param_0.sourceReverse_0) > 0.0f))
    {
        _S353 = 1.0f - _S352;
    }
    else
    {
        _S353 = _S352;
    }
    return mix(param_0.sourceStart_0, param_0.sourceEnd_0, _S353);
}

@compute
@workgroup_size(8, 8, 1)
fn fields(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S354 : u32 = id_0.x;
    var _S355 : bool;
    if((_S354 >= cfg_0[i32(2)]))
    {
        _S355 = true;
    }
    else
    {
        _S355 = ((id_0.y) >= cfg_0[i32(3)]);
    }
    if(_S355)
    {
        return;
    }
    var local_6 : u32 = id_0.y * cfg_0[i32(2)] + _S354;
    var uv_11 : vec2<f32> = (vec2<f32>(id_0.xy + vec2<u32>(cfg_0[i32(0)], cfg_0[i32(1)])) + vec2<f32>(0.5f)) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)]));
    var _S356 : Field_0 = evaluate3_1(uv_11, timeMap_0[local_6]);
    var shade_1 : f32;
    if((((param_0.flags_0) & (u32(256)))) != u32(0))
    {
        shade_1 = _S356.light_0;
    }
    else
    {
        shade_1 = _S356.shade_0;
    }
    if((((param_0.flags_0) & (u32(512)))) != u32(0))
    {
        var _S357 : bool = needsAA53_0(uv_11, timeMap_0[local_6]);
        var _S358 : i32;
        if(_S357)
        {
            _S358 = i32(1);
        }
        else
        {
            _S358 = i32(0);
        }
        shade_1 = f32(_S358);
    }
    var _S359 : u32 = local_6 * u32(2);
    diagnostics_0[_S359] = vec4<f32>(adjusted3_0(_S356.a_0), adjusted3_0(_S356.b_0), clamp(_S356.weight_0, 0.0f, 1.0f), shade_1);
    diagnostics_0[_S359 + u32(1)] = vec4<f32>(_S356.uvA_0, _S356.uvB_0);
    return;
}

