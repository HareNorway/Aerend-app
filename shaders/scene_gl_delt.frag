// Heat plan Step 6: scene_gl.frag with its static part read back from the
// bake (scene_gl_bake.frag, four 8-bit digits per value) instead of
// computed: the stone relief's light factor (fr), the texture factor
// (k = 1 + tx · (1 − e), tx being all static) and the 12-tap window glow (gs). Everything that moves — drips, cloud shade,
// flicker, sheen, sky, fog bands, glints, rain, grain — is the same code as
// scene_gl.frag, in the same order. uPlank is gone (only tx read it); uBSz is
// the bake's size in pixels.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;
uniform vec2 uRes; uniform float uDpr;
uniform float uT;
uniform float uSky;
uniform float uHz;
uniform float uRock;
uniform float uGlow;
uniform float uRegn;
uniform float uSol;
uniform float uVann;
uniform float uSheen;
uniform vec3 uTake;
uniform vec3 uLit;
uniform vec3 uShade;
uniform vec3 uFogC; uniform sampler2D uTex;
uniform sampler2D uTex1;
uniform sampler2D uTex2;
uniform sampler2D uTex3;
uniform float uTW;
uniform float uTH;
uniform vec2 uBSz;
uniform sampler2D uB0;
uniform sampler2D uB1;
uniform sampler2D uB2;
uniform sampler2D uB3;
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
// Heat plan Step 6: the baked value from its four 8-bit digits (see lv() in
// the bake shader); exact: each partial sum fits a float's 24 bits until the
// last, which is the original value itself.
float dk(vec4 t){
  vec4 d = floor(t * 255.0 + 0.5);
  return (d.x + (d.y + (d.z + d.w / 256.0) / 256.0) / 256.0) / 256.0;
}
void main(){
  LOD0 = log2(max(uTW / (uRes.x * uDpr), uTH / (uRes.y * uDpr)));
  vec2 p = FlutterFragCoord().xy / uDpr;
  vec2 uv = p / uRes;
  vec4 s = mip(uv, 0.0); vec4 b1 = mip(uv, 1.6);
  float a = s.a; vec3 col = rett(s), cb = rett(b1);
  col += (col - cb) * 0.4 * step(0.02, b1.a);
  float lum = dot(col, vec3(0.3, 0.55, 0.15));
  float e = emis(col);
  vec2 bq = (floor(FlutterFragCoord().xy) + 0.5) / uBSz;
  vec4 k0 = texture(uB0, bq), k1 = texture(uB1, bq), k2 = texture(uB2, bq), k3 = texture(uB3, bq);
  float fr = dk(vec4(k0.r, k1.r, k2.r, k3.r)) * 2.0, k = dk(vec4(k0.g, k1.g, k2.g, k3.g)) * 2.0, gs = dk(vec4(k0.b, k1.b, k2.b, k3.b)) * 2.0;
  if (uRock > 0.0) {
    col *= fr;
    float drp = smoothstep(0.9, 1.0, vn(vec2(p.x * 0.32, p.y * 0.018 - uT * 0.22))) * smoothstep(0.3, 0.6, vn(vec2(p.x * 0.32 + 7.0, p.y * 0.05)));
    col += vec3(0.75, 0.85, 0.9) * drp * 0.1 * uRock;
  }
  col *= k;
  col *= 0.94 + 0.1 * (1.0 - p.y / uRes.y);
  // uSol == 0 (no sky): the factor below is exactly 1.0, so it is skipped.
  if (uSol > 0.0) {
    float cs = smoothstep(0.5, 0.76, fbm(p * 0.0062 + vec2(uT * 0.012, uT * 0.003)));
    col *= 1.0 - cs * uSol * (1.0 - e);
  }
  if (uHz > 0.0) { float dy = clamp((uHz - p.y) / uHz, 0.0, 1.0); col = mix(col, uFogC, dy * dy * 0.26); }
  if (uVann > 0.0 && p.y > uVann) {
    float bl = smoothstep(0.0, 0.05, col.b - col.r) * smoothstep(0.25, 0.5, lum);
    float gl = smoothstep(0.7, 0.92, vn(vec2(p.x * 0.07 - uT * 0.35, p.y * 0.85)) * vn(vec2(p.x * 0.025 + uT * 0.18, p.y * 0.4)) * 1.5);
    col += uLit * gl * bl * 0.22;
  }
  col = clamp(col, 0.0, 1.0);
  col = mix(col, col * col * (3.0 - 2.0 * col), 0.2);
  float l2 = dot(col, vec3(0.3, 0.55, 0.15)); col = mix(vec3(l2), col, 1.08);
  col += vec3(0.025, -0.004, -0.026) * smoothstep(0.45, 1.0, l2) + vec3(-0.018, 0.008, 0.022) * (1.0 - smoothstep(0.0, 0.45, l2));
  vec2 cel = floor(p / 9.0);
  float fl = 0.86 + 0.14 * sin(uT * (1.1 + hs(cel) * 2.2) + hs(cel + 3.0) * 6.28) * (0.6 + 0.4 * sin(uT * 7.0 + hs(cel) * 30.0));
  col = mix(col, clamp(col * fl * vec3(1.06, 1.0, 0.9), 0.0, 1.0), e * uGlow);
  if (uSheen > 0.0) { float sw = fract(uT * 0.085) * 2.6 - 0.8; float xx = p.x / uRes.x - sw + (p.y / uRes.y - 0.5) * 0.35; col += vec3(1.0, 0.95, 0.82) * exp(-xx * xx * 120.0) * uSheen * smoothstep(0.55, 0.9, col.r) * 0.55; }
  vec4 o = vec4(clamp(col, 0.0, 1.0) * a, a);
  vec3 glo = vec3(1.0, 0.7, 0.36) * gs * uGlow * fl;
  if (uSky > 0.0) {
    float him = (1.0 - smoothstep(0.12, 0.6, a)) * (1.0 - smoothstep(uHz - 8.0, uHz + 24.0, p.y));
    vec2 q = p * vec2(0.0062, 0.0105) + vec2(uT * 0.011, 0.0);
    vec2 w = vec2(fbm(q + vec2(1.7, 9.2) + uT * 0.005), fbm(q + vec2(8.3, 2.8) - uT * 0.004));
    float d1 = fbm(q + w * 1.35), d2 = fbm(q + w * 1.35 + vec2(-0.07, 0.06));
    float den = smoothstep(0.44, 0.8, d1), ly = clamp((d1 - d2) * 5.5 + 0.55, 0.0, 1.0);
    float ca = den * uSky * him * 0.92;
    o += vec4(mix(uShade, uLit, ly) * ca, ca) * (1.0 - o.a);
  }
  if (uTake.z > 0.0) {
    float band = smoothstep(uTake.x - 14.0, uTake.x + 12.0, p.y) * (1.0 - smoothstep(uTake.y - 12.0, uTake.y + 18.0, p.y));
    float f1 = fbm(vec2(p.x * 0.0058 - uT * 0.017, p.y * 0.03 + uT * 0.003)), f2 = fbm(vec2(p.x * 0.012 + uT * 0.009, p.y * 0.055) + 4.0);
    float fa = smoothstep(0.42, 0.82, f1 * 0.62 + f2 * 0.45) * band * uTake.z;
    o = vec4(uFogC * fa, fa) + o * (1.0 - fa);
  }
  o.rgb += glo; o.a = max(o.a, clamp(dot(glo, vec3(0.3, 0.5, 0.2)) * 1.4, 0.0, 1.0));
  if (uRegn > 0.0) {
    vec2 r = vec2(p.x + p.y * 0.17, p.y); float ci = floor(r.x / 6.0);
    float lx = abs(fract(r.x / 6.0) - 0.5) * 6.0;
    float ph = fract((r.y - uT * (360.0 + hs(vec2(ci, 2.0)) * 170.0)) / (64.0 + hs(vec2(ci, 5.0)) * 46.0) + hs(vec2(ci, 9.0)));
    float st = (1.0 - smoothstep(0.0, 0.65, lx)) * smoothstep(0.0, 0.04, ph) * (1.0 - smoothstep(0.04, 0.26, ph)) * step(0.62, hs(vec2(ci, 1.0)));
    float ra = st * 0.26 * uRegn;
    o = vec4(vec3(0.86, 0.92, 0.95) * ra, ra) + o * (1.0 - ra);
  }
  o.rgb += (hs(FlutterFragCoord().xy + fract(uT * 7.0)) - 0.5) * 0.024 * o.a;
  fragColor = o;
}
