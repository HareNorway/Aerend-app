// Ægil · Fløyen (what moves) — the Launch prototype's own WebGL scene (`flGlTegn, second pass (FS2)` in
// «Ærend Kunde Launch.dc.html»), ported as is: reads the static city and adds the water, the boats and their wakes, the fountain, the Fløibanen car, rain and snow.
// Only the dialect changed (ui-tools/gl2flutter.py): uniforms one per line,
// FlutterFragCoord (top-left, so p is the design pixel), fragColor, and
// texture() without a mip bias — the biased reads come from pre-baked
// textures. Rendered offscreen into an image whose pixel grid is
// (uRes * uDpr), like meg_stadion.frag.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;
uniform sampler2D uTex; uniform vec2 uRes; uniform float uDpr;
uniform float uT;
uniform float uNight;
uniform float uRain;
uniform float uSnow;
uniform float uVis;
uniform vec3 uL;
uniform vec3 uV;
float T, AA;
const float CX = 195.0, YH = 26.0, FO = 400.0, HC = 320.0;
const vec2 OR = vec2(140.0, 1180.0), DA = vec2(0.743, 0.669), DN = vec2(-0.669, 0.743), LS = vec2(-204.0, 108.0);
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
vec4 tx(vec2 p){ return texture(uTex, vec2(p.x / uRes.x, p.y / uRes.y)); }
void baat(vec2 P, vec2 B, vec2 hd, float L, float W, float pf, float fa, inout vec3 c){
  vec2 r = P - B; float a = dot(r, hd), b = dot(r, vec2(-hd.y, hd.x));
  if (a > L || a < -L * 16.0 || abs(b) > L * 6.0) return;
  float ww = max(pf * 0.8, 1.5);
  vec3 hv = mix(uL * 0.9, c, fa);
  if (a < 0.0) {
    float e = abs(b) + a * 0.34;
    float arm = exp(-e * e / (ww * ww * 2.0)) * exp(a / (L * 7.0)) * smoothstep(0.0, -L, a);
    float mid = exp(-b * b / (W * W * 0.6 + ww * ww)) * exp(a / (L * 3.5));
    c = mix(c, hv, sat((arm * 0.45 + mid * 0.7) * (0.55 + 0.6 * vn(vec2(a * 0.25, b * 0.5) + T))));
  }
  float hb = W * 0.5 * sat((L * 0.5 - a) / (L * 0.3));
  float m = sat(min(L * 0.5 - abs(a), hb - abs(b)) / max(pf, 0.3) + 0.5);
  c = mix(c, mix(uL * 0.97, c, fa), m);
  c = mix(c, mix(uL * 0.25, c, fa), m * step(abs(a + L * 0.05), L * 0.18) * step(abs(b), W * 0.3));
  c += uV * 0.8 * m * step(abs(a - L * 0.3), L * 0.12) * uNight;
}
void fontene(vec2 p, inout vec3 col){
  vec2 d = p - vec2(165.1, 139.9);
  if (abs(d.x) > 5.0 || d.y > 1.5 || d.y < -10.0) return;
  float hh = 7.0 + 0.6 * sin(T * 1.7), u = sat(-d.y / hh);
  float x = d.x - 0.35 * sin(T * 0.6) * u * u, w = 0.35 + 0.9 * u * u;
  float m = (1.0 - smoothstep(w * 0.5, w, abs(x))) * step(d.y, 0.3) * (1.0 - smoothstep(hh * 0.9, hh * 1.1, -d.y));
  m *= 0.55 + 0.45 * vn(vec2(x * 4.0, d.y * 2.5 + T * 9.0));
  vec2 cq = vec2(x, d.y + hh) * vec2(0.8, 1.2);
  float cap = exp(-dot(cq, cq) / 2.2) * (0.5 + 0.5 * vn(vec2(x * 2.0 + T * 3.0, d.y * 2.0)));
  col = mix(col, uL * 0.95 + uV * 0.25, sat(m * 0.85 + cap * 0.7) * tx(p + vec2(0.0, 1.0 - d.y)).a);
}
void vogn(vec2 p, inout vec3 col){
  if (p.y < 149.0 || p.x < 280.0 || p.x > 345.0) return;
  float ph = mod(T + 30.0, 80.0);
  float zc = ph < 8.0 ? 1.6 : (ph < 38.0 ? mix(1.6, 9.5, smoothstep(8.0, 38.0, ph)) : (ph < 44.0 ? 99.0 : (ph < 74.0 ? mix(9.5, 1.6, smoothstep(44.0, 74.0, ph)) : 1.6)));
  float L = 1.7, z = 92.0 / (p.y - 140.0), c = (p.x - 312.0 - 10.0 / z) / (15.0 / z);
  if (z > zc && z < zc + L + 0.25 && abs(c) < 0.95) col *= 0.62;
  float yf0 = 140.0 + 62.0 / zc, yf1 = 140.0 + 92.0 / zc, cf = (p.x - 312.0 - 10.0 / zc) / (15.0 / zc);
  float zr = 62.0 / max(p.y - 140.0, 0.5), cr = (p.x - 312.0 - 10.0 / zr) / (15.0 / zr);
  vec3 bl = vec3(0.14, 0.33, 0.52) * uL;
  vec3 gls = mix(vec3(0.16, 0.22, 0.28), vec3(0.03, 0.04, 0.06), uNight) + uV * 0.6;
  if (p.y > yf0 && p.y < yf1 && abs(cf) < 0.78) {
    float v = (p.y - yf0) / (yf1 - yf0);
    vec3 fc = bl * 0.7;
    fc = mix(fc, gls + vec3(0.16) * smoothstep(0.25, 0.0, abs(cf * 0.5 + v - 0.35)) * (1.0 - uNight), step(0.14, v) * step(v, 0.6) * step(abs(cf), 0.62));
    fc = mix(fc, uL * 0.85, step(0.72, v) * step(v, 0.8));
    fc = mix(fc, vec3(1.0, 0.95, 0.85) * (0.6 + 1.6 * uNight), step(0.82, v) * step(v, 0.92) * step(0.4, abs(cf)) * step(abs(cf), 0.62));
    col = mix(col, fc, sat((0.78 - abs(cf)) * 15.0 / zc * uDpr + 0.5) * step(0.3, tx(vec2(p.x, yf0 - 1.0)).a + 0.5));
  } else if (zr > zc && zr < zc + L && abs(cr) < 0.78) {
    float vr = (zr - zc) / L;
    vec3 rc = uL * 0.72 * (1.0 - 0.25 * step(fract(vr * 4.0), 0.07));
    rc = mix(rc, gls, step(0.58, abs(cr)));
    rc = mix(rc, bl, step(0.72, abs(cr)));
    rc = mix(rc, uL * 0.95, uSnow * 0.85 * step(abs(cr), 0.58));
    vec4 bak = tx(p);
    col = mix(col, rc, sat((0.78 - abs(cr)) * 15.0 / zr * uDpr + 0.5) * (1.0 - step(0.35, bak.a) * step(bak.a, 0.65) * step(zr, zc + L * 0.0 + 4.6) * 0.0));
  }
}
float regn(vec2 p, float cw, float spd, float len, float sd){
  vec2 r = vec2(p.x + p.y * 0.16, p.y);
  float ci = floor(r.x / cw), lx = abs(fract(r.x / cw) - 0.5) * cw, h1 = hs(vec2(ci, sd)), per = 140.0 + h1 * 120.0;
  float ph = fract((r.y - T * spd * (0.85 + h1 * 0.3)) / per + hs(vec2(ci, sd + 3.0))), lp = len / per;
  return (1.0 - smoothstep(0.0, 0.5, lx)) * smoothstep(0.0, lp * 0.3, ph) * (1.0 - smoothstep(lp * 0.3, lp, ph)) * step(0.55, hs(vec2(ci, sd + 9.0)));
}
float sno(vec2 p, float sz, float spd, float sd){
  vec2 q = p / sz; q.y -= T * spd / sz; q.x += T * 0.22 + sin(q.y * 0.7 + sd + T * 0.6) * 0.3;
  vec2 id = floor(q), f = fract(q) - 0.5; float h = hs(id + sd);
  float d = length(f - (vec2(hs(id + sd + 1.3), hs(id + sd + 2.7)) - 0.5) * 0.55), r = 0.04 + h * 0.045;
  return smoothstep(r, r * 0.2, d) * step(0.45, h);
}
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  T = uT; AA = 1.0 / uDpr;
  vec4 s = tx(p); vec3 col = s.rgb; float m = s.a;
  vec3 bl = (tx(p + vec2(0.8, 0.3)).rgb + tx(p - vec2(0.8, 0.3)).rgb + tx(p + vec2(-0.3, 0.8)).rgb + tx(p + vec2(0.3, -0.8)).rgb) * 0.25;
  col = mix(col, bl, 0.22);
  vec3 gl = (tx(p + vec2(3.0, 0.0)).rgb + tx(p - vec2(3.0, 0.0)).rgb + tx(p + vec2(0.0, 3.0)).rgb + tx(p - vec2(0.0, 3.0)).rgb + tx(p + vec2(4.5, 4.5)).rgb + tx(p - vec2(4.5, 4.5)).rgb + tx(p + vec2(4.5, -4.5)).rgb + tx(p - vec2(4.5, -4.5)).rgb) * 0.125;
  col += max(gl - 0.62, 0.0) * 0.32;
  if (m > 0.15 && m < 0.4) {
    float k = sat((p.y - 115.0) / 100.0);
    vec2 o = vec2(sin(T * 1.3 + p.x * 0.07 + p.y * 0.03) + 0.6 * sin(T * 2.1 + p.y * 0.11), 0.25 * sin(T * 1.7 + p.x * 0.09)) * (0.15 + 0.55 * k) * (0.45 + 0.55 * vn(vec2(p.x * 0.02 + T * 0.25, p.y * 0.03)));
    vec4 s2 = tx(p + o); if (s2.a > 0.15 && s2.a < 0.4) col = mix(col, s2.rgb, 0.85);
  }
  if (m > 0.8) {
    float rx = (p.x - CX) / FO, ry = max((p.y - YH) / FO, 0.0004), t = HC / ry;
    vec2 sq = -vec2(dot(OR, DA), dot(OR, DN)) + vec2(dot(vec2(rx, 1.0), DA), dot(vec2(rx, 1.0), DN)) * t;
    float pf = t / (FO * uDpr), a = sat(1.6 - pf / 3.0), fa = sat(1.0 - exp(-t / uVis) + 0.04);
    float w = vn(sq * vec2(0.03, 0.08) + vec2(T * 0.2, T * 0.08)) - vn(sq * vec2(0.07, 0.15) - vec2(T * 0.3, -T * 0.12));
    col *= 1.0 + w * 0.06 * (0.35 + 0.65 * a);
    col *= 1.0 + 0.07 * (vn(sq * 0.006 + vec2(T * 0.012, T * 0.004)) - 0.5);
    col += uL * 0.12 * pow(vn(sq * 0.35 + vec2(T * 0.7, -T * 0.4)), 12.0) * a * (1.0 - uNight) * (1.0 - uRain);
    float lk = length(sq - LS);
    if (lk < 82.0) col += uL * 0.07 * sin(lk * 0.9 - T * 4.0) * exp(-lk / 16.0);
    baat(sq, vec2(mod(T * 6.5, 1900.0) - 10.0, -18.0), vec2(1.0, 0.0), 24.0, 6.0, pf, fa, col);
    baat(sq, mix(vec2(1500.0, -1100.0), vec2(2900.0, 1700.0), fract(T / 170.0)), vec2(0.447, 0.894), 40.0, 10.0, pf, fa, col);
    baat(sq, vec2(mod(T * 5.0 + 900.0, 2300.0) - 700.0, 955.0), vec2(1.0, 0.0), 14.0, 4.0, pf, fa, col);
    col += uV * 0.12 * smoothstep(0.85, 1.0, uNight) * (vn(vec2(p.x * 1.2, p.y * 0.9 - T * 1.5)) - 0.5) * sat(dot(col - uV * 0.2, vec3(0.6)) * 3.0 - 0.6) * (1.0 - fa);
  }
  fontene(p, col);
  vogn(p, col);
  if (uRain > 0.0) { float r = regn(p, 3.0, 380.0, 9.0, 1.0) * 0.25 + regn(p, 5.0, 560.0, 16.0, 7.0) * 0.4 + regn(p, 8.0, 760.0, 26.0, 13.0) * 0.5;
    col += vec3(0.75, 0.8, 0.85) * (0.06 + 0.2 * (1.0 - uNight)) * r * uRain; }
  if (uSnow > 0.0) { float sn = sno(p, 9.0, 14.0, 1.0) * 0.55 + sno(p, 16.0, 24.0, 5.0) * 0.85 + sno(p, 28.0, 40.0, 9.0);
    col = mix(col, vec3(0.93, 0.95, 1.0) * (0.55 + 0.35 * (1.0 - uNight)), sat(sn) * uSnow); }
  col += (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
