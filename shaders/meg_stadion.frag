// Brann stadion under Ulriken — the Launch prototype's Meg hero scene
// (`data-ulgl="meg"`, `ulGlInit` in «Ærend Kunde Launch.dc.html»), ported
// as is: the mountain and Ulriksbanen, the clouds and mist, the mast light,
// the stadium with the players and the LED boards, the houses, the rain,
// the snow and the stars. Only the GLSL dialect changed (Flutter's runtime
// effect: uniforms one per line, FlutterFragCoord, fragColor). Rendered
// offscreen into an image whose pixel grid is (uRes * uDpr), so
// FlutterFragCoord is the pixel, as in sjo.frag.
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

uniform vec2 uRes;
uniform float uDpr;
uniform float uT;
uniform float uNight;
uniform float uSun;
uniform float uSunset;
uniform float uRain;
uniform float uSnow;
uniform float uWet;
uniform float uHz;
uniform float uCY;
uniform vec3 uSkT;
uniform vec3 uSkM;
uniform vec3 uSkB;

out vec4 fragColor;
float AA, T, LYS, FLD;
vec3 AMB, SUNC, SSC, FOGC, CLDC, VARM;
const float CX = 194.0, YF = 138.0, YN = 168.0, HWF = 64.0, HWN = 84.0, BT = 112.0;
const vec2 SA = vec2(86.0, 93.0), SB = vec2(216.0, 18.0);
const vec3 FL = vec3(1.0, 0.98, 0.92);
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
vec2 rot(vec2 p, float a){ float c = cos(a), s = sin(a); return vec2(c * p.x - s * p.y, s * p.x + c * p.y); }
float crs(vec2 a, vec2 b){ return a.x * b.y - a.y * b.x; }
vec3 lit(float k){ return AMB * (0.78 + 0.22 * k) + SUNC * uSun * k + SSC * uSunset * k * 0.8; }
float ridge(float x){
  float dl = max(230.0 - x, 0.0) / 120.0, dr = max(x - 230.0, 0.0) / 95.0, ds = (x - 232.0) / 14.0;
  float y = x < 230.0 ? 22.0 + 70.0 * (1.0 - exp(-dl * dl)) : 22.0 + 15.0 * (1.0 - exp(-dr * dr));
  return y - 3.0 * exp(-ds * ds) + 3.0 * (vn(vec2(x * 0.045, 1.0)) - 0.5) + 1.2 * (vn(vec2(x * 0.2, 2.0)) - 0.5);
}
float hgt(vec2 p){
  float g = 1.0 - abs(sin(p.x * 0.06 + p.y * 0.035 + vn(p * 0.03) * 4.0));
  return fbm(vec2(p.x * 0.04, p.y * 0.03) + 3.0) + 0.4 * vn(vec2(p.x * 0.14 + p.y * 0.05, p.y * 0.08)) + 0.35 * g * g;
}
vec3 himmel(vec2 p){
  vec3 c = mix(uSkT, uSkB, sat((p.y + 30.0) / 150.0));
  c += vec3(0.28, 0.13, 0.04) * uSunset * smoothstep(10.0, 110.0, p.y) * 0.6;
  if (uNight > 0.3) {
    vec2 g = p / 3.0, id = floor(g), f = fract(g) - 0.5 - (vec2(hs(id + 1.0), hs(id + 2.0)) - 0.5) * 0.6;
    float h = hs(id);
    c += vec3(0.85, 0.9, 1.0) * step(0.985, h) * exp(-dot(f, f) * 40.0) * (0.55 + 0.45 * sin(T * (1.0 + h * 3.0) + h * 60.0)) * (uNight - 0.3) * 1.5 * (1.0 - uRain) * (1.0 - 0.85 * uSnow);
  }
  vec2 q = p * vec2(0.0075, 0.02) + vec2(T * 0.006, 0.0);
  vec2 w = vec2(fbm(q * 1.7 + vec2(1.7, 9.2) + T * 0.006), 0.0);
  float d1 = fbm(q + w * 0.9), d2 = fbm(q + w * 0.9 + vec2(-0.03, -0.05));
  float den = smoothstep(0.46 - 0.14 * max(uRain, uSnow), 0.82, d1);
  vec3 cc = mix(CLDC * 0.82, CLDC * 1.12 + 0.04 * (1.0 - uNight), sat((d1 - d2) * 7.0 + 0.5)) + vec3(0.3, 0.16, 0.06) * uSunset * 0.5;
  return mix(c, cc, den * 0.9);
}
vec3 dome(vec2 d, float r, float sd, out float e){
  float an = atan(d.y, d.x);
  e = r * (0.8 + 0.12 * vn(vec2(an * 2.5 + sd * 9.0, sd)) + 0.08 * vn(vec2(an * 6.0, sd + 3.0))) - length(d);
  float dm = sqrt(max(e, 0.0) * max(2.0 * r - e, 0.0));
  vec3 nn = normalize(vec3(d.x, -d.y, max(dm, 0.2)));
  return vec3((0.45 + 0.62 * max(dot(nn, normalize(vec3(-0.5, 0.6, 0.62))), 0.0)) * (0.6 + 0.7 * vn(d * (3.0 / max(r * 0.5, 0.6)) + sd * 7.0)), dm, 0.0);
}
vec3 lovFarge(float k){ return k < 0.26 ? vec3(0.2, 0.31, 0.12) : (k < 0.44 ? vec3(0.42, 0.45, 0.15) : (k < 0.64 ? vec3(0.68, 0.52, 0.14) : (k < 0.84 ? vec3(0.64, 0.33, 0.09) : vec3(0.46, 0.18, 0.07)))); }
vec3 skog(vec2 p, vec3 bgL, vec2 CS, float rB, float rV, float conH){
  vec2 gi = floor(p / CS);
  vec3 c = vec3(0.035, 0.06, 0.035) * bgL;
  float bK = -1e3, bA = 0.0; vec3 bC = c;
  for (int j = 0; j < 3; j++) {
    for (int i = 0; i < 3; i++) {
      vec2 cid = gi + vec2(float(i) - 1.0, float(j) - 1.0);
      float h = hs(cid), h2 = hs(cid + 7.3), h3 = hs(cid + 13.1);
      vec2 ctr = (cid + 0.5 + (vec2(h2, h3) - 0.5) * 0.75) * CS, d = p - ctr;
      float r = rB + rV * h2, e, sh; vec3 tc;
      if (h < conH + 0.45 * smoothstep(115.0, 70.0, ctr.y)) {
        float wd = r * 0.85 * sat((d.y + r * 1.6) / (r * 2.2));
        e = min(wd - abs(d.x), r * 0.6 - d.y);
        sh = (0.6 + 0.45 * smoothstep(0.5, -0.5, d.x / max(wd, 0.3))) * (0.75 + 0.4 * vn(d * vec2(4.0, 2.0) / max(r * 0.4, 0.6) + cid * 3.0));
        tc = mix(vec3(0.045, 0.11, 0.065), vec3(0.085, 0.16, 0.085), h3);
      } else {
        vec3 dd = dome(d, r, h, e); sh = dd.x;
        float k = sat(vn(ctr * vec2(0.03, 0.045) + 9.0) * 0.75 + h3 * 0.35 - 0.05);
        tc = lovFarge(k); tc = mix(tc, vec3(dot(tc, vec3(0.3, 0.55, 0.15))), 0.24) * (0.6 + 0.5 * h);
      }
      float cov = sat(e * uDpr * 0.6 + 0.5);
      if (cov <= 0.0) continue;
      vec3 tl = tc * sh * bgL;
      tl = mix(tl, vec3(0.86, 0.89, 0.93) * bgL * (0.7 + 0.3 * sh), uSnow * smoothstep(0.55, 0.85, sh + 0.15 * vn(p * 2.0)) * 0.85);
      float key = (e > 0.0 ? sqrt(max(e * (2.0 * r - e), 0.0)) : e * 2.0) + ctr.y * 0.25;
      if (key > bK) { bK = key; bC = tl; bA = cov; }
    }
  }
  return mix(c, bC, bA);
}
vec3 fjell(vec2 p){
  float h = hgt(p);
  float fo = smoothstep(64.0, 90.0, p.y + 16.0 * (vn(vec2(p.x * 0.03, 5.0)) - 0.5) + 14.0 * (h - 0.55));
  float hx = 0.0, hy = 0.0;
  if (fo < 0.99) { hx = hgt(p + vec2(0.9, 0.0)) - h; hy = hgt(p + vec2(0.0, 0.9)) - h; }
  vec3 N = normalize(vec3(-hx * 7.0 + (p.x < 230.0 ? -0.3 : 0.2), hy * 7.0 + 0.2, 1.0));
  float k = max(dot(N, normalize(vec3(-0.55, 0.5, 0.67))), 0.0);
  float rock = smoothstep(0.7, 0.86, h + 0.22 * vn(p * vec2(0.08, 0.2))) * (1.0 - fo) * (0.55 + 0.45 * smoothstep(60.0, 25.0, p.y));
  vec3 heath = mix(vec3(0.3, 0.34, 0.17), vec3(0.44, 0.3, 0.14), vn(p * 0.06 + 3.0));
  heath = mix(heath, vec3(0.2, 0.26, 0.14), vn(p * vec2(0.35, 0.55)) * 0.55);
  heath = mix(heath, vec3(0.5, 0.42, 0.24), smoothstep(0.6, 0.85, vn(p * vec2(0.12, 0.3) + 8.0)) * 0.5);
  vec3 c = mix(heath, vec3(0.47, 0.47, 0.45) * (0.8 + 0.3 * vn(p * 0.8)), rock) * (0.8 + 0.3 * vn(p * vec2(1.2, 1.7)));
  c = mix(c, vec3(0.88, 0.9, 0.94), uSnow * smoothstep(0.3, 0.6, k + 0.25 - rock * 0.45));
  c *= lit(k * 1.1);
  if (fo > 0.01) c = mix(c, skog(p, lit(0.5 + 0.6 * (fo > 0.99 ? 0.6 + 0.5 * (h - 0.5) : k)), vec2(3.4, 2.8), 1.5, 1.1, 0.3), fo);
  return mix(c, FOGC, sat(uHz * mix(1.0, 0.3, smoothstep(20.0, 140.0, p.y))));
}
void toppen(vec2 p, inout vec3 col, inout vec3 glow){
  vec3 L = lit(0.85);
  vec3 glz = mix(uSkB * 0.5, vec3(0.05, 0.06, 0.08), 0.5 + 0.4 * uNight) * (AMB + 0.2);
  if (p.x > 204.0 && p.x < 236.0 && p.y > 10.0 && p.y < 23.0) {
    float d = rb(p, vec2(209.0, 13.8), vec2(230.0, 22.0));
    if (d < 1.0) {
      vec3 c = vec3(0.8, 0.79, 0.76) * (0.92 + 0.08 * vn(p)) * mix(1.0, 0.62, smoothstep(226.0, 229.0, p.x)) * L;
      float gw = cv(rb(p, vec2(210.5, 15.6), vec2(225.5, 18.6)));
      float on = step(0.4, hs(vec2(floor(p.x / 2.2), 3.0)));
      c = mix(c, glz + VARM * LYS * 1.3 * on, gw);
      c = mix(c, vec3(0.2, 0.2, 0.22) * L, cv(abs(p.y - 14.3) - 0.5));
      c = mix(c, vec3(0.9, 0.92, 0.96) * L, uSnow * cv(abs(p.y - 13.9) - 0.5));
      col = mix(col, mix(c, FOGC, uHz * 0.7), cv(d));
    }
    glow += VARM * LYS * 0.25 * exp(-max(rb(p, vec2(210.5, 15.6), vec2(225.5, 18.6)), 0.0) / 2.5);
  }
  if (abs(p.x - 244.0) < 5.0 && p.y < 24.0) {
    float t = sat((21.5 - p.y) / 25.0), w = mix(1.7, 0.45, t);
    float m = cv(max(abs(p.x - 244.0) - w, max(-3.0 - p.y, p.y - 21.5)));
    float pl = cv(max(abs(p.x - 244.0) - 2.6, abs(p.y - 9.0) - 0.6)) + cv(max(abs(p.x - 244.0) - 1.8, abs(p.y - 3.5) - 0.5));
    vec3 mc = vec3(0.72, 0.72, 0.7) * mix(1.0, 0.65, step(244.0, p.x));
    mc = mix(mc, vec3(0.75, 0.15, 0.12), step(p.y, 3.0) * step(0.5, fract(p.y / 1.6)));
    col = mix(col, mix(mc * L, FOGC, uHz * 0.7), sat(m + pl));
  }
  float bl = step(0.55, fract(T * 0.7));
  for (int k = 0; k < 2; k++) { vec2 dd = p - vec2(244.0, k == 0 ? -2.0 : 9.0); float r2 = dot(dd, dd); glow += vec3(1.0, 0.12, 0.08) * bl * (1.6 * exp(-r2 / 0.6) + 0.2 * exp(-r2 / 8.0)) * (0.35 + 0.65 * LYS); }
  if (p.x > 74.0 && p.x < 98.0 && p.y > 82.0 && p.y < 102.0) {
    float dB = rb(p, vec2(78.0, 89.0), vec2(94.0, 99.5)), dR = rb(p, vec2(77.0, 86.0), vec2(95.0, 89.5)), d = min(dB, dR);
    if (d < 1.0) {
      vec3 c = vec3(0.7, 0.69, 0.66) * L * mix(1.0, 0.65, smoothstep(91.0, 94.0, p.x));
      c = mix(c, glz + VARM * LYS * 1.2, cv(rb(p, vec2(80.0, 91.5), vec2(89.0, 96.5))));
      c = mix(c, mix(vec3(0.25, 0.25, 0.27) * L, vec3(0.9, 0.92, 0.96) * L, uSnow), cv(dR));
      col = mix(col, mix(c, FOGC, uHz * 0.35), cv(d));
    }
    glow += VARM * LYS * 0.2 * exp(-max(rb(p, vec2(80.0, 91.5), vec2(89.0, 96.5)), 0.0) / 2.5);
  }
}
float uCab(float t){ float ph = fract(t / 72.0); return smoothstep(0.05, 0.43, ph) * (1.0 - smoothstep(0.57, 0.95, ph)); }
float ropeY(float x, float off){ float t = (x - SA.x) / (SB.x - SA.x); return mix(SA.y, SB.y, t) + 22.0 * t * (1.0 - t) + off; }
void bane(vec2 p, inout vec3 col, inout vec3 glow){
  if (p.x < SA.x - 8.0 || p.x > SB.x + 8.0 || p.y < SB.y - 6.0 || p.y > SA.y + 14.0) return;
  vec3 rc = vec3(0.07, 0.07, 0.08) * (AMB + 0.15);
  float t = (p.x - SA.x) / (SB.x - SA.x);
  if (t > 0.0 && t < 1.0) for (int k = 0; k < 2; k++) {
    float dy = abs(p.y - ropeY(p.x, float(k) * 1.9)) * 0.86;
    col = mix(col, rc, (1.0 - smoothstep(0.05, 0.05 + 0.9 / uDpr, dy)) * 0.5);
  }
  float acc = uCab(T + 0.7) - 2.0 * uCab(T) + uCab(T - 0.7);
  for (int k = 0; k < 2; k++) {
    float fk = float(k), u = k == 0 ? uCab(T) : 1.0 - uCab(T);
    float x = mix(SA.x, SB.x, u), y = ropeY(x, fk * 1.9);
    float sw = 0.05 * sin(T * 1.25 + fk * 2.0) - clamp(acc * 30.0, -0.3, 0.3) * (k == 0 ? 1.0 : -1.0);
    vec2 d0 = p - vec2(x, y);
    glow += VARM * LYS * 0.5 * exp(-dot(d0 - vec2(0.0, 5.6), d0 - vec2(0.0, 5.6)) / 10.0);
    if (abs(d0.x) > 7.0 || d0.y < -2.0 || d0.y > 11.0) continue;
    col = mix(col, vec3(0.1) * (AMB + 0.2), cv(rb(d0, vec2(-1.7, -0.9), vec2(1.7, 0.6))));
    vec2 q = rot(d0, -sw);
    col = mix(col, vec3(0.12) * (AMB + 0.2), cv(rb(q, vec2(-0.28, 0.0), vec2(0.28, 3.7))));
    float bd = rb(q, vec2(-3.3, 3.5), vec2(3.3, 8.3)) - 0.45;
    if (bd < 1.0) {
      float sh = 0.72 + 0.38 * smoothstep(3.0, -3.0, q.x);
      vec3 c = vec3(0.68, 0.13, 0.11) * sh * lit(0.9);
      c = mix(c, vec3(0.82, 0.82, 0.8) * sh * lit(0.9), step(q.y, 4.2));
      float win = cv(max(abs(q.x) - 2.85, abs(q.y - 5.7) - 0.95)) * (1.0 - cv(abs(q.x) - 0.18));
      vec3 glz = mix(uSkB * 0.6, vec3(0.05, 0.06, 0.08), 0.45 + 0.4 * uNight) * (AMB + 0.25) + vec3(0.12) * smoothstep(0.4, 0.0, abs(q.x * 0.4 - q.y + 5.7 + 0.5)) * (1.0 - uNight);
      c = mix(c, glz + VARM * LYS * 1.1, win);
      c *= mix(1.0, 0.7, smoothstep(7.4, 8.4, q.y));
      c = mix(c, vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow * step(q.y, 3.9));
      col = mix(col, mix(c, FOGC, uHz * 0.5 * (1.0 - u * 0.0)), cv(bd));
    }
  }
}
vec3 skyer(vec2 p, vec3 col){
  if (uCY > -5.0) {
    float n = fbm(vec2(p.x * 0.012 - T * 0.025, p.y * 0.03));
    float n2 = fbm(vec2(p.x * 0.03 + T * 0.04, p.y * 0.07) + 4.0);
    float edge = uCY + 18.0 * (n - 0.5) + 7.0 * (n2 - 0.5);
    col = mix(col, CLDC * (0.92 + 0.12 * n2), sat(smoothstep(edge + 9.0, edge - 7.0, p.y) * (0.7 + 0.3 * n2)));
  }
  float wet = max(uRain, uSnow), dy = (p.y - 60.0) / 9.0;
  float b = exp(-dy * dy) * smoothstep(0.45, 0.8, fbm(vec2(p.x * 0.01 - T * 0.02, p.y * 0.05 + 1.7)));
  return mix(col, CLDC, b * (0.15 + 0.5 * wet));
}
void sykehus(vec2 p, inout vec3 col){
  if (p.x > 62.0 || p.y < 78.0 || p.y > 132.0) return;
  float d1 = rb(p, vec2(-4.0, 88.0), vec2(56.0, 131.0)), d2 = rb(p, vec2(12.0, 79.0), vec2(34.0, 88.5));
  float a = max(cv(d1), cv(d2)); if (a <= 0.0) return;
  float side = smoothstep(49.5, 50.5, p.x) * step(88.5, p.y) + smoothstep(29.5, 30.5, p.x) * step(p.y, 88.5);
  vec3 w = vec3(0.8, 0.79, 0.76) * (0.9 + 0.1 * vn(p * 0.5)) * (1.0 - 0.08 * smoothstep(0.6, 0.9, vn(p * vec2(0.4, 0.15))));
  vec3 c = w * lit(mix(1.0, 0.38, side));
  vec2 gi = floor(vec2((p.x + 2.0) / 4.0, (p.y - 81.0) / 3.6)), g = vec2(mod(p.x + 2.0, 4.0), mod(p.y - 81.0, 3.6));
  float win = cv(rb(g, vec2(0.9, 0.9), vec2(3.1, 2.5))) * step(p.y, 127.5) * (1.0 - side) * (1.0 - cv(abs(p.y - 88.5) - 1.2));
  float hh = hs(gi);
  vec3 glz = mix(uSkB * 0.5, vec3(0.05, 0.06, 0.08), 0.5 + 0.4 * uNight) * (AMB + 0.2);
  vec3 E = mix(vec3(0.85, 0.9, 1.0), VARM, step(0.55, fract(hh * 7.0))) * step(1.0 - 0.62 * uNight, hh) * LYS * 1.1;
  c = mix(c, glz + E, win);
  c *= 1.0 - 0.3 * cv(abs(p.y - 88.8) - 0.4) - 0.3 * cv(abs(p.y - 79.6) - 0.5);
  c = mix(c, vec3(0.88, 0.9, 0.94) * lit(1.0), uSnow * sat(cv(abs(p.y - 79.3) - 0.5) + cv(abs(p.y - 88.3) - 0.4) * step(34.0, p.x)) * 0.9);
  col = mix(col, mix(c, FOGC, uHz * 0.3), a);
}
void husrad(vec2 p, inout vec3 col){
  if (p.y < 98.0 || p.y > 146.0) return;
  for (int k = 0; k < 5; k++) {
    float fk = float(k), yb = 110.0 + fk * 7.0, CW = 9.0 + fk * 2.0, sc = 0.7 + fk * 0.16;
    if (p.y > yb + 1.0 || p.y < yb - 12.0 * sc) continue;
    float sh = hs(vec2(fk, 3.0)), ci = floor(p.x / CW + sh);
    float h1 = hs(vec2(ci, fk)), h2 = hs(vec2(ci, fk + 9.0)), h4 = hs(vec2(ci + 5.0, fk));
    float bw = CW * (0.5 + 0.38 * h2), xc = (ci + 0.5 - sh) * CW + (hs(vec2(ci + 17.0, fk)) - 0.5) * (CW - bw);
    float xm = p.x - xc, hb = bw * 0.5, ax = abs(xm), bm = yb - p.y;
    if (h1 > 0.6) {
      float r = (1.7 + 1.5 * h2) * sc, e; vec2 dq = vec2(xm, -(bm - r * 0.9));
      vec3 dd = dome(dq, r, ci + fk * 3.0, e);
      float ta = sat(e * uDpr * 0.6 + 0.5); if (ta < 0.01) continue;
      vec3 c2 = lovFarge(fract(h2 * 7.7)) * dd.x * lit(0.9);
      c2 = mix(c2, vec3(0.86, 0.89, 0.93) * lit(0.9) * (0.7 + 0.3 * dd.x), uSnow * smoothstep(0.5, 0.85, dd.x) * 0.8);
      col = mix(col, mix(c2, FOGC, uHz * 0.25), ta); continue;
    }
    float hw = (3.4 + 2.2 * h4) * sc, rt = hw + min(hb * 0.7, 2.6 * sc) * sat(1.0 - ax / (hb + 0.4));
    float e = max(min(hb - ax, hw - bm), min(min(rt - bm, hb + 0.4 - ax), bm - hw + 0.02));
    float a = sat(e * uDpr * 0.8 + 0.5) * step(-0.5, bm);
    if (a < 0.01) continue;
    vec3 wc = h4 < 0.35 ? vec3(0.82, 0.81, 0.77) : (h4 < 0.55 ? vec3(0.8, 0.7, 0.46) : (h4 < 0.72 ? vec3(0.55, 0.21, 0.15) : (h4 < 0.86 ? vec3(0.7, 0.73, 0.74) : vec3(0.84, 0.82, 0.76))));
    vec3 rc = fract(h4 * 7.3) < 0.55 ? vec3(0.5, 0.2, 0.13) : vec3(0.17, 0.18, 0.2), c;
    if (bm > hw) c = rc * mix(1.05, 0.65, step(0.0, xm)) * lit(0.9) * (0.85 + 0.25 * vn(p * 2.0));
    else {
      c = wc * lit(0.85) * mix(1.0, 0.78, smoothstep(hb - 1.2, hb, xm)) * (0.88 + 0.2 * vn(p * 0.9 + ci));
      vec2 wq = vec2(mod(xm + hb, 2.0 * sc) - sc, mod(bm, 2.2 * sc) - 1.1 * sc);
      float wv = cv(max(abs(wq.x) - 0.45 * sc, abs(wq.y) - 0.5 * sc)) * step(0.8 * sc, bm) * step(bm, hw - 0.6) * step(ax, hb - 0.7);
      float hh = hs(vec2(ci * 5.0 + floor((xm + hb) / (2.0 * sc)), fk * 7.0 + floor(bm / (2.2 * sc))));
      vec3 glz = mix(uSkB * 0.45, vec3(0.05, 0.06, 0.08), 0.5 + 0.4 * uNight) * (AMB + 0.2);
      c = mix(c, glz + VARM * LYS * 1.2 * step(1.0 - 0.45 * uNight, hh), wv);
    }
    c = mix(c, vec3(0.88, 0.9, 0.94) * lit(1.0), uSnow * step(hw, bm) * 0.85);
    col = mix(col, mix(c, FOGC, uHz * 0.25), a);
  }
}
float lnP(float dm, float pxm){ return 1.0 - smoothstep(0.25, 0.25 + 1.0 / uDpr, dm * pxm); }
vec3 fanF(float fh){ return fh < 0.45 ? vec3(0.72, 0.1, 0.09) : (fh < 0.7 ? vec3(0.9, 0.88, 0.85) : (fh < 0.88 ? vec3(0.08, 0.08, 0.1) : vec3(0.3, 0.32, 0.4))); }
vec3 stadion(vec2 p, vec3 col, inout vec3 glow){
  for (int k = 0; k < 2; k++) { vec2 hq = p - vec2(k == 0 ? CX - HWF - 20.0 : CX + HWF + 20.0, 82.0); float r2 = dot(hq, hq); glow += FL * FLD * (1.1 * exp(-r2 / 28.0) + 0.22 / (1.0 + r2 / 500.0)); }
  if (p.x < 80.0 || p.x > 312.0 || p.y < 76.0) return col;
  for (int k = 0; k < 2; k++) {
    float mx = k == 0 ? CX - HWF - 20.0 : CX + HWF + 20.0;
    vec2 hq = p - vec2(mx, 82.0);
    if (abs(hq.x) < 7.0 && hq.y > -5.0 && hq.y < 33.0) {
      float pole = cv(max(abs(hq.x) - 0.75, max(-hq.y, hq.y - 32.0)));
      col = mix(col, vec3(0.45, 0.47, 0.49) * lit(0.75) * mix(1.0, 0.7, step(0.0, hq.x)), pole);
      float head = cv(rb(hq, vec2(-5.2, -3.2), vec2(5.2, 2.0)));
      vec2 lg = vec2(mod(hq.x + 5.2, 2.6), mod(hq.y + 3.2, 2.6));
      float lamp = cv(rb(lg, vec2(0.45, 0.45), vec2(2.15, 2.15))) * head;
      col = mix(col, vec3(0.22, 0.23, 0.24) * lit(0.6), head);
      col = mix(col, mix(vec3(0.62, 0.64, 0.62) * lit(0.8), FL * 3.0, FLD), lamp);
    }
  }
  if (p.y > BT - 5.0 && p.y < YF + 0.5) {
    float v = sat((p.y - BT) / (YF - BT)), hwB = mix(78.0, HWF + 1.0, v);
    float a = sat((hwB - abs(p.x - CX)) * uDpr + 0.5);
    if (a > 0.0) {
      vec3 c;
      if (p.y < BT) {
        c = vec3(0.32, 0.33, 0.35) * lit(0.9) * (0.9 + 0.1 * vn(p * 0.8));
        c = mix(c, vec3(0.86, 0.86, 0.84) * lit(1.0), cv(abs(p.y - (BT - 0.9)) - 0.55));
        c = mix(c, vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow * cv(abs(p.y - (BT - 4.4)) - 0.6));
        c += FL * 1.6 * FLD * step(0.5, fract(p.x / 3.0)) * cv(abs(p.y - (BT - 0.4)) - 0.35);
      } else {
        float rr = (p.y - BT) / 1.3, row = fract(rr);
        vec2 cell = vec2(floor(p.x / 0.9), floor(rr));
        float occ = step(0.5 - 0.25 * FLD, hs(cell));
        c = vec3(0.6, 0.08, 0.07) * (0.7 + 0.3 * smoothstep(0.0, 0.35, row) * smoothstep(1.0, 0.65, row));
        c = mix(c, fanF(hs(cell + 5.0)), occ * 0.75 * step(0.25, row));
        c = mix(c, vec3(0.5, 0.5, 0.49), cv(abs(mod(p.x - CX + 9.0, 18.0) - 9.0) - 0.55));
        c *= mix(0.42, 1.0, smoothstep(BT, BT + 10.0, p.y));
        c *= lit(0.65) + FL * FLD * 0.4;
        c = mix(c, vec3(0.75, 0.74, 0.72) * lit(0.8), cv(abs(p.y - (YF - 0.6)) - 0.5));
      }
      col = mix(col, c, a);
    }
  }
  for (int k = 0; k < 2; k++) {
    float sg = k == 0 ? -1.0 : 1.0, ori = -sg;
    vec2 A = vec2(CX + sg * HWF, YF), B = vec2(CX + sg * HWN, YN), C = vec2(CX + sg * (HWN + 13.0), YN - 18.0), D = vec2(CX + sg * (HWF + 13.0), BT - 3.0);
    vec2 e0 = B - A, e1 = C - B, e2 = D - C, e3 = A - D;
    float d0 = crs(e0, p - A) / length(e0) * ori, d1 = crs(e1, p - B) / length(e1) * ori, d2 = crs(e2, p - C) / length(e2) * ori, d3 = crs(e3, p - D) / length(e3) * ori;
    float dm = min(min(d0, d1), min(d2, d3));
    if (dm < -1.0) continue;
    float a = sat(dm * uDpr + 0.5), s = sat(d0 / max(d0 + d2, 0.1)), row = fract(s * 11.0);
    vec2 cell = vec2(floor(s * 11.0), floor(p.y));
    float occ = step(0.5 - 0.25 * FLD, hs(cell + sg * 3.0));
    vec3 c = vec3(0.6, 0.08, 0.07) * (0.7 + 0.3 * smoothstep(0.0, 0.35, row) * smoothstep(1.0, 0.65, row));
    c = mix(c, fanF(hs(cell + 9.0 + sg)), occ * 0.75 * step(0.25, row));
    c *= (lit(k == 0 ? 0.32 : 0.8) + FL * FLD * 0.38) * mix(0.5, 1.0, smoothstep(0.0, 3.0, d2));
    c = mix(c, mix(vec3(0.3, 0.31, 0.33) * lit(0.85), vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow), 1.0 - smoothstep(1.8, 2.6, d2));
    c = mix(c, vec3(0.75, 0.74, 0.72) * lit(0.8), cv(d0 - 0.5));
    col = mix(col, c, a);
  }
  if (p.y >= YF - 0.5 && p.y <= YN + 0.5) {
    float v = sat((p.y - YF) / (YN - YF)), hw = mix(HWF, HWN, v), u = (p.x - CX) / hw;
    if (abs(u) < 1.02) {
      float a = sat((hw - abs(p.x - CX)) * uDpr + 0.5);
      float pv = 1.6 * v / (1.0 + 0.6 * v), fx = u * 55.0, fy = (pv - 0.5) * 74.0;
      float mx = hw / 55.0, my = (YN - YF) / 74.0 * (1.0 + 0.6 * v) * (1.0 + 0.6 * v) / 1.6;
      float st = mod(floor((fx + 55.0) / 5.5), 2.0), wq = (abs(fx) - 46.0) / 4.0;
      vec3 g = vec3(0.17, 0.37, 0.13) * (0.9 + 0.12 * st) * (0.88 + 0.2 * vn(vec2(fx * 0.4, fy * 0.6)));
      g = mix(g, vec3(0.32, 0.3, 0.16), sat(exp(-wq * wq - fy * fy / 60.0) + 0.5 * exp(-fx * fx / 30.0 - fy * fy / 40.0)) * 0.35);
      float Ln = 0.0, cr = length(vec2(fx, fy));
      Ln = max(Ln, lnP(abs(abs(fy) - 34.0), my) * step(abs(fx), 50.2));
      Ln = max(Ln, lnP(abs(abs(fx) - 50.0), mx) * step(abs(fy), 34.2));
      Ln = max(Ln, lnP(abs(fx), mx) * step(abs(fy), 34.0));
      Ln = max(Ln, lnP(abs(cr - 9.15), 0.5 * (mx + my)));
      Ln = max(Ln, lnP(abs(abs(fx) - 33.5), mx) * step(abs(fy), 20.2) * step(abs(fx), 50.0));
      Ln = max(Ln, lnP(abs(abs(fy) - 20.16), my) * step(33.5, abs(fx)) * step(abs(fx), 50.0));
      Ln = max(Ln, lnP(abs(abs(fx) - 44.5), mx) * step(abs(fy), 9.2));
      Ln = max(Ln, lnP(abs(abs(fy) - 9.16), my) * step(44.5, abs(fx)) * step(abs(fx), 50.0));
      g = mix(g, vec3(0.86, 0.88, 0.85), Ln * 0.85);
      vec3 gl2 = g * (lit(0.85) + FL * FLD * 0.9);
      gl2 *= 1.0 - 0.35 * uSun * smoothstep(0.16, 0.05, pv);
      for (int k = 0; k < 2; k++) {
        float gxs = CX + (k == 0 ? -1.0 : 1.0) * 50.0 / 55.0 * mix(HWF, HWN, 0.3846);
        float gd = rb(p - vec2(gxs, 149.5), vec2(-0.45, -3.4), vec2(0.45, 0.9));
        gl2 = mix(gl2, vec3(0.7) * lit(0.8), cv(gd) * 0.25);
        gl2 = mix(gl2, vec3(0.95) * (lit(0.9) + FL * FLD * 0.6), cv(abs(gd) - 0.22));
      }
      float bx = 36.0 * sin(T * 0.07) + 8.0 * sin(T * 0.31), by = 22.0 * sin(T * 0.09 + 1.0);
      for (int i = 0; i < 13; i++) {
        float fi = float(i);
        float fxp = i == 12 ? bx : clamp(bx * 0.7 + 22.0 * sin(T * 0.19 + fi * 2.3) + 10.0 * sin(T * 0.47 + fi * 4.1), -48.0, 48.0);
        float fyp = i == 12 ? by : clamp(by * 0.6 + 16.0 * sin(T * 0.23 + fi * 1.7 + 1.0), -31.0, 31.0);
        float pvp = fyp / 74.0 + 0.5, vp = pvp / (1.6 - 0.6 * pvp);
        vec2 d = p - vec2(CX + fxp / 55.0 * mix(HWF, HWN, vp), YF + vp * (YN - YF));
        if (abs(d.x) > 2.0 || d.y > 0.8 || d.y < -3.2) continue;
        float sc = 0.85 + 0.3 * vp;
        if (i == 12) { gl2 = mix(gl2, vec3(0.97) * (lit(1.0) + FL * FLD), cv(length(d - vec2(0.0, -0.3)) - 0.32)); continue; }
        gl2 *= 1.0 - 0.45 * (1.0 - smoothstep(0.3, 0.9, length(d * vec2(0.9, 2.6) + vec2(0.4, 0.0))));
        float body = rb(d, vec2(-0.42, -1.7) * sc, vec2(0.42, 0.0)), head = length(d - vec2(0.0, -2.05 * sc)) - 0.3 * sc;
        vec3 kit = i < 6 ? vec3(0.78, 0.1, 0.08) : vec3(0.88, 0.88, 0.9);
        vec3 pc = mix(kit, vec3(0.92, 0.92, 0.9), step(-0.6 * sc, d.y) * (i < 6 ? 1.0 : 0.0));
        pc = mix(pc, vec3(0.72, 0.55, 0.42), cv(head));
        gl2 = mix(gl2, pc * (lit(0.9) + FL * FLD * 0.8), cv(min(body, head)));
      }
      col = mix(col, gl2, a);
    }
  }
  if (p.y > YN - 0.5 && p.y < YN + 16.0 && abs(p.x - CX) < HWN + 13.0) {
    float yy = p.y - YN, ax = abs(p.x - CX), a = sat((HWN + 12.0 - ax) * uDpr + 0.5);
    vec3 c;
    if (yy < 2.2 && ax < HWN - 1.0) {
      float hue = fract(p.x * 0.035 - T * 0.25), seg = step(0.5, fract(p.x * 0.07 - T * 0.5));
      vec3 led = hue < 0.33 ? vec3(0.9, 0.12, 0.1) : (hue < 0.66 ? vec3(0.95, 0.95, 0.92) : vec3(0.95, 0.7, 0.1));
      c = led * (0.75 + 0.25 * seg) * (0.5 + 0.4 * LYS + 0.5 * FLD);
    } else if (yy < 8.0) {
      c = vec3(0.62, 0.62, 0.6) * lit(0.85) * (0.9 + 0.1 * vn(p * 0.6)) * (1.0 - 0.12 * cv(abs(mod(p.x, 6.0) - 3.0) - 0.15)) * mix(0.7, 1.0, smoothstep(2.2, 4.0, yy));
    } else {
      c = mix(vec3(0.55, 0.55, 0.53) * lit(0.8), vec3(0.6, 0.09, 0.08) * (lit(0.9) + VARM * LYS * 0.5), step(ax, 56.0));
    }
    c = mix(c, vec3(0.88, 0.9, 0.94) * lit(1.0), uSnow * step(2.2, yy) * cv(abs(yy - 2.7) - 0.5));
    col = mix(col, c, a);
  }
  if (p.y >= YN + 15.5 && p.x > 70.0 && p.x < 320.0) {
    float yy = p.y - (YN + 16.0);
    vec3 c = vec3(0.17, 0.175, 0.185) * (0.85 + 0.3 * vn(p * vec2(0.6, 1.5))) * lit(0.85) * mix(1.0, 0.55, uWet);
    float rf = uWet * (0.5 + 0.5 * vn(vec2(p.x * 0.3, p.y * 1.4 - T * 0.4)));
    vec3 refl = mix(vec3(0.55, 0.55, 0.53) * lit(0.8), vec3(0.6, 0.09, 0.08) * (lit(0.9) + VARM * LYS * 0.5), step(abs(p.x - CX), 56.0)) * exp(-yy / 5.0);
    c += refl * rf * 0.5;
    for (int k = 0; k < 2; k++) { float mxx = (CX + (k == 0 ? -1.0 : 1.0) * (HWF + 20.0) - p.x) / 4.0; c += FL * FLD * exp(-mxx * mxx) * rf * 0.35; }
    c = mix(c, vec3(0.86, 0.89, 0.93) * lit(0.9), uSnow * 0.8);
    col = c;
  }
  return col;
}
void venstre(vec2 p, inout vec3 col){
  if (p.x > 118.0 || p.y < 116.0) return;
  float lim = 100.0 - (p.y - 140.0) * 0.12;
  col = mix(col, vec3(0.03, 0.05, 0.03) * lit(0.5), sat((lim - p.x) * 0.5) * smoothstep(126.0, 134.0, p.y));
  vec2 CS = vec2(7.5, 6.0), gi = floor(p / CS);
  float bK = -1e3, bA = 0.0; vec3 bC = vec3(0.0);
  for (int j = 0; j < 3; j++) {
    for (int i = 0; i < 3; i++) {
      vec2 cid = gi + vec2(float(i) - 1.0, float(j) - 1.0);
      float h = hs(cid + 31.0), h2 = hs(cid + 37.3), h3 = hs(cid + 43.1);
      vec2 ctr = (cid + 0.5 + (vec2(h2, h3) - 0.5) * 0.7) * CS;
      if (ctr.y < 126.0 || ctr.x > 100.0 - (ctr.y - 140.0) * 0.12 + 6.0 * (h - 0.5)) continue;
      vec2 d = p - ctr; float r = 3.4 + 2.4 * h2, e, sh; vec3 tc;
      if (h < 0.35) {
        float wd = r * 0.8 * sat((d.y + r * 1.7) / (r * 2.3)) * (0.75 + 0.4 * vn(vec2(d.y * 1.4, cid.x * 3.0)));
        e = min(wd - abs(d.x), r * 0.6 - d.y);
        sh = (0.6 + 0.45 * smoothstep(0.5, -0.5, d.x / max(wd, 0.3))) * (0.7 + 0.45 * vn(d * vec2(1.6, 0.9) + cid * 3.0));
        tc = mix(vec3(0.045, 0.11, 0.065), vec3(0.085, 0.16, 0.085), h3);
      } else {
        vec2 dw = d + (vec2(vn(d * 0.9 + cid * 5.0), vn(d * 0.9 + cid * 5.0 + 3.7)) - 0.5) * r * 0.45;
        vec3 dd = dome(dw, r, h, e); sh = dd.x * (0.75 + 0.4 * vn(d * 1.8 + cid));
        tc = lovFarge(sat(vn(ctr * 0.05 + 4.0) * 0.8 + h3 * 0.3)) * (0.65 + 0.45 * h);
      }
      float cov = sat(e * uDpr * 0.6 + 0.5);
      if (cov <= 0.0) continue;
      vec3 tl = tc * sh * lit(0.9);
      tl = mix(tl, vec3(0.86, 0.89, 0.93) * lit(0.9) * (0.7 + 0.3 * sh), uSnow * smoothstep(0.55, 0.85, sh) * 0.85);
      float key = (e > 0.0 ? sqrt(max(e * (2.0 * r - e), 0.0)) : e * 2.0) + ctr.y * 0.25;
      if (key > bK) { bK = key; bC = tl; bA = cov; }
    }
  }
  col = mix(col, bC, bA);
}
void hoyre(vec2 p, inout vec3 col){
  if (p.x < 270.0) return;
  for (int k = 0; k < 3; k++) {
    float fk = float(k), bx = 372.0 + fk * 8.5, base = 170.0 - 36.0 * smoothstep(282.0, 392.0, bx), top = base - 22.0 - 4.0 * fk;
    float tx = p.x - bx - (p.y - base) * 0.03;
    float tr = cv(max(abs(tx) - 0.6, max(top - p.y, p.y - base)));
    vec3 tc = vec3(0.86, 0.85, 0.8) * lit(mix(1.0, 0.5, step(0.0, tx))) * (1.0 - 0.8 * step(0.8, vn(vec2(bx, p.y * 1.3))));
    col = mix(col, tc, tr);
    float e; vec2 cd = (p - vec2(bx, top + 2.0)) * vec2(1.0, 1.15);
    vec3 dd = dome(cd, 5.0, fk + 2.0, e);
    vec3 cc = mix(vec3(0.74, 0.6, 0.16), vec3(0.5, 0.52, 0.18), vn(cd * 0.8 + fk)) * dd.x * lit(0.9);
    cc = mix(cc, vec3(0.86, 0.89, 0.93) * lit(0.9) * (0.7 + 0.3 * dd.x), uSnow * 0.75);
    col = mix(col, cc, sat(e * uDpr * 0.6 + 0.5));
  }
  float yR = 170.0 - 36.0 * smoothstep(282.0, 392.0, p.x) + 2.5 * (vn(vec2(p.x * 0.15, 7.0)) - 0.5);
  if (p.y < yR - 1.0) return;
  float a = sat((p.y - yR) * uDpr + 0.5);
  vec3 g = mix(vec3(0.46, 0.42, 0.2), vec3(0.3, 0.36, 0.17), vn(p * 0.12));
  g = mix(g, vec3(0.34, 0.21, 0.18), smoothstep(0.55, 0.8, vn(p * 0.2 + 5.0)) * 0.7);
  g *= 0.7 + 0.45 * (vn(p * vec2(0.9, 1.6)) * 0.6 + vn(p * 2.6) * 0.4);
  g = mix(g, vec3(0.5, 0.5, 0.48) * (0.8 + 0.3 * vn(p * 2.0)), smoothstep(0.78, 0.86, vn(p * 0.45 + 11.0)));
  float yP = 196.0 - (p.x - 296.0) * 0.5, pd = abs(p.y - yP) - (2.4 + (p.y - 150.0) * 0.04);
  g = mix(g, vec3(0.56, 0.51, 0.43) * (0.75 + 0.4 * vn(p * 1.8)) * mix(1.0, 0.65, uWet), cv(pd * 0.7));
  g = mix(g, vec3(0.88, 0.9, 0.94) * (0.85 + 0.15 * vn(p)), uSnow * (1.0 - cv(pd) * 0.6) * 0.9);
  vec3 c = g * lit(0.9) * (0.9 + 0.12 * smoothstep(yR + 5.0, yR, p.y));
  vec2 sd = (p - vec2(307.0, 183.0)) / vec2(7.0, 2.0);
  c *= 1.0 - 0.4 * exp(-dot(sd, sd)) * (0.4 + 0.6 * uSun);
  for (int k = 0; k < 4; k++) {
    float fk = float(k);
    vec2 cc = vec2(306.0 + 0.5 * sin(fk * 2.0), 181.0 - fk * 3.1), r = vec2(5.0 - fk * 1.0, 2.5 - fk * 0.3);
    vec2 q = (p - cc) / r; float l = length(q);
    if (l > 1.2) continue;
    float dm = sqrt(max(1.0 - l * l, 0.0));
    vec3 nn = normalize(vec3(q.x, -q.y, dm + 0.15));
    float shd = 0.35 + 0.75 * max(dot(nn, normalize(vec3(-0.5, 0.6, 0.62))), 0.0);
    vec3 st = mix(vec3(0.5, 0.5, 0.48), vec3(0.42, 0.44, 0.36), vn(p * 1.5 + fk)) * (0.8 + 0.3 * vn(p * 3.0));
    st = mix(st, vec3(0.9, 0.92, 0.95), uSnow * step(0.3, nn.y));
    c = mix(c, st * shd * lit(0.9), sat((1.0 - l) * min(r.x, r.y) * uDpr * 1.2 + 0.5));
  }
  col = mix(col, c, a);
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
  vec2 p = FlutterFragCoord().xy / uDpr;
  AA = 1.0 / uDpr; T = uT; LYS = 0.22 + 0.78 * uNight; FLD = max(smoothstep(0.3, 0.7, uNight), uRain * 0.55);
  VARM = vec3(1.0, 0.74, 0.42);
  AMB = max(mix(uSkM, uSkB, 0.5) * mix(1.0, 0.4, uNight) * mix(1.0, 0.62, uSun), vec3(0.07, 0.08, 0.1)) + vec3(0.05, 0.035, 0.02) * uNight;
  SUNC = vec3(1.0, 0.93, 0.8) * 0.8; SSC = vec3(1.0, 0.6, 0.34) * 0.85;
  FOGC = mix(uSkB, uSkM, 0.3) + vec3(0.1, 0.06, 0.02) * uNight * 0.5;
  CLDC = mix(uSkB, uSkM, 0.55) * 1.02 + vec3(0.12, 0.07, 0.02) * uNight * 0.55;
  vec3 glow = vec3(0.0), col = vec3(0.0);
  bool skjult = (p.y > 113.0 && abs(p.x - CX) < 64.0) || (p.y > 184.5 && p.x > 104.0 && p.x < 296.0);
  if (!skjult) {
    col = p.y < ridge(p.x) ? himmel(p) : fjell(p);
    toppen(p, col, glow);
    bane(p, col, glow);
    col = skyer(p, col);
    sykehus(p, col);
    husrad(p, col);
  }
  col = stadion(p, col, glow);
  venstre(p, col);
  hoyre(p, col);
  col += glow;
  if (uRain > 0.0) { float r = regn(p, 3.0, 380.0, 9.0, 1.0) * 0.25 + regn(p, 5.0, 560.0, 16.0, 7.0) * 0.4 + regn(p, 8.0, 760.0, 26.0, 13.0) * 0.5;
    col += (vec3(0.75, 0.8, 0.85) * (0.08 + 0.26 * (1.0 - uNight)) + glow * 1.4) * r * uRain; }
  if (uSnow > 0.0) { float sn = sno(p, 9.0, 14.0, 1.0) * 0.55 + sno(p, 16.0, 24.0, 5.0) * 0.85 + sno(p, 28.0, 40.0, 9.0);
    col = mix(col, vec3(0.93, 0.95, 1.0) * (0.6 + 0.35 * (1.0 - uNight)) + glow * 1.5, sat(sn) * uSnow); }
  col = max(col, 0.0);
  float lu = dot(col, vec3(0.3, 0.55, 0.15));
  col = mix(vec3(lu), col, 0.86);
  col += (vec3(-0.01, 0.002, 0.018) * (1.0 - smoothstep(0.0, 0.35, lu)) + vec3(0.018, 0.006, -0.014) * smoothstep(0.4, 1.0, lu)) * (1.0 - 0.6 * uNight);
  vec3 xe = col * (0.92 - 0.14 * uSun);
  col = clamp((xe * (2.51 * xe + 0.03)) / (xe * (2.43 * xe + 0.59) + 0.14), 0.0, 1.0);
  vec2 vq = p / uRes - 0.5; col *= 1.0 - 0.14 * smoothstep(0.35, 0.8, length(vq * vec2(1.0, 0.8)));
  col += (hs(floor(p * uDpr) + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
