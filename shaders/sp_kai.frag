// Sporing · Bekreftet — the Launch prototype's own WebGL scene (`spGlInit / spGlTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: the quay at Bryggen: the shop front, the awning, the string lights, the wet cobbles and the rain.
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
uniform float uSunset;
uniform vec3 uSkT;
uniform vec3 uSkH;
uniform vec3 uBoat;
out vec4 fragColor;
float AA, T, LYS, LF;
vec2 BL[5]; float BF[5];
vec3 LP[9]; vec3 LC[9]; float LR[9]; vec3 LW[9];
const float HZ = 220.0, FL = 420.0, HC = 2.2048, KK = 926.0, ZF = 11.872;
const vec3 VARM = vec3(1.0, 0.74, 0.42);
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
float tak(vec2 p, vec2 tp, float by, float hw){ float t = (p.y - tp.y) / (by - tp.y); return max(max(tp.y - p.y, p.y - by), (abs(p.x - tp.x) - hw * t) * 0.5); }
float bue(vec2 p, vec2 c, float r, float by){ if (p.y < c.y) return length(p - c) - r; return max(abs(p.x - c.x) - r, p.y - by); }
float wireY(float x){ float t = clamp((x - 40.0) / 330.0, 0.0, 1.0), u = 1.0 - t; float sw = sin(T * 0.8) * 1.4 + sin(T * 1.7 + 1.0) * 0.5;
  return u * u * u * 92.0 + 3.0 * u * u * t * (120.0 + sw) + 3.0 * u * t * t * (120.0 + sw) + t * t * t * 90.0; }
float murH(vec2 p, out vec2 id){ float r = floor(p.y / 5.5); float x = p.x + mod(r, 2.0) * 6.0; id = vec2(floor(x / 12.0), r);
  vec2 f = vec2(mod(x, 12.0), mod(p.y, 5.5)); float e = min(min(f.x, 12.0 - f.x), min(f.y, 5.5 - f.y));
  return smoothstep(0.2, 1.3, e) * (0.85 + 0.15 * hs(id)) + (vn(p * 1.3) - 0.5) * 0.16; }
float bordH(float x){ float f = mod(x, 8.0); return smoothstep(0.0, 1.0, f) * smoothstep(8.0, 7.2, f) * (0.55 + 0.45 * f / 8.0); }
vec3 belys(vec3 P, vec3 N){
  N = normalize(N);
  vec3 s = mix(vec3(0.8, 0.84, 0.88), vec3(0.19, 0.25, 0.3), uNight) * (0.72 + 0.28 * N.y);
  for (int i = 0; i < 9; i++) { vec3 d = LP[i] - P; float l2 = dot(d, d); s += LC[i] * max(dot(N, d * inversesqrt(l2)), 0.0) / (1.0 + l2 / (LR[i] * LR[i])); }
  return s;
}
void vindu(vec2 p, vec2 o, float on, vec3 fr, inout vec3 alb, inout vec3 N, inout vec3 em, inout float lit, inout float ao){
  float d = rb(p, o - 2.0, o + vec2(22.0, 28.0)); if (d > 4.0) return;
  float c = cv(d);
  vec2 u = (p - o) / vec2(20.0, 26.0);
  float g = cv(rb(p, o + 0.7, o + vec2(19.3, 25.3)));
  g *= 1.0 - max(cv(abs(p.x - o.x - 10.0) - 0.7), cv(abs(p.y - o.y - 11.0) - 0.7));
  vec3 G, E = vec3(0.0);
  float sh = smoothstep(0.09, 0.0, abs(u.x - u.y * 0.6 - 0.12)) * 0.22;
  if (on > 0.5) {
    G = vec3(1.0, 0.8, 0.5) * (0.72 + 0.5 * (1.0 - length((u - vec2(0.55, 0.3)) * vec2(1.0, 1.4))));
    G = mix(G, vec3(0.9, 0.5, 0.32) * 0.75, (smoothstep(0.26, 0.2, u.x) + smoothstep(0.74, 0.8, u.x)) * 0.7);
    G *= 0.92 + 0.08 * sin(T * 0.9 + o.x * 0.3) * sin(T * 2.3 + o.y);
    E = (G * (0.45 + 0.75 * uNight) + sh * 0.25) * g;
    G = vec3(0.04);
  } else G = mix(vec3(0.24, 0.31, 0.36), vec3(0.08, 0.11, 0.14), u.y) * (1.0 - 0.35 * uNight) + sh;
  alb = mix(alb, mix(fr, G, g), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, E, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  float sl = cv(rb(p, vec2(o.x - 3.0, o.y + 26.0), vec2(o.x + 23.0, o.y + 29.0)));
  alb = mix(alb, fr * 1.15, sl); N = mix(N, vec3(0.0, 0.7, 0.7), sl); em = mix(em, vec3(0.0), sl); lit = mix(lit, 1.0, sl); ao = mix(ao, 1.0, sl);
  if (uSnow > 0.0) { float sn = cv(rb(p, vec2(o.x - 3.0, o.y + 24.4), vec2(o.x + 23.0, o.y + 26.4))) * uSnow * step(0.22, vn(vec2(p.x * 0.4, o.y)));
    alb = mix(alb, vec3(0.9, 0.93, 0.97), sn); N = mix(N, vec3(0.0, 1.0, 0.25), sn); em = mix(em, vec3(0.0), sn); lit = mix(lit, 1.0, sn); ao = mix(ao, 1.0, sn); }
  ao *= 1.0 - 0.4 * cv(d - 1.8) * (1.0 - c);
}
void treHus(vec2 p, vec2 a, vec2 b, vec3 fa, float sv, float ty, float q, inout vec3 alb, inout vec3 N, inout float lit, inout float ao){
  float c = cv(rb(p, a, b)); if (c <= 0.0) return;
  float x = p.x - a.x, h = bordH(x), bi = floor(x / 8.0);
  vec3 A = fa * (0.9 + 0.14 * hs(vec2(bi, a.x))) * (0.93 + 0.1 * vn(vec2(bi * 5.0, p.y * 0.06)));
  if (q > 0.5) A = mix(A, fa * vec3(0.62, 0.55, 0.5), smoothstep(0.62, 0.86, fbm(p * vec2(0.07, 0.025) + a.x)) * 0.5);
  A *= 1.0 - 0.28 * smoothstep(b.y - 34.0, b.y, p.y);
  A *= 1.0 - 0.34 * (sv > 0.0 ? smoothstep(b.x - 16.0, b.x, p.x) : smoothstep(a.x + 16.0, a.x, p.x));
  A *= 1.0 - 0.12 * uRain;
  float tr = cv(abs(p.y - ty) - 1.6); A = mix(A, fa * 0.74, tr);
  vec3 NN = vec3(0.0, 0.0, 1.0);
  if (q > 0.5) { float h2 = bordH(x + 0.5); NN = vec3(-(h2 - h) * 3.0, tr * 0.6, 1.0); }
  alb = mix(alb, A, c); N = mix(N, NN, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); ao *= mix(1.0, 0.62 + 0.38 * h, c);
}
void takFlate(vec2 p, vec2 tp, float by, float hw, vec3 fa, inout vec3 alb, inout vec3 N, inout float lit, inout float ao){
  float d = tak(p, tp, by, hw), c = cv(d); if (c <= 0.0) return;
  float ry = p.y - tp.y, row = floor(ry / 4.6), fy = fract(ry / 4.6);
  float xx = p.x + mod(row, 2.0) * 4.0, ti = floor(xx / 8.0), fx = fract(xx / 8.0);
  vec3 A = fa * (0.75 + 0.45 * hs(vec2(ti, row + tp.x)));
  float hh = fy * smoothstep(0.0, 0.1, fx) * smoothstep(1.0, 0.9, fx);
  vec3 NN = vec3(sign(p.x - tp.x) * 0.45, 0.45 + (fy - 0.5) * 0.9, 0.75);
  float vg = smoothstep(-3.2, -0.8, d); A = mix(A, fa * 0.5, vg);
  float sn = uSnow * smoothstep(0.35, 0.6, vn(p * vec2(0.11, 0.3)) * 0.55 + 0.3 + fy * 0.3 - vg * 0.3);
  A = mix(A, vec3(0.86, 0.9, 0.95), sn); NN = mix(NN, vec3(0.0, 1.0, 0.35), sn);
  alb = mix(alb, A, c); N = mix(N, NN, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); ao *= mix(1.0, 0.55 + 0.45 * hh + sn * 0.3, c);
}
vec3 fasade(vec2 p, float q){
  vec3 N = vec3(0.0, 0.0, 1.0), em = vec3(0.0); float lit = 0.0, ao = 1.0, d, c;
  vec3 alb = mix(uSkT, uSkH, sat((p.y + 40.0) / 220.0));
  bool occ = (p.x > 95.0 && p.x < 297.0 && p.y > 90.0) || (p.x < 87.0 && p.y > 154.0) || (p.x > 303.0 && p.y > 162.0);
  if (!occ) {
    if (q > 0.5 && p.y < 175.0) {
      vec2 cq = p * vec2(0.0075, 0.016) + vec2(T * 0.006, 0.0);
      float cl = fbm(cq + vec2(fbm(cq * 1.9 + T * 0.012), 0.0) * 0.9);
      vec3 cc = mix(uSkT * 1.1 + 0.05, uSkH, sat((p.y + 10.0) / 180.0)) + vec3(0.22, 0.12, 0.04) * uNight * sat(p.y / 160.0);
      alb = mix(alb, cc, smoothstep(0.42, 0.8, cl) * 0.8);
    }
    float r1 = 118.0 - 22.0 * sin(p.x * 0.011 + 0.6) - 8.0 * sin(p.x * 0.033 + 2.0) - 5.0 * vn(vec2(p.x * 0.06, 0.0));
    alb = mix(alb, mix(mix(uSkH, vec3(0.45, 0.55, 0.58), 0.55), vec3(0.17, 0.25, 0.29), uNight * 0.85), cv(r1 - p.y));
    float r2 = 146.0 - 16.0 * sin(p.x * 0.017 + 2.4) - 4.0 * vn(vec2(p.x * 0.12, 3.0)), ih = cv(r2 - p.y);
    if (ih > 0.0) {
      vec3 hc = mix(vec3(0.3, 0.4, 0.38), vec3(0.08, 0.14, 0.15), uNight) * (0.7 + 0.55 * (q > 0.5 ? fbm(p * vec2(0.25, 0.35)) : 0.5));
      vec2 gg = p / vec2(6.0, 4.6), gi = floor(gg), gf = fract(gg) - 0.5;
      float on = step(0.78, hs(gi)) * smoothstep(r2 + 3.0, r2 + 7.0, p.y);
      hc += mix(VARM, vec3(0.8, 0.88, 1.0), step(0.92, hs(gi + 7.0))) * on * exp(-dot(gf, gf) * 30.0) * (0.75 + 0.25 * sin(T * (0.5 + hs(gi + 3.1) * 1.4) + hs(gi) * 20.0)) * (0.15 + 0.95 * uNight);
      alb = mix(alb, hc, ih);
    }
    float fb = smoothstep(100.0, 135.0, p.y) * (1.0 - smoothstep(148.0, 175.0, p.y));
    if (q > 0.5) fb *= 0.4 + 0.6 * smoothstep(0.3, 0.75, fbm(vec2(p.x * 0.012 - T * 0.025, p.y * 0.06)));
    alb = mix(alb, mix(uSkH, vec3(0.55, 0.62, 0.66), 0.4), fb * 0.6);
  }
  c = cv(rb(p, vec2(86.0, 150.0), vec2(96.0, 300.0))); alb = mix(alb, vec3(0.04, 0.06, 0.07), c);
  treHus(p, vec2(-8.0, 150.0), vec2(90.0, 300.0), vec3(0.86, 0.66, 0.33), 1.0, 222.0, q, alb, N, lit, ao);
  treHus(p, vec2(300.0, 158.0), vec2(402.0, 300.0), vec3(0.93, 0.9, 0.84), -1.0, 226.0, q, alb, N, lit, ao);
  if (p.x < 100.0 && p.y > 170.0) { vec3 fr = vec3(0.48, 0.35, 0.23);
    vindu(p, vec2(12.0, 184.0), 1.0, fr, alb, N, em, lit, ao); vindu(p, vec2(52.0, 184.0), 1.0, fr, alb, N, em, lit, ao);
    vindu(p, vec2(12.0, 236.0), 0.0, fr, alb, N, em, lit, ao); vindu(p, vec2(52.0, 236.0), 1.0, fr, alb, N, em, lit, ao); }
  if (p.x > 300.0 && p.y > 175.0) { vec3 fr = vec3(0.43, 0.35, 0.28);
    vindu(p, vec2(318.0, 188.0), 1.0, fr, alb, N, em, lit, ao); vindu(p, vec2(360.0, 188.0), 0.0, fr, alb, N, em, lit, ao);
    vindu(p, vec2(318.0, 240.0), 1.0, fr, alb, N, em, lit, ao); vindu(p, vec2(360.0, 240.0), 1.0, fr, alb, N, em, lit, ao); }
  takFlate(p, vec2(42.0, 92.0), 153.0, 57.0, vec3(0.3, 0.22, 0.17), alb, N, lit, ao);
  takFlate(p, vec2(350.0, 104.0), 161.0, 57.0, vec3(0.36, 0.2, 0.14), alb, N, lit, ao);
  c = cv(rb(p, vec2(92.0, 86.0), vec2(300.0, 300.0)));
  if (c > 0.0) {
    vec2 id; float h = murH(p, id);
    vec3 A = mix(vec3(0.6, 0.24, 0.15), vec3(0.76, 0.35, 0.22), hs(id));
    A = mix(A, vec3(0.42, 0.17, 0.11), step(0.88, hs(id + 4.0)) * 0.7);
    A = mix(vec3(0.42, 0.38, 0.35), A, smoothstep(0.15, 0.6, h));
    A *= (1.0 - 0.34 * exp(-(p.y - 88.0) / 16.0)) * (1.0 - 0.22 * smoothstep(272.0, 300.0, p.y)) * (1.0 - 0.1 * uRain);
    A *= mix(1.0, 0.42, smoothstep(295.0, 297.5, p.x));
    float pl = cv(rb(p, vec2(92.0, 289.0), vec2(300.0, 300.0)));
    A = mix(A, vec3(0.44, 0.44, 0.43) * (0.85 + 0.25 * hs(vec2(floor(p.x / 18.0), 3.0))) * (1.0 - 0.5 * cv(abs(mod(p.x, 18.0) - 9.0) - 8.4)), pl);
    vec3 NN = vec3(0.0, 0.0, 1.0);
    if (q > 0.5) { vec2 i2; float hx = murH(p + vec2(0.6, 0.0), i2), hy = murH(p + vec2(0.0, 0.6), i2); NN = vec3(-(hx - h) * 2.2, (hy - h) * 2.2 + pl * 0.3, 1.0); }
    float aw = smoothstep(96.0, 104.0, p.x) * smoothstep(292.0, 284.0, p.x) * smoothstep(163.0, 167.0, p.y) * (1.0 - smoothstep(170.0, 202.0, p.y));
    alb = mix(alb, A, c); N = mix(N, NN, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); ao *= mix(1.0, (0.55 + 0.45 * smoothstep(0.0, 0.7, max(h, pl))) * (1.0 - 0.5 * aw), c);
  }
  takFlate(p, vec2(194.0, 18.0), 87.0, 118.0, vec3(0.22, 0.17, 0.15), alb, N, lit, ao);
  c = cv(rb(p, vec2(82.0, 84.0), vec2(306.0, 91.0)));
  if (c > 0.0) { vec3 A = vec3(0.2, 0.13, 0.09) * (0.9 + 0.2 * vn(vec2(p.x * 0.3, 1.0)));
    float sn = uSnow * cv(84.0 + 1.8 - p.y + (vn(vec2(p.x * 0.3, 2.0)) - 0.5) * 1.6) ; A = mix(A, vec3(0.9, 0.93, 0.97), sn);
    alb = mix(alb, A, c); N = mix(N, mix(vec3(0.0, -0.55, 0.85), vec3(0.0, 1.0, 0.3), sn), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(rb(p, vec2(242.0, -14.0), vec2(260.0, 30.0)));
  if (c > 0.0) { vec2 id; float h = murH(p * 0.9, id); alb = mix(alb, vec3(0.3, 0.24, 0.22) * (0.7 + 0.4 * h) * mix(1.0, 0.6, smoothstep(254.0, 260.0, p.x)), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(rb(p, vec2(123.0, 103.0), vec2(265.0, 143.0)) - 2.0);
  if (c > 0.0) { float inn = cv(rb(p, vec2(126.0, 106.0), vec2(262.0, 140.0)) - 1.0);
    alb = mix(alb, mix(vec3(0.48, 0.23, 0.13), vec3(0.06), inn), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, vec3(1.0, 0.98, 0.93) * (0.75 + 0.35 * uNight) * inn, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  if (p.y > 139.0 && p.y < 178.0 && p.x > 90.0 && p.x < 298.0) {
    float t = sat((p.y - 142.0) / 22.0), x0 = 100.0 - 6.0 * t, x1 = 288.0 + 6.0 * t;
    float u = (p.x - x0) / (x1 - x0) * 188.0;
    float wv = sin(u * 0.05 + T * 1.3) * 0.6 + sin(u * 0.13 - T * 2.1) * 0.35, yb = 164.0 + wv * 0.7;
    float inA = cv(max(max(142.0 - p.y, p.y - yb), max(x0 - p.x, p.x - x1)));
    float st = mod(floor(u / 20.0), 2.0);
    float sx = mod(u, 20.0);
    vec3 A = mix(vec3(0.8, 0.12, 0.07), vec3(0.97, 0.93, 0.86), st) * (0.78 + 0.3 * (1.0 - t)) * (0.9 + 0.1 * sin(sx * 0.157));
    A *= 1.0 - 0.35 * (smoothstep(1.2, 0.0, sx) + smoothstep(18.8, 20.0, sx)) - 0.3 * smoothstep(144.5, 142.0, p.y);
    float sn = uSnow * cv(p.y - 145.5 - (vn(vec2(u * 0.3, 4.0)) - 0.5) * 2.0); A = mix(A, vec3(0.9, 0.93, 0.97), sn);
    vec3 NN = normalize(vec3(cos(u * 0.314) * 0.22 + wv * 0.1, 0.72, 0.62));
    alb = mix(alb, A, inA); N = mix(N, NN, inA); em = mix(em, vec3(0.0), inA); lit = mix(lit, 1.0, inA); ao = mix(ao, 1.0, inA); ao *= mix(1.0, 0.85 + 0.15 * (1.0 - t), inA);
    float ux = mod(u, 20.0) - 10.0, sd = length(vec2(ux, p.y - yb)) - 9.4;
    float inS = cv(max(sd, yb - p.y)) * step(0.0, u) * step(u, 188.0);
    alb = mix(alb, mix(vec3(0.8, 0.12, 0.07), vec3(0.97, 0.93, 0.86), st) * (0.72 - 0.25 * smoothstep(6.0, 9.4, sd + 9.4)), inS); N = mix(N, vec3(0.0, -0.15, 1.0), inS); em = mix(em, vec3(0.0), inS); lit = mix(lit, 1.0, inS); ao = mix(ao, 1.0, inS);
  }
  d = rb(p, vec2(110.0, 180.0), vec2(206.0, 286.0));
  if (d < 3.0) {
    c = cv(d);
    float g = cv(rb(p, vec2(114.0, 184.0), vec2(202.0, 282.0)));
    vec2 u = (p - vec2(114.0, 184.0)) / vec2(88.0, 98.0);
    vec3 I = mix(vec3(1.0, 0.86, 0.6), vec3(0.86, 0.6, 0.34), u.y) * (0.9 + 0.25 * (1.0 - length((u - vec2(0.5, 0.25)) * vec2(1.2, 1.0))));
    I *= 0.95 + 0.05 * step(0.5, fract(p.x / 8.0 + step(0.5, fract(p.y / 8.0)) * 0.5));
    for (int k = 0; k < 5; k++) { float fk = float(k), bx = 126.0 + fk * 14.5, top = 194.0 + hs(vec2(fk, 2.0)) * 5.0;
      float bd = min(rb(p, vec2(bx - 3.6, top + 5.0), vec2(bx + 3.6, 210.0)) - 1.0, rb(p, vec2(bx - 1.3, top), vec2(bx + 1.3, top + 6.0)));
      vec3 bc = mod(fk, 3.0) < 0.5 ? vec3(0.78, 0.28, 0.1) : (mod(fk, 3.0) < 1.5 ? vec3(0.22, 0.52, 0.3) : vec3(0.98, 0.78, 0.3));
      float rim = smoothstep(2.5, 3.6, abs(p.x - bx));
      I = mix(I, bc * (0.75 + 0.5 * rim) + vec3(0.25) * smoothstep(1.0, 0.0, abs(p.x - bx + 1.6)), cv(bd)); }
    I = mix(I, vec3(0.97, 0.92, 0.84) * (0.9 + 0.1 * (1.0 - u.y)), cv(rb(p, vec2(146.0, 229.0), vec2(172.0, 239.0)) - 2.0));
    I = mix(I, vec3(0.38, 0.22, 0.12), sat(cv(abs(p.y - 211.0) - 1.4) + cv(abs(p.y - 241.0) - 1.4)));
    I = mix(I, vec3(0.42, 0.25, 0.14) * (0.75 + 0.25 * u.x), smoothstep(262.0, 264.0, p.y));
    float mu = cv(abs(p.x - 158.0) - 1.6);
    float sh = smoothstep(0.1, 0.0, abs(u.x * 0.8 - u.y + 0.15)) * 0.22 + smoothstep(0.05, 0.0, abs(u.x * 0.8 - u.y + 0.38)) * 0.12;
    vec3 E = (I * (0.55 + 0.6 * uNight) * (0.97 + 0.03 * sin(T * 2.7)) + sh * 0.6) * g * (1.0 - mu);
    alb = mix(alb, mix(vec3(0.3, 0.14, 0.08), vec3(0.03), g * (1.0 - mu)), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, E, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
    float sl = cv(rb(p, vec2(107.0, 285.0), vec2(209.0, 289.0)));
    alb = mix(alb, vec3(0.5, 0.48, 0.45), sl); N = mix(N, vec3(0.0, 0.8, 0.6), sl); em = mix(em, vec3(0.0), sl); lit = mix(lit, 1.0, sl); ao = mix(ao, 1.0, sl);
  }
  d = bue(p, vec2(250.0, 210.0), 34.0, 298.0);
  if (d < 3.0) {
    c = cv(d);
    float g = cv(bue(p, vec2(250.0, 210.0), 30.0, 297.0));
    vec2 u = (p - vec2(220.0, 180.0)) / vec2(60.0, 118.0);
    vec3 I = mix(vec3(0.34, 0.19, 0.11), vec3(1.0, 0.8, 0.5), exp(-pow(length((u - vec2(0.5, 0.62)) * vec2(1.6, 1.1)), 2.0) * 2.2));
    I = mix(I, vec3(0.78, 0.58, 0.38) * (0.82 + 0.18 * step(0.5, fract(p.x / 6.0 + floor(p.y / 4.0) * 0.5))), smoothstep(282.0, 284.0, p.y) * 0.8);
    vec3 E = I * (0.6 + 0.55 * uNight) * g * (0.95 + 0.05 * sin(T * 3.1) * sin(T * 1.7));
    float fr = (1.0 - g) * (0.8 + 0.2 * smoothstep(-34.0, -30.0, -length(p - vec2(250.0, 210.0))));
    alb = mix(alb, mix(vec3(0.3, 0.14, 0.08) * (0.8 + 0.3 * fr), vec3(0.03), g), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, E, c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  }
  c = cv(rb(p, vec2(-10.0, 297.0), vec2(400.0, 302.0)));
  if (c > 0.0) { float bi = floor(p.x / 23.0); vec3 A = vec3(0.42, 0.43, 0.44) * (0.82 + 0.3 * hs(vec2(bi, 7.0))) * (1.0 - 0.45 * cv(abs(mod(p.x, 23.0) - 11.5) - 11.0)) * mix(1.0, 0.6, uWet);
    float top = smoothstep(299.0, 297.5, p.y); float sn = uSnow * top * step(0.3, vn(vec2(p.x * 0.25, 9.0)));
    A = mix(A, vec3(0.9, 0.93, 0.97), sn);
    alb = mix(alb, A, c); N = mix(N, mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 0.9, 0.45), top), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(rb(p, vec2(216.0, 295.0), vec2(284.0, 298.5)));
  alb = mix(alb, vec3(0.5, 0.49, 0.47), c); N = mix(N, vec3(0.0, 0.8, 0.6), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  float bd = length((p - vec2(89.0, 275.0)) * vec2(1.0, 1.05)) - 11.0 - (vn(p * 0.55) - 0.5) * 3.2;
  c = cv(bd);
  if (c > 0.0) { vec3 A = vec3(0.2, 0.38, 0.24) * (0.55 + 0.7 * vn(p * 0.7 + 3.0));
    vec3 NN = normalize(vec3((p.x - 89.0) / 11.0, -(p.y - 275.0) / 11.0, 0.7));
    float sn = uSnow * smoothstep(0.1, 0.5, NN.y + (vn(p * 0.8) - 0.5) * 0.5); A = mix(A, vec3(0.88, 0.92, 0.96), sn);
    alb = mix(alb, A, c); N = mix(N, NN, c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(max(abs(p.x - 89.0) - (7.0 - (p.y - 285.0) * 0.18), abs(p.y - 291.0) - 6.0));
  alb = mix(alb, vec3(0.68, 0.33, 0.2) * (0.75 + 0.35 * smoothstep(95.0, 84.0, p.x)), c); N = mix(N, vec3(0.0, 0.0, 1.0), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  c = max(cv(rb(p, vec2(22.0, 196.0), vec2(26.6, 297.0))), cv(rb(p, vec2(19.5, 290.0), vec2(29.0, 297.5)) - 0.6));
  if (c > 0.0) { float cx = clamp((p.x - 24.3) / 3.0, -1.0, 1.0);
    alb = mix(alb, vec3(0.07, 0.08, 0.09), c); N = mix(N, vec3(cx, 0.0, sqrt(max(1.0 - cx * cx, 0.05))), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(max(rb(p, vec2(13.5, 186.0), vec2(35.5, 200.0)), abs(p.x - 24.5) - 8.0 - (p.y - 186.0) * 0.2));
  if (c > 0.0) { float sn = uSnow * smoothstep(189.0, 187.0, p.y);
    alb = mix(alb, mix(vec3(0.09, 0.09, 0.1), vec3(0.9, 0.93, 0.97), sn), c); N = mix(N, vec3(0.0, 0.6, 0.8), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c); }
  c = cv(rb(p, vec2(17.0, 199.0), vec2(32.0, 206.5)) - 0.5);
  alb = mix(alb, vec3(0.1), c); em = mix(em, vec3(1.0, 0.88, 0.64) * 2.2 * LF * LYS + vec3(0.25), c); lit = mix(lit, 1.0, c); ao = mix(ao, 1.0, c);
  if (p.x > 38.0 && p.x < 372.0 && p.y < 140.0) {
    c = cv(abs(p.y - wireY(p.x)) - 0.55) * 0.9; alb = mix(alb, vec3(0.05, 0.04, 0.04), c); lit = mix(lit, 0.0, c); em = mix(em, vec3(0.0), c);
    for (int i = 0; i < 5; i++) {
      vec2 b = BL[i];
      c = cv(rb(p, b + vec2(-1.7, -6.5), b + vec2(1.7, -2.6))); alb = mix(alb, vec3(0.08, 0.07, 0.06), c); em = mix(em, vec3(0.0), c); lit = mix(lit, 0.0, c);
      float r = length(p - b); c = cv(r - 3.1);
      alb = mix(alb, vec3(0.2), c); em = mix(em, VARM * (1.6 + 1.6 * exp(-r * r / 2.5)) * BF[i] * (0.4 + 0.6 * LYS) + vec3(0.25), c); lit = mix(lit, 0.0, c);
    }
  }
  vec3 L = lit > 0.001 ? belys(vec3(p.x, -p.y, 0.0), N) : vec3(1.0);
  return mix(alb, alb * L * ao, lit) + em;
}
vec3 glow(vec2 p){
  vec3 g = vec3(0.0);
  for (int i = 0; i < 5; i++) { vec2 d = p - BL[i]; float r2 = dot(d, d); g += VARM * BF[i] * (1.2 * exp(-r2 / 12.0) + 0.16 / (1.0 + r2 / 70.0)); }
  vec2 dl = (p - vec2(24.5, 203.0)) * vec2(0.85, 1.25); float r2 = dot(dl, dl);
  g += vec3(1.0, 0.85, 0.62) * LF * (1.4 * exp(-r2 / 22.0) + 0.34 / (1.0 + r2 / 200.0));
  g += vec3(0.95, 0.94, 0.9) * 0.18 * exp(-max(rb(p, vec2(126.0, 106.0), vec2(262.0, 140.0)), 0.0) / 8.0);
  g += VARM * 0.12 * exp(-max(rb(p, vec2(114.0, 184.0), vec2(202.0, 282.0)), 0.0) / 9.0);
  g += VARM * 0.1 * exp(-max(bue(p, vec2(250.0, 210.0), 30.0, 297.0), 0.0) / 9.0);
  return g * LYS;
}
vec3 speil(vec3 W, vec3 R){
  if (R.z < 0.02 || R.y < 0.0) return uSkH;
  float t = (ZF - W.z) / R.z; vec3 H = W + R * t;
  vec2 s = vec2(195.0 + FL * H.x / ZF, min(HZ + FL * (HC - H.y) / ZF, 301.5));
  float a0 = AA; AA = 1.3; vec3 c = fasade(s, 0.0) + glow(s) * 1.2; AA = a0;
  return c;
}
vec2 ringer(vec2 w, float cs){
  vec2 gp = w / cs, id = floor(gp), f = fract(gp) - 0.5;
  float r1 = hs(id), ph = fract(T * (0.7 + r1 * 0.5) + r1 * 7.0);
  vec2 dv = f - (vec2(hs(id + 3.1), hs(id + 5.7)) - 0.5) * 0.5;
  float r = length(dv) + 1e-4, rad = ph * 0.45;
  return dv / r * sin((r - rad) * 60.0) * exp(-abs(r - rad) * 30.0) * (1.0 - ph) * (1.0 - ph);
}
vec3 vann(vec2 p, vec3 W, vec3 Vd){
  vec2 wp = W.xz, g = vec2(0.0), dr = vec2(0.78, 0.62);
  float fr = 2.2, am = 0.042, fx = W.z / FL / uDpr, fz = W.z * W.z / KK / uDpr;
  for (int i = 0; i < 9; i++) {
    float fp = abs(dr.x) * fx + abs(dr.y) * fz, aa = sat((6.2832 / fr / fp - 2.5) * 0.4);
    float ph = dot(dr, wp) * fr + T * (1.0 + fr * 0.28), e = exp(sin(ph) - 1.0);
    g += dr * e * cos(ph) * fr * am * aa;
    dr = vec2(dr.x * 0.8 - dr.y * 0.6, dr.x * 0.6 + dr.y * 0.8); fr *= 1.3; am *= 0.72;
  }
  if (uBoat.z > 0.0) {
    float dx = p.x - uBoat.x, dy = p.y - uBoat.y;
    float beh = smoothstep(4.0, -14.0, dx) * exp(dx / 110.0), v = abs(dy) - max(-dx, 0.0) * 0.07;
    g.y += sin(dx * 0.55 + T * 7.0) * beh * exp(-v * v / 5.0) * 0.5 * uBoat.z;
    float rr = length(vec2(dx / 30.0, dy / 5.0));
    g += vec2(dx / 30.0, dy / 5.0) / (rr + 0.2) * 0.07 * sin(rr * 9.0 - T * 4.0) * exp(-max(rr - 1.0, 0.0) * 2.5) * uBoat.z;
  }
  if (uRain > 0.0) g += (ringer(wp, 0.55) + ringer(wp + 0.27, 0.8) * 0.7) * 0.45 * uRain;
  vec3 Nw = normalize(vec3(-g.x, 1.0, -g.y)), R = reflect(Vd, Nw);
  float F = 0.02 + 0.98 * pow(1.0 - max(dot(Nw, -Vd), 0.0), 5.0);
  vec3 col = mix(mix(vec3(0.12, 0.22, 0.24), vec3(0.025, 0.07, 0.085), uNight), speil(W, R) * 1.08, sat(F * 2.2 + 0.18));
  for (int i = 0; i < 9; i++) col += LC[i] * pow(max(dot(R, normalize(LW[i] - W)), 0.0), 700.0) * 5.0;
  col *= 0.55 + 0.45 * smoothstep(302.0, 309.0, p.y);
  if (uBoat.z > 0.0) {
    float dx = p.x - uBoat.x + sin(p.y * 1.3 + T * 3.0) * 1.2, dy = p.y - uBoat.y;
    float hull = cv(max(abs(dx) - 26.0 * (1.0 - dy / 11.0), max(-dy, dy - 9.0)));
    col = mix(col, vec3(0.2, 0.12, 0.06) * (0.3 + 0.7 * LYS), hull * 0.6 * uBoat.z);
  }
  return col;
}
float hel(vec2 w, out vec2 id){
  float rz = w.y / 0.4, row = floor(rz), rx = w.x / 0.46 + mod(row, 2.0) * 0.5 + hs(vec2(row, 3.0)) * 0.4;
  id = vec2(floor(rx), row);
  vec2 f = vec2(fract(rx), fract(rz)) - 0.5;
  vec2 q = abs(f) - (vec2(0.43, 0.41) - vec2(hs(id), hs(id + 2.0)) * 0.05) + 0.16;
  float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.16;
  return smoothstep(0.02, -0.1, d) * (0.62 + 0.38 * sat(1.0 - dot(f, f) * 3.2)) + (hs(id + 5.0) - 0.5) * 0.12;
}
vec3 bakke(vec2 p, vec3 W, vec3 Vd){
  vec2 w = W.xz, id, i2;
  float det = sat((0.42 / (W.z * W.z / KK / uDpr) - 2.5) / 4.0), curb = step(8.53, W.z), h;
  vec3 N = vec3(0.0, 1.0, 0.0);
  if (curb > 0.5) { float u = w.x / 1.3; id = vec2(floor(u), -7.0); h = smoothstep(0.5, 0.47, abs(fract(u) - 0.5)) * smoothstep(8.53, 8.6, W.z) * 0.9 + 0.1; }
  else { h = hel(w, id); float hx = hel(w + vec2(0.025, 0.0), i2), hz = hel(w + vec2(0.0, 0.025), i2); N = normalize(vec3(-(hx - h) * 1.2 * det, 1.0, -(hz - h) * 1.2 * det)); }
  vec3 A = mix(vec3(0.3, 0.31, 0.33), vec3(0.46, 0.44, 0.41), hs(id)) * (1.0 + 0.3 * (vn(w * 14.0) - 0.5) * det);
  A = mix(A, vec3(0.36, 0.4, 0.44), step(0.8, hs(id + 9.0)) * 0.7);
  A = mix(A, vec3(0.42, 0.34, 0.28), step(0.9, hs(id + 13.0)) * 0.6);
  if (curb > 0.5) A = vec3(0.54, 0.54, 0.52) * (0.88 + 0.2 * hs(id));
  float gap = 1.0 - smoothstep(0.12, 0.5, h);
  A = mix(A, vec3(0.11, 0.1, 0.09), gap * mix(0.55, 1.0, det));
  float pud = smoothstep(0.5, 0.66, fbm(w * vec2(0.5, 0.85) + 4.0)) * uWet * (1.0 - curb);
  float vt = max(pud, gap * uWet * 0.7 * det);
  A *= mix(1.0, 0.42, uWet);
  float sn = uSnow * smoothstep(0.32, 0.62, fbm(w * vec2(0.9, 1.5) + 2.0) * 0.9 + h * 0.14 - pud * 0.5 + curb * 0.15);
  vec3 Np = vec3(0.0, 1.0, 0.0);
  if (uRain > 0.0) { vec2 rg = ringer(w, 0.4) * 0.5 * uRain; Np = normalize(vec3(-rg.x, 1.0, -rg.y)); }
  vec3 Ns = normalize(mix(N, Np, vt)), V = -Vd;
  vec3 dif = mix(vec3(0.72, 0.76, 0.8), vec3(0.15, 0.2, 0.24), uNight) * (0.7 + 0.3 * Ns.y), sp = vec3(0.0);
  float shin = mix(24.0, 140.0, uWet);
  for (int i = 0; i < 9; i++) {
    vec3 dd = LW[i] - W; float l2 = dot(dd, dd); vec3 L = dd * inversesqrt(l2); float at = 1.0 / (1.0 + l2 / 16.0);
    dif += LC[i] * max(dot(Ns, L), 0.0) * at;
    sp += LC[i] * pow(max(dot(Ns, normalize(L + V)), 0.0), shin) * at * shin * 0.018;
  }
  vec3 R = reflect(Vd, Ns);
  float F = 0.02 + 0.98 * pow(1.0 - max(dot(Ns, V), 0.0), 5.0);
  vec3 col = A * dif * (0.55 + 0.45 * h) + sp * (0.2 + 0.8 * uWet) * (1.0 - sn) * (0.4 + 0.6 * h);
  col = mix(col, speil(W, R) * mix(0.75, 1.0, vt), sat(mix(0.3 * uWet, 1.0, vt) * F * 2.4) * (1.0 - sn));
  return mix(col, vec3(0.87, 0.9, 0.95) * (dif * 0.9 + 0.05) + sp * 0.15, sn);
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
vec3 tm(vec3 c){ vec3 k = max(c - 0.6, 0.0); return min(c, 0.6) + 0.4 * (1.0 - exp(-k / 0.4)); }
void main(){
  float sc = 390.0 / uRes.x;
  vec2 p = (FlutterFragCoord().xy / uDpr) * sc;
  AA = 0.7 * sc / uDpr; T = uT; LYS = 0.3 + 0.7 * uNight;
  LF = 0.95 + 0.05 * sin(T * 13.0) * sin(T * 3.7) - 0.25 * step(0.985, hs(vec2(floor(T * 9.0), 1.0)));
  for (int i = 0; i < 5; i++) {
    float fi = float(i), bx = 82.0 + fi * 61.0, sw = sin(T * 1.1 + fi * 1.3) * 0.9 * sin(3.14159 * (bx - 40.0) / 330.0);
    bx += sw; float by = wireY(bx) + 4.5 + abs(sw) * 0.2;
    BL[i] = vec2(bx, by); BF[i] = 0.92 + 0.08 * sin(T * (7.0 + fi * 1.7) + fi) * sin(T * 2.3 + fi * 3.0);
    LP[i] = vec3(bx, -by, 24.0); LC[i] = VARM * 0.7 * BF[i] * LYS; LR[i] = 62.0;
    float zl = ZF - 0.7; LW[i] = vec3((bx - 195.0) * zl / FL, HC - (by - HZ) * zl / FL, zl);
  }
  LP[5] = vec3(24.5, -203.0, 34.0); LC[5] = vec3(1.0, 0.82, 0.56) * 1.6 * LF * LYS; LR[5] = 95.0;
  LP[6] = vec3(194.0, -123.0, 16.0); LC[6] = vec3(0.95) * 0.5 * LYS; LR[6] = 64.0;
  LP[7] = vec3(158.0, -236.0, 12.0); LC[7] = VARM * 0.85 * LYS; LR[7] = 58.0;
  LP[8] = vec3(250.0, -250.0, 12.0); LC[8] = VARM * 0.75 * LYS; LR[8] = 52.0;
  LW[5] = vec3((24.5 - 195.0) * 11.3 / FL, HC - (203.0 - HZ) * 11.3 / FL, 11.3);
  LW[6] = vec3(-1.0 * 11.6 / FL, HC - (123.0 - HZ) * 11.6 / FL, 11.6);
  LW[7] = vec3((158.0 - 195.0) * ZF / FL, HC - (236.0 - HZ) * ZF / FL, ZF);
  LW[8] = vec3((250.0 - 195.0) * ZF / FL, HC - (250.0 - HZ) * ZF / FL, ZF);
  vec3 col;
  if (p.y < 302.0) col = fasade(p, 1.0);
  else {
    float Z = KK / (p.y - HZ); vec3 W = vec3((p.x - 195.0) * Z / FL, 0.0, Z), Vd = normalize(vec3(W.x, -HC, Z));
    col = p.y < 322.0 ? vann(p, W, Vd) : bakke(p, W, Vd);
  }
  vec3 G0 = glow(p); col += G0;
  float cy = p.y - 206.0, cone = 0.0;
  if (cy > 0.0 && cy < 112.0) {
    cone = pow(sat(1.0 - abs(p.x - 24.5) / (4.0 + cy * 0.52)), 1.6) * (1.0 - smoothstep(60.0, 108.0, cy)) * smoothstep(0.0, 6.0, cy);
    col += vec3(1.0, 0.82, 0.55) * cone * (0.75 + 0.5 * fbm(vec2(p.x * 0.05, p.y * 0.03 - T * 0.25))) * 0.16 * LYS * LF;
  }
  if (uRain > 0.0) { float r = regn(p, 4.0, 520.0, 14.0, 1.0) * 0.3 + regn(p, 7.0, 760.0, 24.0, 7.0) * 0.45 + regn(p, 11.0, 1000.0, 40.0, 13.0) * 0.6;
    col += (vec3(0.7, 0.78, 0.82) * (0.14 + 0.35 * (1.0 - uNight)) + G0 * 2.0 + cone * 1.6 * LYS) * r * uRain; }
  if (uSnow > 0.0) { float s = sno(p, 13.0, 20.0, 1.0) * 0.5 + sno(p, 22.0, 32.0, 5.0) * 0.75 + sno(p, 38.0, 52.0, 9.0);
    col = mix(col, vec3(0.92, 0.95, 1.0) * (0.62 + 0.35 * (1.0 - uNight)) + G0 * 2.2 + cone * 2.4 * LYS, sat(s) * uSnow); }
  col = mix(col, uSkH * 0.55, 0.04);
  vec2 vq = p / vec2(390.0, 472.0) - vec2(0.5, 0.42);
  col *= 1.0 - 0.32 * smoothstep(0.32, 0.8, length(vq * vec2(1.1, 0.95)));
  col = tm(max(col, 0.0)) + (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.018;
  fragColor = vec4(col, 1.0);
}
