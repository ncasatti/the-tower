/*
 * Blue Light Filter + Vibrance
 *
 * Combines blue light filtering with color saturation enhancement.
 * Use warmer colors to make the display easier on your eyes while
 * enhancing color vibrancy.
 *
 * Combines effects from:
 * - Blue Light Filter: https://github.com/hyprwm/Hyprland/issues/1140#issuecomment-1335128437
 * - Vibrance: https://github.com/hyprwm/Hyprland/issues/1140#issuecomment-1614863627
 */

#version 300 es

precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;

out vec4 fragColor;

/**
 * Color temperature in Kelvin for blue light filtering.
 * https://en.wikipedia.org/wiki/Color_temperature
 *
 * @min 1000.0
 * @max 40000.0
 */
const float Temperature = 3500.0;

/**
 * Strength of blue light filter.
 *
 * @min 0.0
 * @max 1.0
 */
const float BlueFilterStrength = 0.5;

/**
 * Per-channel multiplier to vibrance strength.
 *
 * @min 0.0
 * @max 10.0
 */
const vec3 Balance = vec3(1.0, 1.0, 1.0);

/**
 * Strength of vibrance filter.
 * (Negative values will reduce vibrance.)
 *
 * @min -1.0
 * @max 1.0
 */
const float VibranceStrength = 0.5;

#define WithQuickAndDirtyLuminancePreservation
const float LuminancePreservationFactor = 15.0;

const vec3 VIB_coeffVibrance = Balance * -VibranceStrength;

// function from https://www.shadertoy.com/view/4sc3D7
// valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float temperature) {
    // values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693
    mat3 m = (temperature <= 6500.0) ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
                                            vec3(0.0, 1669.5803561666639, 2575.2827530017594),
                                            vec3(1.0, 1.3302673723350029, 1.8993753891711275))
                                     : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                            vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                            vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
    return mix(clamp(vec3(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), vec3(0.0), vec3(1.0)),
               vec3(1.0), smoothstep(1000.0, 0.0, temperature));
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = vec3(pixColor[0], pixColor[1], pixColor[2]);

    // Apply blue light filter first
#ifdef WithQuickAndDirtyLuminancePreservation
    color *= mix(1.0, dot(color, vec3(0.2126, 0.7152, 0.0722)) / max(dot(color, vec3(0.2126, 0.7152, 0.0722)), 1e-5),
                 LuminancePreservationFactor);
#endif

    color = mix(color, color * colorTemperatureToRGB(Temperature), BlueFilterStrength);

    // Apply vibrance enhancement
    vec3 VIB_coefLuma = vec3(0.212656, 0.715158, 0.072186);
    float luma = dot(VIB_coefLuma, color);
    
    float max_color = max(color[0], max(color[1], color[2]));
    float min_color = min(color[0], min(color[1], color[2]));
    
    float color_saturation = max_color - min_color;
    
    vec3 p_col = vec3(vec3(vec3(vec3(sign(VIB_coeffVibrance) * color_saturation) - 1.0) * VIB_coeffVibrance) + 1.0);
    
    color[0] = mix(luma, color[0], p_col[0]);
    color[1] = mix(luma, color[1], p_col[1]);
    color[2] = mix(luma, color[2], p_col[2]);

    vec4 outCol = vec4(color, pixColor[3]);
    fragColor = outCol;
}

// vim: ft=glsl
