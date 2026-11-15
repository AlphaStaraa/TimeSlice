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

fn rot3_0( v_0 : vec2<f32>,  a_1 : f32) -> vec2<f32>
{
    var _S4 : f32 = cos(a_1);
    var _S5 : f32 = v_0.x;
    var _S6 : f32 = sin(a_1);
    var _S7 : f32 = v_0.y;
    return vec2<f32>(_S4 * _S5 + _S6 * _S7, - _S6 * _S5 + _S4 * _S7);
}

fn gridSize3_0( n_0 : f32,  size_0 : vec2<f32>) -> vec2<f32>
{
    var _S8 : f32 = size_0.y;
    var rows_0 : f32 = clamp(round(sqrt(n_0 * _S8 / size_0.x)), 1.0f, min(_S8, n_0));
    return vec2<f32>(floor(n_0 / rows_0), rows_0);
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

fn play3_0( x_1 : f32,  mode_0 : u32) -> f32
{
    var _S9 : f32;
    if(mode_0 == u32(0))
    {
        _S9 = clamp(x_1, 0.0f, 1.0f);
    }
    else
    {
        if(mode_0 == u32(2))
        {
            _S9 = fract(x_1);
        }
        else
        {
            _S9 = bounce3_0(x_1);
        }
    }
    return _S9;
}

fn stripeBorder42_0( cut_0 : f32,  lengthPx_1 : f32,  count_1 : f32) -> f32
{
    if(((max(lengthPx_1, count_1)) <= 32768.0f))
    {
        var n_1 : u32 = u32(count_1);
        var numerator_0 : u32 = u32(2) * u32(cut_0) * u32(lengthPx_1);
        var _S10 : f32;
        if((numerator_0 <= n_1))
        {
            _S10 = 0.0f;
        }
        else
        {
            var _S11 : u32 = (numerator_0 + n_1 - u32(1)) / (u32(2) * n_1);
            _S10 = f32(_S11);
        }
        return _S10;
    }
    return clamp(ceil(cut_0 * lengthPx_1 / count_1 - 0.5f), 0.0f, lengthPx_1);
}

fn filteredLight42_0( _S12 : f32,  _S13 : f32,  _S14 : f32,  _S15 : f32,  _S16 : bool) -> f32
{
    var _S17 : bool;
    if((_S13 <= 1.0f))
    {
        _S17 = true;
    }
    else
    {
        _S17 = (_S14 <= 0.0f);
    }
    if(_S17)
    {
        return 1.0f;
    }
    var _S18 : f32 = min(0.77999997138977051f, max(param_0.shadowWidth_0, 1.5f / _S13));
    var halfPixel_0 : f32 = 0.5f * _S15 / _S13;
    if((_S12 > (_S18 + halfPixel_0)))
    {
        if(!_S16)
        {
            _S17 = true;
        }
        else
        {
            _S17 = (_S12 < (1.0f - halfPixel_0));
        }
    }
    else
    {
        _S17 = false;
    }
    if(_S17)
    {
        return 1.0f;
    }
    var feather_2 : f32 = _S18 * max(0.02500000037252903f, param_0.shadowSoftness_0);
    var solid_2 : f32 = _S18 - feather_2;
    var lo_0 : f32 = _S12 - halfPixel_0;
    var hi_0 : f32 = _S12 + halfPixel_0;
    var area_0 : f32;
    if(_S16)
    {
        area_0 = repeatedShadowArea42_0(hi_0, solid_2, feather_2) - repeatedShadowArea42_0(lo_0, solid_2, feather_2);
    }
    else
    {
        area_0 = shadowArea42_0(hi_0, solid_2, feather_2) - shadowArea42_0(lo_0, solid_2, feather_2);
    }
    return 1.0f - param_0.shadowStrength_0 * _S14 * (clamp(area_0 / (2.0f * halfPixel_0), 0.0f, 1.0f) * smoothstep(1.0f, 2.5f, _S13));
}

fn tiledLight42_0( _S19 : f32,  _S20 : f32,  _S21 : f32) -> f32
{
    var _S22 : f32;
    if(((param_0.shadowSide_0) > 0.0f))
    {
        _S22 = _S19;
    }
    else
    {
        _S22 = 1.0f - _S19;
    }
    return filteredLight42_0(_S22, _S20, _S21, 1.2999999523162842f, true);
}

fn edgeLight42_0( _S23 : f32,  _S24 : f32,  _S25 : f32) -> f32
{
    var _S26 : f32;
    if(((param_0.shadowSide_0) > 0.0f))
    {
        _S26 = _S23;
    }
    else
    {
        _S26 = 1.0f - _S23;
    }
    return filteredLight42_0(_S26, _S24, _S25, 1.0f, false);
}

fn creative42_0( _S27 : vec2<f32>) -> Field_0
{
    var _S28 : f32 = param_0.cy_0;
    var center_0 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var _S29 : f32 = param_0.sampleW_0;
    var _S30 : f32 = param_0.sampleH_0;
    var _S31 : f32 = param_0.aspect_0;
    var metric_0 : vec2<f32> = vec2<f32>(param_0.aspect_0, 1.0f);
    var _S32 : vec2<f32> = _S27 - center_0;
    var v_1 : vec2<f32> = _S32 * metric_0;
    var u_1 : f32 = param_0.u_0;
    var _S33 : f32 = param_0.cycles_0;
    var clock_0 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var _S34 : f32 = max(2.0f, param_0.slices_0);
    var f_1 : Field_0 = single3_0(_S27, bounce3_0(clock_0 + 1.0f));
    switch(param_0.design_0)
    {
    case u32(407):
        {
            var y_0 : f32 = _S27.y - _S28;
            var band_0 : f32 = (creativeAxis42_0(_S27.x + (0.10499999672174454f * sin(6.2831854820251465f * (y_0 + 0.34999999403953552f * u_1)) + 0.026000000536441803f * sin(6.2831854820251465f * (2.0f * y_0 - 0.69999998807907104f * u_1))), param_0.direction_0) - 0.51999998092651367f * _S33 * u_1) * _S34;
            var cell_0 : f32 = floor(band_0);
            var t_2 : f32 = bounce3_0(clock_0 - 0.75f * cell_0 / _S34);
            var _S35 : f32 = mix(t_2, 1.0f - t_2, fract(cell_0 * 0.5f) * 2.0f * param_0.span_0);
            f_1.b_0 = _S35;
            f_1.a_0 = _S35;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = tiledLight42_0(fract(band_0), _S29 / _S34, 1.0f);
            }
        }
    case u32(408):
        {
            var pitch_0 : f32 = sqrt(2.0f * _S31 / (1.7320507764816284f * _S34));
            const basis_0 : vec2<f32> = vec2<f32>(1.0f, 1.7320507764816284f);
            var pos_0 : vec2<f32> = rot3_0(v_1, 0.15999999642372131f * sin(6.2831854820251465f * u_1)) / vec2<f32>(pitch_0);
            var _S36 : vec2<f32> = vec2<f32>(0.5f);
            var a_2 : vec2<f32> = floor(pos_0 / basis_0 + _S36) * basis_0;
            var b_1 : vec2<f32> = floor(pos_0 / basis_0) * basis_0 + basis_0 * _S36;
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
            var _S37 : f32 = cell_1.x;
            var _S38 : f32 = cell_1.y;
            var row_0 : f32 = round(2.0f * _S38 / 1.7320507764816284f);
            var _S39 : f32 = 0.039999999105930328f + 0.93000000715255737f * smoothstep(0.15999999642372131f, 0.8399999737739563f, bounce3_0(clock_0 - (1.3999999761581421f * creativeAxis42_0(0.5f + _S37 * pitch_0 / _S31, param_0.direction_0) + 0.34000000357627869f * _S38 * pitch_0 + 1.1000000238418579f * fract((round(_S37 - 0.5f * row_0) - row_0) / 3.0f)) * param_0.span_0));
            f_1.b_0 = _S39;
            f_1.a_0 = _S39;
            var _S40 : f32 = min(0.5f, max(0.0010000000474974513f, 1.0f - 1.7320507764816284f * abs(local_0.y)));
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = edgeLight42_0(0.5f + 0.5f * local_0.x / _S40, 2.0f * _S40 * pitch_0 * _S30, 1.0f);
            }
        }
    case u32(409):
        {
            var swing_0 : f32 = 0.52999997138977051f * sin(6.2831854820251465f * u_1);
            var focal_0 : f32 = 0.2199999988079071f * min(_S31, 1.0f);
            var focus_0 : vec2<f32> = vec2<f32>(cos(swing_0), sin(swing_0)) * vec2<f32>(focal_0);
            var range_0 : f32 = 2.0f * (max(length(max(center_0, vec2<f32>(1.0f) - center_0) * metric_0), 0.0010000000474974513f) - focal_0) + 0.039999999105930328f;
            var band_1 : f32 = creativeAxis42_0(clamp((length(v_1 - focus_0) + length(v_1 + focus_0) - 2.0f * focal_0) / max(0.019999999552965164f, range_0), 0.0f, 1.0f), param_0.direction_0) * _S34 - 0.77999997138977051f * _S33 * u_1;
            var cell_2 : f32 = floor(band_1);
            var t_3 : f32 = bounce3_0(clock_0 - param_0.span_0 * cell_2 / _S34);
            var _S41 : f32 = mix(t_3, 1.0f - t_3, 0.80000001192092896f * fract(cell_2 * 0.5f) * 2.0f);
            f_1.b_0 = _S41;
            f_1.a_0 = _S41;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = tiledLight42_0(fract(band_1), range_0 * 0.5f * _S30 / _S34, 1.0f);
            }
        }
    case u32(410):
        {
            var _S42 : f32 = min(3.0f, _S34);
            var shift_0 : vec2<f32> = _S32 + vec2<f32>(0.5f);
            var _S43 : f32 = shift_0.y * _S42;
            var row_1 : f32 = floor(_S43);
            var base_0 : f32 = floor(_S34 / _S42);
            var _S44 : i32;
            if(((clamp(row_1, 0.0f, _S42 - 1.0f)) < (_S34 - base_0 * _S42)))
            {
                _S44 = i32(1);
            }
            else
            {
                _S44 = i32(0);
            }
            var cols_0 : f32 = base_0 + f32(_S44);
            var x_2 : f32 = shift_0.x * cols_0 - (0.62999999523162842f + 0.12999999523162842f * row_1) * _S33 * creativeAxis42_0(u_1, param_0.direction_0) + 0.36000001430511475f * row_1;
            var col_0 : f32 = floor(x_2);
            var _S45 : f32 = fract(x_2) - 0.5f;
            var _S46 : f32 = fract(_S43) - 0.5f;
            var roundBox_0 : vec2<f32> = abs(vec2<f32>(_S45, _S46)) - vec2<f32>(0.37000000476837158f, 0.33000001311302185f);
            var edge_0 : f32 = length(max(roundBox_0, vec2<f32>(0.0f))) + min(max(roundBox_0.x, roundBox_0.y), 0.0f) - 0.075000002980232239f;
            var aa_0 : f32 = max(cols_0 / _S29, _S42 / _S30) * 1.1000000238418579f;
            f_1.a_0 = 0.20000000298023224f + 0.63999998569488525f * bounce3_0(clock_0 + 0.69999998807907104f);
            f_1.b_0 = bounce3_0(clock_0 - 0.40999999642372131f * col_0 - 0.28999999165534973f * row_1) * param_0.span_0 + 0.039999999105930328f;
            f_1.weight_0 = 1.0f - smoothstep(- aa_0, aa_0, edge_0);
            var _S47 : f32 = max(0.0f, abs(_S46) - 0.33000001311302185f);
            var bound_0 : f32 = 0.37000000476837158f + sqrt(max(0.0f, 0.0056250002235174179f - _S47 * _S47));
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_1.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * _S45 / bound_0, 0.0f, 1.0f), 2.0f * bound_0 * _S29 / cols_0, f_1.weight_0);
            }
        }
    default :
        {
        }
    }
    return f_1;
}

struct Coord_0
{
     raw_0 : f32,
     q_1 : f32,
     index_1 : f32,
     coverage_0 : f32,
     cell_3 : vec2<f32>,
     frac_0 : vec2<f32>,
};

fn isStripe42_0() -> bool
{
    var _S48 : bool;
    if((param_0.customMap_0) == u32(0))
    {
        _S48 = ((param_0.direction_0) < u32(2));
    }
    else
    {
        _S48 = false;
    }
    if(_S48)
    {
        var _S49 : u32 = param_0.shape_0;
        if((param_0.shape_0) == u32(0))
        {
            _S48 = true;
        }
        else
        {
            _S48 = _S49 == u32(1);
        }
        if(_S48)
        {
            _S48 = true;
        }
        else
        {
            _S48 = _S49 == u32(11);
        }
    }
    else
    {
        _S48 = false;
    }
    return _S48;
}

fn filteredFreeze52_0() -> bool
{
    var _S50 : bool;
    if((param_0.family_0) != u32(0))
    {
        _S50 = true;
    }
    else
    {
        _S50 = (param_0.customMap_0) != u32(0);
    }
    if(_S50)
    {
        _S50 = true;
    }
    else
    {
        _S50 = ((param_0.pixel_0) > 0.0f);
    }
    if(_S50)
    {
        _S50 = true;
    }
    else
    {
        var _S51 : u32 = param_0.shape_0;
        if((param_0.shape_0) != u32(0))
        {
            _S50 = _S51 != u32(1);
        }
        else
        {
            _S50 = false;
        }
        if(_S50)
        {
            _S50 = _S51 != u32(2);
        }
        else
        {
            _S50 = false;
        }
    }
    if(_S50)
    {
        return false;
    }
    var _S52 : u32 = param_0.shape_0;
    if((param_0.shape_0) != u32(2))
    {
        _S50 = ((param_0.direction_0) < u32(2));
    }
    else
    {
        _S50 = false;
    }
    if(_S50)
    {
        _S50 = (param_0.outputW_0) == (param_0.sampleW_0);
    }
    else
    {
        _S50 = false;
    }
    if(_S50)
    {
        _S50 = (param_0.outputH_0) == (param_0.sampleH_0);
    }
    else
    {
        _S50 = false;
    }
    if(_S50)
    {
        var _S53 : f32;
        if(_S52 == u32(1))
        {
            _S53 = param_0.sampleH_0;
        }
        else
        {
            _S53 = param_0.sampleW_0;
        }
        var pitch_1 : f32 = _S53 / max(2.0f, param_0.slices_0);
        if(((abs(pitch_1 - round(pitch_1))) < 9.99999997475242708e-07f))
        {
            return false;
        }
    }
    return true;
}

fn coordinate3_0( _S54 : vec2<f32>,  _S55 : f32) -> Coord_0
{
    var c_0 : Coord_0;
    var _S56 : vec2<f32> = vec2<f32>(vec2<i32>(i32(0)));
    c_0.cell_3 = _S56;
    c_0.frac_0 = _S56;
    c_0.index_1 = 0.0f;
    c_0.coverage_0 = 1.0f;
    var _S57 : f32 = _S54.x;
    var _S58 : f32 = max(2.0f, param_0.slices_0);
    var _S59 : f32 = param_0.outputW_0;
    var _S60 : f32 = param_0.outputH_0;
    var dim_0 : vec2<f32> = vec2<f32>(param_0.outputW_0, param_0.outputH_0);
    var _S61 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var v_2 : vec2<f32> = (_S54 - _S61) * dim_0;
    var _S62 : vec2<f32> = vec2<f32>(1.0f);
    var radii_0 : vec2<f32> = max(_S61, _S62 - _S61) * dim_0;
    var _S63 : f32 = max(length(radii_0), 1.0f);
    var rmin_0 : f32 = length(max(_S56, max((vec2<f32>(0) - _S61), _S61 - _S62)) * dim_0);
    var _S64 : u32 = param_0.shape_0;
    var q_2 : f32;
    var lengthPx_2 : f32;
    var _S65 : i32;
    var _S66 : bool;
    switch(param_0.shape_0)
    {
    case u32(0):
        {
            q_2 = _S57;
        }
    case u32(1):
        {
            q_2 = _S54.y;
        }
    case u32(2), u32(12):
        {
            var a_3 : f32 = param_0.angle_0 * 3.1415927410125732f / 180.0f;
            var _S67 : f32 = cos(a_3);
            var _S68 : f32 = sin(a_3);
            var _S69 : f32 = _S59 * _S67;
            var _S70 : f32 = _S60 * _S68;
            var q_3 : f32 = (dot(_S54 * dim_0, vec2<f32>(_S67, _S68)) - (min(0.0f, _S69) + min(0.0f, _S70))) / max(1.0f, abs(_S69) + abs(_S70));
            if(_S64 == u32(12))
            {
                q_2 = q_3 + 0.070000000298023224f * (2.0f * abs(2.0f * fract(_S54.y * 6.0f) - 1.0f) - 1.0f);
            }
            else
            {
                q_2 = q_3;
            }
        }
    case u32(3):
        {
            switch(param_0.origin_0)
            {
            case u32(1):
                {
                    q_2 = atan2(v_2.y, v_2.x);
                }
            case u32(2):
                {
                    q_2 = atan2(v_2.x, - v_2.y);
                }
            case u32(3):
                {
                    q_2 = atan2(- v_2.x, v_2.y);
                }
            default :
                {
                    q_2 = atan2(- v_2.y, - v_2.x);
                }
            }
            if((q_2 >= 0.0f))
            {
                _S66 = (q_2 <= 3.1415927410125732f);
            }
            else
            {
                _S66 = false;
            }
            if(_S66)
            {
                _S65 = i32(1);
            }
            else
            {
                _S65 = i32(0);
            }
            c_0.coverage_0 = f32(_S65);
            q_2 = clamp(q_2 / 3.1415927410125732f, 0.0f, 1.0f);
        }
    case u32(4):
        {
            q_2 = fract(atan2(v_2.x, - v_2.y) / 6.2831854820251465f + 1.0f - param_0.turns_0 * param_0.u_0);
        }
    case u32(5), u32(14):
        {
            q_2 = (length(v_2) - rmin_0) / max(1.0f, _S63 - rmin_0);
        }
    case u32(6), u32(7):
        {
            var vr_0 : vec2<f32> = rot3_0(v_2, param_0.angle_0 * 3.1415927410125732f / 180.0f + param_0.turns_0 * 2.0f * 3.1415927410125732f * param_0.u_0);
            if(_S64 == u32(6))
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
            var _S71 : bool = _S64 == u32(10);
            if(_S71)
            {
                q_2 = max(1.0f, ceil(_S58 / 2.0f));
            }
            else
            {
                q_2 = _S58;
            }
            var gs_0 : vec2<f32> = gridSize3_0(q_2, dim_0);
            var _S72 : f32 = gs_0.y;
            var _S73 : f32 = _S54.y * _S72;
            var _S74 : f32 = min(floor(_S73), _S72 - 1.0f);
            var _S75 : f32 = gs_0.x;
            var extra_0 : f32 = q_2 - _S75 * _S72;
            if((_S74 < extra_0))
            {
                _S65 = i32(1);
            }
            else
            {
                _S65 = i32(0);
            }
            var cols_1 : f32 = _S75 + f32(_S65);
            var _S76 : f32 = _S57 * cols_1;
            var _S77 : f32 = min(floor(_S76), cols_1 - 1.0f);
            var index_2 : f32 = _S74 * _S75 + min(_S74, extra_0) + _S77;
            c_0.cell_3 = vec2<f32>(_S77, _S74);
            c_0.frac_0 = fract(vec2<f32>(_S76, _S73));
            if(_S71)
            {
                var _S78 : f32 = _S58 - 1.0f;
                var _S79 : f32 = index_2 * 2.0f;
                if(((c_0.frac_0.x + c_0.frac_0.y) >= 1.0f))
                {
                    _S65 = i32(1);
                }
                else
                {
                    _S65 = i32(0);
                }
                lengthPx_2 = min(_S78, _S79 + f32(_S65));
            }
            else
            {
                lengthPx_2 = index_2;
            }
            q_2 = lengthPx_2 / max(1.0f, _S58 - 1.0f);
        }
    case u32(9):
        {
            q_2 = fract(atan2(v_2.y, v_2.x) / 6.2831854820251465f + 0.5f + 1.5f * (length(v_2) / _S63));
        }
    case u32(11):
        {
            q_2 = _S57;
        }
    case u32(13):
        {
            q_2 = length(v_2) / max(1.0f, _S63 * (0.77999997138977051f + 0.2199999988079071f * cos(5.0f * atan2(v_2.y, v_2.x))));
        }
    default :
        {
            q_2 = _S57;
        }
    }
    if((param_0.customMap_0) != u32(0))
    {
        c_0.coverage_0 = 1.0f;
        q_2 = _S55;
    }
    var q_4 : f32 = clamp(q_2, 0.0f, 1.0f);
    var _S80 : u32 = param_0.direction_0;
    var _S81 : bool = (param_0.direction_0) == u32(1);
    if(_S81)
    {
        q_2 = 1.0f - q_4;
    }
    else
    {
        q_2 = q_4;
    }
    if((_S80 >= u32(2)))
    {
        if(_S64 == u32(8))
        {
            _S66 = true;
        }
        else
        {
            _S66 = _S64 == u32(10);
        }
        if(_S66)
        {
            q_2 = max(abs(_S57 - 0.5f), abs(_S54.y - 0.5f)) * 2.0f;
        }
        else
        {
            q_2 = abs(q_2 - 0.5f) * 2.0f;
        }
        if(_S80 == u32(3))
        {
            q_2 = 1.0f - q_2;
        }
    }
    c_0.raw_0 = q_2;
    var _S82 : f32 = _S58 - 1.0f;
    c_0.index_1 = min(floor(q_2 * _S58), _S82);
    if(isStripe42_0())
    {
        if(filteredFreeze52_0())
        {
            _S66 = ((param_0.reserved0_0) > 0.0f);
        }
        else
        {
            _S66 = false;
        }
        _S66 = !_S66;
    }
    else
    {
        _S66 = false;
    }
    if(_S66)
    {
        var _S83 : bool = _S64 == u32(1);
        if(_S83)
        {
            lengthPx_2 = param_0.sampleH_0;
        }
        else
        {
            lengthPx_2 = param_0.sampleW_0;
        }
        var _S84 : f32;
        if(_S83)
        {
            _S84 = _S54.y;
        }
        else
        {
            _S84 = _S57;
        }
        var pixel_2 : f32 = floor(_S84 * lengthPx_2);
        if(_S81)
        {
            _S84 = lengthPx_2 - 1.0f - pixel_2;
        }
        else
        {
            _S84 = pixel_2;
        }
        var _S85 : f32 = rasterStripeIndex42_0(_S84, lengthPx_2, _S58);
        c_0.index_1 = _S85;
    }
    if(((param_0.pixel_0) > 0.0f))
    {
    }
    else
    {
        q_2 = c_0.index_1 / _S82;
    }
    c_0.q_1 = q_2;
    return c_0;
}

fn creative3_0( _S86 : vec2<f32>,  _S87 : Coord_0) -> Field_0
{
    var u_2 : f32 = param_0.u_0;
    var _S88 : f32 = param_0.cycles_0;
    var clock_1 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var _S89 : f32 = max(2.0f, param_0.slices_0);
    var depth_0 : f32 = param_0.span_0;
    var _S90 : f32 = param_0.cx_0;
    var center_1 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var _S91 : f32 = param_0.aspect_0;
    var metric_1 : vec2<f32> = vec2<f32>(param_0.aspect_0, 1.0f);
    var v_3 : vec2<f32> = (_S86 - center_1) * metric_1;
    var _S92 : f32 = bounce3_0(clock_1);
    var f_2 : Field_0 = single3_0(_S86, _S92);
    var band_2 : f32;
    var phase_0 : f32;
    var lateral_0 : f32;
    var q_5 : f32;
    var i_0 : i32;
    var horizontal_0 : bool;
    switch(param_0.design_0)
    {
    case u32(9):
        {
            var _S93 : f32 = length(v_3);
            var phase_1 : f32 = fract(2.0f * (atan2(v_3.x, - v_3.y) / 6.2831854820251465f) + _S93 / max(length(metric_1 * vec2<f32>(0.5f)), 0.0010000000474974513f) * 1.5f * depth_0);
            var _S94 : f32 = param_0.pixel_0;
            var _S95 : bool = ((param_0.pixel_0) > 0.0f);
            if(_S95)
            {
                band_2 = phase_1 - _S88 * u_2;
            }
            else
            {
                band_2 = phase_1 * _S89;
            }
            if(_S94 == 0.0f)
            {
                phase_0 = floor(band_2) / (_S89 - 1.0f);
            }
            else
            {
                phase_0 = phase_1;
            }
            var _S96 : f32 = 0.20000000298023224f + 0.80000001192092896f * fract(_S88 * u_2 - phase_0);
            f_2.b_0 = _S96;
            f_2.a_0 = _S96;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                var _S97 : f32 = fract(band_2);
                var _S98 : f32 = min(3.1415927410125732f * _S93 * param_0.sampleH_0, param_0.sampleH_0);
                if(_S95)
                {
                    band_2 = 1.0f;
                }
                else
                {
                    band_2 = _S89;
                }
                f_2.light_0 = tiledLight42_0(_S97, _S98 / band_2, 1.0f);
            }
        }
    case u32(10):
        {
            var q_6 : f32 = clamp(1.0f - abs(_S86.x - _S90) * 2.0f, 0.0f, 1.0f);
            var _S99 : f32 = _S89 - 1.0f;
            var band_3 : f32 = q_6 * _S99;
            var _S100 : f32 = param_0.pixel_0;
            if((param_0.pixel_0) == 0.0f)
            {
                q_5 = floor(band_3) / _S99;
            }
            else
            {
                q_5 = q_6;
            }
            var _S101 : f32 = 0.80000001192092896f * depth_0;
            var _S102 : f32 = _S101 * q_5;
            var _S103 : f32 = bounce3_0(clock_1 - _S102);
            f_2.b_0 = _S103;
            f_2.a_0 = _S103;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                var _S104 : bool = (_S100 > 0.0f);
                if(_S104)
                {
                    band_2 = _S102 - clock_1;
                }
                else
                {
                    band_2 = band_3;
                }
                var _S105 : f32 = fract(band_2);
                var _S106 : f32 = 0.5f * param_0.sampleW_0;
                if(_S104)
                {
                    band_2 = _S101;
                }
                else
                {
                    band_2 = _S99;
                }
                f_2.light_0 = tiledLight42_0(_S105, _S106 / band_2, 1.0f);
            }
        }
    case u32(11):
        {
            var _S107 : f32 = 0.23999999463558197f + max(0.0040000001899898052f, param_0.softness_0 * 0.15999999642372131f);
            var _S108 : f32 = _S87.frac_0.y;
            var ah_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S107, abs(_S108 - 0.5f));
            var _S109 : f32 = _S87.frac_0.x;
            var av_0 : f32 = 1.0f - smoothstep(0.23999999463558197f, _S107, abs(_S109 - 0.5f));
            var _S110 : f32 = _S87.cell_3.y;
            var over_0 : bool = (i32(floor(_S87.cell_3.x) + floor(_S110)) % i32(2)) == i32(0);
            var ht_0 : f32 = bounce3_0(clock_1 - _S86.x * depth_0);
            var vt_0 : f32 = bounce3_0(clock_1 + _S86.y * depth_0 + 1.0f);
            var _S111 : bool = (ah_0 > 0.0f);
            if(_S111)
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
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                if(_S111)
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
                    if(_S111)
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
                    phase_0 = _S108;
                }
                else
                {
                    phase_0 = _S109;
                }
                var phase_2 : f32 = clamp((phase_0 - 0.25999999046325684f) / 0.47999998927116394f, 0.0f, 1.0f);
                var grid_0 : vec2<f32> = gridSize3_0(_S89, vec2<f32>(param_0.outputW_0, param_0.outputH_0));
                var _S112 : f32 = grid_0.x;
                var _S113 : f32 = grid_0.y;
                if((_S110 < (_S89 - _S112 * _S113)))
                {
                    i_0 = i32(1);
                }
                else
                {
                    i_0 = i32(0);
                }
                var cols_2 : f32 = _S112 + f32(i_0);
                if(horizontal_0)
                {
                    phase_0 = param_0.sampleH_0 / _S113;
                }
                else
                {
                    phase_0 = param_0.sampleW_0 / cols_2;
                }
                f_2.light_0 = edgeLight42_0(phase_2, 0.47999998927116394f * phase_0, band_2);
            }
        }
    case u32(12):
        {
            var sources_0 : u32 = clamp(param_0.waveSources_0, u32(2), u32(4));
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
                var r_0 : f32 = length((_S86 - (center_1 + vec2<f32>(0.18000000715255737f * cos(a_4), 0.18000000715255737f * sin(a_4)))) * metric_1);
                var band_4 : f32 = r_0 * _S89;
                var _S114 : f32 = param_0.pixel_0;
                if((param_0.pixel_0) == 0.0f)
                {
                    phase_0 = floor(band_4) / _S89;
                }
                else
                {
                    phase_0 = r_0;
                }
                var _S115 : f32 = phase_0 * 1.2999999523162842f * depth_0;
                var sum_0 : f32 = band_2 + bounce3_0(clock_1 - _S115);
                if(((param_0.shadowStrength_0) > 0.0f))
                {
                    var _S116 : bool = (_S114 > 0.0f);
                    if(_S116)
                    {
                        lateral_0 = _S115 - clock_1;
                    }
                    else
                    {
                        lateral_0 = band_4;
                    }
                    var phase_3 : f32 = fract(lateral_0);
                    var _S117 : f32 = f_2.light_0;
                    var _S118 : f32 = param_0.sampleH_0;
                    if(_S116)
                    {
                        q_5 = 1.2999999523162842f * depth_0;
                    }
                    else
                    {
                        q_5 = _S89;
                    }
                    f_2.light_0 = min(_S117, tiledLight42_0(phase_3, _S118 / q_5, 1.0f));
                }
                i_1 = i_1 + u32(1);
                band_2 = sum_0;
            }
            var _S119 : f32 = band_2 / f32(sources_0);
            f_2.b_0 = _S119;
            f_2.a_0 = _S119;
        }
    case u32(13):
        {
            var _S120 : f32 = 6.2831854820251465f * u_2;
            var _S121 : f32 = sin(_S120);
            var local_1 : vec2<f32> = (_S86 - (center_1 + vec2<f32>(0.2199999988079071f * _S121, 0.12999999523162842f * cos(_S120)))) * metric_1;
            var r_1 : f32 = length(local_1);
            var radius_0 : f32 = 0.17000000178813934f + 0.039999999105930328f * _S121;
            var _S122 : f32 = max(0.0020000000949949026f, param_0.softness_0 * 0.15999999642372131f);
            f_2.b_0 = bounce3_0(clock_1 + 0.80000001192092896f * depth_0);
            f_2.weight_0 = 1.0f - smoothstep(radius_0 - _S122, radius_0 + _S122, r_1);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                horizontal_0 = ((f_2.weight_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S123 : f32 = local_1.y;
                var halfWidth_0 : f32 = sqrt(max(9.99999997475242708e-07f, radius_0 * radius_0 - _S123 * _S123));
                f_2.light_0 = edgeLight42_0(clamp(0.5f + 0.5f * local_1.x / halfWidth_0, 0.0f, 1.0f), 2.0f * halfWidth_0 * param_0.sampleH_0, f_2.weight_0);
            }
        }
    case u32(400):
        {
            var _S124 : f32 = max(_S89, 2.0f);
            var gap_0 : f32 = 0.64999997615814209f / _S124;
            var d_0 : f32 = fract(u_2 * _S88) * 1.6499999761581421f - _S86.x;
            var j_0 : f32 = floor(d_0 / gap_0);
            var local_2 : f32 = fract(d_0 / gap_0);
            if((j_0 >= 0.0f))
            {
                horizontal_0 = (j_0 < _S124);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S125 : f32 = max(0.014999999664723873f, param_0.softness_0 * 0.15000000596046448f);
                var a_5 : f32 = smoothstep(0.0f, _S125, local_2) * (1.0f - smoothstep(0.64999997615814209f, 0.64999997615814209f + _S125, local_2));
                f_2.b_0 = clamp(1.0f - j_0 / _S124, 0.0f, 1.0f);
                f_2.weight_0 = a_5 * (1.0f - 0.64999997615814209f * j_0 / _S124);
            }
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = edgeLight42_0(clamp(1.0f - local_2 / 0.64999997615814209f, 0.0f, 1.0f), gap_0 * 0.64999997615814209f * param_0.sampleW_0, f_2.weight_0);
            }
        }
    case u32(401):
        {
            var _S126 : f32 = _S86.y;
            if((i32(floor(_S126 * _S89)) % i32(2)) == i32(0))
            {
                band_2 = 1.0f;
            }
            else
            {
                band_2 = -1.0f;
            }
            var gap_1 : f32 = 0.34999999403953552f * smoothstep(_S92 - 0.059999998658895493f, _S92 + 0.059999998658895493f, _S126);
            var seam_0 : f32 = _S90 + band_2 * 0.02500000037252903f;
            var _S127 : f32 = _S86.x;
            var _S128 : f32 = _S127 - seam_0;
            var outside_0 : bool = ((abs(_S128)) > gap_1);
            if(outside_0)
            {
                if((_S127 < seam_0))
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
            var _S129 : bool = ((param_0.shadowStrength_0) > 0.0f);
            if(_S129)
            {
                var _S130 : f32 = clamp((_S128 + gap_1) / 0.2199999988079071f + 1.0f, 0.0f, 1.0f);
                var _S131 : f32 = 0.2199999988079071f * param_0.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S127 < seam_0);
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
                f_2.light_0 = edgeLight42_0(_S130, _S131, band_2);
            }
            if(_S129)
            {
                horizontal_0 = ((param_0.shadowSide_0) > 0.0f);
            }
            else
            {
                horizontal_0 = false;
            }
            if(horizontal_0)
            {
                var _S132 : f32 = clamp((_S128 - gap_1) / 0.2199999988079071f, 0.0f, 1.0f);
                var _S133 : f32 = 0.2199999988079071f * param_0.sampleW_0;
                if(outside_0)
                {
                    horizontal_0 = (_S127 > seam_0);
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
                f_2.light_0 = edgeLight42_0(_S132, _S133, band_2);
            }
        }
    case u32(402):
        {
            var a_6 : f32 = atan2(v_3.y, v_3.x);
            var r_2 : f32 = length(v_3);
            var radius_1 : f32 = 0.4699999988079071f * min(_S91, 1.0f) * (0.5f - 0.5f * cos(6.2831854820251465f * u_2 * _S88)) * (0.72000002861022949f + 0.2800000011920929f * cos(a_6 * _S89));
            var _S134 : f32 = max(0.0010000000474974513f, param_0.softness_0 * 0.019999999552965164f);
            var _S135 : f32 = fract((a_6 + 3.1415927410125732f) / 6.2831854820251465f) * _S89;
            f_2.b_0 = bounce3_0(clock_1 + floor(_S135) / _S89 * depth_0);
            f_2.weight_0 = 1.0f - smoothstep(radius_1 - _S134, radius_1 + _S134, r_2);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = tiledLight42_0(fract(_S135), 6.2831854820251465f * r_2 * param_0.sampleH_0 / _S89, f_2.weight_0);
            }
        }
    case u32(403):
        {
            var r_3 : f32 = length(v_3);
            var _S136 : f32 = max(3.0f, _S89);
            var sector_0 : f32 = 6.2831854820251465f / _S136;
            var _S137 : f32 = atan2(v_3.y, v_3.x) + u_2 * 3.1415927410125732f + 3.1415927410125732f;
            var aperture_0 : f32 = (0.02500000037252903f + 0.44999998807907104f * (0.5f - 0.5f * cos(6.2831854820251465f * u_2 * _S88))) * min(_S91, 1.0f) * cos(3.1415927410125732f / _S136) / max(0.0010000000474974513f, cos(fract(_S137 / sector_0) * sector_0 - sector_0 * 0.5f));
            f_2.a_0 = bounce3_0(clock_1 - depth_0 * floor(fract(_S137 / 6.2831854820251465f) * _S136) / _S136);
            f_2.b_0 = bounce3_0(clock_1 + 1.0f);
            f_2.weight_0 = 1.0f - smoothstep(aperture_0 - 0.0020000000949949026f, aperture_0 + 0.0020000000949949026f, r_3);
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = tiledLight42_0(fract(_S137 / sector_0), sector_0 * r_3 * param_0.sampleH_0, 1.0f - f_2.weight_0);
            }
        }
    case u32(404):
        {
            var _S138 : f32 = fract(u_2 * _S88);
            band_2 = 1.0e+09f;
            phase_0 = 0.0f;
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
                var _S139 : f32 = f32(i_0);
                var a0_0 : f32 = 6.2831854820251465f * _S139 / 32.0f;
                var _S140 : i32 = i_0 + i32(1);
                var a1_0 : f32 = 6.2831854820251465f * f32(_S140) / 32.0f;
                var a_7 : vec2<f32> = center_1 + vec2<f32>(0.34000000357627869f * sin(a0_0), 0.2199999988079071f * sin(2.0f * a0_0));
                var segment_0 : vec2<f32> = (center_1 + vec2<f32>(0.34000000357627869f * sin(a1_0), 0.2199999988079071f * sin(2.0f * a1_0)) - a_7) * metric_1;
                var point_0 : vec2<f32> = (_S86 - a_7) * metric_1;
                var k_0 : f32 = clamp(dot(point_0, segment_0) / max(dot(segment_0, segment_0), 1.00000001168609742e-07f), 0.0f, 1.0f);
                var delta_0 : vec2<f32> = point_0 - vec2<f32>(k_0) * segment_0;
                var distance_2 : f32 = dot(delta_0, delta_0);
                var trail_0 : f32 = fract(_S138 - (_S139 + k_0) / 32.0f + 1.0f);
                if((trail_0 < 0.60000002384185791f))
                {
                    horizontal_0 = (distance_2 < band_2);
                }
                else
                {
                    horizontal_0 = false;
                }
                if(horizontal_0)
                {
                    if(((param_0.shadowStrength_0) > 0.0f))
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
                    band_2 = distance_2;
                    phase_0 = trail_0;
                    lateral_0 = q_5;
                }
                i_0 = _S140;
            }
            var _S141 : f32 = max(0.0020000000949949026f, param_0.softness_0 * 0.039999999105930328f);
            var best_0 : f32 = sqrt(band_2);
            f_2.weight_0 = 1.0f - smoothstep(0.035000000149011612f - _S141, 0.035000000149011612f + _S141, best_0);
            var q_7 : f32 = phase_0 / 0.60000002384185791f;
            if((param_0.pixel_0) == 0.0f)
            {
                q_5 = floor(q_7 * _S89) / (_S89 - 1.0f);
            }
            else
            {
                q_5 = q_7;
            }
            f_2.b_0 = 0.15000000596046448f + 0.85000002384185791f * q_5;
            if(((param_0.shadowStrength_0) > 0.0f))
            {
                f_2.light_0 = edgeLight42_0(clamp(0.5f + best_0 * lateral_0 / 0.070000000298023224f, 0.0f, 1.0f), 0.070000000298023224f * param_0.sampleH_0, f_2.weight_0);
            }
        }
    default :
        {
        }
    }
    return f_2;
}

fn frozen3_0( _S142 : vec2<f32>,  _S143 : Coord_0) -> Field_0
{
    var build_1 : f32 = clamp(param_0.build_0, 0.10000000149011612f, 0.89999997615814209f);
    var u_3 : f32 = param_0.u_0;
    var _S144 : bool = ((param_0.pixel_0) > 0.0f);
    var held_0 : f32;
    if(_S144)
    {
        held_0 = _S143.raw_0;
    }
    else
    {
        held_0 = min(1.0f, (_S143.index_1 + 1.0f) / max(2.0f, param_0.slices_0));
    }
    var a_8 : f32;
    if((u_3 < build_1))
    {
        var progress_0 : f32 = u_3 / build_1;
        var _S145 : bool;
        if(_S144)
        {
            _S145 = true;
        }
        else
        {
            _S145 = (((param_0.flags_0) & (u32(1)))) != u32(0);
        }
        if(_S145)
        {
            var _S146 : f32 = max(1.0f / max(param_0.outputW_0, param_0.outputH_0), param_0.softness_0 * 0.0030000000260770321f);
            a_8 = 1.0f - smoothstep(progress_0 - _S146, progress_0 + _S146, _S143.raw_0);
        }
        else
        {
            var _S147 : i32;
            if((progress_0 >= (_S143.q_1)))
            {
                _S147 = i32(1);
            }
            else
            {
                _S147 = i32(0);
            }
            a_8 = f32(_S147);
        }
        var f_3 : Field_0 = single3_0(_S142, progress_0);
        f_3.b_0 = held_0;
        f_3.weight_0 = a_8;
        return f_3;
    }
    var after_0 : f32 = clamp((u_3 - build_1) / (1.0f - build_1), 0.0f, 1.0f);
    switch(param_0.ending_0)
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
            var release_0 : f32 = _S143.q_1 * 0.64999997615814209f;
            a_8 = clamp(held_0 + max(0.0f, after_0 - release_0) / max(0.05000000074505806f, 1.0f - release_0), 0.0f, 1.0f);
        }
    case u32(3):
        {
            if((after_0 > 0.0f))
            {
                held_0 = play3_0(held_0 - 2.0f * param_0.cycles_0 * after_0, param_0.playback_0);
            }
            a_8 = held_0;
        }
    case u32(4):
        {
            a_8 = bounce3_0(held_0 - 2.0f * param_0.cycles_0 * after_0);
        }
    default :
        {
            a_8 = held_0;
        }
    }
    return single3_0(_S142, a_8);
}

fn relative3_0( _S148 : Coord_0) -> f32
{
    var _S149 : u32 = param_0.flags_0;
    var d_1 : f32;
    if((((param_0.flags_0) & (u32(4)))) != u32(0))
    {
        d_1 = (_S148.raw_0 * 255.0f - 128.0f) / 128.0f;
    }
    else
    {
        if(((_S149 & (u32(8)))) != u32(0))
        {
            d_1 = (_S148.raw_0 * 65535.0f - 32768.0f) / 32768.0f;
        }
        else
        {
            d_1 = 2.0f * _S148.raw_0 - 1.0f;
        }
    }
    if((param_0.pixel_0) == 0.0f)
    {
        var _S150 : f32 = param_0.slices_0 - 1.0f;
        var positive_0 : f32 = ceil(_S150 / 2.0f);
        var negative_0 : f32 = floor(_S150 / 2.0f);
        var _S151 : f32;
        if((d_1 < 0.0f))
        {
            _S151 = negative_0;
        }
        else
        {
            _S151 = positive_0;
        }
        var _S152 : f32 = max(1.0f, _S151);
        d_1 = round(d_1 * _S152) / _S152;
    }
    return param_0.span_0 * d_1;
}

fn basic3_0( _S153 : vec2<f32>,  _S154 : Coord_0) -> Field_0
{
    var _S155 : f32 = param_0.cycles_0;
    var _S156 : f32 = param_0.u_0;
    var clock_2 : f32 = 2.0f * param_0.cycles_0 * param_0.u_0;
    var t_4 : f32;
    if((param_0.customMap_0) != u32(0))
    {
        if((((param_0.flags_0) & (u32(2)))) != u32(0))
        {
            t_4 = _S156 + relative3_0(_S154);
        }
        else
        {
            t_4 = _S154.q_1 + clock_2;
        }
        return single3_0(_S153, play3_0(t_4, param_0.playback_0));
    }
    var _S157 : u32 = param_0.design_0;
    if((param_0.design_0) == u32(0))
    {
        t_4 = 0.20000000298023224f + 0.80000001192092896f * fract(_S155 * _S156 - _S154.q_1);
    }
    else
    {
        if(_S157 == u32(5))
        {
            t_4 = bounce3_0(1.0f - clock_2 - param_0.span_0 * _S154.q_1);
        }
        else
        {
            if((param_0.shape_0) == u32(11))
            {
                if((i32(_S154.index_1) % i32(2)) == i32(0))
                {
                    t_4 = 1.0f;
                }
                else
                {
                    t_4 = -1.0f;
                }
                t_4 = play3_0(1.0f + clock_2 * t_4 - param_0.span_0 * _S154.q_1, param_0.playback_0);
            }
            else
            {
                t_4 = play3_0(1.0f + clock_2 - param_0.span_0 * _S154.q_1, param_0.playback_0);
            }
        }
    }
    return single3_0(_S153, t_4);
}

fn wave3_0( _S158 : vec2<f32>,  _S159 : Coord_0) -> Field_0
{
    var _S160 : bool;
    if((param_0.customMap_0) != u32(0))
    {
        _S160 = (((param_0.flags_0) & (u32(2)))) != u32(0);
    }
    else
    {
        _S160 = false;
    }
    var phase_4 : f32;
    if(_S160)
    {
        phase_4 = 2.0f * param_0.cycles_0 * param_0.u_0 + relative3_0(_S159);
    }
    else
    {
        phase_4 = 2.0f * param_0.cycles_0 * param_0.u_0 - 2.0f * param_0.density_0 * _S159.q_1;
    }
    return single3_0(_S158, play3_0(phase_4, param_0.playback_0));
}

fn coordSpan42_0( _S161 : vec2<f32>) -> f32
{
    var _S162 : f32 = param_0.sampleW_0;
    var _S163 : f32 = param_0.sampleH_0;
    var size_1 : vec2<f32> = vec2<f32>(param_0.sampleW_0, param_0.sampleH_0);
    var _S164 : vec2<f32> = vec2<f32>(param_0.cx_0, param_0.cy_0);
    var v_4 : vec2<f32> = (_S161 - _S164) * size_1;
    var _S165 : vec2<f32> = vec2<f32>(1.0f);
    var radii_1 : vec2<f32> = max(_S164, _S165 - _S164) * size_1;
    if((param_0.customMap_0) != u32(0))
    {
        return min(_S162, _S163);
    }
    switch(param_0.shape_0)
    {
    case u32(1):
        {
            return _S163;
        }
    case u32(2), u32(12):
        {
            var a_9 : f32 = param_0.angle_0 * 3.1415927410125732f / 180.0f;
            return _S162 * abs(cos(a_9)) + _S163 * abs(sin(a_9));
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
            return length(radii_1) - length(max(vec2<f32>(vec2<i32>(i32(0))), max((vec2<f32>(0) - _S164), _S164 - _S165)) * size_1);
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
            return _S162;
        }
    }
}

fn stripeLight42_0( _S166 : f32,  _S167 : f32,  _S168 : f32,  _S169 : f32,  _S170 : bool,  _S171 : f32) -> f32
{
    var span_1 : f32 = _S168 / _S169;
    if((span_1 <= 1.0f))
    {
        return 1.0f;
    }
    var leading_0 : bool = ((param_0.shadowSide_0) > 0.0f);
    var center_2 : f32;
    if(leading_0)
    {
        center_2 = 0.0f;
    }
    else
    {
        center_2 = 1.0f;
    }
    var edge_1 : f32 = stripeBorder42_0(_S167 + center_2, _S168, _S169);
    var center_3 : f32 = floor(_S166 * _S168) + 0.5f;
    if(_S170)
    {
        center_2 = _S168 - center_3;
    }
    else
    {
        center_2 = center_3;
    }
    if(leading_0)
    {
        center_2 = center_2 - edge_1;
    }
    else
    {
        center_2 = edge_1 - center_2;
    }
    return filteredLight42_0(max(0.5f, center_2) / span_1, span_1, _S171, 1.0f, false);
}

fn sliceLight42_0( _S172 : vec2<f32>,  _S173 : Coord_0,  _S174 : f32) -> f32
{
    var _S175 : f32 = max(2.0f, param_0.slices_0);
    var _S176 : u32 = param_0.shape_0;
    var _S177 : bool = (param_0.shape_0) == u32(8);
    var _S178 : bool;
    if(_S177)
    {
        _S178 = true;
    }
    else
    {
        _S178 = _S176 == u32(10);
    }
    if(_S178)
    {
        _S178 = (param_0.customMap_0) == u32(0);
    }
    else
    {
        _S178 = false;
    }
    if(_S178)
    {
        _S178 = ((param_0.direction_0) < u32(2));
    }
    else
    {
        _S178 = false;
    }
    var cells_0 : f32;
    var x_3 : f32;
    if(_S178)
    {
        var _S179 : bool = _S176 == u32(10);
        if(_S179)
        {
            cells_0 = ceil(_S175 / 2.0f);
        }
        else
        {
            cells_0 = _S175;
        }
        var grid_1 : vec2<f32> = gridSize3_0(cells_0, vec2<f32>(param_0.outputW_0, param_0.outputH_0));
        var _S180 : f32 = grid_1.x;
        var _S181 : i32;
        if(((_S173.cell_3.y) < (cells_0 - _S180 * grid_1.y)))
        {
            _S181 = i32(1);
        }
        else
        {
            _S181 = i32(0);
        }
        var x_4 : f32 = _S173.frac_0.x;
        var span_2 : f32 = param_0.sampleW_0 / (_S180 + f32(_S181));
        var span_3 : f32;
        if(_S179)
        {
            var cut_1 : f32 = 1.0f - _S173.frac_0.y;
            var first_1 : bool = (x_4 < cut_1);
            if(first_1)
            {
                cells_0 = cut_1;
            }
            else
            {
                cells_0 = 1.0f - cut_1;
            }
            var span_4 : f32 = span_2 * cells_0;
            if(first_1)
            {
                cells_0 = x_4 / max(cut_1, 9.99999997475242708e-07f);
            }
            else
            {
                cells_0 = (x_4 - cut_1) / max(1.0f - cut_1, 9.99999997475242708e-07f);
            }
            x_3 = cells_0;
            span_3 = span_4;
        }
        else
        {
            x_3 = x_4;
            span_3 = span_2;
        }
        var phase_5 : f32;
        if((param_0.direction_0) == u32(1))
        {
            phase_5 = 1.0f - x_3;
        }
        else
        {
            phase_5 = x_3;
        }
        if(_S177)
        {
            cells_0 = tiledLight42_0(phase_5, span_3, _S174);
        }
        else
        {
            cells_0 = edgeLight42_0(phase_5, span_3, _S174);
        }
        return cells_0;
    }
    var _S182 : f32 = coordSpan42_0(_S172);
    var _S183 : u32 = param_0.direction_0;
    if(((param_0.direction_0) >= u32(2)))
    {
        cells_0 = _S182 * 0.5f;
    }
    else
    {
        cells_0 = _S182;
    }
    if(((param_0.pixel_0) > 0.0f))
    {
        _S178 = (param_0.family_0) == u32(2);
    }
    else
    {
        _S178 = false;
    }
    if(_S178)
    {
        if((param_0.customMap_0) != u32(0))
        {
            _S178 = (((param_0.flags_0) & (u32(2)))) != u32(0);
        }
        else
        {
            _S178 = false;
        }
        if(_S178)
        {
            x_3 = 2.0f * param_0.span_0;
        }
        else
        {
            x_3 = 2.0f * param_0.density_0;
        }
        var _S184 : f32 = max(0.0099999997764825821f, x_3);
        return tiledLight42_0(fract(_S184 * _S173.raw_0 - 2.0f * param_0.cycles_0 * param_0.u_0), cells_0 / _S184, _S174);
    }
    if(isStripe42_0())
    {
        if(_S176 == u32(1))
        {
            x_3 = _S172.y;
        }
        else
        {
            x_3 = _S172.x;
        }
        var _S185 : f32 = stripeLight42_0(x_3, _S173.index_1, cells_0, _S175, _S183 == u32(1), _S174);
        return _S185;
    }
    return tiledLight42_0(clamp(_S173.raw_0 * _S175 - _S173.index_1, 0.0f, 1.0f), cells_0 / _S175, _S174);
}

fn evaluate3_0( _S186 : vec2<f32>,  _S187 : f32) -> Field_0
{
    if(((param_0.design_0) >= u32(407)))
    {
        return creative42_0(_S186);
    }
    var _S188 : Coord_0 = coordinate3_0(_S186, _S187);
    var base_1 : f32;
    if((_S188.coverage_0) == 0.0f)
    {
        var _S189 : u32 = param_0.family_0;
        if((param_0.family_0) == u32(0))
        {
            base_1 = play3_0(param_0.u_0 / max(0.10000000149011612f, param_0.build_0), param_0.playback_0);
        }
        else
        {
            if(_S189 == u32(1))
            {
                base_1 = 1.0f;
            }
            else
            {
                base_1 = 0.0f;
            }
            base_1 = play3_0(base_1 + 2.0f * param_0.cycles_0 * param_0.u_0, param_0.playback_0);
        }
        return single3_0(_S186, base_1);
    }
    var _S190 : u32 = param_0.family_0;
    if((param_0.family_0) == u32(3))
    {
        return creative3_0(_S186, _S188);
    }
    var f_4 : Field_0;
    var _S191 : bool = _S190 == u32(0);
    var _S192 : Field_0;
    if(_S191)
    {
        _S192 = frozen3_0(_S186, _S188);
    }
    else
    {
        if(_S190 == u32(1))
        {
            _S192 = basic3_0(_S186, _S188);
        }
        else
        {
            _S192 = wave3_0(_S186, _S188);
        }
    }
    f_4 = _S192;
    if(((param_0.shadowStrength_0) > 0.0f))
    {
        var _S193 : bool;
        if(_S191)
        {
            _S193 = ((param_0.u_0) < (clamp(param_0.build_0, 0.10000000149011612f, 0.89999997615814209f)));
        }
        else
        {
            _S193 = false;
        }
        if(_S193)
        {
            base_1 = f_4.weight_0;
        }
        else
        {
            base_1 = 1.0f;
        }
        if((base_1 > 0.0f))
        {
            var _S194 : f32 = sliceLight42_0(_S186, _S188, base_1);
            f_4.light_0 = _S194;
        }
    }
    return f_4;
}

fn adjusted3_0( _S195 : f32) -> f32
{
    var _S196 : f32 = clamp(_S195, 0.0f, 1.0f);
    var _S197 : f32;
    if(((param_0.sourceReverse_0) > 0.0f))
    {
        _S197 = 1.0f - _S196;
    }
    else
    {
        _S197 = _S196;
    }
    return mix(param_0.sourceStart_0, param_0.sourceEnd_0, _S197);
}

@compute
@workgroup_size(8, 8, 1)
fn fields(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S198 : u32 = id_0.x;
    var _S199 : bool;
    if((_S198 >= cfg_0[i32(2)]))
    {
        _S199 = true;
    }
    else
    {
        _S199 = ((id_0.y) >= cfg_0[i32(3)]);
    }
    if(_S199)
    {
        return;
    }
    var local_3 : u32 = id_0.y * cfg_0[i32(2)] + _S198;
    var _S200 : Field_0 = evaluate3_0((vec2<f32>(id_0.xy + vec2<u32>(cfg_0[i32(0)], cfg_0[i32(1)])) + vec2<f32>(0.5f)) / vec2<f32>(f32(cfg_0[i32(4)]), f32(cfg_0[i32(5)])), timeMap_0[local_3]);
    var _S201 : u32 = local_3 * u32(2);
    diagnostics_0[_S201] = vec4<f32>(adjusted3_0(_S200.a_0), adjusted3_0(_S200.b_0), clamp(_S200.weight_0, 0.0f, 1.0f), _S200.shade_0);
    diagnostics_0[_S201 + u32(1)] = vec4<f32>(_S200.uvA_0, _S200.uvB_0);
    return;
}

