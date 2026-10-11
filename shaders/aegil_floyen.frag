// Ægil · Fløyen (the static city) — the Launch prototype's own WebGL scene (`flGlInit / flGlTegn, first pass` in
// «Ærend Kunde Launch.dc.html»), ported as is: the view from Fløyen: the ray-traced blocks, Vågen, Nordnes, the fjords, the mountains and the forest, drawn once per weather; alpha is the material mask the second pass reads.
// Only the dialect changed (ui-tools/gl2flutter.py): uniforms one per line,
// FlutterFragCoord (top-left, so p is the design pixel), fragColor, and
// texture() without a mip bias — the biased reads come from pre-baked
// textures. Rendered offscreen into an image whose pixel grid is
// (uRes * uDpr), like meg_stadion.frag.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;
uniform vec2 uRes; uniform float uDpr;
uniform float uT;
uniform float uNight;
uniform float uSun;
uniform float uSunset;
uniform float uRain;
uniform float uSnow;
uniform float uWet;
uniform float uCY;
uniform float uVis;
uniform vec3 uSkT;
uniform vec3 uSkM;
uniform vec3 uSkB;
float AA, T, LYS, PF, MAT;
vec3 AMB, SUNC, SSC, FOGC, CLDC, VARM;
vec2 O2;
const float CX = 195.0, YH = 26.0, FO = 400.0, HC = 320.0, CS = 16.0, HMX = 27.0, STN = 0.659;
const vec2 OR = vec2(140.0, 1180.0), DA = vec2(0.743, 0.669), DN = vec2(-0.669, 0.743), LS = vec2(-204.0, 108.0), SQ = vec2(-0.999, -0.035);
const vec3 SL = vec3(-0.6, 0.55, -0.58);
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
vec3 lit(float k){ return AMB * (0.78 + 0.22 * k) + SUNC * uSun * k + SSC * uSunset * k * 0.8; }
vec3 n3(vec2 nq, float up){ vec2 x = nq.x * DA + nq.y * DN; return normalize(vec3(x.x, up, x.y)); }
vec3 himmel(vec2 p){
  vec3 c = mix(uSkT, uSkB, sat((p.y + 40.0) / 66.0));
  c += vec3(0.28, 0.13, 0.04) * uSunset * smoothstep(-30.0, 26.0, p.y) * 0.6;
  if (uNight > 0.3) {
    vec2 g = p / 3.0, id = floor(g), f = fract(g) - 0.5 - (vec2(hs(id + 1.0), hs(id + 2.0)) - 0.5) * 0.6;
    float h = hs(id);
    c += vec3(0.85, 0.9, 1.0) * step(0.985, h) * exp(-dot(f, f) * 40.0) * (0.55 + 0.45 * sin(T * (1.0 + h * 3.0) + h * 60.0)) * (uNight - 0.3) * 1.5 * (1.0 - uRain) * (1.0 - 0.85 * uSnow);
  }
  vec2 q = p * vec2(0.0075, 0.02) + vec2(T * 0.006, 0.0);
  vec2 w = vec2(fbm(q * 1.7 + vec2(1.7, 9.2) + T * 0.006), 0.0);
  float d1 = fbm(q + w * 0.9), d2 = fbm(q + w * 0.9 + vec2(-0.03, -0.05));
  float den = smoothstep(0.5 - 0.16 * max(uRain, uSnow), 0.84, d1);
  vec3 cc = mix(CLDC * 0.82, CLDC * 1.12 + 0.04 * (1.0 - uNight), sat((d1 - d2) * 7.0 + 0.5)) + vec3(0.3, 0.16, 0.06) * uSunset * 0.5;
  return mix(c, cc, den * 0.9);
}
float skyS(vec2 P){ return 1.0 - 0.7 * uSun * smoothstep(0.52, 0.7, fbm(P * 0.0007 + vec2(T * 0.006, T * 0.0025))); }
float hLov(float x){ return 60.0 + 415.0 * pow(1.0 - smoothstep(-30.0, 215.0, x), 1.15) + 16.0 * (vn(vec2(x * 0.05, 1.0)) - 0.5) + 5.0 * (vn(vec2(x * 0.22, 2.0)) - 0.5); }
float hAsk(float x){ return 25.0 + 150.0 * smoothstep(296.0, 385.0, x) + 26.0 * (vn(vec2(x * 0.045, 4.0)) - 0.5) + 6.0 * (vn(vec2(x * 0.25, 5.0)) - 0.5); }
float hLyd(float x){ return 40.0 + 360.0 * exp(-pow(abs(x - 186.0) / 44.0, 1.5)) + 70.0 * exp(-pow((x - 128.0) / 34.0, 2.0)) + 14.0 * (vn(vec2(x * 0.08, 6.0)) - 0.5); }
float hSot(float x){ return 30.0 + 150.0 * vn(vec2(x * 0.02, 8.0)) + 30.0 * (vn(vec2(x * 0.09, 9.0)) - 0.5); }
vec3 fjellF(vec2 p, float D, float sd, float topp, inout vec3 glow){
  float X = (p.x - CX) * D / FO, Y = HC - (p.y - YH) * D / FO;
  vec2 m = vec2(X, Y) * vec2(0.0045, 0.009) + sd;
  float n = fbm(m), gx = fbm(m + vec2(0.06, 0.0)) - n, gy = fbm(m + vec2(0.0, 0.06)) - n;
  vec3 N = normalize(vec3(-gx * 9.0 - 0.1, 0.55 + gy * 9.0, -1.0));
  float gu = 1.0 - abs(sin(X * 0.0045 + vn(vec2(X, Y) * 0.003 + sd) * 4.0 + Y * 0.002));
  float k = max(dot(N, SL) + 0.3 * (gu * gu - 0.4), 0.0), rel = Y / max(topp, 1.0);
  vec3 sk = mix(vec3(0.05, 0.09, 0.05), vec3(0.13, 0.16, 0.08), vn(vec2(X, Y) * 0.02 + sd));
  sk = mix(sk, vec3(0.36, 0.32, 0.14), smoothstep(0.55, 0.85, vn(vec2(X * 0.006, Y * 0.03) + sd * 2.0)) * 0.4);
  sk *= (0.55 + 0.7 * (vn(vec2(X, Y) * 0.09 + sd) * 0.6 + vn(vec2(X, Y) * 0.3 + sd) * 0.4)) * (0.75 + 0.5 * gu);
  vec3 ly = mix(vec3(0.34, 0.31, 0.19), vec3(0.46, 0.45, 0.42), smoothstep(0.55, 0.75, n));
  float ht = smoothstep(0.62, 0.86, rel + 0.25 * (vn(vec2(X * 0.01, 3.0 + sd)) - 0.5)) * step(220.0, topp);
  vec3 c = mix(sk, ly * (0.7 + 0.5 * vn(vec2(X, Y) * 0.15)), ht);
  c = mix(c, vec3(0.42, 0.41, 0.39) * (0.8 + 0.3 * vn(vec2(X, Y) * 0.2)), smoothstep(0.012, 0.03, length(vec2(gx, gy))) * smoothstep(0.35, 0.7, rel) * 0.7);
  float hz = smoothstep(95.0, 40.0, Y + 40.0 * (vn(vec2(X * 0.006, sd)) - 0.5)) * step(D, 6600.0), hm = 0.0, hl = 0.0;
  if (hz > 0.0) { vec2 id = floor(vec2(X / 12.0, Y / 7.0)); float hh = hs(id + sd);
    vec3 hc = hh < 0.55 ? vec3(0.86, 0.85, 0.8) : (hh < 0.8 ? vec3(0.55, 0.25, 0.16) : vec3(0.3, 0.3, 0.32));
    hm = hz * step(0.5, hs(id + 3.0 + sd)); c = mix(c, hc, hm * 0.75); hl = hm * step(0.45, hs(id + 7.0)); }
  c = mix(c, vec3(0.88, 0.9, 0.94), uSnow * smoothstep(0.25, 0.55, k + rel * 0.3));
  c *= lit(k * 1.1 * skyS(vec2(X, D)));
  float tk = fbm(vec2(X * 0.0012 - T * 0.01, Y * 0.006) + sd * 1.7);
  float fa = sat(1.0 - exp(-D * (0.8 + 0.5 * tk) / uVis) + 0.08 + (0.16 + 0.22 * max(uRain, uSnow)) * smoothstep(0.55, 0.05, rel) * smoothstep(0.35, 0.7, tk));
  glow += VARM * LYS * 0.7 * hl * smoothstep(0.8, 1.0, uNight) * (1.0 - 0.5 * uRain) * (1.0 - fa);
  return mix(c, FOGC, fa);
}
float tupp(float q){
  float nord = 1050.0 + 330.0 * sqrt(sat(1.0 - (q - 450.0) * (q - 450.0) / 136900.0));
  float laks = 1050.0 + min(max(q - 1100.0, 0.0) * 1.6, 1500.0);
  float b = q < 820.0 ? (q > 80.0 ? nord : 1050.0) : (q < 1100.0 ? 1050.0 : laks);
  return b + 40.0 * (vn(vec2(q * 0.011, 3.0)) - 0.5) + 14.0 * (vn(vec2(q * 0.05, 7.0)) - 0.5);
}
float sjoL(vec2 sq){ vec2 a = abs(sq - LS); return 82.0 - max(max(a.x, a.y), (a.x + a.y) * 0.7071); }
float vannD2(vec2 sq, float tp){
  float s = sq.x, q = sq.y;
  float dV = min(80.0 + 0.07 * max(s, 0.0) - abs(q), s + 10.0);
  float dP = min(130.0 + 0.05 * max(s, 0.0) - abs(q - 960.0), s + 900.0);
  return max(max(dV, dP), max(s - tp, sjoL(sq)));
}
float vannD(vec2 sq){ return vannD2(sq, tupp(sq.y)); }
vec4 rute(vec2 ce){
  float q = (ce.y + 0.5) * CS, s = (ce.x + 0.5) * CS;
  vec4 n = q < -82.0 ? vec4(4.0, 3.0, 1.0, 0.0) : (q > 1080.0 ? vec4(4.0, 4.0, 2.0, 1.0) : ((q > 240.0 && s > -260.0) ? vec4(5.0, 4.0, 2.0, 1.0) : vec4(6.0, 5.0, 0.0, 0.0)));
  return vec4(mod(ce.x + n.z, n.x), mod(ce.y + n.w, n.y), n.x, n.y);
}
float bygg(vec2 ce, out vec4 bx, out float sty, out float rid, out float hc){
  vec2 c0 = ce * CS, cm = c0 + 0.5 * CS;
  bx = vec4(c0, c0 + CS); sty = 0.0; rid = 2.0; hc = hs(ce);
  vec4 ru = rute(ce);
  float i6 = ru.x, j5 = ru.y;
  if (i6 > ru.z - 1.5 || j5 > ru.w - 1.5) return 0.0;
  float s = cm.x, q = cm.y;
  if (s > -84.0 && s < 6.0 && abs(q) < 96.0) return 0.0;
  if (s > -172.0 && s < -84.0 && q > -12.0 && q < 74.0) return 0.0;
  if (sjoL(cm) > -52.0) return 0.0;
  float tp = tupp(q);
  if (vannD2(cm, tp) > -13.0) return 0.0;
  if (q > 90.0 && q < 820.0 && s > tp - 200.0) return 0.0;
  float hb = hs(ce - ru.xy + 3.1), h2 = hs(ce + 5.7), h3 = hs(ce + 11.3);
  bool ytre = i6 < 0.5 || i6 > ru.z - 2.5 || j5 < 0.5 || j5 > ru.w - 2.5;
  float h, g;
  float rs = (j5 < 0.5 || j5 > ru.w - 2.5) ? 0.0 : 1.0;
  if (hb > 0.72 && abs(i6 - 2.0) < 0.5 && h3 < 0.6) return 0.0;
  if (q < -82.0) { sty = 2.0; h = 8.0 + 6.0 * h2; rid = 1.0; g = (q > -160.0 && s > -20.0 && s < 430.0) ? 0.25 : 1.2 + 1.8 * h3; }
  else if (q > 1080.0) { sty = 3.0; h = 6.0 + 5.0 * h2; g = 1.5 + 2.0 * h3; rid = step(0.5, h3); if (h3 > 0.72) return 0.0; }
  else if (q > 240.0 && s > -260.0) { sty = 1.0; h = 7.0 + 9.0 * h2 * h2; g = 0.4 + 1.6 * step(0.6, h3); rid = rs; }
  else { sty = 0.0; h = 12.0 + 13.0 * h2 * (0.6 + 0.4 * hb); g = 0.25; rid = h3 > 0.86 ? 2.0 : rs; }
  if (hb > 0.94 && sty < 1.5) { sty = 4.0; rid = 2.0; return 17.0 + 120.0 * (hb - 0.94); }
  if (!ytre) { if (h3 < 0.5) return 0.0; h = 4.0 + 3.0 * h2; rid = 2.0; }
  bx += vec4(g, g, -g, -g);
  return min(h, HMX);
}
void spes(int i, out vec4 bx, out vec2 hy, out float sty){
  if (i == 0) { bx = vec4(-150.0, 12.0, -122.0, 50.0); hy = vec2(0.0, 58.0); sty = 5.0; }
  else if (i == 1) { bx = vec4(492.0, 85.0, 628.0, 105.0); hy = vec2(0.0, 9.0); sty = 6.0; }
  else if (i == 2) { bx = vec4(500.0, 87.5, 590.0, 102.5); hy = vec2(9.0, 22.0); sty = 7.0; }
  else if (i == 3) { bx = vec4(556.0, 92.0, 566.0, 98.0); hy = vec2(22.0, 28.0); sty = 8.0; }
  else if (i == 4) { bx = vec4(-208.0, 800.0, -192.0, 1110.0); hy = vec2(21.0, 24.0); sty = 9.0; }
  else if (i == 5) { bx = vec4(-204.0, 905.0, -196.0, 911.0); hy = vec2(0.0, 21.0); sty = 9.0; }
  else { bx = vec4(-204.0, 1010.0, -196.0, 1016.0); hy = vec2(0.0, 21.0); sty = 9.0; }
}
float rbox(vec2 d2, float ry, vec4 bx, vec2 hy, out float fc){
  vec2 t1 = (bx.xy - O2) / d2, t2 = (bx.zw - O2) / d2;
  vec2 tn = min(t1, t2), tf = max(t1, t2);
  float tN = max(tn.x, tn.y), tF = min(tf.x, tf.y);
  float tT = (HC - hy.y) / ry, tB = (HC - hy.x) / ry;
  float te = max(tN, tT);
  fc = tT >= tN ? 0.0 : (tn.x > tn.y ? 1.0 : 2.0);
  return te < min(tF, tB) ? te : -1.0;
}
float skygge(vec2 sq, float y0){
  if (uSun + uSunset < 0.01) return 1.0;
  float sh = 1.0;
  vec2 ce0 = floor(sq / CS);
  for (int k = 0; k < 4; k++) {
    vec4 bx; float sty, rid, hc;
    float h = bygg(ce0 - vec2(float(k), 0.0), bx, sty, rid, hc);
    if (h <= y0) continue;
    vec2 t1 = (bx.xy - sq) / SQ, t2 = (bx.zw - sq) / SQ;
    vec2 tn = min(t1, t2), tf = max(t1, t2);
    float dN = max(max(tn.x, tn.y), 0.0), dF = min(tf.x, tf.y);
    if (dN < dF) sh = min(sh, smoothstep(-1.0, 1.0, y0 + dN * STN - h));
  }
  for (int i = 0; i < 7; i++) {
    vec4 bx; vec2 hy; float sty; spes(i, bx, hy, sty);
    vec2 t1 = (bx.xy - sq) / SQ, t2 = (bx.zw - sq) / SQ;
    vec2 tn = min(t1, t2), tf = max(t1, t2);
    float a = max(max(max(tn.x, tn.y), 0.0), (hy.x - y0) / STN), b = min(min(tf.x, tf.y), (hy.y - y0) / STN);
    if (a < b) sh = min(sh, 0.0);
  }
  return sh;
}
vec3 fasF(float sty, float k, vec2 sq){
  if (sty < 0.5) return k < 0.4 ? vec3(0.84, 0.83, 0.8) : (k < 0.56 ? vec3(0.82, 0.79, 0.71) : (k < 0.7 ? vec3(0.72, 0.72, 0.71) : (k < 0.8 ? vec3(0.54, 0.4, 0.34) : (k < 0.91 ? vec3(0.8, 0.76, 0.66) : vec3(0.62, 0.61, 0.58)))));
  if (sty < 1.5) return k < 0.62 ? vec3(0.87, 0.86, 0.84) : (k < 0.76 ? vec3(0.84, 0.79, 0.62) : (k < 0.88 ? vec3(0.58, 0.32, 0.26) : vec3(0.74, 0.77, 0.75)));
  if (sty < 2.5) {
    if (sq.y > -160.0 && sq.x > -20.0 && sq.x < 430.0) return k < 0.3 ? vec3(0.56, 0.24, 0.18) : (k < 0.55 ? vec3(0.8, 0.68, 0.44) : (k < 0.78 ? vec3(0.86, 0.84, 0.8) : vec3(0.68, 0.43, 0.24)));
    return k < 0.7 ? vec3(0.87, 0.86, 0.84) : (k < 0.85 ? vec3(0.8, 0.75, 0.6) : vec3(0.56, 0.3, 0.24));
  }
  if (sty < 3.5) return k < 0.65 ? vec3(0.85, 0.84, 0.82) : (k < 0.82 ? vec3(0.77, 0.73, 0.63) : vec3(0.55, 0.31, 0.24));
  if (sty < 4.5) return k < 0.5 ? vec3(0.8, 0.8, 0.79) : vec3(0.6, 0.62, 0.64);
  if (sty < 5.5) return vec3(0.42, 0.4, 0.37);
  if (sty < 6.5) return vec3(0.1, 0.1, 0.12);
  if (sty < 7.5) return vec3(0.93, 0.93, 0.92);
  if (sty < 8.5) return vec3(0.75, 0.15, 0.12);
  return vec3(0.68, 0.68, 0.66);
}
vec3 takF(float sty, float k){
  if (sty < 0.5) return k < 0.5 ? vec3(0.23, 0.24, 0.26) : (k < 0.72 ? vec3(0.15, 0.15, 0.16) : (k < 0.88 ? vec3(0.45, 0.27, 0.21) : (k < 0.95 ? vec3(0.42, 0.42, 0.41) : vec3(0.4, 0.5, 0.46))));
  if (sty < 1.5) return k < 0.36 ? vec3(0.48, 0.28, 0.21) : (k < 0.85 ? vec3(0.2, 0.21, 0.22) : vec3(0.44, 0.44, 0.43));
  if (sty < 3.5) return k < 0.45 ? vec3(0.24, 0.21, 0.2) : (k < 0.8 ? vec3(0.44, 0.26, 0.2) : vec3(0.33, 0.34, 0.35));
  if (sty < 4.5) return vec3(0.4, 0.4, 0.39);
  if (sty < 5.5) return vec3(0.3, 0.29, 0.28);
  if (sty < 6.5) return vec3(0.82, 0.8, 0.76);
  if (sty < 7.5) return vec3(0.9, 0.9, 0.89);
  if (sty < 8.5) return vec3(0.12, 0.12, 0.13);
  return vec3(0.5, 0.5, 0.49);
}
vec3 byggF(vec2 sq, float Y, float fc, vec2 d2, vec4 bx, vec2 hy, float sty, float rid, float hc, float t, vec2 P){
  float pf = t * PF;
  vec2 nq = fc < 0.5 ? vec2(0.0) : (fc < 1.5 ? vec2(-sign(d2.x), 0.0) : vec2(0.0, -sign(d2.y)));
  float sh = skygge(sq + nq * 0.3, Y + (fc < 0.5 ? 0.05 : 0.0)) * skyS(P);
  float k1 = fract(hc * 7.31), k2 = fract(hc * 3.71 + 0.13);
  vec3 glz = mix(uSkB * 0.55, vec3(0.05, 0.06, 0.08), 0.45 + 0.45 * uNight) * (AMB + 0.25);
  vec3 c;
  if (fc < 0.5) {
    vec2 m = (bx.xy + bx.zw) * 0.5, hw = max((bx.zw - bx.xy) * 0.5, vec2(0.5));
    vec2 lq = (sq - m) / hw;
    vec3 rc = takF(sty, k2), N = vec3(0.0, 1.0, 0.0);
    if (rid < 1.5) {
      float v = rid < 0.5 ? lq.y : lq.x;
      N = n3(rid < 0.5 ? vec2(0.0, sign(v) * 0.62) : vec2(sign(v) * 0.62, 0.0), 0.78);
      rc *= 1.0 + 0.22 * (1.0 - smoothstep(0.0, 0.1 + pf * 0.08, abs(v)));
      rc *= 0.93 + 0.07 * sat(1.4 - pf) * step(0.5, fract((rid < 0.5 ? sq.y : sq.x) * 1.4));
    } else {
      rc *= 0.85 + 0.25 * vn(sq * 0.7);
      float ed = min(hw.x - abs(sq.x - m.x), hw.y - abs(sq.y - m.y));
      rc = mix(rc * 1.25, rc, smoothstep(0.2, 0.8, ed));
      vec2 gq = floor(sq / 4.0), fq = sq - gq * 4.0 - 2.0;
      rc = mix(rc, rc * 1.35 + 0.05, step(0.8, hs(gq + hc)) * step(max(abs(fq.x), abs(fq.y)), 1.0) * step(1.5, ed) * sat(1.5 - pf));
    }
    rc = mix(rc, vec3(0.9, 0.92, 0.95), uSnow * 0.78 * step(sty, 7.5));
    c = rc * lit(max(dot(N, SL), 0.0) * sh);
    c *= 1.0 - 0.25 * (1.0 - smoothstep(0.0, 0.5 + pf * 0.5, min(hw.x - abs(sq.x - m.x), hw.y - abs(sq.y - m.y))));
  } else {
    float u = fc < 1.5 ? sq.y - bx.y : sq.x - bx.x;
    vec3 fcol = fasF(sty, k1, sq) * (0.9 + 0.12 * vn(vec2(u * 0.4, Y * 0.3) + hc * 9.0)) * (0.88 + 0.16 * fract(hc * 13.7)) * (0.86 + 0.14 * smoothstep(0.0, 9.0, Y));
    if (sty > 5.5 && sty < 6.5) { fcol = mix(fcol, vec3(0.55, 0.12, 0.1), step(Y, 1.6)); fcol = mix(fcol, vec3(0.9), step(7.6, Y)); }
    float kd = max(dot(n3(nq, 0.0), SL), 0.0);
    float hasW = (sty < 5.5 || (sty > 6.5 && sty < 7.5)) ? 1.0 : 0.0;
    float fl = sty > 6.5 ? 2.6 : (sty > 4.5 ? 3.4 : 3.1);
    vec2 wg = vec2(u / 3.2, Y / fl), wi = floor(wg), wf = fract(wg);
    float win = step(0.28, wf.x) * step(wf.x, 0.72) * step(0.3, wf.y) * step(wf.y, 0.8) * step(2.8, Y) * step(Y, hy.y - 1.0) * hasW;
    float wa = sat(1.6 - pf / 1.6);
    float ln = smoothstep(0.8, 1.0, uNight) * (1.0 - 0.5 * uRain);
    float lyst = step(0.97 - 0.55 * ln, hs(wi + hc * 17.0 + nq));
    vec3 cf = fcol * lit(kd * sh);
    vec3 cw = glz + VARM * (0.25 + 1.0 * ln) * 1.1 * lyst * mix(1.0, 0.35, smoothstep(1.0, 3.0, pf)) + vec3(0.1) * uSun * kd * step(0.85, hs(wi + 3.0 + hc));
    c = mix(cf, cw, win * wa + (1.0 - wa) * 0.22 * hasW);
    c *= 0.62 + 0.38 * smoothstep(0.0, 5.0, Y - hy.x);
    c *= 1.0 - 0.2 * (1.0 - smoothstep(0.0, 0.6 + pf * 0.4, hy.y - Y));
  }
  float nb = vn(sq * 0.0055 + 17.0), nb2 = vn(sq * 0.019 + 3.0);
  c *= 0.82 + 0.32 * nb;
  c *= mix(vec3(1.0), vec3(1.05, 0.99, 0.92), smoothstep(0.45, 0.85, nb2)) * mix(vec3(1.0), vec3(0.94, 0.98, 1.04), smoothstep(0.55, 0.15, nb2));
  if (fc < 0.5) c += uWet * 0.07 * mix(uSkB, uSkM, 0.5) * (0.6 + 0.4 * vn(sq * 0.4)) * sat(1.2 - pf * 0.15);
  return c;
}
vec3 landF(vec2 sq, vec2 P, float t, float wd, inout vec3 glow){
  float pf = t * PF;
  vec2 ce = floor(sq / CS), f = sq - ce * CS;
  vec4 ru = rute(ce);
  float i6 = ru.x, j5 = ru.y, s = sq.x, q = sq.y;
  bool gate = i6 > ru.z - 1.5 || j5 > ru.w - 1.5;
  bool rad = j5 > ru.w - 1.5;
  bool torg = (s > -84.0 && s < 6.0 && abs(q) < 96.0) || (s > -172.0 && s < -84.0 && q > -12.0 && q < 74.0);
  bool park = sjoL(sq) > -52.0 || (q > 90.0 && q < 820.0 && s > tupp(q) - 200.0);
  float sh = skygge(sq, 0.0) * skyS(P), tre = 0.0;
  vec3 c;
  if (wd > -13.0) c = vec3(0.6, 0.59, 0.56) * (0.9 + 0.15 * vn(sq * 0.5));
  else if (torg) { c = vec3(0.62, 0.6, 0.56) * (0.88 + 0.16 * vn(sq * 0.4)); c *= 0.95 + 0.05 * step(0.5, fract((sq.x + sq.y) * 0.25)) * sat(1.4 - pf); }
  else if (park || !gate) {
    bool gard = !park;
    c = gard ? mix(vec3(0.3, 0.36, 0.17), vec3(0.46, 0.45, 0.42), step(0.55, hs(floor(sq / 16.0) + 4.0))) * (0.8 + 0.3 * vn(sq * 0.3)) : vec3(0.28, 0.36, 0.14) * (0.8 + 0.3 * vn(sq * 0.12));
    c *= gard ? 0.7 : 1.0;
    vec2 gi = floor(sq / 7.0);
    float bK = -1.0, bA = 0.0; vec3 bC = c;
    for (int j = 0; j < 3; j++) { for (int i = 0; i < 3; i++) {
      vec2 cid = gi + vec2(float(i) - 1.0, float(j) - 1.0); float h = hs(cid + 2.0);
      if (h < (gard ? 0.48 : 0.24)) continue;
      vec2 ctr = (cid + 0.5 + (vec2(hs(cid + 4.0), hs(cid + 6.0)) - 0.5) * 0.7) * 7.0, d = sq - ctr;
      float r = 2.8 + 1.6 * hs(cid + 8.0), l = length(d) / r;
      float cov = sat((r - length(d)) / max(pf, 0.25) + 0.5);
      if (cov <= 0.0) continue;
      float dm = sqrt(max(1.0 - l * l, 0.0));
      float kk = max(dot(normalize(vec3(d / r, dm + 0.2)), vec3(SQ * 0.835, 0.55)), 0.0) * (0.7 + 0.5 * vn(d * 1.3 + cid * 5.0));
      float ka = sat(vn(cid * 0.31 + 2.0) * 0.8 + hs(cid + 9.0) * 0.4);
      vec3 tc = ka < 0.32 ? vec3(0.22, 0.29, 0.13) : (ka < 0.56 ? vec3(0.5, 0.46, 0.18) : (ka < 0.8 ? vec3(0.56, 0.41, 0.15) : vec3(0.47, 0.26, 0.12)));
      tc *= 0.75 + 0.45 * vn(d * 2.2 + cid * 3.0);
      if (dm > bK) { bK = dm; bA = cov; bC = tc * (0.45 + 0.75 * kk); }
    } }
    vec2 sp = sq - SQ * 3.5; vec2 gs = floor(sp / 7.0);
    c *= 1.0 - 0.35 * step(0.28, hs(gs + 2.0)) * step(length(sp - (gs + 0.5 + (vec2(hs(gs + 4.0), hs(gs + 6.0)) - 0.5) * 0.7) * 7.0), 3.2) * uSun;
    c = mix(c, bC, bA); tre = bA;
  } else if (gate) {
    float cr = rad ? f.y - 8.0 : f.x - 8.0, al = rad ? sq.x : sq.y, sid = rad ? ce.y : ce.x + 500.0;
    c = vec3(0.29, 0.29, 0.3) * (0.85 + 0.25 * vn(sq * 0.35));
    c = mix(c, vec3(0.55, 0.54, 0.51), step(5.6, abs(cr)));
    if (abs(cr) < 4.8) {
      float dir = cr > 0.0 ? 1.0 : -1.0, spd = 5.0 + 5.0 * hs(vec2(sid, dir));
      float a = al - T * spd * dir, ci = floor(a / 9.0), fa = a - ci * 9.0, hh = hs(vec2(ci, sid * 3.0 + dir));
      if (hh > 0.55) {
        float m = step(abs(fa - 4.5), 2.2) * step(abs(abs(cr) - 2.4), 0.9);
        vec3 cc = hh < 0.68 ? vec3(0.85) : (hh < 0.78 ? vec3(0.1) : (hh < 0.86 ? vec3(0.45) : (hh < 0.93 ? vec3(0.6, 0.12, 0.1) : vec3(0.15, 0.25, 0.5))));
        c = mix(c, cc, m * sat(1.6 - pf / 2.5));
        glow += vec3(1.0, 0.92, 0.8) * smoothstep(0.8, 1.0, uNight) * 0.5 * m * sat(2.0 - pf / 3.0);
      }
    }
    float tid = hs(vec2(sid, 9.0));
    if (tid > 0.5) {
      float ta = mod(al + 5.0 * hs(vec2(sid, 2.0)), 9.0) - 4.5; vec2 dq = vec2(ta, abs(cr) - 6.4); float rt = 2.4 + 0.6 * hs(vec2(floor((al + 5.0 * hs(vec2(sid, 2.0))) / 9.0), sid)), l = length(dq) / rt;
      if (l < 1.0) { float dm = sqrt(1.0 - l * l); float kk = max(dot(normalize(vec3(dq / rt, dm + 0.2)), vec3(SQ * 0.835, 0.55)), 0.0) * (0.7 + 0.5 * vn(sq * 1.3));
        c = mix(c, mix(vec3(0.24, 0.3, 0.13), vec3(0.52, 0.43, 0.17), fract(tid * 7.0)) * (0.42 + 0.75 * kk), sat((1.0 - l) * rt / max(pf, 0.25))); tre = 1.0; }
      else c *= 1.0 - 0.3 * uSun * step(length(dq + vec2(-SQ.x * 3.0, 0.0)) / rt, 1.0);
    }
    vec2 lp = vec2(abs(cr) - 6.0, mod(al, 24.0) - 12.0);
    glow += VARM * LYS * 0.6 * smoothstep(0.8, 1.0, uNight) * exp(-dot(lp, lp) / (1.0 + pf * pf * 0.5));
  } else c = mix(vec3(0.34, 0.4, 0.18) * (0.8 + 0.3 * vn(sq * 0.3)), vec3(0.5, 0.49, 0.46), step(0.5, hs(floor(sq / 32.0))));
  c = mix(c, vec3(0.88, 0.9, 0.94), uSnow * (gate ? 0.3 : 0.7));
  c *= mix(1.0, 0.68, uWet * (1.0 - tre));
  c *= lit(0.55 * sh);
  c += uWet * 0.1 * mix(uSkB, uSkM, 0.5) * (gate ? 1.0 : 0.4);
  c *= 0.82 + 0.32 * vn(sq * 0.0055 + 17.0);
  return c;
}
void baat(vec2 P, vec2 B, vec2 hd, float L, float W, float pf, inout vec3 c){
  vec2 r = P - B; float a = dot(r, hd), b = dot(r, vec2(-hd.y, hd.x));
  if (a > L || a < -L * 16.0 || abs(b) > L * 6.0) return;
  float ww = max(pf * 0.8, 1.5);
  if (a < 0.0) {
    float e = abs(b) + a * 0.34;
    float arm = exp(-e * e / (ww * ww * 2.0)) * exp(a / (L * 7.0)) * smoothstep(0.0, -L, a);
    float mid = exp(-b * b / (W * W * 0.6 + ww * ww)) * exp(a / (L * 3.5));
    c = mix(c, vec3(0.88, 0.91, 0.93) * lit(0.75), sat((arm * 0.5 + mid * 0.75) * (0.55 + 0.6 * vn(vec2(a * 0.25, b * 0.5) + T))));
  }
  float hb = W * 0.5 * sat((L * 0.5 - a) / (L * 0.3));
  float m = sat(min(L * 0.5 - abs(a), hb - abs(b)) / max(pf, 0.3) + 0.5);
  c = mix(c, vec3(0.92, 0.92, 0.9) * lit(0.85), m);
  c = mix(c, vec3(0.2, 0.22, 0.25) * lit(0.6), m * step(abs(a + L * 0.05), L * 0.18) * step(abs(b), W * 0.3));
}
vec3 vannF(vec2 p, vec2 sq, float t, float wd, float ry, inout vec3 glow){
  float pf = t * PF, a = sat(1.6 - pf / 3.0);
  vec2 wq = sq * 0.04;
  float w1 = vn(wq + vec2(T * 0.22, T * 0.09)), w2 = vn(wq * 2.7 - vec2(T * 0.31, -T * 0.12));
  float sl = ((w1 - 0.5) * 0.6 + (w2 - 0.5) * 0.4) * (0.4 + 0.6 * a) * (1.0 + uRain);
  float ce = ry / sqrt(1.0 + ry * ry);
  float fr = 0.02 + 0.98 * pow(1.0 - sat(ce + sl * 0.18), 5.0);
  vec3 refl = himmel(vec2(p.x + sl * 40.0, 2.0 * YH - p.y - 30.0 + sl * 10.0));
  vec3 body = vec3(0.032, 0.082, 0.098) * (AMB * 1.5 + SUNC * uSun * 0.2);
  vec3 c = mix(body, refl, sat(fr * 1.1 + 0.08));
  float vind = vn(sq * 0.0045 + vec2(3.0, 0.0)) * 0.6 + vn(sq * vec2(0.006, 0.016) + 7.0) * 0.4;
  float strk = vn(vec2(p.x * 0.035 + T * 0.05, p.y * 1.3)) * 0.6 + vn(vec2(p.x * 0.09 - T * 0.08, p.y * 2.6)) * 0.4;
  c *= (0.74 + 0.44 * vind) * (0.9 + 0.2 * strk);
  c += refl * 0.07 * smoothstep(0.6, 0.85, vind) * (1.0 - 0.7 * uNight);
  c = mix(c, vec3(dot(c, vec3(0.3, 0.55, 0.15))), 0.22);
  c *= mix(1.0, 0.78, max(uRain, uSnow));
  c *= mix(0.72, 1.0, smoothstep(0.0, 40.0, wd));
  float sh = skygge(sq, 0.0); c *= 0.7 + 0.3 * sh;
  if (abs(sq.y) < 200.0 && sq.x < 1000.0 && wd < 13.0) {
    float ci = floor(sq.x / 8.0), fa = sq.x - ci * 8.0 - 4.0, hh = hs(vec2(ci, sign(sq.y)));
    float m = step(0.45, hh) * step(abs(fa), 2.0 + 1.2 * hh) * step(abs(wd - 5.5), 1.3);
    c = mix(c, vec3(0.92, 0.92, 0.9) * lit(0.85), m * sat(1.8 - pf / 2.0));
  }
  float lk = length(sq - LS);
  c = mix(c, vec3(0.9, 0.93, 0.95) * lit(0.8), exp(-lk * lk / 30.0) * 0.8);
  glow += VARM * LYS * 0.45 * smoothstep(0.85, 1.0, uNight) * exp(-wd / 14.0) * step(0.62, hs(vec2(floor(p.x * 0.7), floor(sq.x / 30.0)))) * (0.6 + 0.4 * vn(vec2(p.x * 0.8, p.y * 0.9))) * exp(-t / 2500.0);
  return c;
}
vec3 fjernF(vec2 sq, float t, vec2 P, inout vec3 glow){
  float pf = t * PF;
  vec2 g = sq / 13.0, id = floor(g), f = fract(g) - 0.5;
  vec3 gr = mix(vec3(0.2, 0.28, 0.11), vec3(0.4, 0.34, 0.13), vn(sq * 0.008));
  float pat = vn(sq * 0.0035 + 3.0), dens = smoothstep(0.62, 0.3, pat) * (0.6 + 0.4 * vn(sq * 0.012));
  gr = mix(gr, vec3(0.09, 0.15, 0.07) * (0.8 + 0.4 * vn(sq * 0.03)), smoothstep(0.5, 0.75, pat));
  float hh = hs(id), on = step(1.0 - dens * 0.9, hs(id + 3.1));
  vec3 hc = hh < 0.55 ? vec3(0.86, 0.85, 0.8) : (hh < 0.8 ? vec3(0.24, 0.24, 0.26) : vec3(0.56, 0.26, 0.17));
  float m = on * sat((0.3 - max(abs(f.x), abs(f.y))) * 13.0 / max(pf, 0.5) + 0.5);
  vec3 c = mix(gr, hc, m);
  c = mix(c, mix(gr, vec3(0.68, 0.64, 0.58), 0.55 * dens), sat(pf / 8.0 - 0.6));
  c = mix(c, vec3(0.88, 0.9, 0.94), uSnow * 0.6);
  glow += VARM * LYS * 0.5 * smoothstep(0.8, 1.0, uNight) * (1.0 - 0.5 * uRain) * on * step(0.6, hs(id + 5.0)) * sat(2.0 / max(pf, 1.0)) * exp(-t / uVis);
  return c * lit(0.55 * skyS(P)) * (0.82 + 0.32 * vn(sq * 0.0035 + 17.0));
}
vec3 byen(vec2 p, float rx, float ry, inout vec3 glow){
  float tG = HC / ry;
  vec2 d2 = vec2(dot(vec2(rx, 1.0), DA), dot(vec2(rx, 1.0), DN));
  float tH = 1e7, fcH = 0.0, styH = 0.0, ridH = 0.0, hcH = 0.0; vec4 bxH = vec4(0.0); vec2 hyH = vec2(0.0);
  if (tG < 3600.0) {
    float tS = (HC - HMX) / ry;
    vec2 pos = O2 + d2 * tS, ce = floor(pos / CS), sg = sign(d2), dd = abs(CS / d2);
    vec2 tM = tS + ((ce + max(sg, 0.0)) * CS - pos) / d2;
    for (int i = 0; i < 38; i++) {
      vec4 bx; float sty, rid, hc;
      float h = bygg(ce, bx, sty, rid, hc);
      if (h > 0.0) { float fc; float th = rbox(d2, ry, bx, vec2(0.0, h), fc);
        if (th > 0.0 && th < tG) { tH = th; fcH = fc; bxH = bx; hyH = vec2(0.0, h); styH = sty; ridH = rid; hcH = hc; break; } }
      if (min(tM.x, tM.y) > tG) break;
      if (tM.x < tM.y) { ce.x += sg.x; tM.x += dd.x; } else { ce.y += sg.y; tM.y += dd.y; }
    }
  }
  for (int i = 0; i < 7; i++) { vec4 bx; vec2 hy; float sty; spes(i, bx, hy, sty); float fc; float th = rbox(d2, ry, bx, hy, fc);
    if (th > 0.0 && th < min(tH, tG)) { tH = th; fcH = fc; bxH = bx; hyH = hy; styH = sty; ridH = 2.0; hcH = 0.37 + float(i) * 0.1; } }
  vec3 c; float t;
  if (tH < tG) { t = tH; c = byggF(O2 + d2 * t, HC - ry * t, fcH, d2, bxH, hyH, styH, ridH, hcH, t, vec2(rx * t, t)); }
  else { t = tG; vec2 sq = O2 + d2 * t; float wd = vannD(sq);
    if (wd > 0.0) { c = vannF(p, sq, t, wd, ry, glow); MAT = 1.0; } else c = t > 3600.0 ? fjernF(sq, t, vec2(rx * t, t), glow) : landF(sq, vec2(rx * t, t), t, wd, glow); }
  vec2 fq = O2 + d2 * t;
  float vl = fbm(fq * 0.0014 + vec2(T * 0.011, -T * 0.004)), wetv = max(uRain, uSnow);
  float cur = fbm(vec2(p.x * 0.018 - T * 0.06, p.y * 0.0035 + 2.0));
  float fd = (1.0 - exp(-t * (0.72 + 0.62 * vl) / uVis)) * mix(1.0, 0.8, wetv) + 0.04 + wetv * 0.2 * (cur - 0.42) * sat(t / 1400.0);
  vec3 fc2 = FOGC * (0.95 + 0.09 * vl) + vec3(0.02, 0.025, 0.03) * (cur - 0.5) * wetv;
  return mix(c, fc2, sat(fd));
}
vec3 skyer(vec2 p, vec3 col){
  if (uCY > -5.0) {
    float n = fbm(vec2(p.x * 0.012 - T * 0.025, p.y * 0.03)), n2 = fbm(vec2(p.x * 0.03 + T * 0.04, p.y * 0.07) + 4.0);
    float edge = uCY + 18.0 * (n - 0.5) + 7.0 * (n2 - 0.5);
    col = mix(col, CLDC * (0.92 + 0.12 * n2), sat(smoothstep(edge + 9.0, edge - 7.0, p.y) * (0.7 + 0.3 * n2)));
  }
  float wet = max(uRain, uSnow), dy = (p.y - 66.0) / 8.0;
  float b = exp(-dy * dy) * smoothstep(0.45, 0.8, fbm(vec2(p.x * 0.01 - T * 0.02, p.y * 0.05 + 1.7)));
  return mix(col, CLDC, b * (0.08 + 0.3 * wet));
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
  float base = exp(-(d.x * d.x / 6.0 + d.y * d.y * 1.5)) * 0.5;
  col = mix(col, vec3(0.94, 0.96, 0.98) * lit(0.9) + VARM * LYS * 0.3, sat(m * 0.85 + cap * 0.7 + base));
}
float tlin(float x){ return mix(150.0, 158.0, smoothstep(110.0, 210.0, x)) - 32.0 * smoothstep(225.0, 390.0, x) + 3.0 * (vn(vec2(x * 0.08, 2.0)) - 0.5); }
vec3 li(vec2 p){
  vec3 g = mix(vec3(0.4, 0.35, 0.13), vec3(0.22, 0.25, 0.1), vn(p * 0.12));
  g = mix(g, vec3(0.5, 0.3, 0.1), smoothstep(0.6, 0.8, vn(p * 0.3 + 5.0)) * 0.5);
  g *= 0.5 + 0.5 * vn(p * vec2(0.5, 0.9)) + 0.15 * vn(p * 2.0);
  g = mix(g, vec3(0.86, 0.89, 0.93), uSnow * 0.8);
  return g * lit(0.55);
}
vec3 dome(vec2 d, float r, float sd, out float e){
  float an = atan(d.y, d.x);
  e = r * (0.8 + 0.12 * vn(vec2(an * 2.5 + sd * 9.0, sd)) + 0.08 * vn(vec2(an * 6.0, sd + 3.0))) - length(d);
  float dm = sqrt(max(e, 0.0) * max(2.0 * r - e, 0.0));
  vec3 nn = normalize(vec3(d.x, -d.y, max(dm, 0.2)));
  return vec3((0.45 + 0.62 * max(dot(nn, normalize(vec3(-0.5, 0.6, 0.62))), 0.0)) * (0.6 + 0.7 * vn(d * (3.0 / max(r * 0.5, 0.6)) + sd * 7.0)), dm, 0.0);
}
vec3 lovFarge(float k){ return k < 0.26 ? vec3(0.2, 0.31, 0.12) : (k < 0.44 ? vec3(0.42, 0.45, 0.15) : (k < 0.64 ? vec3(0.68, 0.52, 0.14) : (k < 0.84 ? vec3(0.64, 0.33, 0.09) : vec3(0.46, 0.18, 0.07)))); }
void spor(vec2 p, inout vec3 col, inout vec3 glow){
  if (p.y < 149.0 || p.x < 262.0 || p.x > 360.0) return;
  float z = 92.0 / (p.y - 140.0), hw = 15.0 / z, c = (p.x - 312.0 - 10.0 / z) / hw, pz = 1.0 / (hw * uDpr);
  if (abs(c) < 1.8) {
    vec3 g = vec3(0.4, 0.38, 0.33) * (0.8 + 0.3 * vn(vec2(c * 6.0, z * 14.0)));
    g = mix(g, vec3(0.6, 0.59, 0.56) * (0.9 + 0.1 * vn(vec2(z * 30.0, c))), smoothstep(0.82, 0.88, abs(c)) * (1.0 - smoothstep(1.0, 1.06, abs(c))));
    g = mix(g, vec3(0.32, 0.3, 0.16) * (0.7 + 0.5 * vn(vec2(c * 3.0, z * 6.0))), smoothstep(1.06, 1.12, abs(c)));
    g = mix(g, vec3(0.5, 0.48, 0.44), step(fract(z * 4.0), 0.38) * step(abs(c), 0.64) * sat(1.5 - z * 0.15));
    g = mix(g, vec3(0.8, 0.8, 0.82), 1.0 - smoothstep(0.03, 0.03 + pz * 1.2, abs(abs(c) - 0.42)));
    g = mix(g, vec3(0.1), 1.0 - smoothstep(0.02, 0.02 + pz, abs(c)));
    g = mix(g, vec3(0.88, 0.9, 0.94), uSnow * 0.7 * (1.0 - step(abs(abs(c) - 0.42), 0.05)));
    g *= lit(0.6) * (0.72 + 0.28 * smoothstep(-1.0, 0.4, c));
    col = mix(col, g, sat((1.8 - abs(c)) / (pz * 1.5))); MAT = 0.0;
  }
  for (int k = 0; k < 4; k++) {
    float zp = k == 0 ? 1.35 : (k == 1 ? 2.3 : (k == 2 ? 3.5 : 5.0)), xp = 312.0 + 10.0 / zp + 1.4 * 15.0 / zp, yb = 140.0 + 92.0 / zp, ht = 40.0 / zp;
    col = mix(col, vec3(0.5, 0.52, 0.54) * lit(0.7), cv(max(abs(p.x - xp) - 0.5 / sqrt(zp) - 0.2, max(yb - ht - p.y, p.y - yb))));
    col = mix(col, vec3(0.3) * lit(0.6), cv(max(abs(p.x - xp + 1.2 / zp) - 1.6 / zp, abs(p.y - yb + ht) - 0.6 / zp)));
    vec2 lq = p - vec2(xp - 1.8 / zp, yb - ht + 0.8 / zp);
    glow += VARM * LYS * uNight * 0.9 * exp(-dot(lq, lq) * zp);
  }
  float ph = 40.0;
  float zc = ph < 8.0 ? 1.6 : (ph < 38.0 ? mix(1.6, 9.5, smoothstep(8.0, 38.0, ph)) : (ph < 44.0 ? 99.0 : (ph < 74.0 ? mix(9.5, 1.6, smoothstep(44.0, 74.0, ph)) : 1.6)));
  float L = 1.7;
  if (z > zc && z < zc + L + 0.25 && abs(c) < 0.95) col *= 0.62;
  float yf0 = 140.0 + 62.0 / zc, yf1 = 140.0 + 92.0 / zc, cf = (p.x - 312.0 - 10.0 / zc) / (15.0 / zc);
  float zr = 62.0 / max(p.y - 140.0, 0.5), cr = (p.x - 312.0 - 10.0 / zr) / (15.0 / zr);
  vec3 bl = vec3(0.12, 0.29, 0.45);
  if (p.y > yf0 && p.y < yf1 && abs(cf) < 0.78) {
    float v = (p.y - yf0) / (yf1 - yf0);
    vec3 fc = bl * lit(0.55);
    float gw = step(0.14, v) * step(v, 0.6) * step(abs(cf), 0.62);
    vec3 gls = mix(uSkB * 0.5, vec3(0.04, 0.05, 0.07), 0.5 + 0.4 * uNight) * (AMB + 0.25) + vec3(0.18) * smoothstep(0.25, 0.0, abs(cf * 0.5 + v - 0.35)) * (1.0 - uNight) + VARM * LYS * 0.7;
    fc = mix(fc, gls, gw);
    fc = mix(fc, vec3(0.92) * lit(0.7), step(0.72, v) * step(v, 0.8));
    float hl = step(0.82, v) * step(v, 0.92) * step(0.4, abs(cf)) * step(abs(cf), 0.62);
    fc = mix(fc, vec3(1.0, 0.95, 0.85) * (0.6 + 1.6 * uNight), hl);
    col = mix(col, fc, sat((0.78 - abs(cf)) * 15.0 / zc * uDpr + 0.5));
  } else if (zr > zc && zr < zc + L && abs(cr) < 0.78) {
    float vr = (zr - zc) / L;
    vec3 rc = vec3(0.68, 0.7, 0.71) * (1.0 - 0.25 * step(fract(vr * 4.0), 0.07));
    rc = mix(rc, mix(uSkB * 0.5, vec3(0.04, 0.05, 0.07), 0.5) * (AMB + 0.3) + VARM * LYS * 0.6, step(0.58, abs(cr)));
    rc = mix(rc, bl, step(0.72, abs(cr)));
    rc = mix(rc, vec3(0.9, 0.92, 0.95), uSnow * 0.85 * step(abs(cr), 0.58));
    col = mix(col, rc * lit(0.85), sat((0.78 - abs(cr)) * 15.0 / zr * uDpr + 0.5));
  }
}
void trelag(vec2 p, vec2 CZ, float rB, float rV, float off, float sd, float nr, inout vec3 col){
  vec2 gi = floor(p / CZ);
  float bK = -1e3, bA = 0.0; vec3 bC = col;
  for (int j = 0; j < 3; j++) { for (int i = 0; i < 3; i++) {
    vec2 cid = gi + vec2(float(i) - 1.0, float(j) - 1.0);
    float h = hs(cid + sd), h2 = hs(cid + sd + 7.3), h3 = hs(cid + sd + 13.1);
    vec2 ctr = (cid + 0.5 + (vec2(h2, h3) - 0.5) * 0.8) * CZ;
    if (ctr.y < tlin(ctr.x) + off) continue;
    if (ctr.y > 150.0) { float zt = 92.0 / (ctr.y - 140.0); if (zt < 5.5 && abs(ctr.x - 312.0 - 10.0 / zt) < 27.0 / zt + rB * 0.3) continue; }
    if (ctr.y > 166.0 && ctr.x < 148.0 + (ctr.y - 164.0) * 0.516) continue;
    float r = rB + rV * h2;
    vec2 d = p - ctr;
    d.x -= sin(T * (0.9 + h3 * 0.6) + h * 6.28) * 0.05 * r * sat(0.6 - d.y / r);
    float e, sh; vec3 tc;
    float lf = vn(d * 7.0 / r + cid * 3.1), lf2 = vn(d * 16.0 / r + cid * 5.3);
    if (h < 0.5) {
      if (nr > 0.5 && h < 0.3) {
        vec2 dq = d + vec2(0.0, r * 0.95);
        vec2 dw = dq + (vec2(vn(dq * 2.2 / r + cid * 5.0), vn(dq * 2.2 / r + cid * 5.0 + 3.7)) - 0.5) * r * 0.9;
        float an = atan(dw.y, dw.x);
        e = r * (0.62 + 0.25 * vn(vec2(an * 2.0 + h * 20.0, h))) - length(dw * vec2(0.85, 1.35)) + r * 0.16 * (lf - 0.5) + r * 0.08 * (lf2 - 0.5);
        sh = (0.5 + 0.55 * smoothstep(0.6, -0.6, dw.x / r) * smoothstep(0.5, -0.7, dw.y / r)) * (0.42 + 0.7 * lf * lf2 + 0.2 * lf);
        tc = mix(vec3(0.07, 0.12, 0.07), vec3(0.13, 0.17, 0.09), h3);
        float tx0 = d.x - d.y * 0.05 + 0.25 * sin(d.y * 0.4 + cid.x * 3.0);
        float et = min(r * 0.06 + 0.22 - abs(tx0), min(d.y + r * 0.55, r * 1.6 - d.y));
        if (et > e) { e = et; sh = 0.5 + 0.6 * smoothstep(0.4, -0.4, tx0 / (r * 0.06)); tc = mix(vec3(0.52, 0.32, 0.19), vec3(0.3, 0.26, 0.22), smoothstep(-0.2, 1.3, d.y / r)) * (0.8 + 0.3 * vn(vec2(d.y * 2.0, cid.x))); }
      } else {
        float yy = (d.y + r * 1.9) / (r * 2.6), lag = fract(yy * 7.0 + h * 3.0);
        float wd = r * 0.6 * sat(yy) * (0.78 + 0.35 * lag) * (0.8 + 0.4 * vn(vec2(d.y * 3.0 / r, cid.x * 3.0)));
        e = min(wd - abs(d.x) + r * 0.12 * (lf2 - 0.5), r * 0.7 - d.y);
        sh = (0.5 + 0.5 * smoothstep(0.5, -0.5, d.x / max(wd, 0.3))) * (0.5 + 0.6 * lf) * (0.72 + 0.38 * lag);
        tc = mix(vec3(0.04, 0.085, 0.055), vec3(0.08, 0.13, 0.075), h3);
      }
    } else {
      vec2 dw = d + (vec2(vn(d * 2.4 / r + cid * 5.0), vn(d * 2.4 / r + cid * 5.0 + 3.7)) - 0.5) * r * 0.55;
      vec3 dd = dome(dw, r, h, e);
      e += r * 0.2 * (lf - 0.5) + r * 0.1 * (lf2 - 0.5);
      sh = dd.x * (0.42 + 0.72 * lf * (0.6 + 0.4 * lf2));
      float k = sat(0.15 + h3 * 0.85);
      tc = k < 0.3 ? vec3(0.21, 0.27, 0.12) : (k < 0.56 ? vec3(0.52, 0.47, 0.2) : (k < 0.8 ? vec3(0.56, 0.4, 0.16) : vec3(0.46, 0.25, 0.11)));
      tc *= vec3(1.0) + (lf2 - 0.5) * vec3(0.16, 0.08, -0.1);
      if (nr > 0.5 && h > 0.82) { float et = min(r * 0.05 + 0.2 - abs(d.x), min(d.y - r * 0.25, r * 1.5 - d.y)); if (et > e) { e = et; tc = mix(vec3(0.8, 0.79, 0.75), vec3(0.14), step(0.8, vn(vec2(d.x * 3.0, d.y * 1.4)))); sh = 0.55 + 0.5 * smoothstep(0.3, -0.3, d.x / (r * 0.05)); } }
    }
    float cov = sat(e * uDpr * 0.7 + 0.5);
    if (cov <= 0.0) continue;
    vec3 tl = tc * sh * lit(0.85);
    tl = mix(tl, FOGC * 0.8, CZ.x < 8.0 ? 0.12 : (nr > 0.5 ? 0.0 : 0.05));
    tl = mix(tl, vec3(0.86, 0.89, 0.93) * lit(0.9) * (0.7 + 0.3 * sh), uSnow * smoothstep(0.55, 0.85, sh) * 0.85);
    if (ctr.y > bK) { bK = ctr.y; bC = tl; bA = cov; }
  } }
  col = mix(col, bC, bA);
  if (bA > 0.5) MAT = 0.25;
}
void plattform(vec2 p, inout vec3 col){
  if (p.x > 200.0 || p.y < 136.0) return;
  float yb = 170.0 - 6.0 * p.x / 152.0, xe = 152.0 + (p.y - 164.0) * 0.516;
  float ww = 2.5 + max(p.y - 164.0, 0.0) * 0.12, vv = (p.x - 152.0) / 32.0;
  if ((p.y > yb - 23.0 && p.x < max(xe + ww, 153.5)) || (vv > -0.06 && vv < 1.15 && p.y > 162.0 + 62.0 * vv - 21.0 * (1.0 + 1.6 * vv) && p.y < 164.5 + 62.0 * vv)) MAT = 0.0;
  if (p.y > 164.0 && p.x > xe - 1.0 && p.x < xe + ww) {
    vec3 m = vec3(0.42, 0.41, 0.39) * (0.75 + 0.35 * vn(p * vec2(0.5, 0.9))) * lit(0.35);
    m *= 0.85 + 0.15 * step(0.5, fract(p.y * 0.18 + floor(p.x * 0.3) * 0.5));
    col = mix(col, m, cv(max(xe - p.x, p.x - xe - ww)));
  }
  float de = min(p.y - yb, xe - p.x);
  if (de > -1.0) {
    vec3 g = vec3(0.64, 0.62, 0.58) * (0.86 + 0.2 * vn(p * 1.6)) * (0.94 + 0.12 * hs(floor(p * uDpr * 1.5)));
    float rl = log(p.y - yb + 3.0) * 3.2, cl = (p.x - 30.0) / (p.y - 110.0) * 5.0, rr = fract(rl), cc = fract(cl);
    g *= (0.97 + 0.05 * hs(vec2(floor(rl), floor(cl)))) * (0.94 + 0.1 * vn(p * vec2(0.08, 0.2))) * (0.95 + 0.08 * vn(p * 0.6));
    g *= 1.0 - 0.045 * (1.0 - smoothstep(0.0, 0.05, min(rr, 1.0 - rr))) - 0.04 * (1.0 - smoothstep(0.0, 0.025, min(cc, 1.0 - cc)));
    g *= 1.0 - 0.1 * smoothstep(0.55, 0.85, vn(p * 0.12 + 7.0));
    g *= 1.0 - 0.18 * smoothstep(6.0, 0.0, p.y - yb);
    g = mix(g, vec3(0.9, 0.92, 0.95), uSnow * 0.85);
    vec2 tl2 = vec2(floor(rl), floor(cl)); float tv = hs(tl2 + 5.0);
    g *= (tv < 0.33 ? vec3(1.04, 1.0, 0.94) : (tv < 0.66 ? vec3(0.95, 0.97, 1.0) : vec3(0.99))) * (0.9 + 0.14 * hs(tl2 + 2.0));
    g = mix(g, g * vec3(0.78, 0.86, 0.66), smoothstep(0.62, 0.8, vn(p * vec2(0.06, 0.14) + 11.0)) * 0.45);
    float dyp = p.y - yb, gl2 = 1.0 - smoothstep(0.0, 70.0, dyp);
    vec3 rf = mix(uSkM, uSkT, sat(dyp / 120.0)) * mix(1.0, 0.55, uNight);
    float pv0 = vn(vec2(p.x * 0.06, p.y * 0.2) + 3.0) * 0.7 + vn(p * vec2(0.16, 0.45) + 8.0) * 0.3;
    float pud = smoothstep(0.66, 0.71, pv0) * uWet * (0.55 + 0.45 * gl2), pring = (smoothstep(0.6, 0.66, pv0) - smoothstep(0.66, 0.71, pv0)) * uWet;
    vec3 dc = g * lit(0.75) * mix(1.0, 0.62, uWet) + uWet * 0.1 * rf * (0.5 + 0.5 * vn(vec2(p.x * 0.2, p.y * 0.6)));
    dc = mix(dc, rf * 0.8, uWet * 0.26 * gl2);
    dc *= 1.0 - 0.18 * pring;
    vec3 pc = mix(dc, rf * 0.62, 0.75) * (1.0 + uRain * 0.22 * (vn(vec2(p.x * 0.7, p.y * 1.4) + T * 1.4) - 0.5)) + vec3(0.012);
    if (p.x < 153.5) { float pm2 = mod(p.x + 9.0, 30.0) - 15.0; pc = mix(pc, vec3(0.13, 0.14, 0.15) * lit(0.5), cv(abs(pm2) - 0.9) * step(dyp, 21.0) * 0.8); pc = mix(pc, vec3(0.3, 0.32, 0.34) * lit(0.6), cv(abs(dyp - 20.0) - 0.9) * 0.7); }
    dc = mix(dc, pc, pud * 0.7);
    vec2 lq = (p - vec2(74.0, 196.0)) * vec2(0.022, 0.06); dc += VARM * g * smoothstep(0.85, 1.0, uNight) * (1.0 - uRain) * 0.45 * exp(-dot(lq, lq) * 2.0);
    col = mix(col, dc, sat(de * uDpr + 0.5));
  }
  if (p.x < 153.5) {
    float yt = yb - 21.0;
    if (p.y > yt + 1.0 && p.y < yb - 0.5) col = col * 0.82 + vec3(0.05, 0.075, 0.085) * (AMB + 0.3) + vec3(0.06) * smoothstep(0.7, 1.0, vn(vec2(p.x * 0.05 + p.y * 0.08, 3.0)));
    col = mix(col, vec3(0.2, 0.21, 0.22) * lit(0.5), cv(abs(p.y - (yb - 1.2)) - 0.8));
    float pm = mod(p.x + 9.0, 30.0) - 15.0;
    col = mix(col, vec3(0.5, 0.52, 0.55) * lit(0.8) * mix(1.0, 0.65, step(0.0, pm)), cv(max(abs(pm) - 0.8, max(yt - p.y, p.y - yb))));
    col = mix(col, mix(vec3(0.7, 0.72, 0.75), vec3(0.34, 0.36, 0.39), smoothstep(-0.9, 0.9, p.y - yt)) * lit(0.85), cv(abs(p.y - yt) - 0.9));
  }
  float v = (p.x - 152.0) / 32.0;
  if (v > -0.06 && v < 1.15) {
    float s = 1.0 + 1.6 * v, ybs = 164.0 + 62.0 * v, yts = ybs - 21.0 * s;
    if (p.y > yts && p.y < ybs && v > 0.0) col = col * 0.82 + vec3(0.05, 0.075, 0.085) * (AMB + 0.3) + vec3(0.07) * smoothstep(0.6, 1.0, vn(vec2(v * 3.0 + p.y * 0.04, 5.0)));
    float pv = abs(mod(v + 0.18, 0.36) - 0.18) * 32.0;
    col = mix(col, vec3(0.5, 0.52, 0.55) * lit(0.7), cv(max(pv - 0.8 * s, max(yts - p.y, p.y - ybs))));
    col = mix(col, mix(vec3(0.7, 0.72, 0.75), vec3(0.34, 0.36, 0.39), smoothstep(-0.9 * s, 0.9 * s, p.y - yts)) * lit(0.85), cv(abs(p.y - yts) - 0.9 * s));
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
  AA = 1.0 / uDpr; T = uT; LYS = 0.2 + 0.8 * uNight; PF = 1.0 / (FO * uDpr);
  VARM = vec3(1.0, 0.74, 0.42);
  AMB = max(mix(uSkM, uSkB, 0.5) * mix(1.0, 0.4, uNight) * mix(1.0, 0.62, uSun), vec3(0.07, 0.08, 0.1)) + vec3(0.05, 0.035, 0.02) * uNight;
  SUNC = vec3(1.0, 0.93, 0.8) * 0.8; SSC = vec3(1.0, 0.6, 0.34) * 0.85;
  FOGC = mix(uSkB, uSkM, 0.3) + vec3(0.1, 0.06, 0.02) * uNight * 0.5;
  CLDC = mix(uSkB, uSkM, 0.55) * 1.02 + vec3(0.12, 0.07, 0.02) * uNight * 0.55;
  O2 = -vec2(dot(OR, DA), dot(OR, DN)); MAT = 0.0;
  AMB *= mix(1.0, 0.68, uRain) * mix(1.0, 0.8, uSnow); FOGC *= mix(1.0, 0.88, max(uRain, uSnow)); CLDC *= mix(1.0, 0.9, uRain);
  vec3 glow = vec3(0.0), col;
  float tl = tlin(p.x), yb = 170.0 - 6.0 * p.x / 152.0, xe = 152.0 + (p.y - 164.0) * 0.516;
  bool dekk = p.y > yb + 1.5 && p.x < xe - 1.5;
  if (p.y > tl + 6.0 || dekk) col = li(p);
  else {
    float rx = (p.x - CX) / FO, ry = (p.y - YH) / FO, tG = ry > 0.0004 ? HC / ry : 1e7;
    float hL = hLov(p.x), yL = YH + FO * (HC - hL) / 3400.0;
    float hA = p.x > 292.0 ? hAsk(p.x) : -999.0, yA = YH + FO * (HC - hA) / 5800.0;
    float hY = hLyd(p.x), yY = YH + FO * (HC - hY) / 6500.0;
    float hS = (p.x > 150.0 && p.x < 322.0) ? hSot(p.x) * smoothstep(150.0, 175.0, p.x) * smoothstep(322.0, 300.0, p.x) : -999.0, yS = YH + FO * (HC - hS) / 14000.0;
    if (tG > 3400.0 && p.y > yL) col = fjellF(p, 3400.0, 0.0, hL, glow);
    else if (tG > 5800.0 && p.y > yA) col = fjellF(p, 5800.0, 3.0, hA, glow);
    else if (tG > 6500.0 && p.y > yY) col = fjellF(p, 6500.0, 6.0, hY, glow);
    else if (tG > 14000.0 && p.y > yS) col = fjellF(p, 14000.0, 9.0, max(hS, 30.0), glow);
    else if (ry <= 0.0004) col = himmel(p);
    else col = byen(p, rx, ry, glow);
    col = skyer(p, col);
    if (p.y > tl + 2.0) col = mix(col, li(p), sat((p.y - tl - 2.0) / 4.0));
    if (p.y > tl + 4.0) MAT = 0.0;
  }
  if (!dekk && p.y > tl - 26.0) {
    spor(p, col, glow);
    trelag(p, vec2(7.0, 6.0), 2.4, 1.8, 2.0, 1.0, 0.0, col);
    trelag(p, vec2(12.0, 10.0), 4.5, 3.0, 14.0, 21.0, 0.0, col);
    trelag(p, vec2(21.0, 17.0), 8.0, 6.0, 34.0, 41.0, 1.0, col);
  }
  plattform(p, col);
  col += glow;
  col = max(col, 0.0);
  float lu = dot(col, vec3(0.3, 0.55, 0.15));
  col = mix(vec3(lu), col, 0.96 + 0.12 * uSun);
  col += (vec3(-0.01, 0.002, 0.018) * (1.0 - smoothstep(0.0, 0.35, lu)) + vec3(0.018, 0.006, -0.014) * smoothstep(0.4, 1.0, lu)) * (1.0 - 0.6 * uNight);
  vec3 xe3 = col * (0.94 - 0.12 * uSun);
  col = clamp((xe3 * (2.51 * xe3 + 0.03)) / (xe3 * (2.43 * xe3 + 0.59) + 0.14), 0.0, 1.0);
  vec2 vq = p / uRes - 0.5; col *= 1.0 - 0.12 * smoothstep(0.35, 0.8, length(vq * vec2(1.0, 0.8)));
  col += (hs(floor(p * uDpr) + fract(T * 6.0) * 97.0) - 0.5) * 0.026 * (1.0 - 0.6 * dot(col, vec3(0.33)));
  col = col * 0.975 + vec3(0.008, 0.011, 0.014);
  fragColor = vec4(col, MAT);
}
