// Heat plan Step 6: the static part of aegil_floyen_liv.frag, baked once per
// city and size (AegilFloyen): the city read with its 4-tap soft blur and
// 8-tap glow — the first lines of that shader's main(), copied in their order,
// so the value is the same float it computes from the same 13 reads. Written
// halved (exact; col < 1.13) as four 8-bit digits, one pass per digit
// (uNivaa 0–3), alpha 1.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;
uniform sampler2D uTex; uniform vec2 uRes; uniform float uDpr;
uniform float uNivaa;
vec4 tx(vec2 p){ return texture(uTex, vec2(p.x / uRes.x, p.y / uRes.y)); }
// One 8-bit digit of u in [0, 1): u in base 256, four
// digits — 32 bits after the point, so every float u >= 2^-8 (24-bit
// mantissa) comes back bit for bit (smaller ones within 2^-32). Every step is
// exact (powers of two, floor, subtraction of the integer part). dk() in the
// live pass reads the digits back, rounding each to its integer first (so
// 10-bit or half-float storage reads back the same).
float lv(float u){
  float x = clamp(u, 0.0, 0.99999994) * 256.0;
  float d1 = floor(x); x = (x - d1) * 256.0;
  float d2 = floor(x); x = (x - d2) * 256.0;
  float d3 = floor(x); x = (x - d3) * 256.0;
  float d4 = floor(x);
  return (uNivaa < 0.5 ? d1 : (uNivaa < 1.5 ? d2 : (uNivaa < 2.5 ? d3 : d4))) / 255.0;
}
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  vec4 s = tx(p); vec3 col = s.rgb; float m = s.a;
  vec3 bl = (tx(p + vec2(0.8, 0.3)).rgb + tx(p - vec2(0.8, 0.3)).rgb + tx(p + vec2(-0.3, 0.8)).rgb + tx(p + vec2(0.3, -0.8)).rgb) * 0.25;
  col = mix(col, bl, 0.22);
  vec3 gl = (tx(p + vec2(3.0, 0.0)).rgb + tx(p - vec2(3.0, 0.0)).rgb + tx(p + vec2(0.0, 3.0)).rgb + tx(p - vec2(0.0, 3.0)).rgb + tx(p + vec2(4.5, 4.5)).rgb + tx(p - vec2(4.5, 4.5)).rgb + tx(p + vec2(4.5, -4.5)).rgb + tx(p - vec2(4.5, -4.5)).rgb) * 0.125;
  col += max(gl - 0.62, 0.0) * 0.32;
  fragColor = vec4(lv(col.r * 0.5), lv(col.g * 0.5), lv(col.b * 0.5), 1.0);
}
