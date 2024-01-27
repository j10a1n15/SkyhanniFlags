// Chroma Fragment Shader
// Taken from SkyblockAddons
// Modified in SkyHanni
// And finally modified by nea89 to use the bi flag

#version 120
#define FLAG_SIZE 5

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

float lerp_flag(float progress, float[FLAG_SIZE] values) {
    float realProgress = mod(progress, 1) * (FLAG_SIZE+1);
    int lowerIndex = int(mod(realProgress, FLAG_SIZE));
    int higherIndex = int(mod(lowerIndex + 1, FLAG_SIZE));
    return circular_mix(values[lowerIndex], values[higherIndex], mod(realProgress, 1));
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


    float[FLAG_SIZE] hues = float[](328.47 / 360, 328.47 / 360, 303.85 / 360, 221.29 / 360, 221.29 / 360);
    float[FLAG_SIZE] saturations = float[](100, 100, 50, 100, 100);
    float[FLAG_SIZE] brightnesses = float[](84.31, 84.31, 61.18, 66.67, 66.67);

    // The hue takes in account the position, chroma settings, and time
    float hue = lerp_flag(((fragCoord) / chromaSize) - timeOffset, hues);

    // Set the color to use the new hue & original saturation/value/alpha values
    gl_FragColor = vec4(hsb2rgb_smooth(vec3(hue, saturation, rgb2b(originalColor.rgb))), originalColor.a);
}

