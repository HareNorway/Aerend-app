// Heat plan Step 6: the static part of scene_gl.frag, baked once per size
// and texture set (SceneGl berg, via SpGl.del). Every line below is copied
// from scene_gl.frag's main() in its order, so each value is the same float
// the full shader computes: fr (the stone relief's light factor, `mix(1.0,
// .55 + .62 * rel, uRock * a)`), k (`1.0 + tx * (1.0 - e)`, tx being the
// grain, plank, forest and stone texture term, all of it static) and gs (the
// 12-tap window glow). All three are positive and below 2, so they are
// written halved (exact) as four 8-bit digits, one pass per digit (uNivaa 0–3),
// alpha 1.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;
uniform vec2 uRes; uniform float uDpr;
uniform float uPlank;
uniform float uRock;
uniform float uTW;
uniform float uTH;
uniform float uNivaa;
uniform sampler2D uTex;
uniform sampler2D uTex1;
uniform sampler2D uTex2;
uniform sampler2D uTex3;
float LOD0;
vec4 mip(vec2 uv, float b){
  float l = clamp(LOD0 + b, 0.0, 3.0);
  if (l < 1.0) return mix(texture(uTex, uv), texture(uTex1, uv), l);
  if (l < 2.0) return mix(texture(uTex1, uv), texture(uTex2, uv), l - 1.0);
  return mix(texture(uTex2, uv), texture(uTex3, uv), l - 2.0);
}
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
vec3 rett(vec4 c){ return c.a > 0.002 ? c.rgb / c.a : vec3(0.0); }
float emis(vec3 c){ float l = dot(c, vec3(0.3, 0.55, 0.15)); return smoothstep(0.86, 0.97, c.r) * smoothstep(0.12, 0.3, c.r - c.b) * smoothstep(0.6, 0.8, l); }
// Heat plan Step 6: one 8-bit digit of u in [0, 1): u in base 256, four
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
  LOD0 = log2(max(uTW / (uRes.x * uDpr), uTH / (uRes.y * uDpr)));
  vec2 p = FlutterFragCoord().xy / uDpr;
  vec2 uv = p / uRes;
  vec4 s = mip(uv, 0.0); vec4 b1 = mip(uv, 1.6);
  float a = s.a; vec3 col = rett(s), cb = rett(b1);
  col += (col - cb) * 0.4 * step(0.02, b1.a);
  float lum = dot(col, vec3(0.3, 0.55, 0.15));
  float tx = (vn(p * 1.15) - 0.5) * 0.06 + (fbm(p * 0.17) - 0.5) * 0.1;
  float plk = 0.5 + 0.5 * sin(p.x * 2.05 + vn(vec2(p.x * 0.3, 0.0)) * 2.0);
  tx += uPlank * ((plk - 0.5) * 0.08 + (vn(vec2(p.x * 0.9, p.y * 0.07)) - 0.5) * 0.12);
  float skog = smoothstep(-0.02, 0.07, col.g - col.r) * (1.0 - smoothstep(0.32, 0.58, lum));
  tx += skog * (smoothstep(0.5, 0.82, vn(p * 0.6)) - 0.35) * 0.16;
  float e = emis(col);
  float fr = 1.0;
  if (uRock > 0.0) {
    vec2 rq = p * vec2(0.035, 0.06);
    float h0 = fbm(rq) + 0.45 * fbm(rq * 3.1 + 5.0), hx = fbm(rq + vec2(0.02, 0.0)) + 0.45 * fbm((rq + vec2(0.02, 0.0)) * 3.1 + 5.0), hy = fbm(rq + vec2(0.0, 0.03)) + 0.45 * fbm((rq + vec2(0.0, 0.03)) * 3.1 + 5.0);
    float rel = dot(normalize(vec3(-(hx - h0) * 9.0, (hy - h0) * 9.0, 1.0)), normalize(vec3(-0.45, 0.6, 0.66)));
    fr = mix(1.0, 0.55 + 0.62 * rel, uRock * a);
    tx += uRock * ((h0 - 0.7) * 0.22 + (vn(p * 0.85) - 0.5) * 0.1);
  }
  float k = 1.0 + tx * (1.0 - e);
  float gs = 0.0;
  for (int i = 0; i < 12; i++) {
    float fi = float(i), r = fi < 6.0 ? 3.6 : 8.5;
    vec2 d = vec2(cos(fi * 2.3998), sin(fi * 2.3998)) * r / uRes;
    vec4 sm = mip(uv + d, 1.0);
    gs += emis(rett(sm)) * sm.a * (fi < 6.0 ? 0.12 : 0.065);
  }
  fragColor = vec4(lv(fr * 0.5), lv(k * 0.5), lv(gs * 0.5), 1.0);
}
