// Chroma Fragment Shader
// Taken from SkyblockAddons
// Modified in SkyHanni
// And finally modified by nea89 to use the bi flag

#version 120


// FLAG_BEGIN
#define HUE_INIT (0.9124031007751938,0.9124031007751938,0.844017094017094,0.6147058823529412,0.6147058823529412)
#define SATURATION_INIT (1.0,1.0,0.5,1.0,1.0)
#define BRIGHTNESS_INIT (0.8431372549019608,0.8431372549019608,0.611764705882353,0.6666666666666666,0.6666666666666666)
#define FLAG_SIZE 5
#define MAX_SATURATION false
#define INTERPOLATION_LEVEL 0
// FLAG_END


uniform float chromaSize;
uniform float timeOffset;
uniform float saturation;
uniform bool forwardDirection;

uniform sampler2D outTexture;

varying vec2 outTextureCoords;
varying vec4 outColor;

float rgb2b(vec3 rgb) {
    return max(max(rgb.r, rgb.g), rgb.b);
}

vec3 hsb2rgb_smooth(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);// Cubic smoothing
    return c.z * mix(vec3(1.0), rgb, c.y);
}


float circular_mix(float left, float right, float progress) {
    float shortest_angle = mod(mod(right - left, 1) + 1.5, 1) - 0.5;
    return mod(left + (shortest_angle * progress), 1);
}

float lerp_flag(float progress, float[FLAG_SIZE] values, bool isCircular) {
    float realProgress = mod(progress, 1) * (FLAG_SIZE);
    int lowerIndex = int(mod(realProgress, FLAG_SIZE));
    int higherIndex = int(mod(lowerIndex + 1, FLAG_SIZE));
    float innerProgress = mod(realProgress, 1);
    if (INTERPOLATION_LEVEL >= 1) {
        if (innerProgress < 0.5)
            innerProgress = pow(2.0, INTERPOLATION_LEVEL * innerProgress - INTERPOLATION_LEVEL / 2.0) / 2.0;
        else
            innerProgress = 1.0 - pow(2.0, -INTERPOLATION_LEVEL * innerProgress + INTERPOLATION_LEVEL / 2.0) / 2.0;

    }

    if (isCircular)
        return circular_mix(values[lowerIndex], values[higherIndex], innerProgress);
    else
        return mix(values[lowerIndex], values[higherIndex], innerProgress);
}

void main() {
    vec4 originalColor = texture2D(outTexture, outTextureCoords) * outColor;

    // Determine the direction chroma moves
    float fragCoord;
    if (forwardDirection) {
        fragCoord = gl_FragCoord.x - gl_FragCoord.y;
    } else {
        fragCoord = gl_FragCoord.x + gl_FragCoord.y;
    }


    float[FLAG_SIZE] hues = float[]HUE_INIT;
    float[FLAG_SIZE] saturations = float[]SATURATION_INIT;
    float[FLAG_SIZE] brightnesses = float[]BRIGHTNESS_INIT;

    // The hue takes in account the position, chroma settings, and time
    float offset = ((fragCoord) / chromaSize) - timeOffset;
    float hue = lerp_flag(offset, hues, true);
    float saturationMultiplier = lerp_flag(offset, saturations, false);
    if (MAX_SATURATION)
        saturationMultiplier = 1;
    float brightness = lerp_flag(offset, brightnesses, false);

    // Set the color to use the new hue & original saturation/value/alpha values
    gl_FragColor = vec4(hsb2rgb_smooth(vec3(hue, saturation * saturationMultiplier, rgb2b(originalColor.rgb) * brightness)), originalColor.a);
}