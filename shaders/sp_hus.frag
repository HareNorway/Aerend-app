// Sporing · Levert — the Launch prototype's own WebGL scene (`spLvInit / spLvTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: the street with the house, the lamp posts, the wet road, the courier's lights and Ægil's shadow.
// Only the dialect changed (ui-tools/gl2flutter.py): uniforms one per line,
// FlutterFragCoord (top-left, so p is the design pixel), fragColor, and
// texture() without a mip bias — the biased reads come from pre-baked
// textures. Rendered offscreen into an image whose pixel grid is
// (uRes * uDpr), like meg_stadion.frag.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

uniform vec2 uRes; uniform float uDpr;
uniform float uT;
uniform float uNight;
uniform float uRain;
uniform float uSnow;
uniform float uWet;
uniform float uAge;
uniform float uUt;
uniform float uHall;
uniform float uMoon;
uniform vec3 uSkT;
uniform vec3 uSkH;
uniform vec4 uVA;
uniform vec4 uVB;
uniform vec4 uVC;
uniform vec4 uAe;
const vec4 uWin[12] = vec4[12](vec4(320.0, 194.0, 28.0, 36.0), vec4(364.0, 194.0, 28.0, 36.0), vec4(320.0, 244.0, 28.0, 40.0), vec4(364.0, 244.0, 28.0, 40.0), vec4(16.0, 186.0, 22.0, 22.0), vec4(4.0, 238.0, 30.0, 44.0), vec4(50.0, 238.0, 28.0, 44.0), vec4(184.0, 132.0, 24.0, 28.0), vec4(116.0, 194.0, 28.0, 38.0), vec4(248.0, 194.0, 28.0, 38.0), vec4(112.0, 236.0, 36.0, 46.0), vec4(242.0, 236.0, 36.0, 46.0));
const vec2 uWinM[12] = vec2[12](vec2(1.0, 5.0), vec2(0.0, 6.0), vec2(1.0, 7.0), vec2(1.0, 8.0), vec2(0.0, 1.0), vec2(1.0, 2.0), vec2(-1.0, 3.0), vec2(1.0, 9.0), vec2(1.0, 10.0), vec2(0.0, 11.0), vec2(1.0, 12.0), vec2(1.0, 13.0));
out vec4 fragColor;
float AA, T, LYS, BELL;
vec3 LP[7]; vec3 LC[7]; float LR[7]; vec3 LW[7];
const float HZ = 236.0, FL = 420.0, HC = 2.2, KK = 924.0, ZF = 11.268;
const vec3 VARM = vec3(1.0, 0.74, 0.42);
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
float gavl(vec2 p, vec2 tp, float by, float hw){ float t = (p.y - tp.y) / (by - tp.y); return max(max(tp.y - p.y, p.y - by), (abs(p.x - tp.x) - hw * t) * 0.6); }
float rFjern(float x){ return 128.0 + 15.0 * sin(x * 0.012 + 0.4) + 7.0 * sin(x * 0.037 + 1.3) + 4.0 * vn(vec2(x * 0.09, 2.0)); }
float rNaer(float x){ return 156.0 + 8.0 * sin(x * 0.019 + 2.0) + 4.0 * sin(x * 0.061 + 0.7) + 3.0 * vn(vec2(x * 0.2, 5.0)); }
vec2 veiP(float u){ return vec2(104.0 - 124.0 * u, 165.0 + 12.0 * u + 1.5 * sin(u * 12.0)); }
vec3 bakgrunn(vec2 p, float q){
  vec3 top = mix(uSkT, uSkH, 0.18);
  vec3 c = mix(top, uSkH, pow(sat(p.y / 236.0), 1.3));
  c += vec3(0.3, 0.17, 0.07) * uNight * smoothstep(110.0, 236.0, p.y) * 0.4;
  if (q > 0.5) {
    if (uNight > 0.3 && p.y < 205.0) {
      vec2 g = p / 3.0, id = floor(g), f = fract(g) - 0.5 - (vec2(hs(id + 1.0), hs(id + 2.0)) - 0.5) * 0.6;
      float h = hs(id), st = step(0.982, h) * exp(-dot(f, f) * 40.0) * (0.55 + 0.45 * sin(T * (1.0 + h * 3.0) + h * 60.0));
      c += vec3(0.85, 0.9, 1.0) * st * (uNight - 0.3) * 1.6 * (1.0 - uRain) * (1.0 - 0.85 * uSnow) * smoothstep(215.0, 80.0, p.y);
    }
    if (uMoon > 0.0) {
      vec2 dm = p - vec2(342.0, 84.0); float r = length(dm);
      vec3 mc = vec3(0.98, 0.95, 0.86) * (0.84 + 0.16 * smoothstep(0.35, 0.65, fbm(dm * 0.25 + 3.0))) * (1.0 - 0.22 * smoothstep(4.0, 10.5, length(dm + vec2(3.0, 2.0))));
      c = mix(c, mc, cv(r - 10.5) * uMoon);
      c += vec3(0.75, 0.8, 0.85) * (0.2 * exp(-r / 16.0) + 0.07 * exp(-r / 60.0)) * uMoon;
    }
    vec2 cq = p * vec2(0.0062, 0.015) + vec2(T * 0.007, 0.0);
    float cl = fbm(cq + vec2(fbm(cq * 1.8 + vec2(0.0, T * 0.01)), 0.0) * 0.9);
    float den = smoothstep(0.46 - 0.12 * max(uRain, uSnow), 0.82, cl) * smoothstep(240.0, 150.0, p.y);
    vec3 cc = mix(top * 1.25 + 0.035, uSkH * 1.08, sat(p.y / 200.0)) + vec3(0.32, 0.2, 0.1) * uNight * sat((p.y - 40.0) / 160.0) * 0.5;
    cc += vec3(0.5, 0.52, 0.55) * 0.35 * exp(-length(p - vec2(342.0, 84.0)) / 55.0) * uMoon;
    c = mix(c, cc, den * 0.88);
  }
  float r1 = rFjern(p.x);
  if (p.y > r1 - 1.0) {
    vec3 fc = mix(mix(uSkH, vec3(0.42, 0.52, 0.56), 0.5), vec3(0.12, 0.18, 0.22), uNight * 0.85);
    fc = mix(fc, uSkH, 0.3 * (1.0 - smoothstep(r1, r1 + 30.0, p.y)));
    if (uSnow > 0.0) fc = mix(fc, vec3(0.78, 0.82, 0.88) * (1.0 - uNight * 0.55), uSnow * smoothstep(0.4, 0.6, fbm(p * vec2(0.05, 0.12))));
    c = mix(c, fc, cv(r1 - p.y));
  }
  float r2 = rNaer(p.x);
  if (p.y > r2 - 1.0) {
    vec3 hc = mix(vec3(0.28, 0.36, 0.35), vec3(0.06, 0.1, 0.12), uNight) * (0.75 + 0.45 * (q > 0.5 ? fbm(p * vec2(0.22, 0.3)) : 0.5));
    if (uSnow > 0.0) hc = mix(hc, vec3(0.7, 0.75, 0.82) * (1.0 - uNight * 0.5), uSnow * 0.55 * smoothstep(0.45, 0.6, vn(p * 0.35)));
    vec2 gg = p / vec2(5.0, 4.0), gi = floor(gg), gf = fract(gg) - 0.5;
    float on = step(0.8, hs(gi)) * smoothstep(r2 + 4.0, r2 + 8.0, p.y);
    hc += mix(VARM, vec3(0.8, 0.88, 1.0), step(0.9, hs(gi + 7.0))) * on * exp(-dot(gf, gf) * 26.0) * (0.75 + 0.25 * sin(T * (0.4 + hs(gi + 3.1)) + hs(gi) * 20.0)) * (0.1 + 0.9 * uNight);
    if (p.x < 120.0) for (int k = 0; k < 9; k++) { vec2 d = p - veiP(float(k) / 8.0); hc += vec3(1.0, 0.78, 0.5) * exp(-dot(d, d) / 1.3) * 0.9 * LYS; }
    c = mix(c, hc, cv(r2 - p.y));
  }
  if (uUt >= 0.0 && p.x < 125.0) {
    float u = sat(uUt / 9.5), fade = smoothstep(0.0, 0.05, u) * (1.0 - smoothstep(0.86, 1.0, u));
    vec2 vp = veiP(u * u * (3.0 - 2.0 * u) * 0.3 + u * 0.7), d = p - vp;
    float rr = dot(d, d);
    c += vec3(1.0, 0.92, 0.75) * (exp(-rr / 2.2) * 2.4 + exp(-rr / 46.0) * 0.55 + exp(-rr / 300.0) * 0.12) * fade;
    vec2 dt = d - vec2(3.2, 0.5); c += vec3(1.0, 0.15, 0.08) * exp(-dot(dt, dt) / 1.2) * 1.4 * fade;
    float ax = vp.x - p.x;
    if (ax > 0.0 && ax < 40.0) c += vec3(1.0, 0.9, 0.7) * exp(-pow((p.y - vp.y) / (1.2 + ax * 0.2), 2.0)) * exp(-ax / 14.0) * 0.3 * fade;
  }
  float ph = fract(T / 29.0);
  if (ph < 0.5 && p.x > 290.0) {
    float u = ph / 0.5, x = 296.0 + 110.0 * u; vec2 d = p - vec2(x, 171.0 + 8.0 * sin(x * 0.019 + 2.0) + 4.0 * sin(x * 0.061 + 0.7));
    c += vec3(1.0, 0.9, 0.72) * (exp(-dot(d, d) / 0.9) * 1.2 + exp(-dot(d, d) / 16.0) * 0.18) * LYS * smoothstep(0.0, 0.05, u) * (1.0 - smoothstep(0.9, 1.0, u));
  }
  if (q > 0.5 && p.x > 236.0 && p.x < 360.0 && p.y < 108.0) {
    float hh = (106.0 - p.y) / 106.0, cx = 256.0 + hh * hh * 60.0 + sin(hh * 5.0 - T * 0.6) * 5.0 * hh;
    float m = smoothstep(1.0, 0.2, abs(p.x - cx) / (4.0 + hh * 26.0));
    float n = fbm(vec2(p.x * 0.05 - T * 0.15, p.y * 0.05 + T * 0.5));
    float sm = smoothstep(0.35, 0.75, n) * m * (1.0 - smoothstep(0.5, 1.0, hh)) * smoothstep(0.0, 0.06, hh);
    c = mix(c, mix(vec3(0.55, 0.57, 0.6), vec3(0.3, 0.32, 0.36), uNight) + vec3(0.2, 0.12, 0.05) * uNight, sm * 0.5);
  }
  return c;
}
void hus(vec2 p, float x0, float x1, float base, float eave, float peakY, vec3 fa, float sd, float q, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  float cx = (x0 + x1) * 0.5, hw = (x1 - x0) * 0.5; vec2 tp = vec2(cx, peakY);
  float dW = min(rb(p, vec2(x0, eave), vec2(x1, base)), gavl(p, tp, eave, hw));
  float dB = gavl(p, tp - vec2(0.0, 5.0), eave + 3.0, hw + 9.0);
  float dR = gavl(p, tp - vec2(0.0, 9.5), eave + 3.5, hw + 13.0);
  float cR = cv(dR);
  if (cR > 0.0) {
    vec3 A = vec3(0.13, 0.13, 0.15) * (0.85 + 0.3 * vn(p * 0.6));
    float sn = uSnow * smoothstep(-3.2, -1.2, dR);
    alb = mix(alb, mix(A, vec3(0.88, 0.91, 0.96), sn), cR); N = mix(N, mix(vec3(0.0, 0.5, 0.85), vec3(0.0, 1.0, 0.3), sn), cR); em = mix(em, vec3(0.0), cR); lit = mix(lit, 1.0, cR); ao = mix(ao, 1.0, cR);
  }
  float cB = cv(dB);
  if (cB > 0.0) { alb = mix(alb, vec3(0.9, 0.89, 0.85), cB); N = mix(N, vec3(0.0, 0.25, 1.0), cB); em = mix(em, vec3(0.0), cB); lit = mix(lit, 1.0, cB); ao = mix(ao, 0.92, cB); }
  float c = cv(dW); if (c <= 0.0) return;
  float yb = base - p.y, f = fract(yb / 5.6), bi = floor(yb / 5.6);
  vec3 A = fa * (0.93 + 0.1 * hs(vec2(bi, sd))) * (0.95 + 0.08 * vn(vec2(p.x * 0.05 + sd * 7.0, bi)));
  if (q > 0.5) A *= 1.0 - 0.13 * smoothstep(0.55, 0.85, fbm(vec2(p.x * 0.11, p.y * 0.014) + sd));
  A *= (1.0 - 0.14 * smoothstep(base - 26.0, base, p.y)) * (1.0 - 0.1 * uRain);
  float cb = cv(min(p.x - x0, x1 - p.x) - 4.0), gt = cv(abs(p.y - eave - 1.5) - 2.2) * step(x0, p.x) * step(p.x, x1), trim = max(cb, gt);
  A = mix(A, mix(fa, vec3(0.92, 0.9, 0.86), 0.55), trim);
  float bs = 1.0 - 0.45 * (1.0 - smoothstep(0.0, 7.0, -gavl(p, tp, eave, hw))) * step(p.y, eave + 1.0);
  alb = mix(alb, A, c); N = mix(N, mix(vec3(0.0, 0.16, 1.0), vec3(0.0, 0.0, 1.0), trim), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c);
  ao = mix(ao, mix(0.62 + 0.38 * smoothstep(1.0, 0.8, f), 1.0, trim) * bs, c);
}
void vindu(vec2 p, vec2 o, vec2 sz, float on, float sd, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  vec2 o1 = o + sz;
  float d = rb(p, o - 3.0, o1 + 3.0); if (d > 10.0) return;
  ao *= 1.0 - 0.35 * cv(d - 2.5) * (1.0 - cv(d));
  float c = cv(d), g = cv(rb(p, o + 0.6, o1 - 0.6));
  vec2 u = (p - o) / sz;
  float bars = max(cv(abs(p.x - o.x - sz.x * 0.5) - 0.9), max(cv(abs(u.y - 0.333) * sz.y - 0.6), cv(abs(u.y - 0.666) * sz.y - 0.6)));
  float refl = smoothstep(0.12, 0.0, abs(u.x - u.y * 0.55 - 0.15)) * 0.25 + smoothstep(0.05, 0.0, abs(u.x - u.y * 0.55 - 0.42)) * 0.12;
  vec3 G = vec3(0.03), E = vec3(0.0);
  if (on > 0.5) {
    vec3 I = vec3(1.0, 0.78, 0.48) * (0.75 + 0.45 * (1.0 - length((u - vec2(0.5, 0.25)) * vec2(1.1, 1.4))));
    float cur = smoothstep(0.26, 0.2, u.x) + smoothstep(0.74, 0.8, u.x);
    vec3 cc = mix(vec3(0.95, 0.88, 0.74), vec3(0.85, 0.42, 0.3), step(0.5, hs(vec2(sd, 4.0)))) * (0.75 + 0.25 * sin(u.x * 60.0 + sd * 3.0));
    I = mix(I, cc * 0.85, cur * 0.9);
    float pl = length((p - vec2(o.x + sz.x * (0.32 + 0.36 * hs(vec2(sd, 1.0))), o1.y - 5.0)) * vec2(1.0, 1.2)) - 4.5 - (vn(p * 0.8) - 0.5) * 3.0;
    I = mix(I, vec3(0.16, 0.1, 0.06), cv(pl) * 0.85);
    I *= 0.94 + 0.06 * sin(T * 0.7 + sd * 5.0);
    E = I * (0.5 + 0.7 * uNight) + refl * 0.12;
  } else if (on < -0.5) {
    float fl = 0.55 + 0.45 * vn(vec2(T * 2.3, sd)) * (0.7 + 0.3 * sin(T * 13.0));
    E = mix(vec3(0.35, 0.5, 0.95), vec3(0.75, 0.8, 1.0), vn(vec2(T * 1.7, sd + 3.0))) * fl * (0.25 + 0.35 * uNight) * (0.6 + 0.4 * (1.0 - u.y)) + refl * 0.08;
  } else G = mix(mix(uSkH, uSkT, u.y) * 0.55, vec3(0.06, 0.08, 0.1), 0.45 + 0.3 * uNight) + refl * (0.5 - 0.3 * uNight);
  vec3 TR = vec3(0.93, 0.92, 0.88);
  alb = mix(alb, mix(TR, G, g * (1.0 - bars)), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, E * g * (1.0 - bars), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  float sl = cv(rb(p, vec2(o.x - 5.0, o1.y + 3.0), vec2(o1.x + 5.0, o1.y + 6.0)));
  alb = mix(alb, TR, sl); N = mix(N, vec3(0.0, 0.75, 0.66), sl); em = mix(em, vec3(0.0), sl); lit = mix(lit, 1.0, sl); ao = mix(ao, 1.0, sl);
  ao *= 1.0 - 0.4 * cv(rb(p, vec2(o.x - 5.0, o1.y + 6.0), vec2(o1.x + 5.0, o1.y + 9.5)));
  if (uSnow > 0.0) { float sn = cv(rb(p, vec2(o.x - 5.0, o1.y + 1.2), vec2(o1.x + 5.0, o1.y + 3.4))) * uSnow * step(0.25, vn(vec2(p.x * 0.4, o.y)));
    alb = mix(alb, vec3(0.9, 0.93, 0.97), sn); N = mix(N, vec3(0.0, 1.0, 0.3), sn); em = mix(em, vec3(0.0), sn); lit = mix(lit, 1.0, sn); ao = mix(ao, 1.0, sn); }
}
void kasse(vec2 p, vec2 a, vec2 b, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  if (p.x < a.x - 2.0 || p.x > b.x + 2.0 || p.y < a.y - 9.0 || p.y > b.y + 1.0) return;
  float c = cv(rb(p, a, b));
  vec3 A = vec3(0.24, 0.3, 0.2) * (0.8 + 0.3 * vn(vec2(p.x * 0.5, 1.0)));
  alb = mix(alb, A, c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 0.9, c);
  vec2 g = p / 3.2, id = floor(g), f = fract(g) - 0.5;
  float top = a.y - 1.0 - vn(vec2(p.x * 0.35, 3.0)) * 6.0;
  float leaf = cv(top - p.y) * cv(p.y - a.y - 1.0) * step(a.x + 1.0, p.x) * step(p.x, b.x - 1.0);
  float fl = step(0.55, hs(id)) * smoothstep(0.42, 0.18, length(f)) * step(p.y, a.y - 1.5);
  vec3 L = mix(vec3(0.12, 0.3, 0.14) * (0.7 + 0.5 * vn(p * 1.3)), vec3(0.78, 0.12, 0.1) * (0.85 + 0.3 * hs(id + 2.0)), fl * (1.0 - uSnow));
  L = mix(L, vec3(0.88, 0.91, 0.96), uSnow * smoothstep(0.4, 0.7, vn(p * 0.9)));
  alb = mix(alb, L, leaf); N = mix(N, normalize(vec3((vn(p) - 0.5) * 0.8, 0.6, 0.8)), leaf); em = mix(em, vec3(0.0), leaf); lit = mix(lit, 1.0, leaf); ao = mix(ao, 0.85 + 0.15 * fl, leaf);
}
void mur(vec2 p, float x0, float x1, float y0, float y1, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  float c = cv(rb(p, vec2(x0, y0), vec2(x1, y1))); if (c <= 0.0) return;
  float r = floor((y1 - p.y) / 4.0), xx = p.x + mod(r, 2.0) * 7.0; vec2 id = vec2(floor(xx / 14.0), r);
  vec2 f = vec2(mod(xx, 14.0), mod(y1 - p.y, 4.0)); float e = min(min(f.x, 14.0 - f.x), min(f.y, 4.0 - f.y)), h = smoothstep(0.1, 1.0, e);
  vec3 A = vec3(0.4, 0.4, 0.41) * (0.8 + 0.35 * hs(id)) * (0.9 + 0.2 * vn(p * 0.7));
  A = mix(vec3(0.15), A, h) * (1.0 - 0.35 * uWet);
  alb = mix(alb, A, c); N = mix(N, vec3(0.0, 0.2 * h, 1.0), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 0.6 + 0.4 * h, c);
}
void trinn(vec2 p, vec2 a, vec2 b, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  float c = cv(rb(p, a, b)); if (c <= 0.0) return;
  float topf = smoothstep(a.y + 2.4, a.y + 1.6, p.y);
  vec3 A = vec3(0.5, 0.49, 0.47) * (0.82 + 0.22 * vn(p * vec2(0.4, 1.2)) + 0.1 * hs(floor(p / 3.0))) * (1.0 - 0.35 * uWet * (1.0 - topf));
  A = mix(A, vec3(0.9, 0.93, 0.97), uSnow * topf * step(0.3, vn(vec2(p.x * 0.3, a.y))));
  alb = mix(alb, A, c); N = mix(N, mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.45), topf), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c);
  ao = mix(ao, 1.0 - 0.35 * smoothstep(b.y - 2.0, b.y, p.y), c);
}
void lykt(vec2 p, float x, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  if (abs(p.x - x) > 10.0 || p.y < 130.0 || p.y > 330.0) return;
  float w = 1.7 + smoothstep(304.0, 326.0, p.y) * 1.8, c = cv(max(abs(p.x - x) - w, max(158.0 - p.y, p.y - 328.5)));
  if (c > 0.0) { float nx = clamp((p.x - x) / w, -1.0, 1.0), ring = cv(abs(p.y - 302.0) - 1.2) + cv(abs(p.y - 172.0) - 1.0);
    alb = mix(alb, vec3(0.07, 0.075, 0.08) * (1.0 + 0.6 * ring), c); N = mix(N, vec3(nx, 0.0, sqrt(max(1.0 - nx * nx, 0.04))), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  float q = abs(p.x - x);
  float cap = max(q - (2.0 + (p.y - 134.0) * 0.9), max(134.0 - p.y, p.y - 140.0)), bot = max(q - 3.4, max(155.0 - p.y, p.y - 158.5)), fin = length(p - vec2(x, 132.6)) - 1.3;
  float dk = cv(min(min(cap, bot), fin));
  if (dk > 0.0) { float sn = uSnow * smoothstep(137.0, 135.0, p.y);
    alb = mix(alb, mix(vec3(0.06), vec3(0.9, 0.93, 0.97), sn), dk); N = mix(N, vec3(0.0, 0.6, 0.8), dk); em = mix(em, vec3(0.0), dk); lit = mix(lit, 1.0, dk); ao = mix(ao, 1.0, dk); }
  float gl = cv(max(q - (6.2 - (p.y - 140.0) * 0.14), max(140.0 - p.y, p.y - 155.0)));
  if (gl > 0.0) { float bar = cv(q - 0.5) + cv(abs(q - 4.6) - 0.45);
    alb = mix(alb, vec3(0.08), gl); em = mix(em, mix(vec3(1.0, 0.88, 0.62) * (0.4 + 2.0 * LYS) * (0.85 + 0.15 * smoothstep(155.0, 141.0, p.y)), vec3(0.05), sat(bar)), gl); lit = mix(lit, 0.0, gl); }
}
vec3 belys(vec3 P, vec3 N){
  N = normalize(N);
  vec3 s = mix(vec3(0.78, 0.82, 0.86), vec3(0.17, 0.22, 0.28), uNight) * (0.72 + 0.28 * N.y);
  for (int i = 0; i < 7; i++) { vec3 d = LP[i] - P; float l2 = dot(d, d); s += LC[i] * max(dot(N, d * inversesqrt(l2)), 0.0) / (1.0 + l2 / (LR[i] * LR[i])); }
  return s;
}
vec3 fasade(vec2 p, float q){
  vec3 alb = bakgrunn(p, q), N = vec3(0.0, 0.0, 1.0), em = vec3(0.0); float lit = 0.0, ao = 1.0, c;
  c = cv(rb(p, vec2(84.0, 210.0), vec2(94.0, 318.0))) + cv(rb(p, vec2(298.0, 186.0), vec2(308.0, 318.0)));
  alb = mix(alb, vec3(0.025, 0.03, 0.035), sat(c));
  c = cv(rb(p, vec2(248.0, 106.0), vec2(262.0, 152.0)));
  if (c > 0.0) { float r = floor(p.y / 4.0), xx = p.x + mod(r, 2.0) * 3.5; vec2 id = vec2(floor(xx / 7.0), r);
    float e = min(min(mod(xx, 7.0), 7.0 - mod(xx, 7.0)), min(mod(p.y, 4.0), 4.0 - mod(p.y, 4.0)));
    vec3 A = mix(vec3(0.5, 0.2, 0.13), vec3(0.62, 0.27, 0.17), hs(id)) * mix(0.55, 1.0, smoothstep(0.1, 0.9, e)) * mix(1.0, 0.65, smoothstep(256.0, 262.0, p.x));
    alb = mix(alb, A, c); lit = mix(lit, 1.0, c); }
  c = cv(rb(p, vec2(246.0, 102.5), vec2(264.0, 106.5)));
  if (c > 0.0) { alb = mix(alb, mix(vec3(0.12), vec3(0.9, 0.93, 0.97), uSnow * smoothstep(105.0, 103.0, p.y)), c); N = mix(N, vec3(0.0, 0.6, 0.8), c); lit = mix(lit, 1.0, c); }
  for (int k = 0; k < 3; k++) {
    if (k == 0 && p.x < 290.0) continue;
    if (k == 1 && p.x > 100.0) continue;
    float x0 = k == 0 ? 306.0 : (k == 1 ? -30.0 : 92.0), x1 = k == 0 ? 430.0 : (k == 1 ? 86.0 : 300.0);
    float ev = k == 0 ? 178.0 : (k == 1 ? 222.0 : 182.0), pk = k == 0 ? 122.0 : (k == 1 ? 168.0 : 100.0);
    vec3 fa = k == 0 ? vec3(0.66, 0.22, 0.15) : (k == 1 ? vec3(0.85, 0.6, 0.28) : vec3(0.9, 0.88, 0.82));
    hus(p, x0, x1, 318.0, ev, pk, fa, float(k) + 1.0, q, alb, N, em, lit, ao);
  }
  for (int i = 0; i < 12; i++) { vec4 wd = uWin[i]; if (abs(p.x - wd.x - wd.z * 0.5) < wd.z * 0.5 + 10.0 && abs(p.y - wd.y - wd.w * 0.5) < wd.w * 0.5 + 13.0) vindu(p, wd.xy, wd.zw, uWinM[i].x, uWinM[i].y, alb, N, em, lit, ao); }
  mur(p, -10.0, 400.0, 306.0, 318.0, alb, N, em, lit, ao);
  if (p.x > 80.0 && p.x < 312.0) {
    for (int k = 0; k < 2; k++) { float bx = k == 0 ? 110.0 : 240.0; kasse(p, vec2(bx, 289.0), vec2(bx + 40.0, 295.0), alb, N, em, lit, ao); }
    float df = rb(p, vec2(175.0, 211.0), vec2(217.0, 304.0));
    if (df < 5.0) {
      ao *= 1.0 - 0.35 * cv(df - 2.0) * (1.0 - cv(df));
      c = cv(df);
      vec3 A = vec3(0.92, 0.91, 0.87), NN = vec3(0.0, 0.0, 1.0), E = vec3(0.0);
      vec3 hall = vec3(1.0, 0.82, 0.55) * (0.1 + 0.9 * uHall) * (0.55 + 0.7 * uNight);
      float tg = cv(rb(p, vec2(180.0, 214.0), vec2(212.0, 223.0))) * (1.0 - max(cv(abs(p.x - 190.7) - 0.6), cv(abs(p.x - 201.3) - 0.6)));
      A = mix(A, vec3(0.04), tg); E += hall * tg * 0.9;
      float dl = cv(rb(p, vec2(180.0, 226.0), vec2(212.0, 304.0)));
      if (dl > 0.0) {
        vec3 D = vec3(0.1, 0.28, 0.33) * (0.9 + 0.12 * vn(p * vec2(0.3, 0.05))), DN = vec3(0.0, 0.0, 1.0);
        float gw = cv(rb(p, vec2(184.0, 230.0), vec2(208.0, 254.0))) * (1.0 - cv(abs(p.x - 196.0) - 0.9));
        float pd = min(rb(p, vec2(184.0, 260.0), vec2(194.5, 299.0)), rb(p, vec2(197.5, 260.0), vec2(208.0, 299.0)));
        float bev = cv(pd) * (1.0 - cv(pd + 1.6));
        vec2 pc = p.x < 196.0 ? vec2(189.25, 279.5) : vec2(202.75, 279.5), dr = normalize(p - pc + 0.001);
        DN = mix(DN, normalize(vec3(-dr.x * 0.6, dr.y * 0.6, 0.8)), bev); D *= mix(1.0, 0.9, cv(pd + 1.6));
        D = mix(D, vec3(0.04), gw);
        float hd = length(p - vec2(207.0, 272.0)) - 1.7;
        D = mix(D, vec3(0.78, 0.62, 0.3), cv(hd)); DN = mix(DN, normalize(vec3((p.x - 207.0) * 0.5, -(p.y - 272.0) * 0.5, 0.8)), cv(hd));
        A = mix(A, D, dl); NN = mix(NN, DN, dl); E = mix(E, hall * (0.8 + 0.2 * sin(p.y * 1.4)) * gw, dl);
      }
      alb = mix(alb, A, c); N = mix(N, NN, c); em = mix(em, E, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
    }
    float bd = length(p - vec2(222.5, 266.0)), bc = cv(bd - 2.0);
    if (bc > 0.0) { alb = mix(alb, vec3(0.7, 0.58, 0.32), bc); em = mix(em, vec3(1.0, 0.75, 0.4) * (0.15 + 1.8 * BELL) * cv(bd - 1.1), bc); lit = mix(lit, 1.0, bc); ao = mix(ao, 1.0, bc); }
    float ld = min(min(rb(p, vec2(161.5, 232.0), vec2(170.5, 235.5)) - 0.4, rb(p, vec2(163.0, 246.0), vec2(169.0, 248.5)) - 0.3), rb(p, vec2(169.0, 238.6), vec2(175.0, 240.0)));
    c = cv(ld); alb = mix(alb, vec3(0.05), c); N = mix(N, vec3(0.0, 0.5, 0.85), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
    c = cv(rb(p, vec2(162.6, 235.5), vec2(169.4, 246.0)));
    if (c > 0.0) { alb = mix(alb, vec3(0.08), c); em = mix(em, mix(vec3(1.0, 0.86, 0.58) * (0.4 + 1.8 * LYS), vec3(0.05), cv(abs(p.x - 166.0) - 0.4)), c); lit = mix(lit, 0.0, c); }
    for (int k = 0; k < 2; k++) { float e = float(k) * 6.0, y = float(k) * 7.0; trinn(p, vec2(166.0 + e, 311.0 - y), vec2(226.0 - e, 318.0 - y), alb, N, em, lit, ao); }
    if (p.x > 196.0 && p.x < 224.0 && p.y > 284.0) {
      ao *= 1.0 - 0.45 * (1.0 - smoothstep(0.0, 4.0, rb(p, vec2(201.0, 302.5), vec2(220.0, 305.5))));
      float bw = 7.6 - (304.0 - p.y) * 0.04, db = max(abs(p.x - 209.0) - bw, max(288.6 - p.y + 0.6 * sin(p.x * 2.6), p.y - 304.0));
      c = cv(db);
      if (c > 0.0) {
        vec3 A = vec3(0.62, 0.45, 0.27) * (0.85 + 0.25 * vn(p * vec2(1.2, 0.4))) * (0.8 + 0.3 * smoothstep(217.0, 202.0, p.x));
        A *= 1.0 - 0.18 * smoothstep(291.6, 290.6, p.y) - 0.25 * cv(abs(p.y - 291.8) - 0.4);
        float lr = length(p - vec2(209.0, 297.5));
        A = mix(A, mix(vec3(0.86, 0.36, 0.14), vec3(0.97, 0.84, 0.6), cv(lr - 2.0)), cv(lr - 3.4));
        alb = mix(alb, A, c); N = mix(N, normalize(vec3((p.x - 209.0) / 12.0, 0.1, 1.0)), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
      }
    }
  }
  for (int k = 0; k < 2; k++) lykt(p, k == 0 ? 48.0 : 344.0, alb, N, em, lit, ao);
  vec3 L = lit > 0.001 ? belys(vec3(p.x, -p.y, 0.0), N) : vec3(1.0);
  return mix(alb, alb * L * ao, lit) + em;
}
vec3 glow(vec2 p){
  vec3 g = vec3(0.0); vec2 d; float r2;
  d = p - vec2(48.0, 148.0); r2 = dot(d, d); g += vec3(1.0, 0.85, 0.6) * (1.2 * exp(-r2 / 34.0) + 0.3 / (1.0 + r2 / 300.0)) * LYS;
  d = p - vec2(344.0, 148.0); r2 = dot(d, d); g += vec3(1.0, 0.85, 0.6) * (1.2 * exp(-r2 / 34.0) + 0.3 / (1.0 + r2 / 300.0)) * LYS;
  d = p - vec2(166.0, 241.0); r2 = dot(d, d); g += vec3(1.0, 0.82, 0.55) * (0.9 * exp(-r2 / 14.0) + 0.22 / (1.0 + r2 / 130.0)) * LYS;
  d = p - vec2(222.5, 266.0); g += vec3(1.0, 0.7, 0.35) * exp(-dot(d, d) / 6.0) * BELL * 0.9;
  g += VARM * 0.1 * (exp(-max(rb(p, vec2(112.0, 236.0), vec2(148.0, 282.0)), 0.0) / 8.0) + exp(-max(rb(p, vec2(242.0, 236.0), vec2(278.0, 282.0)), 0.0) / 8.0)) * LYS;
  g += vec3(1.0, 0.82, 0.55) * 0.12 * uHall * exp(-max(rb(p, vec2(180.0, 214.0), vec2(212.0, 254.0)), 0.0) / 8.0) * LYS;
  return g;
}
vec2 ringer(vec2 w, float cs){
  vec2 gp = w / cs, id = floor(gp), f = fract(gp) - 0.5;
  float r1 = hs(id), ph = fract(T * (0.7 + r1 * 0.5) + r1 * 7.0);
  vec2 dv = f - (vec2(hs(id + 3.1), hs(id + 5.7)) - 0.5) * 0.5;
  float r = length(dv) + 1e-4, rad = ph * 0.45;
  return dv / r * sin((r - rad) * 60.0) * exp(-abs(r - rad) * 30.0) * (1.0 - ph) * (1.0 - ph);
}
vec3 bakke(vec2 p, vec3 W, vec3 Vd, out vec2 sL, out float rw, out float rm, out vec3 add, out float sn, out vec3 snc){
  vec2 w = W.xz;
  float det = sat((0.35 / (W.z * W.z / KK / uDpr) - 2.0) / 4.0), h = 1.0, road = 0.0, pud = 0.0, face = 0.0;
  vec3 A, N = vec3(0.0, 1.0, 0.0);
  if (W.z > 9.5) {
    float rz = (W.z - 9.5) / 0.88, row = floor(rz), rx = w.x / 1.25 + mod(row, 2.0) * 0.5;
    vec2 id = vec2(floor(rx), row), f = vec2(fract(rx), fract(rz));
    h = smoothstep(0.004, 0.03, min(min(f.x, 1.0 - f.x) * 1.25, min(f.y, 1.0 - f.y) * 0.88));
    A = vec3(0.4, 0.4, 0.41) * (0.82 + 0.3 * hs(id)) * (1.0 + 0.3 * (vn(w * 11.0) - 0.5) * det);
    A = mix(vec3(0.1), A, mix(1.0, h, det * 0.8 + 0.2));
    pud = smoothstep(0.6, 0.72, fbm(w * vec2(0.6, 1.4) + 9.0)) * uWet * 0.8;
  } else if (W.z > 9.36) {
    float u = w.x / 1.5; h = smoothstep(0.5, 0.47, abs(fract(u) - 0.5));
    A = vec3(0.54, 0.54, 0.52) * (0.85 + 0.2 * hs(vec2(floor(u), 4.0))) * mix(0.4, 1.0, h);
  } else if (W.z > 8.88) {
    face = 1.0; float u = w.x / 1.5; h = smoothstep(0.5, 0.47, abs(fract(u) - 0.5));
    A = vec3(0.4, 0.4, 0.39) * (0.85 + 0.2 * hs(vec2(floor(u), 4.0))) * mix(0.4, 1.0, h) * (1.0 - 0.3 * uWet);
    N = vec3(0.0, 0.05, -1.0);
  } else {
    road = 1.0;
    A = vec3(0.16, 0.165, 0.175) * (0.86 + 0.3 * (vn(w * 34.0) - 0.5) * det + 0.16 * (fbm(w * 0.7) - 0.5));
    A = mix(A, vec3(0.12, 0.125, 0.135), smoothstep(0.6, 0.64, fbm(w * 0.32 + 2.0)) * 0.8);
    A *= 1.0 - 0.5 * (1.0 - smoothstep(0.0, 0.012, abs(fbm(w * 0.9 + 5.0) - 0.5))) * det;
    vec2 mh = w - vec2(-0.9, 7.0); float mr = length(mh);
    if (mr < 0.4) A = mix(A, vec3(0.13, 0.12, 0.11) * (0.8 + 0.35 * step(0.5, fract((mh.x + mh.y) * 9.0)) * smoothstep(0.36, 0.34, mr)), smoothstep(0.39, 0.36, mr));
    vec2 dg = w - vec2(-2.7, 8.7); if (abs(dg.x) < 0.35 && abs(dg.y) < 0.14) A = mix(vec3(0.03), vec3(0.2, 0.2, 0.21), step(0.5, fract(dg.x * 14.0)));
    pud = max(smoothstep(0.52, 0.64, fbm(w * vec2(0.42, 0.9) + 3.0)), smoothstep(8.5, 8.85, W.z) * 0.7) * uWet;
  }
  vec3 Np = vec3(0.0, 1.0, 0.0);
  if (uRain > 0.0 && face < 0.5) { vec2 rg = (ringer(w, 0.42) * 0.5 + ringer(w + 0.21, 0.7) * 0.35) * uRain; Np = normalize(vec3(-rg.x, 1.0, -rg.y)); }
  vec2 mg = (vec2(vn(w * vec2(3.0, 9.0)), vn(w * vec2(3.0, 9.0) + 7.0)) - 0.5) * 0.09 * road;
  vec3 Ns = face > 0.5 ? N : normalize(mix(normalize(vec3(mg.x, 1.0, mg.y)), Np, max(pud, 0.5 * uRain)));
  vec3 V = -Vd, dif = mix(vec3(0.7, 0.74, 0.78), vec3(0.13, 0.17, 0.21), uNight) * (0.7 + 0.3 * abs(Ns.y)), sp = vec3(0.0);
  float shin = mix(30.0, 160.0, uWet);
  for (int i = 0; i < 7; i++) {
    vec3 dd = LW[i] - W; float l2 = dot(dd, dd); vec3 L = dd * inversesqrt(l2);
    float k = 1.0, at = 1.0 / (1.0 + l2 / 14.0);
    if (i == 5) { k = smoothstep(0.78, 0.95, -dd.x / max(length(dd.xz), 0.001)) * 2.6; at = 1.0 / (1.0 + l2 / 40.0); }
    dif += LC[i] * max(dot(Ns, L), 0.0) * at * k;
    sp += LC[i] * pow(max(dot(Ns, normalize(L + V)), 0.0), shin) * at * shin * 0.02 * k;
  }
  vec3 R = reflect(Vd, Ns);
  float F = 0.02 + 0.98 * pow(1.0 - max(dot(Ns, V), 0.0), 5.0);
  vec3 col = A * dif * (0.55 + 0.45 * h) + sp * (0.25 + 0.75 * uWet);
  sL = vec2(-9999.0); rw = 0.0; rm = mix(0.7, 1.0, pud); add = vec3(0.0); sn = 0.0; snc = vec3(0.0);
  if (face < 0.5) {
    rw = sat(mix(0.35 * uWet, 1.0, pud) * F * 2.4);
    if (R.z > 0.02 && R.y > 0.0) { float t = (ZF - W.z) / R.z; vec3 H = W + R * t; sL = vec2(195.0 + FL * H.x / ZF, min(HZ + FL * (HC - H.y) / ZF, 317.0)); }
    for (int i = 5; i < 7; i++) add += LC[i] * pow(max(dot(R, normalize(LW[i] - W)), 0.0), mix(60.0, 900.0, uWet)) * (2.0 + 6.0 * pud) * uWet;
  }
  if (uSnow > 0.0) {
    sn = uSnow * smoothstep(0.3, 0.6, fbm(w * vec2(0.9, 1.5) + 2.0) * 0.9 + (1.0 - road) * 0.35 - pud * 0.4) * (road > 0.5 ? 0.65 : 1.0) * (1.0 - face * 0.6);
    snc = vec3(0.86, 0.89, 0.94) * (dif * 0.85 + 0.06);
  }
  return col;
}
float kjegle(vec2 p, vec2 l){
  float cy = p.y - l.y; if (cy < 0.0 || cy > 190.0) return 0.0;
  return pow(sat(1.0 - abs(p.x - l.x) / (5.0 + cy * 0.5)), 1.6) * smoothstep(0.0, 6.0, cy) * (1.0 - smoothstep(110.0, 185.0, cy));
}
float regn(vec2 p, float cw, float spd, float len, float sd){
  vec2 r = vec2(p.x + p.y * 0.16, p.y);
  float ci = floor(r.x / cw), lx = abs(fract(r.x / cw) - 0.5) * cw, h1 = hs(vec2(ci, sd)), per = 140.0 + h1 * 120.0;
  float ph = fract((r.y - T * spd * (0.85 + h1 * 0.3)) / per + hs(vec2(ci, sd + 3.0))), lp = len / per;
  return (1.0 - smoothstep(0.0, 0.55, lx)) * smoothstep(0.0, lp * 0.3, ph) * (1.0 - smoothstep(lp * 0.3, lp, ph)) * step(0.5, hs(vec2(ci, sd + 9.0)));
}
float sno(vec2 p, float sz, float spd, float sd){
  vec2 q = p / sz; q.y -= T * spd / sz; q.x += T * 0.22 + sin(q.y * 0.7 + sd + T * 0.6) * 0.3;
  vec2 id = floor(q), f = fract(q) - 0.5; float h = hs(id + sd);
  float d = length(f - (vec2(hs(id + sd + 1.3), hs(id + sd + 2.7)) - 0.5) * 0.55), r = 0.045 + h * 0.05;
  return smoothstep(r, r * 0.2, d) * step(0.42, h) * (0.75 + 0.25 * sin(T * 3.0 + h * 40.0));
}
vec3 tm(vec3 c){ vec3 k = max(c - 0.62, 0.0); return min(c, 0.62) + 0.38 * (1.0 - exp(-k / 0.38)); }
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  AA = 0.7 / uDpr; T = uT; LYS = 0.3 + 0.7 * uNight;
  BELL = smoothstep(0.55, 0.7, uAge) * (1.0 - smoothstep(1.8, 2.3, uAge)) * (0.7 + 0.3 * sin(uAge * 40.0));
  LP[0] = vec3(48.0, -148.0, 30.0); LC[0] = vec3(1.0, 0.82, 0.55) * LYS; LR[0] = 120.0;
  LP[1] = vec3(344.0, -148.0, 30.0); LC[1] = LC[0]; LR[1] = 120.0;
  LP[2] = vec3(166.0, -241.0, 12.0); LC[2] = VARM * 1.1 * LYS; LR[2] = 50.0;
  LP[3] = vec3(196.0, -246.0, 8.0); LC[3] = vec3(1.0, 0.8, 0.52) * 0.55 * uHall * (0.4 + 0.6 * uNight); LR[3] = 46.0;
  LP[4] = vec3(258.0, -262.0, 10.0); LC[4] = VARM * 0.32 * (0.3 + 0.7 * uNight); LR[4] = 60.0;
  LP[5] = vec3(uVA.x, -uVA.y, 100.0); LC[5] = vec3(1.0, 0.93, 0.8) * 1.4 * uVC.x; LR[5] = 70.0;
  LP[6] = vec3(uVA.z, -uVA.w, 100.0); LC[6] = vec3(1.0, 0.12, 0.06) * 0.7 * uVC.x; LR[6] = 30.0;
  LW[0] = vec3(-147.0 * 10.0 / FL, HC + 88.0 * 10.0 / FL, 10.0);
  LW[1] = vec3(149.0 * 10.0 / FL, HC + 88.0 * 10.0 / FL, 10.0);
  LW[2] = vec3(-29.0 * 11.0 / FL, HC - 5.0 * 11.0 / FL, 11.0);
  LW[3] = vec3(0.0, HC - 10.0 * 11.1 / FL, 11.1);
  LW[4] = vec3(63.0 * 11.1 / FL, HC - 26.0 * 11.1 / FL, 11.1);
  LW[5] = vec3((uVA.x - 195.0) * 8.6 / FL, HC - (uVA.y - HZ) * 8.6 / FL, 8.6);
  LW[6] = vec3((uVA.z - 195.0) * 8.6 / FL, HC - (uVA.w - HZ) * 8.6 / FL, 8.6);
  vec3 col = vec3(0.0), add = vec3(0.0), snc = vec3(0.0); vec2 sL = p; float rw = 0.0, rm = 1.0, sn = 0.0, gr = step(318.0, p.y);
  if (gr > 0.5) { float Z = KK / (p.y - HZ); vec3 W = vec3((p.x - 195.0) * Z / FL, 0.0, Z); col = bakke(p, W, normalize(vec3(W.x, -HC, Z)), sL, rw, rm, add, sn, snc); }
  vec3 Fc = uSkH * 0.4;
  if (gr < 0.5 || (rw > 0.004 && sL.y > -9000.0)) {
    if (gr > 0.5) AA = 1.4;
    Fc = fasade(sL, 1.0 - gr);
    if (gr > 0.5) { Fc += glow(sL) * 1.1; AA = 0.7 / uDpr; }
  }
  col = gr < 0.5 ? Fc : mix(mix(col, Fc * rm, rw) + add, snc, sn);
  if (uVC.z > 0.5) { vec2 d = (p - vec2((uVB.y + uVB.z) * 0.5, uVB.x)) / vec2(uVC.w * 0.4, 4.0); col *= 1.0 - 0.62 * exp(-dot(d, d) * 1.4); }
  if (uAe.w > 0.0) { vec2 d = (p - uAe.xy) / vec2(uAe.z * 0.24, 2.6); col *= 1.0 - 0.55 * uAe.w * exp(-dot(d, d)); }
  vec3 G0 = glow(p); col += G0;
  float cone = kjegle(p, vec2(48.0, 156.0)) + kjegle(p, vec2(344.0, 156.0));
  col += vec3(1.0, 0.84, 0.58) * cone * (0.03 + 0.16 * max(uRain, uSnow)) * LYS * (0.7 + 0.5 * fbm(vec2(p.x * 0.05, p.y * 0.03 - T * 0.25)));
  if (p.x > 190.0 && p.x < 234.0 && p.y > 236.0 && p.y < 290.0) {
    float hh = (289.0 - p.y) / 48.0, cx = 209.0 + sin(hh * 4.0 - T * 0.9) * 3.0 * hh + hh * 5.0;
    float st = smoothstep(0.42, 0.78, fbm(vec2(p.x * 0.12, p.y * 0.09 + T * 0.7))) * smoothstep(1.0, 0.2, abs(p.x - cx) / (2.5 + hh * 9.0)) * smoothstep(0.0, 0.08, hh) * (1.0 - smoothstep(0.5, 1.0, hh));
    col = mix(col, vec3(0.9, 0.9, 0.92) * (0.35 + 0.5 * LYS) + VARM * 0.15, st * 0.32);
  }
  if (uVB.w > 25.0 && uWet > 0.2 && p.y > 318.0) {
    float sp = sat(uVB.w / 220.0);
    for (int k = 0; k < 2; k++) {
      vec2 d = p - vec2(k == 0 ? uVB.y : uVB.z, uVB.x);
      if (d.x > -3.0 && d.x < 48.0 && d.y < 3.0 && d.y > -24.0) {
        float env = exp(-d.x / (10.0 + 18.0 * sp)) * smoothstep(-24.0, -2.0, d.y + d.x * 0.25) * smoothstep(3.0, 0.0, d.y);
        vec2 g = vec2(d.x - T * uVB.w * 0.5, d.y + T * 40.0) / 2.0, id = floor(g), f = fract(g) - 0.5;
        float a = (smoothstep(0.35, 0.8, fbm(vec2(d.x * 0.18 - T * 3.0, d.y * 0.25 + T * 1.5))) * 0.35 + step(0.82, hs(id)) * smoothstep(0.32, 0.08, length(f)) * 0.6) * env * sp * uWet;
        col = mix(col, vec3(0.78, 0.82, 0.86) * (0.35 + 0.65 * LYS) + G0 * 0.5, sat(a));
      }
    }
  }
  if (uVC.x > 0.0) {
    float ax = uVA.x - p.x;
    if (ax > 0.0) { float b = exp(-pow((p.y - uVA.y - ax * 0.05) / (2.0 + ax * 0.22), 2.0)) * exp(-ax / 140.0) * smoothstep(0.0, 6.0, ax);
      col += vec3(1.0, 0.92, 0.78) * b * (0.05 + 0.24 * max(uRain, uSnow * 0.8)) * uVC.x * (0.7 + 0.3 * fbm(vec2(p.x * 0.05 + T * 0.4, p.y * 0.08))); }
  }
  if (uRain > 0.0) { float r = regn(p, 4.0, 520.0, 14.0, 1.0) * 0.3 + regn(p, 7.0, 760.0, 24.0, 7.0) * 0.45 + regn(p, 11.0, 1000.0, 40.0, 13.0) * 0.6;
    col += (vec3(0.7, 0.78, 0.82) * (0.12 + 0.35 * (1.0 - uNight)) + G0 * 2.0 + cone * 1.6 * LYS) * r * uRain; }
  if (uSnow > 0.0) { float s = sno(p, 13.0, 20.0, 1.0) * 0.5 + sno(p, 22.0, 32.0, 5.0) * 0.75 + sno(p, 38.0, 52.0, 9.0);
    col = mix(col, vec3(0.92, 0.95, 1.0) * (0.62 + 0.35 * (1.0 - uNight)) + G0 * 2.2 + cone * 2.4 * LYS, sat(s) * uSnow); }
  vec2 vq = p / vec2(390.0, 420.0) - vec2(0.5, 0.45);
  col *= 1.0 - 0.3 * smoothstep(0.34, 0.82, length(vq * vec2(1.1, 0.95)));
  col = tm(max(col, 0.0)) + (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.018;
  fragColor = vec4(col, 1.0);
}
