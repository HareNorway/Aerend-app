// Sporing · Henting · disken — the Launch prototype's own WebGL scene (`spHkInit / spHkTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: the pickup counter: panelled wall, the window over Vågen, the pendant lamp, the bag, the bell, the store logo and Ægil as textures.
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
uniform float uTexOk;
uniform float uLogoOk;
uniform vec3 uSkT;
uniform vec3 uSkH;
uniform sampler2D uTex;
uniform sampler2D uTexLo;
uniform sampler2D uLogo;
out vec4 fragColor;
float AA, T, SW, PRESS, RING;
vec3 AMB, WINC, LP0, LP1, LT1;
vec2 B0, AEG;
const float CX = 181.0, CY = 95.0, FL = 420.0, ZW = 4.6, ZA = 4.25, AS = 160.0, YB = 172.0, YF = 207.0;
const vec3 LAMPC = vec3(1.0, 0.8, 0.56);
const vec3 SIGNC = vec3(1.0, 0.52, 0.2);
const vec2 SC = vec2(176.0, 60.0);
const vec4 WIN = vec4(232.0, 8.0, 340.0, 146.0);
const vec2 BELL = vec2(320.0, 194.0);
vec4 upm(vec4 c){ return c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : c; }
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float ga(float x){ return exp(-x * x); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
float esd(vec2 p, vec2 r){ vec2 e = p / r; float k1 = length(e), k2 = length(e / r); return k1 * (k1 - 1.0) / max(k2, 1e-4); }
vec2 rot(vec2 p, float a){ float c = cos(a), s = sin(a); return vec2(c * p.x - s * p.y, s * p.x + c * p.y); }
vec2 proj(vec3 P){ return vec2(CX + FL * P.x / P.z, CY - FL * P.y / P.z); }
vec3 wpt(vec2 p, float z){ return vec3((p.x - CX) / FL * z, -(p.y - CY) / FL * z, z); }
vec3 tm(vec3 c){ vec3 k = max(c - 0.62, 0.0); return min(c, 0.62) + 0.38 * (1.0 - exp(-k / 0.38)); }
vec4 aegT(vec2 s, float b){
  vec2 uv = (s - AEG) / AS; uv.y = 1.0 - (1.0 - uv.y) / (1.0 + 0.013 * sin(T * 2.0));
  if (uTexOk < 0.5 || uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
  return (b > 0.5 ? upm(texture(uTexLo, uv)) : upm(texture(uTex, uv)));
}
vec4 logoT(vec2 s, vec2 c, float r, float b){
  vec2 uv = (s - c) / (2.0 * r) + 0.5;
  if (uLogoOk < 0.5 || uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
  return upm(texture(uLogo, uv));
}
float aegSkygge(vec3 P, vec3 L){ if (P.z <= ZA + 0.01 || L.z >= ZA) return 0.0; float u = (ZA - L.z) / (P.z - L.z); return aegT(proj(L + (P - L) * u), 3.0).a; }
vec3 lys(vec3 P, vec3 N, vec3 V, float gl, float shin, float sk, out vec3 spec){
  vec3 dif = AMB * (0.78 + 0.22 * N.y); spec = vec3(0.0);
  vec3 L = LP0 - P; float l2 = dot(L, L); L *= inversesqrt(l2);
  float at = 1.0 / (1.0 + l2 / 2.6), spot = mix(0.15, 1.0, smoothstep(0.1, 0.7, L.y));
  float sh = sk > 0.5 ? 1.0 - 0.5 * aegSkygge(P, LP0) : 1.0;
  vec3 c = LAMPC * 2.2 * at * spot * sh;
  dif += c * max(dot(N, L), 0.0); spec += c * pow(max(dot(N, normalize(L + V)), 0.0), shin) * gl;
  L = LP1 - P; l2 = dot(L, L); L *= inversesqrt(l2);
  at = 1.0 / (1.0 + l2 / 5.0); spot = mix(0.12, 1.0, smoothstep(0.88, 0.97, dot(L, normalize(LP1 - LT1))));
  sh = sk > 0.5 ? 1.0 - 0.75 * aegSkygge(P, LP1) : 1.0;
  c = LAMPC * 1.4 * at * spot * sh;
  dif += c * max(dot(N, L), 0.0); spec += c * pow(max(dot(N, normalize(L + V)), 0.0), shin) * gl;
  dif += WINC * 0.4 * max(dot(N, normalize(vec3(0.6, 0.2, 0.78))), 0.0);
  return dif;
}
vec3 env(vec3 r){
  vec3 c = mix(vec3(0.2, 0.1, 0.06), vec3(0.5, 0.36, 0.26) * (AMB + 0.5), smoothstep(-0.35, 0.35, r.y));
  c += vec3(0.75, 0.14, 0.06) * 0.6 * smoothstep(-0.1, -0.6, r.y) * smoothstep(0.3, -0.3, r.z);
  c += (WINC * 1.6 + vec3(0.12, 0.14, 0.16)) * smoothstep(0.05, 0.5, r.x) * smoothstep(-0.2, 0.05, r.y) * smoothstep(0.85, 0.35, r.y);
  c += SIGNC * 0.5 * smoothstep(0.2, 0.8, r.y) * smoothstep(0.4, -0.3, r.x);
  c += vec3(0.85, 0.82, 0.78) * 0.35 * ga((r.y - 0.02) / 0.06);
  float k = sat(dot(r, normalize(vec3(-0.35, 0.85, -0.3))));
  c += LAMPC * (4.0 * pow(k, 60.0) + 0.6 * pow(k, 6.0));
  return c;
}
vec3 krom(vec3 N){ return env(reflect(vec3(0.0, -0.18, 1.0), N)) * vec3(0.92, 0.94, 0.97); }
vec3 vegg(vec2 p){
  float pw = 23.0, u = (p.x + 5.0) / pw, id = floor(u), f = fract(u), e = min(f, 1.0 - f) * pw;
  float r1 = hs(vec2(id, 2.0)), r2 = hs(vec2(id, 5.0));
  float gr = fbm(vec2(p.x * 0.32 + id * 13.0, p.y * 0.02 + r1 * 7.0));
  float rg = 0.5 + 0.5 * sin((p.x + gr * 16.0) * 1.1 + r1 * 30.0);
  vec3 A = vec3(0.44, 0.15, 0.08) * (0.8 + 0.32 * r1) * (0.74 + 0.4 * gr) * (0.9 + 0.12 * rg);
  vec2 kc = vec2((id + 0.3 + 0.4 * r2) * pw - 5.0, 26.0 + 130.0 * hs(vec2(id, 9.0)));
  A *= 1.0 - 0.45 * smoothstep(4.5, 0.8, length((p - kc) * vec2(1.0, 0.42))) * step(0.5, hs(vec2(id, 11.0)));
  float bev = smoothstep(3.5, 0.0, e) * sign(f - 0.5), gap = 1.0 - smoothstep(0.35, 1.3, e), gl = 0.18;
  vec3 N = normalize(vec3(bev * 0.55 + (gr - 0.5) * 0.12, (vn(vec2(p.x * 0.4, p.y * 0.06)) - 0.5) * 0.1, -1.0));
  float beam = 1.0 - smoothstep(14.0, 15.0, p.y);
  if (beam > 0.0) {
    float g2 = fbm(vec2(p.x * 0.03, p.y * 0.4 + 5.0));
    A = mix(A, vec3(0.17, 0.09, 0.05) * (0.7 + 0.55 * g2), beam); gap *= 1.0 - beam;
    N = normalize(mix(N, vec3(0.0, -0.7 * smoothstep(9.0, 14.0, p.y), -1.0), beam)); gl = mix(gl, 0.3, beam);
  }
  vec3 P = wpt(p, ZW), V = -normalize(P), sp;
  vec3 dif = lys(P, N, V, gl, 24.0, 1.0, sp);
  vec3 C = (A * dif + sp) * (1.0 - 0.85 * gap);
  C *= mix(1.0, mix(0.5, 1.0, smoothstep(15.0, 28.0, p.y)), 1.0 - beam);
  float r = length(p - SC);
  C += A * SIGNC * 3.2 * exp(-max(r - 36.0, 0.0) / 15.0) * smoothstep(30.0, 37.0, r) * (0.95 + 0.05 * sin(T * 3.1));
  C += A * WINC * 1.5 * exp(-max(rb(p, WIN.xy, WIN.zw), 0.0) / 20.0);
  C *= mix(0.6, 1.0, smoothstep(YB, YB - 22.0, p.y));
  return C;
}
vec3 ute(vec2 p){
  float hz = 102.0;
  vec3 sky = mix(uSkH, uSkT, sat((hz - p.y) / 95.0)), c = sky;
  c = mix(c, mix(uSkH, vec3(0.75), 0.3) * (0.8 + 0.2 * (1.0 - uNight)), smoothstep(0.55, 0.85, fbm(vec2(p.x * 0.02 + T * 0.01, p.y * 0.06))) * 0.35 * smoothstep(hz, 20.0, p.y));
  float ridge = 62.0 + 16.0 * fbm(vec2(p.x * 0.022 + 2.0, 0.5)) + (p.x - 232.0) * 0.1;
  vec3 mtn = mix(uSkH * vec3(0.4, 0.48, 0.5), vec3(0.035, 0.05, 0.06), 0.35 + 0.6 * uNight) * (0.8 + 0.3 * fbm(p * 0.1));
  mtn = mix(mtn, uSkH * 0.7, smoothstep(ridge + 20.0, hz, p.y) * 0.35);
  vec2 cl = floor(p / vec2(5.0, 4.0)), lc = (cl + 0.5) * vec2(5.0, 4.0);
  mtn += vec3(1.0, 0.78, 0.45) * step(0.72, hs(cl)) * smoothstep(ridge + 3.0, ridge + 10.0, p.y) * exp(-dot(p - lc, p - lc) / 1.2) * (0.25 + 1.2 * uNight);
  c = mix(c, mtn, smoothstep(ridge - 0.7, ridge + 0.7, p.y));
  float hh = 92.0 + 6.0 * hs(vec2(floor(p.x / 7.0), 3.0));
  vec3 hc = vec3(0.06, 0.06, 0.07) * (1.0 - 0.5 * uNight) + uSkH * 0.15;
  hc += vec3(1.0, 0.7, 0.36) * 0.7 * step(0.78, hs(floor(p / 3.0) + 7.0)) * step(hh + 2.0, p.y) * step(p.y, hz - 2.0) * step(0.5, fract(p.x / 3.0)) * step(0.5, fract(p.y / 3.0)) * (0.3 + 0.9 * uNight);
  c = mix(c, hc, step(hh, p.y) * step(p.y, hz));
  if (p.y > hz) c = mix(sky * 0.45, vec3(0.02, 0.035, 0.05), 0.3 + 0.5 * uNight) * (0.85 + 0.3 * vn(vec2(p.x * 0.15, p.y * 0.9 - T * 0.8)));
  for (int i = 0; i < 7; i++) {
    float fi = float(i), h1 = hs(vec2(fi, 2.0)), h2 = hs(vec2(fi, 6.0));
    vec2 b = vec2(240.0 + fi * 15.0 + h1 * 8.0, 96.0 + h2 * 6.0);
    vec3 bc = mix(vec3(1.0, 0.72, 0.38), vec3(0.6, 0.85, 1.0), step(0.7, h1));
    float rr = 3.0 + 2.5 * h2, d = length(p - b);
    float k = (0.35 + 0.9 * uNight) * (0.85 + 0.15 * sin(T * (1.0 + h1) + fi));
    c += bc * smoothstep(rr, rr - 1.0, d) * (0.55 + 0.45 * smoothstep(rr - 2.5, rr - 0.6, d)) * k * 0.55;
    if (p.y > hz) { float sx = p.x - b.x - sin(p.y * 0.6 + T * 2.0 + fi) * 1.2; c += bc * k * 0.35 * exp(-sx * sx / 2.0) * exp(-(p.y - hz) / 22.0) * (0.6 + 0.4 * vn(vec2(fi, p.y * 0.5 - T * 2.0))); }
  }
  if (uSnow > 0.01) {
    for (int i = 0; i < 2; i++) {
      float fi = float(i); vec2 q = vec2(p.x + sin(T * 0.7 + fi) * 4.0, p.y - T * (14.0 + fi * 8.0)) / (7.0 + fi * 3.0);
      vec2 id = floor(q), f = fract(q) - 0.5, o = vec2(hs(id), hs(id + 2.0)) - 0.5;
      c += vec3(0.92) * uSnow * smoothstep(0.14, 0.0, length(f - o * 0.6)) * step(0.4, hs(id + 5.0));
    }
  }
  return c;
}
vec3 regn(vec2 p, vec3 g){
  vec2 id = floor(p / 7.0), f = fract(p / 7.0) * 7.0;
  if (hs(id + 3.1) > 0.45) {
    vec2 c = vec2(hs(id + 1.7), hs(id + 9.2)) * 4.0 + 1.5; float r = 0.7 + 1.1 * hs(id + 4.4);
    float m = cv(length(f - c) - r);
    g = mix(g, g * 0.6 + uSkH * 0.25, m * 0.7);
    g += vec3(1.0) * 0.5 * m * smoothstep(r, 0.0, length(f - c + vec2(0.35, 0.35) * r));
  }
  float ci = floor((p.x - 232.0) / 10.0), hc = hs(vec2(ci, 17.0));
  float x0 = 232.0 + (ci + 0.3 + 0.4 * hc) * 10.0 + sin(p.y * 0.08 + hc * 10.0) * 1.2;
  float y0 = 8.0 + fract(T * (0.12 + 0.1 * hc) + hc) * 170.0, dx = p.x - x0, dy = p.y - y0;
  float head = exp(-(dx * dx + dy * dy) / 2.2), trail = exp(-dx * dx / 0.5) * smoothstep(y0 - 50.0, y0, p.y) * step(p.y, y0) * 0.35;
  g += (vec3(0.9, 0.95, 1.0) * 0.5 + LAMPC * 0.2) * (head * 1.2 + trail) * step(0.35, hc);
  return g;
}
void vindu(vec2 p, inout vec3 col, float rain){
  float d = rb(p, WIN.xy, WIN.zw), sl = rb(p, vec2(WIN.x - 6.0, WIN.w), vec2(WIN.z + 6.0, WIN.w + 7.0));
  if (p.y > WIN.w + 7.0 && p.y < WIN.w + 18.0 && p.x > WIN.x - 8.0 && p.x < WIN.z + 8.0) col *= 1.0 - 0.45 * smoothstep(WIN.w + 18.0, WIN.w + 7.0, p.y);
  if (d > 4.0 && sl > 1.0) return;
  if (d > 0.0) col *= 1.0 - 0.35 * smoothstep(4.0, 0.0, d);
  vec3 P = wpt(p, ZW), V = -normalize(P), sp;
  float fm = min(max(d, -d - 7.0), max(d, min(abs(p.x - 286.0) - 2.5, abs(p.y - 77.0) - 2.5)));
  if (d < 1.0) {
    vec3 g = ute(p);
    vec2 rq = p - proj(vec3(LP0.xy, 2.0 * ZW - LP0.z));
    g += LAMPC * (0.4 * exp(-dot(rq, rq) / 26.0) + 0.03);
    if (rain > 0.01) g = mix(g, regn(p, g), rain);
    g *= 1.0 - 0.35 * smoothstep(3.0, 0.0, fm);
    col = mix(col, g, cv(d));
  }
  if (fm < 1.0) {
    vec3 dif = lys(P, vec3(0.0, 0.0, -1.0), V, 0.25, 30.0, 1.0, sp);
    vec3 F = vec3(0.86, 0.83, 0.76) * dif + sp + WINC * 0.45 * smoothstep(1.8, 0.0, -fm);
    col = mix(col, F, cv(fm));
  }
  if (sl < 1.0) {
    float tp = step(p.y, WIN.w + 2.5);
    vec3 dif = lys(P, mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), tp), V, 0.3, 30.0, 0.0, sp);
    col = mix(col, vec3(0.86, 0.83, 0.76) * dif * mix(0.75, 1.1, tp) + sp, cv(sl));
  }
}
void skilt(vec2 p, inout vec3 col){
  float r = length(p - SC); if (r > 40.0) return;
  vec2 n2 = (p - SC) / max(r, 1e-3);
  float rn = clamp((r - 35.0) / 2.5, -1.0, 1.0);
  vec3 N = normalize(vec3(n2.x * rn, -n2.y * rn, -sqrt(max(1.0 - rn * rn, 0.05))));
  col = mix(col, vec3(0.07, 0.06, 0.055) + env(reflect(vec3(0.0, 0.0, 1.0), N)) * 0.5, cv(r - 37.5));
  vec3 Pl = vec3(1.0, 0.97, 0.92) * (1.02 - 0.12 * (r / 32.5) * (r / 32.5));
  vec4 lg = logoT(p, SC, 31.0, 0.0);
  Pl = mix(Pl, lg.rgb * 1.05, lg.a);
  float sw = fract(T / 7.0), sx = mix(-70.0, 70.0, sat(sw * 2.6));
  Pl += vec3(1.0, 0.98, 0.94) * 0.32 * ga(((p.x - SC.x) + (p.y - SC.y) * 0.45 - sx) / 6.0) * step(sw, 0.39);
  col = mix(col, Pl * (0.92 + 0.12 * AMB.r), cv(r - 33.0));
}
void aegil(vec2 p, inout vec3 col){
  vec4 a = aegT(p, 0.0); if (a.a < 0.004) return;
  vec2 gr = vec2(aegT(p + vec2(1.5, 0.0), 0.0).a - aegT(p - vec2(1.5, 0.0), 0.0).a, aegT(p + vec2(0.0, 1.5), 0.0).a - aegT(p - vec2(0.0, 1.5), 0.0).a);
  float edge = sat(length(gr) * 1.6); vec2 on = -gr / max(length(gr), 1e-4);
  float rimL = sat(dot(on, normalize(B0 - p))) * edge;
  float rimS = sat(dot(on, normalize(vec2(10.0, -120.0) - p))) * edge;
  float rimK = sat(dot(on, normalize(SC - p))) * edge * exp(-length(p - SC) / 90.0);
  vec3 lit = AMB * 1.25 + LAMPC * 0.6 * smoothstep(190.0, 70.0, p.y) + LAMPC * 0.3 * exp(-length(p - vec2(150.0, 140.0)) / 80.0);
  vec3 ac = a.rgb * lit + LAMPC * (rimL * 0.4 + rimS * 0.5) + SIGNC * rimK * 0.6;
  ac *= mix(1.0, 0.7, smoothstep(140.0, YB, p.y));
  col = mix(col, vec3(0.88, 0.85, 0.8) * lit, smoothstep(0.8, 0.97, aegT(p, 2.5).a));
  col = mix(col, ac, a.a);
}
float tagg(float x){ float k = fract((x - 204.0) / 6.2); return 3.0 * (1.0 - abs(2.0 * k - 1.0)); }
void pose(vec2 p, inout vec3 col){
  if (p.x < 200.0 || p.x > 290.0 || p.y < 104.0 || p.y > 193.0) return;
  float tg = tagg(p.x), k = sat((212.0 - p.x) / 8.0);
  float df = max(max(212.0 - p.x, p.x - 286.0), max(110.0 + tg - p.y, p.y - 190.0));
  float ds = max(max(204.0 - p.x, p.x - 212.0), max(112.0 + 1.5 * k + tg * 0.8 - p.y, p.y - (190.0 - 2.0 * k)));
  float dm = min(df, ds); if (dm > 1.0) return;
  bool sd = ds < df;
  float cr = fbm(p * vec2(0.035, 0.03) + 3.0), fib = vn(vec2(p.x * 1.4, p.y * 0.06)) * 0.6 + vn(vec2(p.x * 3.1, p.y * 0.12)) * 0.4;
  vec3 A = vec3(0.74, 0.54, 0.34) * (0.95 + 0.08 * cr) * (0.96 + 0.06 * fib);
  vec3 P = wpt(p, 3.32), V = -normalize(P), sp, N;
  if (sd) { N = normalize(vec3(-0.9 + 0.35 * smoothstep(-4.0, 4.0, p.x - 208.0), 0.0, -0.45)); A *= 0.92; }
  else {
    float nx = vn(p * 0.05 + vec2(0.4, 0.0)) - vn(p * 0.05 - vec2(0.4, 0.0));
    float ny = vn(p * 0.05 + vec2(0.0, 0.4)) - vn(p * 0.05 - vec2(0.0, 0.4));
    float cz = p.y - 124.0, fx = min(p.x - 214.5, 283.5 - p.x), fy = p.y - 176.0;
    N = normalize(vec3(nx * 0.22 + 0.22 * ga(fx / 1.4) * sign(p.x - 249.0), -ny * 0.22 - 0.5 * ga(cz / 1.6) * sign(cz) + 0.16 * smoothstep(124.0, 112.0, p.y) - 0.25 * ga(fy / 1.2) * sign(fy), -1.0));
  }
  vec3 dif = lys(P, N, V, 0.08, 10.0, 0.0, sp);
  vec3 C = A * dif + sp;
  if (!sd) {
    C *= 1.0 - 0.22 * ga((p.y - 125.5) / 1.3);
    vec4 lg = logoT(p, vec2(238.0, 162.0), 21.0, 0.0);
    C = mix(C, lg.rgb * dif * vec3(0.98, 0.93, 0.86), lg.a * 0.9);
    C *= 1.0 - 0.22 * smoothstep(281.0, 286.0, p.x);
    C += WINC * 0.45 * smoothstep(283.0, 286.5, p.x);
    C *= 1.0 - 0.35 * smoothstep(3.0, 0.0, p.x - 212.0);
  }
  float te = p.y - (sd ? 112.0 + 1.5 * k + tg * 0.8 : 110.0 + tg);
  C += LAMPC * 0.3 * smoothstep(2.2, 0.0, te);
  C *= mix(0.68, 1.0, smoothstep(190.0, 181.0, p.y));
  col = mix(col, C, cv(dm));
}
void klokke(vec2 p, inout vec3 col){
  vec2 c = BELL; if (abs(p.x - c.x) > 20.0 || p.y < c.y - 34.0 || p.y > c.y + 6.0) return;
  float eb = esd(p - c, vec2(17.0, 4.5)), et = esd(p - c + vec2(0.0, 4.5), vec2(17.0, 4.5));
  float side = max(abs(p.x - c.x) - 17.0, max(c.y - 4.5 - p.y, p.y - c.y));
  float nx = clamp((p.x - c.x) / 17.0, -1.0, 1.0);
  vec3 BC = vec3(0.03, 0.028, 0.027) * (AMB + 0.4) + vec3(1.0, 0.92, 0.82) * 0.28 * ga((nx + 0.45) / 0.12) + WINC * 0.25 * smoothstep(0.5, 1.0, nx);
  if (et < 0.0) BC = vec3(0.07, 0.065, 0.06) * (AMB + 0.5) + LAMPC * 0.1;
  col = mix(col, BC, cv(min(min(eb, et), side)));
  vec2 dc = c - vec2(0.0, 5.5), n2 = (p - dc) / vec2(14.5, 13.5);
  float dd = max(length(n2) - 1.0, (p.y - dc.y) / 13.5) * 13.5;
  if (dd < 1.0) col = mix(col, krom(normalize(vec3(n2.x, -n2.y, -sqrt(max(1.0 - dot(n2, n2), 0.02))))), cv(dd));
  float stem = rb(p, vec2(c.x - 1.4, c.y - 23.5 + PRESS), vec2(c.x + 1.4, c.y - 18.0));
  if (stem < 1.0) { float sx = clamp((p.x - c.x) / 1.4, -1.0, 1.0); col = mix(col, krom(normalize(vec3(sx, 0.0, -sqrt(max(1.0 - sx * sx, 0.02))))), cv(stem)); }
  vec2 kn = (p - vec2(c.x, c.y - 26.5 + PRESS)) / 3.8; float kd = (length(kn) - 1.0) * 3.8;
  if (kd < 1.0) col = mix(col, krom(normalize(vec3(kn.x, -kn.y, -sqrt(max(1.0 - dot(kn, kn), 0.02))))), cv(kd));
}
void disk(vec2 p, inout vec3 col){
  if (p.y >= YF) {
    float u = (p.y - YF) / 5.0, lx = exp(-(p.x - B0.x) * (p.x - B0.x) / 8100.0);
    vec3 A = vec3(0.17, 0.09, 0.05) * (0.85 + 0.3 * fbm(vec2(p.x * 0.05, p.y)));
    vec3 C = A * (AMB * (1.1 - u * 0.7) + LAMPC * 0.8 * lx * (1.0 - u));
    C += vec3(1.0, 0.9, 0.75) * 0.5 * ga((u - 0.18) / 0.12) * (0.35 + 0.65 * lx);
    col = C; return;
  }
  float z = 315.0 / (p.y - CY);
  vec3 P = vec3((p.x - CX) / FL * z, -0.75, z), V = -normalize(P);
  float pl = floor(z / 0.16), g = fbm(vec2(P.x * 2.2 + pl * 7.3, z * 34.0 + pl)), g2 = vn(vec2(P.x * 30.0, z * 2.0 + pl * 3.0));
  vec3 A = vec3(0.17, 0.09, 0.05) * (0.75 + 0.45 * g) * (0.9 + 0.2 * hs(vec2(pl, 4.0))) * (0.92 + 0.1 * g2);
  float fz = fract(z / 0.16), sdz = min(fz, 1.0 - fz) * 0.16, fw = z * z / 315.0;
  A *= 1.0 - 0.5 * (1.0 - smoothstep(0.0, fw * 1.2, sdz));
  vec3 N = normalize(vec3((g - 0.5) * 0.05, 1.0, (g2 - 0.5) * 0.03)), sp;
  vec3 dif = lys(P, N, V, 0.9, 110.0, 0.0, sp);
  float F = 0.04 + 0.96 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
  vec3 d = -V, r = vec3(d.x + N.x * 0.6, -d.y, d.z + N.z * 0.6);
  vec2 s = proj(P + r * ((ZW - z) / max(r.z, 1e-3)));
  vec3 R = vegg(s); vindu(s, R, 0.0);
  pose(vec2(p.x, 380.0 - p.y), R); klokke(vec2(p.x, 2.0 * BELL.y - p.y), R);
  vec3 C = A * dif + sp + R * (0.06 + 0.75 * F);
  C *= 1.0 - 0.6 * (1.0 - smoothstep(-2.0, 7.0, esd(p - vec2(249.0, 190.5), vec2(44.0, 6.0))));
  C *= 1.0 - 0.55 * (1.0 - smoothstep(-2.0, 6.0, esd(p - BELL - vec2(1.0, 1.0), vec2(19.0, 5.0))));
  C *= mix(0.7, 1.0, smoothstep(YB, YB + 6.0, p.y));
  col = C;
}
void medalje(vec2 p, inout vec3 col){
  vec2 c = vec2(181.0, 268.0); float r = length(p - c); if (r > 34.0) return;
  col *= 1.0 - 0.45 * smoothstep(32.0, 24.0, length(p - c - vec2(0.0, 3.0)));
  vec2 n2 = (p - c) / max(r, 1e-3); float rn = clamp((r - 24.25) / 2.25, -1.0, 1.0);
  vec3 N = normalize(vec3(n2.x * rn, -n2.y * rn, -sqrt(max(1.0 - rn * rn, 0.05))));
  vec3 Br = vec3(0.78, 0.58, 0.28);
  col = mix(col, Br * env(reflect(vec3(0.0, 0.2, 1.0), N)) * 1.6 + Br * 0.1, cv(max(r - 26.5, 22.0 - r)));
  vec3 E = vec3(0.95, 0.92, 0.86) * (AMB * 0.9 + LAMPC * 0.5 * exp(-(p.y - 213.0) / 40.0) + 0.15);
  vec4 lg = logoT(p, c, 20.0, 0.0);
  E = mix(E, lg.rgb * (AMB * 0.9 + 0.35 + LAMPC * 0.3), lg.a);
  E += vec3(1.0) * 0.12 * smoothstep(0.0, -18.0, (p.y - c.y) + (p.x - c.x) * 0.4);
  col = mix(col, E, cv(r - 22.0));
}
void front(vec2 p, inout vec3 col){
  if (p.y > 314.0) {
    float u = (p.y - 314.0) / 16.0;
    vec3 S = vec3(0.5, 0.52, 0.54) * (0.82 + 0.18 * vn(vec2(p.x * 0.9, p.y * 0.08))) * (AMB * 0.9 + 0.2);
    S += vec3(0.55, 0.1, 0.05) * 0.25 * (1.0 - u) + vec3(1.0, 0.95, 0.9) * 0.4 * ga((p.y - 315.0) / 0.9);
    col = S; return;
  }
  float sw = 14.5, u = (p.x - 2.0) / sw, id = floor(u), f = fract(u), e = min(f, 1.0 - f) * sw;
  vec3 A = vec3(0.6, 0.1, 0.045) * (0.92 + 0.14 * hs(vec2(id, 1.0))) * (0.9 + 0.16 * fbm(vec2(p.x * 0.25 + id * 9.0, p.y * 0.025)));
  float groove = 1.0 - smoothstep(0.3, 1.2, e), bev = smoothstep(2.8, 0.0, e) * sign(f - 0.5);
  vec3 P = wpt(p, 2.8), V = -normalize(P), sp;
  vec3 dif = lys(P, normalize(vec3(bev * 0.6, 0.0, -1.0)), V, 0.35, 34.0, 0.0, sp);
  vec3 wash = LAMPC * 1.1 * exp(-(p.y - 212.0) / 30.0) * (0.75 + 0.25 * (1.0 - abs(bev)));
  vec3 C = (A * (dif * 0.8 + wash) + sp * 0.6) * (1.0 - 0.8 * groove);
  C *= mix(1.0, 0.55, smoothstep(250.0, 314.0, p.y)) * (1.0 - 0.35 * smoothstep(306.0, 314.0, p.y));
  C += LAMPC * 0.9 * ga((p.y - 212.6) / 0.8);
  col = C;
  medalje(p, col);
}
void ringer(vec2 p, inout vec3 col){
  if (RING >= 1.0) return;
  vec2 d = (p - BELL + vec2(0.0, 26.0)) * vec2(1.0, 1.25); float rr = length(d);
  for (int i = 0; i < 2; i++) {
    float o = float(i) * 0.18, a = sat(1.0 - RING) * step(o, RING), rad = 8.0 + (RING - o) * 48.0;
    col += vec3(1.0, 0.92, 0.74) * 0.5 * ga((rr - rad) / 1.1) * a * a * smoothstep(BELL.y - 4.0, BELL.y - 12.0, p.y);
  }
}
void lampe(vec2 p, inout vec3 col){
  vec2 top = vec2(249.0, -6.0), q = rot(p - top, SW), s = q - vec2(0.0, 28.0);
  if (abs(q.x) > 60.0 || q.y > 90.0) return;
  col = mix(col, vec3(0.04, 0.035, 0.03), cv(rb(q, vec2(-0.6, 0.0), vec2(0.6, 28.0))));
  float hw = mix(4.5, 21.0, pow(sat(s.y / 19.0), 0.75));
  float dS = max(abs(s.x) - hw, max(-s.y, s.y - 19.0)), nx = clamp(s.x / max(hw, 1.0), -1.0, 1.0);
  vec3 E = vec3(0.09, 0.27, 0.32) * (0.35 + 0.75 * (1.0 - nx * nx));
  E += vec3(1.0, 0.95, 0.88) * 0.55 * ga((nx + 0.42) / 0.12) * smoothstep(19.0, 3.0, s.y);
  E += WINC * 0.45 * smoothstep(0.35, 1.0, nx) + SIGNC * 0.12 * smoothstep(-0.2, -1.0, nx);
  E *= AMB * 0.9 + 0.35;
  col = mix(col, vec3(0.08, 0.075, 0.07) * (AMB + 0.4) + vec3(0.3) * ga((s.x + 1.5) / 1.0), cv(rb(s, vec2(-3.5, -3.0), vec2(3.5, 1.5)) - 0.8));
  col = mix(col, E, cv(dS));
  vec2 bq = (s - vec2(0.0, 19.5)) / vec2(8.0, 3.2);
  col = mix(col, LAMPC * (1.3 + 1.6 * exp(-dot(bq, bq))), cv(esd(s - vec2(0.0, 19.0), vec2(21.0, 4.8))) * step(19.0, s.y));
  vec2 gq = (s - vec2(0.0, 24.0)) / vec2(34.0, 16.0);
  col += LAMPC * 0.28 * exp(-dot(gq, gq) * 1.5);
}
vec3 kjegle(vec2 p, vec2 o){
  float dy = p.y - o.y; if (dy < 0.0 || p.y > 196.0) return vec3(0.0);
  float m = smoothstep(1.0, 0.45, abs(p.x - o.x) / (20.0 + dy * 0.5)) * exp(-dy / 160.0) * smoothstep(0.0, 14.0, dy) * smoothstep(196.0, 160.0, p.y);
  return LAMPC * 0.09 * m * (0.7 + 0.45 * fbm(vec2(p.x * 0.035 + T * 0.05, p.y * 0.015 - T * 0.12)));
}
vec3 straale(vec2 p){
  vec2 a = vec2(10.0, -120.0), ab = vec2(110.0, 170.0) - a; float t = dot(p - a, ab) / dot(ab, ab);
  if (t < 0.0 || t > 1.05 || p.y > YB) return vec3(0.0);
  float d = length(p - a - ab * t), w = 10.0 + t * 52.0;
  return LAMPC * 0.05 * smoothstep(w, w * 0.25, d) * smoothstep(1.05, 0.7, t) * smoothstep(0.25, 0.45, t) * (0.7 + 0.45 * fbm(vec2(p.x * 0.03 - T * 0.05, p.y * 0.02 + T * 0.08)));
}
float damp(vec2 p){
  float hh = (112.0 - p.y) / 85.0; if (hh < 0.0 || hh > 1.0 || abs(p.x - 248.0) > 50.0) return 0.0;
  float cxs = 246.0 + sin(hh * 3.4 - T * 0.6) * 7.0 * hh, m = smoothstep(1.0, 0.2, abs(p.x - cxs) / (12.0 + hh * 26.0));
  if (m <= 0.0) return 0.0;
  vec2 q = vec2(p.x * 0.045, p.y * 0.03 + T * 0.45);
  float n = fbm(q + vec2(fbm(q * 1.7 - vec2(0.0, T * 0.15)), 0.0) * 0.8);
  return smoothstep(0.42, 0.8, n) * m * smoothstep(0.0, 0.15, hh) * (1.0 - smoothstep(0.45, 1.0, hh));
}
vec3 stov(vec2 p){
  vec3 s = vec3(0.0);
  if (p.y < 40.0 || p.y > 200.0 || p.x < 150.0 || p.x > 345.0) return s;
  for (int i = 0; i < 16; i++) {
    float fi = float(i), h1 = hs(vec2(fi, 1.3)), h2 = hs(vec2(fi, 4.7)), h3 = hs(vec2(fi, 8.1));
    vec2 q = vec2(195.0 + h1 * 110.0 + sin(T * (0.25 + h2 * 0.3) + fi) * 8.0, 50.0 + fract(h2 + T * (0.01 + h3 * 0.015)) * 140.0);
    float dy = q.y - B0.y, inC = smoothstep(1.0, 0.5, abs(q.x - B0.x) / (20.0 + max(dy, 0.0) * 0.5)) * step(0.0, dy);
    vec2 d = p - q; float r2 = dot(d, d);
    s += LAMPC * inC * (0.55 + 0.45 * sin(T * 1.7 + fi * 3.0)) * (exp(-r2 / 0.8) * 0.8 + exp(-r2 / 6.0) * 0.1);
  }
  return s;
}
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  AA = 0.75 / uDpr; T = uT;
  SW = sin(T * 0.7) * 0.022 + sin(T * 1.9) * 0.005;
  float ph = fract(T / 3.2);
  PRESS = 2.0 * smoothstep(0.0, 0.03, ph) * (1.0 - smoothstep(0.06, 0.14, ph)); RING = ph / 0.3;
  AMB = mix(vec3(0.58, 0.56, 0.56), vec3(0.38, 0.34, 0.33), uNight);
  WINC = mix(uSkH * 0.85 + vec3(0.08), vec3(0.14, 0.2, 0.3), uNight) * (1.0 - 0.25 * uRain);
  B0 = vec2(249.0, -6.0) + rot(vec2(0.0, 47.0), -SW);
  LP0 = wpt(B0 + vec2(0.0, 2.0), 3.1);
  LP1 = wpt(vec2(10.0, -120.0), 3.4); LT1 = wpt(vec2(110.0, 170.0), 4.3);
  AEG = vec2(4.0, 66.0 + sin(T * 2.0) * 0.6);
  vec3 col;
  if (p.y < YB) { col = vegg(p); vindu(p, col, uRain); skilt(p, col); aegil(p, col); }
  else if (p.y < 212.0) disk(p, col);
  else front(p, col);
  pose(p, col);
  klokke(p, col);
  ringer(p, col);
  col += straale(p);
  lampe(p, col);
  float st = damp(p);
  if (st > 0.0) col = mix(col, vec3(0.95, 0.93, 0.9) * (AMB * 0.8 + LAMPC * 0.55 * exp(-(p.x - B0.x) * (p.x - B0.x) / 1600.0) + 0.1), st * 0.32);
  col += kjegle(p, B0 + vec2(0.0, 2.0)) + stov(p);
  vec2 vq = p / uRes - vec2(0.5, 0.42);
  col *= 1.0 - 0.32 * smoothstep(0.38, 0.9, length(vq * vec2(1.05, 0.95)));
  col = tm(max(col, 0.0)) + (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
