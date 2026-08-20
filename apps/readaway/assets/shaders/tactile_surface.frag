#version 310 es
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uMode;
uniform vec4 uBaseColor;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 3; ++i) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 col = uBaseColor.rgb;

    if (uMode < 0.5) {
        float paperFibers = fbm(uv * vec2(uResolution.x / 4.0, uResolution.y / 4.0));
        float microNoise = hash(uv * uResolution.xy);

        col -= vec3(0.035) * paperFibers;
        col -= vec3(0.015) * microNoise;

        float edgeVignette = smoothstep(0.0, 0.25, uv.x) * smoothstep(1.0, 0.75, uv.x)
                           * smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.75, uv.y);
        col *= mix(0.97, 1.0, edgeVignette);
    } else {
        vec2 slateCoord = vec2(uv.x * 2.5, uv.y * 12.0) * (uResolution.y / 8.0);
        float rockGrain = fbm(slateCoord);
        float fineSpecks = hash(uv * uResolution.xy * 2.0);

        col += (vec3(fineSpecks) - 0.5) * 0.04;
        col += (vec3(rockGrain) - 0.5) * 0.025;
        col += vec3(0.015) * (1.0 - uv.y);
    }

    fragColor = vec4(col, 1.0);
}
