// Sporing · Tilberedes — the Launch prototype's own WebGL scene (`spKjInit / spKjTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: the kitchen: tiles, lamps, the shelf, the rack, the steel worktop, the real flames, the steam, Ægil as a texture.
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
uniform float uTexOk;
uniform sampler2D uTex;
uniform sampler2D uTexLo;
out vec4 fragColor;
float AA, T, FI, BURST, PUFF, LIFT, FLIP, HOP, LID, FOOD;
vec3 LP[4]; vec3 LC[4]; float LR[4];
vec2 LS[2]; float LA[2]; float UA[3];
vec3 AMB; vec2 AEG;
const float CX = 181.0, CY = 150.0, FL = 420.0, ZA = 4.2;
const vec3 FIREC = vec3(1.0, 0.5, 0.17);
const vec3 LAMPC = vec3(1.0, 0.85, 0.62);
vec4 upm(vec4 c){ return c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : c; }
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
float esd(vec2 p, vec2 r){ vec2 e = p / r; float k1 = length(e), k2 = length(e / r); return k1 * (k1 - 1.0) / max(k2, 1e-4); }
vec2 rot(vec2 p, float a){ float c = cos(a), s = sin(a); return vec2(c * p.x - s * p.y, s * p.x + c * p.y); }
vec2 proj(vec3 P){ return vec2(CX + FL * P.x / P.z, CY - FL * P.y / P.z); }
vec3 wpt(vec2 p, float z){ return vec3((p.x - CX) / FL * z, -(p.y - CY) / FL * z, z); }
vec4 aegT(vec2 s, float b){ vec2 uv = (s - AEG) / 210.0; if (uTexOk < 0.5 || uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0); return (b > 0.5 ? upm(texture(uTexLo, uv)) : upm(texture(uTex, uv))); }
float aegSkygge(vec3 P, vec3 L){ if (P.z <= ZA + 0.01 || L.z >= ZA) return 0.0; float u = (ZA - L.z) / (P.z - L.z); vec2 s = proj(L + (P - L) * u); return aegT(s, 2.8).a; }
float hylleSd(vec2 p){
  float d = rb(p, vec2(14.0, 96.0), vec2(98.0, 104.0));
  d = min(d, rb(p, vec2(21.5, 71.5), vec2(34.5, 94.5)) - 1.5);
  d = min(d, rb(p, vec2(43.5, 77.5), vec2(54.5, 94.5)) - 1.5);
  d = min(d, rb(p, vec2(63.5, 67.5), vec2(76.5, 94.5)) - 1.5);
  d = min(d, rb(p, vec2(83.5, 81.5), vec2(92.5, 94.5)) - 1.5);
  return d;
}
float redskapSd(vec2 p){
  float d = rb(p, vec2(222.0, 92.0), vec2(342.0, 96.0));
  vec2 q = rot(p - vec2(250.5, 96.0), -UA[0]);
  d = min(d, min(rb(q, vec2(-1.3, 0.0), vec2(1.3, 44.0)), rb(q, vec2(-6.5, 42.0), vec2(6.5, 60.0)) - 1.0));
  q = rot(p - vec2(288.5, 96.0), -UA[1]);
  d = min(d, min(rb(q, vec2(-1.5, 0.0), vec2(1.5, 34.0)), esd(q - vec2(0.0, 47.0), vec2(8.5, 14.0))));
  q = rot(p - vec2(326.5, 96.0), -UA[2]);
  d = min(d, min(rb(q, vec2(-1.3, 0.0), vec2(1.3, 38.0)), length(q - vec2(0.0, 46.0)) - 10.0));
  return d;
}
float dekor(vec2 p){
  float d = 1e3;
  if (p.x < 112.0 && p.y > 58.0 && p.y < 118.0) d = hylleSd(p);
  if (p.x > 214.0 && p.y > 84.0 && p.y < 170.0) d = min(d, redskapSd(p));
  return d;
}
vec3 lys(vec3 P, vec3 N, vec3 V, float gl, float shin, float sk, vec2 p, out vec3 spec){
  vec3 dif = AMB * (0.8 + 0.2 * N.y); spec = vec3(0.0);
  for (int i = 0; i < 4; i++) {
    vec3 L = LP[i] - P; float l2 = dot(L, L); L *= inversesqrt(l2);
    float at = 1.0 / (1.0 + l2 / (LR[i] * LR[i]));
    float spot = i < 2 ? mix(0.07, 1.0, smoothstep(0.2, 0.78, L.y)) : 1.0;
    float sh = 1.0;
    if (sk > 0.5) {
      sh = 1.0 - (i == 2 ? 0.8 : 0.6) * aegSkygge(P, LP[i]);
      if (i < 2) { vec2 o = normalize(p - LS[i]) * 5.0; sh *= 1.0 - 0.65 * (1.0 - smoothstep(-1.5, 5.0, dekor(p - o))); }
    }
    vec3 c = LC[i] * at * spot * sh;
    dif += c * max(dot(N, L), 0.0);
    spec += c * pow(max(dot(N, normalize(L + V)), 0.0), shin) * gl;
  }
  return dif;
}
vec3 rom(vec2 p){
  vec3 d = vec3((p.x - CX) / FL, -(p.y - CY) / FL, 1.0);
  float tB = 6.0, tS = 2.1 / max(abs(d.x), 1e-4), tF = d.y < 0.0 ? 2.0 / -d.y : 1e4, tC = d.y > 0.0 ? 2.14 / d.y : 1e4;
  float t = min(min(tB, tS), min(tF, tC));
  vec3 P = d * t, V = -normalize(d), N = vec3(0.0, 0.0, -1.0), A;
  float gl = 0.0, shin = 8.0, fw = t / FL / uDpr, sk = 0.0;
  if (t == tC) { N = vec3(0.0, -1.0, 0.0); A = vec3(0.4, 0.38, 0.36); }
  else if (t == tF) {
    N = vec3(0.0, 1.0, 0.0); float pl = P.x / 0.2, pi = floor(pl), zz = P.z / 1.3 + hs(vec2(pi, 1.0)), bi = floor(zz);
    A = vec3(0.5, 0.32, 0.2) * (0.75 + 0.35 * hs(vec2(pi, bi))) * (0.85 + 0.25 * fbm(vec2(P.x * 30.0, P.z * 3.0)));
    gl = 0.3; shin = 50.0;
  } else {
    vec3 T1 = vec3(1.0, 0.0, 0.0), T2 = vec3(0.0, 1.0, 0.0); vec2 uv = P.xy;
    if (t != tB) { float sx = sign(d.x); N = vec3(-sx, 0.0, 0.0); uv = vec2(P.z * sx, P.y); T1 = vec3(0.0, 0.0, sx); } else sk = 1.0;
    vec2 sz = vec2(0.3, 0.15); float row = floor(uv.y / sz.y), xx = uv.x / sz.x + mod(row, 2.0) * 0.5;
    vec2 id = vec2(floor(xx), row), f = vec2(fract(xx) * sz.x, fract(uv.y / sz.y) * sz.y) - sz * 0.5;
    vec2 hw = sz * 0.5 - 0.0065, q = abs(f) - hw;
    float grout = smoothstep(-fw, fw, max(q.x, q.y));
    vec2 bq = clamp((abs(f) - (hw - 0.024)) / 0.024, 0.0, 1.0), sl = sign(f) * bq * bq * 0.85 * (1.0 - grout);
    vec2 tl = (vec2(hs(id), hs(id + 3.7)) - 0.5) * 0.06 + (vec2(vn(uv * 7.0), vn(uv * 7.0 + 5.0)) - 0.5) * 0.05;
    N = normalize(N + T1 * (sl.x + tl.x) + T2 * (sl.y + tl.y));
    A = vec3(0.93, 0.96, 0.95) * (0.95 + 0.06 * hs(id + 1.3));
    float sot = smoothstep(0.45, 0.85, fbm(uv * 3.0)) * exp(-length(p - vec2(125.0, 205.0)) / 70.0);
    A = mix(A, vec3(0.6, 0.53, 0.4), sot * 0.55);
    A = mix(A, vec3(0.68, 0.69, 0.66) * (0.85 + 0.3 * vn(uv * 40.0)), grout);
    gl = 1.1 * (1.0 - grout); shin = 160.0;
  }
  vec3 sp; vec3 dif = lys(P, N, V, gl, shin, sk, p, sp);
  float F = 0.04 + 0.96 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
  return A * dif + sp + AMB * F * gl * 0.6;
}
vec3 stal(float nx){
  vec3 c = vec3(0.56, 0.59, 0.61) * (0.35 + 0.55 * smoothstep(-0.95, -0.2, nx) * smoothstep(0.95, 0.3, nx));
  c += vec3(1.0, 0.96, 0.9) * 0.85 * exp(-pow((nx + 0.38) / 0.13, 2.0));
  c += FIREC * FI * 0.3 * smoothstep(0.2, -0.9, nx);
  return c * (AMB * 0.9 + 0.45);
}
void glass(vec2 p, vec4 b, vec3 fc, inout vec3 col){
  float d = rb(p, b.xy + 1.5, b.zw - 1.5) - 1.5; if (d > 1.0) return;
  float c = cv(d), u = (p.x - b.x) / (b.z - b.x) * 2.0 - 1.0;
  float lid = smoothstep(b.y + 4.5, b.y + 3.5, p.y), fill = smoothstep(b.y + 8.0, b.y + 9.5, p.y);
  vec3 C = fc * (0.6 + 0.5 * vn(p * 1.5)) * (0.78 + 0.28 * (1.0 - u * u));
  vec3 J = mix(col * vec3(0.78, 0.85, 0.84), C * (AMB * 1.1 + LAMPC * 0.45 + FIREC * FI * 0.08), fill);
  J += vec3(1.0) * 0.5 * exp(-pow((u + 0.55) / 0.12, 2.0)) * (1.0 - lid);
  J += vec3(1.0) * 0.14 * exp(-pow((u - 0.62) / 0.1, 2.0)) * (1.0 - lid);
  J *= 1.0 - 0.4 * pow(abs(u), 5.0);
  vec3 Lc = mix(vec3(0.55, 0.42, 0.24), vec3(0.98, 0.86, 0.6), smoothstep(0.5, -0.6, u)) * (0.55 + 0.45 * smoothstep(b.y, b.y + 2.0, p.y)) * (AMB + 0.5);
  col = mix(col, mix(J, Lc, lid), c);
}
void hylle(vec2 p, inout vec3 col){
  glass(p, vec4(20.0, 70.0, 36.0, 96.0), vec3(0.8, 0.22, 0.12), col);
  glass(p, vec4(42.0, 76.0, 56.0, 96.0), vec3(0.9, 0.8, 0.6), col);
  glass(p, vec4(62.0, 66.0, 78.0, 96.0), vec3(0.3, 0.55, 0.24), col);
  glass(p, vec4(82.0, 80.0, 94.0, 96.0), vec3(0.94, 0.7, 0.16), col);
  float d = rb(p, vec2(14.0, 96.0), vec2(98.0, 104.0)) - 0.5;
  if (d < 1.0) { float g = fbm(vec2(p.x * 0.09, p.y * 1.1));
    vec3 W = vec3(0.56, 0.36, 0.22) * (0.75 + 0.4 * g) * mix(1.3, 0.75, smoothstep(97.5, 104.0, p.y));
    col = mix(col, W * (AMB * 1.1 + LAMPC * 0.45 + FIREC * FI * 0.1), cv(d)); }
}
void redskap(vec2 p, inout vec3 col){
  float d = rb(p, vec2(222.0, 92.0), vec2(342.0, 96.0)) - 0.6;
  if (d < 1.0) col = mix(col, stal((p.y - 94.0) / 2.6), cv(d));
  vec2 q = rot(p - vec2(250.5, 96.0), -UA[0]); float dd;
  dd = rb(q, vec2(-1.3, 0.0), vec2(1.3, 44.0)); if (dd < 1.0) col = mix(col, stal(q.x / 1.3), cv(dd));
  dd = max(rb(q, vec2(-5.5, 43.0), vec2(5.5, 59.0)) - 1.0, -max(abs(mod(q.x + 6.0, 4.0) - 2.0) - 0.6, abs(q.y - 52.0) - 4.5));
  if (dd < 1.0) col = mix(col, stal(q.x / 8.0 - 0.1), cv(dd));
  q = rot(p - vec2(288.5, 96.0), -UA[1]);
  dd = rb(q, vec2(-1.5, 0.0), vec2(1.5, 34.0)); if (dd < 1.0) col = mix(col, stal(q.x / 1.5), cv(dd));
  for (int k = 0; k < 3; k++) { float rx = 2.8 + float(k) * 2.8; dd = abs(esd(q - vec2(0.0, 47.0), vec2(rx, 14.0))) - 0.5; if (dd < 1.0) col = mix(col, stal(q.x / 9.0), cv(dd)); }
  q = rot(p - vec2(326.5, 96.0), -UA[2]);
  dd = rb(q, vec2(-1.3, 0.0), vec2(1.3, 38.0)); if (dd < 1.0) col = mix(col, stal(q.x / 1.3), cv(dd));
  dd = length(q - vec2(0.0, 46.0)) - 10.0;
  if (dd < 1.0) { vec2 e = (q - vec2(0.0, 46.0)) / 10.0; vec3 S = stal(e.x * 0.9) * (0.8 + 0.3 * (1.0 - e.y)); S += vec3(1.0) * 0.6 * exp(-dot(e - vec2(-0.35, -0.4), e - vec2(-0.35, -0.4)) * 16.0); col = mix(col, S, cv(dd)); }
}
void lampe(vec2 p, float hx, float a, inout vec3 col){
  vec2 q = rot(p - vec2(hx, -4.0), -a);
  if (abs(q.x) > 40.0 || q.y > 110.0) return;
  float d = rb(q, vec2(-1.1, -10.0), vec2(1.1, 50.0)); if (d < 1.0) col = mix(col, vec3(0.04), cv(d));
  float yt = 50.0, yb = 74.0, k = sat((q.y - yt) / (yb - yt)), hw = mix(8.0, 20.0, k * 0.65 + k * k * 0.35);
  float ds = max(abs(q.x) - hw, max(yt - q.y, q.y - yb));
  if (ds < 1.0) {
    float nx = q.x / hw;
    vec3 E = mix(vec3(0.95, 0.42, 0.2), vec3(0.66, 0.22, 0.08), k * 0.5) * (0.5 + 0.5 * (1.0 - nx * nx));
    E += vec3(1.0, 0.92, 0.82) * 0.6 * exp(-pow((nx + 0.45) / 0.13, 2.0)) * (1.0 - k * 0.5);
    E += vec3(1.0, 0.8, 0.5) * 0.35 * smoothstep(yb - 3.0, yb, q.y);
    col = mix(col, E * (AMB * 1.2 + 0.4), cv(ds));
  }
  float bulb = esd(q - vec2(0.0, yb), vec2(hw - 2.5, 3.0));
  if (bulb < 1.5) col = mix(col, vec3(2.8, 2.35, 1.7), cv(bulb) * step(yb - 0.5, q.y));
  float r = length((q - vec2(0.0, yb + 1.5)) * vec2(0.55, 1.0));
  col += LAMPC * (0.6 * exp(-r * r / 50.0) + 0.14 * exp(-r / 20.0)) * smoothstep(yb - 8.0, yb + 2.0, q.y);
}
vec3 kjegle(vec2 p, vec2 b){
  float dy = p.y - b.y; if (dy < 0.0 || dy > 240.0) return vec3(0.0);
  float w = 15.0 + dy * 0.38;
  float c = pow(sat(1.0 - abs(p.x - b.x) / w), 1.5) * smoothstep(0.0, 12.0, dy) * (1.0 - smoothstep(110.0, 230.0, dy));
  if (c <= 0.0) return vec3(0.0);
  float n = 0.5 + 0.7 * fbm(vec2(p.x * 0.035, p.y * 0.022 - T * 0.1));
  vec2 g = p / 8.0 + vec2(sin(T * 0.13) * 1.5, T * 0.09); vec2 id = floor(g), f = fract(g) - 0.5 - (vec2(hs(id + 1.0), hs(id + 2.0)) - 0.5) * 0.6;
  float mo = step(0.88, hs(id)) * exp(-dot(f, f) * 160.0) * (0.5 + 0.5 * sin(T * 2.0 + hs(id) * 30.0));
  return LAMPC * c * (n * 0.07 + mo * 0.7);
}
vec3 potSteel(float nx, float y){
  vec3 c = mix(vec3(0.15, 0.16, 0.17), vec3(0.8, 0.82, 0.82), smoothstep(0.55, 0.97, abs(nx)));
  c += vec3(0.4, 0.42, 0.43) * exp(-pow((nx + 0.1) / 0.2, 2.0));
  c += vec3(1.0, 0.95, 0.86) * 1.3 * exp(-pow((nx + 0.55) / 0.06, 2.0));
  c += vec3(1.0, 0.95, 0.86) * 0.9 * exp(-pow((nx - 0.42) / 0.05, 2.0));
  c += FIREC * FI * 0.9 * exp(-pow((nx + 0.84) / 0.13, 2.0));
  c *= mix(1.0, 0.5, smoothstep(228.0, 262.0, y)) * (AMB * 0.7 + 0.55);
  c += FIREC * 0.12 * smoothstep(250.0, 262.0, y) * (0.8 + 0.2 * sin(T * 7.0));
  return c;
}
vec3 blaa(vec2 p, vec2 c, vec2 r){
  float d = esd(p - c, r); if (abs(d) > 8.0) return vec3(0.0);
  vec2 e = (p - c) / r; float ang = atan(e.y, e.x);
  float tg = vn(vec2(ang * 9.0, T * 7.0)) * 0.55 + 0.45 * (0.5 + 0.5 * sin(ang * 28.0 + T * 3.0));
  float f = exp(-d * d / (5.0 + tg * 9.0)) * (0.5 + 0.5 * tg) * step(c.y - 1.0, p.y);
  return vec3(0.2, 0.42, 1.0) * f * 0.9 + vec3(0.7, 0.85, 1.0) * pow(f, 3.0) * 0.6;
}
void bacon(vec2 p, vec2 c, vec2 r, float inn, inout vec3 col){
  vec2 f = (p - c - vec2(0.0, 3.0 - FOOD)) / (r * vec2(0.66, 0.56));
  float cf = cos(FLIP); f.y /= max(abs(cf), 0.18);
  if (abs(f.x) > 1.05 || abs(f.y) > 1.3) return;
  float clipM = mix(inn, 1.0, smoothstep(2.0, 10.0, FOOD));
  for (int k = 0; k < 3; k++) {
    float fk = float(k), yk = (fk - 1.0) * 0.66;
    float v = (f.y - yk - 0.1 * sin(f.x * 6.0 + fk * 2.0)) / 0.34, len = 0.9 - abs(fk - 1.0) * 0.1;
    float d = max(abs(v) - 1.0, (abs(f.x) - len) * 4.0);
    col *= 1.0 - 0.35 * (1.0 - smoothstep(0.0, 0.6, d)) * inn;
    if (d < 0.25) {
      float a = 1.0 - smoothstep(-0.15, 0.08, d);
      float fat = smoothstep(0.14, 0.26, abs(v)) * (1.0 - smoothstep(0.46, 0.58, abs(v))) + smoothstep(0.8, 0.92, abs(v)) * 0.8;
      vec3 B = mix(vec3(0.6, 0.18, 0.12), vec3(0.9, 0.74, 0.58), fat);
      B = mix(B, vec3(0.36, 0.15, 0.07), smoothstep(0.4, 0.85, fbm(vec2(f.x * 7.0 + fk * 3.0, v * 1.4))) * 0.7);
      B *= mix(1.0, 0.55, smoothstep(0.75, 1.0, abs(v)) + smoothstep(len - 0.12, len, abs(f.x)));
      if (cf < 0.0) B = mix(B, vec3(0.45, 0.2, 0.09), 0.45);
      vec3 Cb = B * (0.7 + 0.4 * (1.0 - v * v)) * (AMB * 0.85 + LAMPC * 0.25 + FIREC * FI * 0.32);
      Cb += vec3(1.0, 0.92, 0.8) * pow(vn(vec2(f.x * 22.0 + fk * 7.0, v * 2.5 + T * 0.5)), 14.0) * 0.7 * (0.6 + 0.6 * FI);
      col = mix(col, Cb, a * clipM);
    }
  }
}
float panne(vec2 p, inout vec3 col){
  vec2 c = vec2(125.0, 227.0 - LIFT), r = vec2(59.0, 21.0 + LIFT * 0.3);
  float h = 9.0;
  if (p.x < 58.0 || p.x > 236.0 || p.y < c.y - 30.0 - FOOD || p.y > 270.0) return 0.0;
  float fm = 0.0;
  vec2 hq = rot(p - vec2(c.x + r.x - 6.0, c.y + 5.0), 0.1);
  float dh = rb(hq, vec2(0.0, -4.0), vec2(50.0, 4.0)) - 1.6;
  if (dh < 1.0) { float u = hq.y / 5.5; vec3 H = vec3(0.08, 0.085, 0.09) * (0.7 + 0.6 * (1.0 - u * u)) + vec3(1.0) * 0.2 * exp(-pow((u + 0.45) / 0.18, 2.0));
    float rv = min(length(hq - vec2(5.0, 0.0)), length(hq - vec2(11.0, 0.0))) - 1.6; H = mix(H, vec3(0.55), cv(rv) * 0.8);
    col = mix(col, H * (AMB + 0.4), cv(dh)); }
  float d1 = esd(p - c, r);
  vec2 cb = c + vec2(0.0, h), rB = r * 0.86;
  float d2 = esd(p - cb, rB), k = sat((p.y - c.y) / h);
  float d3 = max(abs(p.x - c.x) - mix(r.x, rB.x, k), max(c.y - p.y, p.y - cb.y));
  float sil = min(d1, min(d2, d3));
  if (sil > 0.0) col += blaa(p, cb + vec2(0.0, 2.0), rB * vec2(0.92, 0.95)) * (0.8 + 0.4 * FI);
  if (sil < 1.0) {
    float nx = (p.x - c.x) / r.x;
    vec3 O = vec3(0.07, 0.075, 0.08) * (0.6 + 0.5 * (1.0 - nx * nx)) + vec3(1.0, 0.95, 0.9) * 0.22 * exp(-pow((nx + 0.5) / 0.1, 2.0));
    O += vec3(0.25, 0.45, 1.0) * 0.07 * smoothstep(c.y + h * 0.4, cb.y + rB.y, p.y);
    col = mix(col, O * (AMB * 0.8 + 0.5), cv(sil));
    fm = cv(sil) * step(c.y, p.y);
  }
  if (d1 < 1.0) {
    vec2 e = (p - c) / r;
    float lip = cv(d1) * (1.0 - cv(d1 + 3.2)), inn = cv(d1 + 3.2);
    vec3 Lp = vec3(0.55, 0.57, 0.58) * (0.55 + 0.5 * smoothstep(0.2, -0.8, e.y)) + FIREC * FI * 0.65 * smoothstep(-0.2, 0.8, e.y);
    Lp += vec3(1.0) * 0.55 * exp(-dot(e - vec2(-0.6, -0.65), e - vec2(-0.6, -0.65)) * 20.0);
    vec2 ci = c + vec2(0.0, 3.0); float df = esd(p - ci, r * vec2(0.84, 0.74));
    vec3 I = vec3(0.035, 0.035, 0.04);
    I = mix(I * 1.7 + vec3(0.03), I, cv(df));
    I += FIREC * FI * 0.6 * (1.0 - smoothstep(0.0, 1.1, length((p - ci) / r))) * (0.75 + 0.35 * BURST);
    col = mix(col, I, inn);
    bacon(p, c, r, inn * cv(df), col);
    vec2 g = (p - c) / 4.5, id = floor(g), fr = fract(g) - 0.5 - (vec2(hs(id + 1.3), hs(id + 2.9)) - 0.5) * 0.5;
    float h1 = hs(id), ph = fract(T * (0.9 + h1) + h1 * 9.0);
    col += vec3(1.0, 0.85, 0.6) * smoothstep(0.08, 0.0, abs(length(fr) - ph * 0.38)) * (1.0 - ph) * step(0.55, h1) * 0.55 * inn * cv(df);
    col = mix(col, Lp * (AMB * 0.6 + 0.6), lip);
    fm = max(fm, lip * step(c.y, p.y));
  } else if (FOOD > 2.0) bacon(p, c, r, 0.0, col);
  return fm;
}
void gryte(vec2 p, inout vec3 col){
  if (p.x < 214.0 || p.x > 336.0 || p.y < 160.0 || p.y > 272.0) return;
  vec2 lc = vec2(275.0, 187.0 - LID);
  float dh = min(rb(p, vec2(221.0, 207.0), vec2(238.0, 218.0)), rb(p, vec2(312.0, 207.0), vec2(329.0, 218.0))) - 2.5;
  if (dh < 1.0) { float u = (p.y - 212.5) / 6.0; vec3 H = vec3(0.09) * (0.7 + 0.6 * (1.0 - u * u)) + vec3(1.0) * 0.14 * exp(-pow((u + 0.5) / 0.2, 2.0)); col = mix(col, H * (AMB + 0.45), cv(dh)); }
  float db = rb(p, vec2(246.0, 196.0), vec2(304.0, 252.0)) - 10.0;
  if (db > 0.0 && p.y > 248.0) col *= 1.0 - 0.45 * (1.0 - smoothstep(0.0, 7.0, esd(p - vec2(275.0, 262.0), vec2(46.0, 5.0))));
  if (db < 1.0) {
    vec3 S = potSteel((p.x - 275.0) / 39.0, p.y);
    float rim = smoothstep(4.0, 0.0, abs(p.y - 191.0)); S = mix(S, S * 1.25 + 0.05, rim * 0.5);
    col = mix(col, S, cv(db)); }
  float dl = min(esd(p - lc, vec2(43.0, 8.0)), max(esd(p - lc - vec2(0.0, -1.0), vec2(36.0, 13.0)), p.y - lc.y));
  if (dl < 1.0) { vec2 e = (p - lc) / vec2(43.0, 13.0);
    vec3 S = vec3(0.62, 0.64, 0.66) * (0.55 + 0.45 * smoothstep(0.6, -0.6, e.y));
    S += vec3(1.0, 0.96, 0.9) * 0.9 * exp(-dot(e - vec2(0.3, -0.45), e - vec2(0.3, -0.45)) * 30.0);
    S += vec3(1.0, 0.96, 0.9) * 0.5 * exp(-dot(e - vec2(-0.45, -0.3), e - vec2(-0.45, -0.3)) * 40.0);
    S += FIREC * FI * 0.35 * smoothstep(0.0, -0.9, e.x);
    S *= AMB * 0.7 + 0.55;
    S += vec3(0.4) * smoothstep(1.5, 0.0, abs(esd(p - lc, vec2(43.0, 8.0)))) * step(lc.y, p.y);
    col = mix(col, S, cv(dl)); }
  vec2 kc = lc + vec2(0.0, -14.0); float dk = length((p - kc) * vec2(1.0, 1.3)) - 5.0;
  if (dk < 1.0) { vec2 e = (p - kc) / 5.0; col = mix(col, vec3(0.06) + vec3(1.0) * 0.35 * exp(-dot(e - vec2(-0.3, -0.4), e - vec2(-0.3, -0.4)) * 6.0), cv(dk)); }
}
float ild(vec2 p, vec2 b, float hgt, float wid){
  vec2 q = vec2((p.x - b.x) / wid, (b.y - p.y) / hgt);
  if (q.y < -0.2 || q.y > 1.4 || abs(q.x) > 1.5) return 0.0;
  float n1 = fbm(vec2(q.x * 2.4, q.y * 1.7 - T * 2.2));
  float n2 = vn(vec2(q.x * 7.0 + 3.0, q.y * 5.0 - T * 4.8));
  float tong = 0.5 + 0.5 * sin(q.x * 9.0 + n1 * 6.0 + T * 1.3);
  float w = 0.95 * pow(sat(1.0 - q.y), 0.65) - tong * 0.22 * q.y;
  float dx = abs(q.x + (n1 - 0.5) * 0.7 * q.y);
  float f = sat((w - dx) * 1.6 + (n1 - 0.5) * 1.3 + (n2 - 0.5) * 0.45);
  return f * smoothstep(-0.18, 0.06, q.y) * (1.0 - smoothstep(0.7, 1.3, q.y + (n2 - 0.5) * 0.3));
}
vec3 ildF(float f){ return vec3(1.0, 0.3, 0.05) * smoothstep(0.0, 0.45, f) * 1.15 + vec3(0.75, 0.5, 0.12) * smoothstep(0.35, 0.85, f) * 1.15 + vec3(0.45, 0.42, 0.3) * smoothstep(0.82, 1.0, f) * 0.7; }
float damp(vec2 p){
  float hh = (180.0 - LID - p.y) / 150.0; if (hh < 0.0 || hh > 1.0 || abs(p.x - 280.0) > 95.0) return 0.0;
  float cxs = 275.0 + sin(hh * 3.2 - T * 0.5) * 12.0 * hh + hh * hh * 18.0, w = 24.0 + hh * 54.0;
  float m = smoothstep(1.0, 0.25, abs(p.x - cxs) / w);
  if (m <= 0.0) return 0.0;
  vec2 q = vec2(p.x * 0.028, p.y * 0.022 + T * 0.42);
  float n = fbm(q + vec2(fbm(q * 1.7 - vec2(0.0, T * 0.2)), 0.0) * 0.8);
  return smoothstep(0.36, 0.78, n) * m * smoothstep(0.0, 0.1, hh) * (1.0 - smoothstep(0.55, 1.0, hh)) * (0.6 + 0.6 * PUFF);
}
vec3 gnister(vec2 p){
  vec3 s = vec3(0.0);
  for (int i = 0; i < 14; i++) {
    float fi = float(i), h1 = hs(vec2(fi, 3.0)), h2 = hs(vec2(fi, 7.0)), ph = fract(T * (0.45 + h1 * 0.5) + h2);
    vec2 q = vec2(125.0 + (h1 - 0.5) * 70.0 + sin(ph * 6.0 + fi) * 10.0 * ph + (h2 - 0.5) * 40.0 * ph, 212.0 - LIFT - ph * (110.0 + h2 * 80.0));
    vec2 d = p - q; float r2 = dot(d, d);
    s += mix(vec3(1.0, 0.85, 0.5), vec3(1.0, 0.35, 0.08), ph) * (1.0 - ph) * (1.0 - ph) * (0.6 + 0.4 * sin(T * 30.0 + fi * 5.0)) * (exp(-r2 / 1.3) * 1.6 + exp(-r2 / 14.0) * 0.18);
  }
  return s;
}
void knott(vec2 p, vec2 c, float ang, float on, inout vec3 col){
  float r = length(p - c);
  col *= 1.0 - 0.45 * (1.0 - smoothstep(0.0, 5.0, r - 7.0)) * step(c.y, p.y);
  if (r < 9.0) { vec2 e = (p - c) / 7.5;
    vec3 K = vec3(0.72, 0.74, 0.76) * (0.5 + 0.5 * (1.0 - length(e - vec2(-0.3, -0.35))));
    K += vec3(1.0) * 0.55 * exp(-dot(e - vec2(-0.35, -0.4), e - vec2(-0.35, -0.4)) * 10.0);
    K *= mix(1.0, 0.65, smoothstep(0.75, 1.0, length(e)));
    vec2 rd = rot(vec2(0.0, -1.0), ang);
    float ln = max(abs(dot(e, vec2(-rd.y, rd.x))) - 0.08, -dot(e, rd));
    K = mix(K, vec3(0.12), (1.0 - smoothstep(0.0, 0.07, ln)) * step(length(e), 0.82));
    col = mix(col, K * (AMB * 0.8 + 0.5), cv(r - 7.5)); }
  if (on > 0.5) { float l = length(p - c - vec2(0.0, -13.0)); col += vec3(1.0, 0.42, 0.18) * (cv(l - 1.8) * 1.6 + 0.35 * exp(-l * l / 18.0)) * (0.9 + 0.1 * sin(T * 3.0)); }
}
void benk(vec2 p, inout vec3 col){
  vec3 d = vec3((p.x - CX) / FL, -(p.y - CY) / FL, 1.0); float t = 0.9 / -d.y; vec3 P = d * t, V = -normalize(d);
  float br = vn(vec2(p.x * 0.012, p.y * 1.6)) * 0.6 + vn(vec2(p.x * 0.05, p.y * 4.0)) * 0.4;
  vec3 N = normalize(vec3(0.0, 1.0, (br - 0.5) * 0.08));
  vec3 sp; vec3 dif = lys(P, N, V, 0.5, 40.0, 0.0, p, sp);
  float F = 0.04 + 0.96 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
  vec2 s = vec2(p.x + (br - 0.5) * 6.0, 522.0 - p.y);
  vec3 R = AMB * vec3(0.82, 0.9, 0.96) * 0.5 + FIREC * FI * 1.1 * exp(-pow((s.x - 125.0) / 34.0, 2.0) - pow((s.y - 190.0) / 60.0, 2.0));
  R += vec3(0.9, 0.93, 0.95) * 0.3 * exp(-pow((s.x - 275.0) / 30.0, 2.0)) * smoothstep(262.0, 276.0, p.y);
  R += LAMPC * 0.35 * (exp(-pow((s.x - LS[0].x) / 16.0, 2.0)) + exp(-pow((s.x - LS[1].x) / 16.0, 2.0))) * smoothstep(250.0, 276.0, p.y);
  vec3 C = vec3(0.42, 0.45, 0.47) * (0.88 + 0.2 * br) * dif * 0.65 + sp * 0.8 + R * (0.22 + 0.6 * F);
  C *= 1.0 - 0.5 * (1.0 - smoothstep(0.0, 9.0, esd(p - vec2(125.0, 259.0), vec2(56.0, 7.0))));
  C = mix(C, vec3(0.85, 0.87, 0.88) * (AMB + 0.35), smoothstep(272.5, 275.0, p.y) * smoothstep(277.5, 275.5, p.y));
  col = C * mix(0.5, 1.0, smoothstep(250.0, 254.5, p.y));
}
void front(vec2 p, inout vec3 col){
  vec3 C;
  if (p.y < 294.0) {
    float u = (p.y - 277.0) / 17.0;
    C = vec3(0.6, 0.62, 0.63) * (0.72 + 0.38 * (1.0 - u)) * (0.92 + 0.12 * vn(vec2(p.x * 0.02, p.y * 3.0)));
    C = C * (AMB * 1.2 + 0.25) + FIREC * FI * 0.12 * exp(-pow((p.x - 125.0) / 60.0, 2.0));
    C *= mix(1.0, 0.6, smoothstep(290.0, 294.0, p.y));
  } else if (p.x < 36.0 || p.x > 326.0) {
    float x = p.x < 36.0 ? p.x : p.x - 326.0;
    vec3 W = vec3(0.6, 0.4, 0.25) * (0.8 + 0.3 * fbm(vec2(p.x * 0.6, p.y * 0.05)));
    float fr = rb(vec2(x, p.y), vec2(4.0, 299.0), vec2(32.0, 412.0));
    W *= 1.0 - 0.4 * (1.0 - smoothstep(0.0, 1.6, abs(fr)));
    W *= (AMB * 1.1 + 0.15 + FIREC * FI * 0.05) * mix(0.5, 1.0, smoothstep(294.0, 312.0, p.y));
    vec2 kp = vec2(p.x < 36.0 ? 29.0 : 333.0, 314.0);
    C = mix(W, vec3(0.8) * (AMB + 0.35), cv(length(p - kp) - 2.2));
  } else {
    C = mix(vec3(0.16, 0.17, 0.19), vec3(0.055, 0.06, 0.07), smoothstep(294.0, 330.0, p.y));
    C += vec3(1.0) * 0.05 * smoothstep(0.035, 0.0, abs((p.x - 36.0) / 290.0 - (p.y - 294.0) / 160.0 - 0.18));
    float dp = rb(p, vec2(60.0, 330.0), vec2(302.0, 374.0)) - 8.0;
    if (dp < 1.0) { vec3 G = vec3(0.022, 0.026, 0.03) + LAMPC * 0.06 * (exp(-pow((p.x - LS[0].x) / 22.0, 2.0)) + exp(-pow((p.x - LS[1].x) / 22.0, 2.0))) * smoothstep(374.0, 330.0, p.y);
      G += vec3(1.0) * 0.07 * smoothstep(1.2, 0.0, abs(dp + 1.0));
      C = mix(C, G, cv(dp)); }
    C *= mix(0.6, 1.0, smoothstep(294.0, 300.0, p.y));
    knott(p, vec2(77.0, 353.0), -0.9, 1.0, C); knott(p, vec2(119.0, 353.0), 0.0, 0.0, C);
    knott(p, vec2(243.0, 353.0), 0.6, 1.0, C); knott(p, vec2(285.0, 353.0), 0.0, 0.0, C);
  }
  col = C;
}
vec3 tm(vec3 c){ vec3 k = max(c - 0.62, 0.0); return min(c, 0.62) + 0.38 * (1.0 - exp(-k / 0.38)); }
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  AA = 0.75 / uDpr; T = uT;
  float ph = fract(T / 6.0), kk = sat(ph / 0.15), up = sin(3.14159 * kk) * step(ph, 0.15);
  LIFT = up * 7.0; FLIP = kk * 3.14159 * step(ph, 0.15); HOP = up * 3.0; FOOD = up * 32.0;
  BURST = ph > 0.15 ? exp(-(ph - 0.15) * 16.0) : 0.0;
  PUFF = exp(-fract(T / 3.4) * 3.5); LID = abs(sin(T * 36.0)) * 1.6 * smoothstep(0.35, 0.8, PUFF);
  FI = (0.86 + 0.14 * sin(T * 11.0) * sin(T * 4.3 + 1.0) + 0.08 * (vn(vec2(T * 9.0, 0.0)) - 0.5)) * (1.0 + 0.9 * BURST);
  AMB = mix(vec3(0.66, 0.69, 0.7), vec3(0.5, 0.53, 0.56), uNight);
  AEG = vec2(45.0, 113.0 + sin(T * 2.1) * 0.8 - HOP);
  for (int i = 0; i < 2; i++) {
    float fi = float(i), hx = fi < 0.5 ? 98.0 : 266.0, a = sin(T * 0.8 + fi * 1.9) * 0.022 + sin(T * 1.7 + fi) * 0.006;
    LA[i] = a; vec2 b = vec2(hx, -4.0) + rot(vec2(0.0, 76.0), a); LS[i] = b; LP[i] = wpt(b, 3.6); LC[i] = LAMPC * 1.3; LR[i] = 2.4;
  }
  LP[2] = wpt(vec2(125.0, 196.0 - LIFT), 3.4); LC[2] = FIREC * 1.6 * FI; LR[2] = 1.3;
  LP[3] = wpt(vec2(275.0, 262.0), 3.4); LC[3] = vec3(1.0, 0.5, 0.25) * 0.35 * (0.9 + 0.1 * sin(T * 7.0)); LR[3] = 0.7;
  UA[0] = sin(T * 1.3) * 0.03; UA[1] = sin(T * 1.1 + 1.0) * 0.035; UA[2] = sin(T * 0.95 + 2.0) * 0.03;
  vec2 pb = p;
  float hz = smoothstep(75.0, 25.0, abs(p.x - 125.0)) * smoothstep(30.0, 110.0, p.y) * smoothstep(215.0, 165.0, p.y);
  if (hz > 0.0) pb += (vec2(vn(p * 0.14 + vec2(0.0, T * 3.0)), vn(p * 0.14 + vec2(5.0, T * 3.4))) - 0.5) * 3.2 * hz * (0.7 + 0.6 * BURST);
  vec3 col;
  if (p.y < 250.0) {
    col = rom(pb);
    if (pb.x < 110.0 && pb.y > 60.0 && pb.y < 110.0) hylle(pb, col);
    if (pb.x > 215.0 && pb.y > 85.0 && pb.y < 168.0) redskap(pb, col);
    vec4 a = aegT(pb, 0.0);
    if (a.a > 0.004) {
      float e = 1.4 / 210.0; vec2 uv = (pb - AEG) / 210.0;
      vec2 gr = vec2(texture(uTex, uv + vec2(e, 0.0)).a - texture(uTex, uv - vec2(e, 0.0)).a, texture(uTex, uv + vec2(0.0, e)).a - texture(uTex, uv - vec2(0.0, e)).a);
      float edge = sat(length(gr) * 1.6); vec2 on = -gr / max(length(gr), 1e-4);
      float rimF = sat(dot(on, normalize(vec2(125.0, 205.0 - LIFT) - pb))) * edge;
      float rimL = (sat(dot(on, normalize(LS[0] - pb))) + sat(dot(on, normalize(LS[1] - pb)))) * 0.5 * edge;
      vec3 lit = AMB * 1.05 + LAMPC * 0.42 * smoothstep(260.0, 120.0, pb.y) + FIREC * FI * 0.55 * exp(-length(pb - vec2(125.0, 205.0)) / 90.0);
      vec3 ac = a.rgb * lit + FIREC * FI * rimF * 0.9 + LAMPC * rimL * 0.25;
      ac *= mix(1.0, 0.72, smoothstep(205.0, 250.0, pb.y));
      col = mix(col, ac, a.a);
    }
  } else if (p.y < 277.0) benk(p, col);
  else front(p, col);
  gryte(p, col);
  float fm = panne(p, col);
  if (p.x > 40.0 && p.x < 215.0 && p.y > 50.0 && p.y < 245.0) {
    float hg = 62.0 * (1.0 + 0.7 * BURST) * (0.92 + 0.08 * FI);
    float f = ild(p, vec2(125.0, 223.0 - LIFT), hg, 44.0 * (1.0 + 0.18 * BURST));
    col += ildF(f) * (1.0 - fm) * (0.85 + 0.25 * FI);
    float sm = smoothstep(0.5, 0.85, fbm(vec2(p.x * 0.03, p.y * 0.025 + T * 0.4))) * smoothstep(60.0, 10.0, abs(p.x - 125.0 - (150.0 - p.y) * 0.15)) * smoothstep(150.0, 95.0, p.y) * smoothstep(0.0, 60.0, p.y);
    col = mix(col, vec3(0.4, 0.38, 0.36) * (AMB + 0.3), sm * 0.12);
  }
  col += FIREC * FI * 0.16 * exp(-length((p - vec2(125.0, 190.0 - LIFT)) / vec2(80.0, 65.0)));
  lampe(p, 98.0, LA[0], col); lampe(p, 266.0, LA[1], col);
  float st = damp(p);
  if (st > 0.0) { float ls = exp(-pow((p.x - LS[1].x) / 50.0, 2.0)); col = mix(col, vec3(0.93, 0.95, 0.96) * (AMB * 0.9 + LAMPC * 0.5 * ls + 0.16), st * 0.72); }
  if (p.x > 30.0 && p.x < 225.0 && p.y > 10.0 && p.y < 235.0) col += gnister(p);
  col += kjegle(p, LS[0]) + kjegle(p, LS[1]);
  vec2 vq = p / uRes - vec2(0.5, 0.4);
  col *= 1.0 - 0.3 * smoothstep(0.35, 0.85, length(vq * vec2(1.1, 0.9)));
  col = tm(max(col, 0.0)) + (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
