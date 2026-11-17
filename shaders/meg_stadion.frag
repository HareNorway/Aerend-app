// Brann stadion under Ulriken — the prototype's Meg hero scene
// (`data-ulgl="meg"`, `ulGlInit` in the Lys export ui-tools/proto-lys/onb.html),
// ported as is: the mountain and Ulriksbanen (cable, cabins), the clouds and
// mist, the mast light, the stadium with the crowd (`publikum`), the players
// (`spillere`), the LED boards (`led`), the floodlights and their beams, the
// town lights (`lykter`), the haze band (`dis`), the houses, the rain, the
// snow and the stars, through the filmic grade and vignette (`grade`).
// Two passes, as `ulGlTegn` draws them: uPass 0 is the scene, rendered into
// a supersampled image (up to 4× the design px) a stripe at a time; uPass 1
// is the screen pass, which reads that image (uScene) and adds what moves —
// the soft blur over the mountain, the Ulriksbanen cabins, the mast's red
// blink, the players and the ball, the LED boards, rain, snow and grain.
// Only the GLSL dialect changed (Flutter's runtime effect: uniforms one per
// line — uPass and uScene moved to the end of the list —, FlutterFragCoord,
// fragColor, texture()). Rendered offscreen into an image whose pixel grid is
// (uRes * uDpr), so FlutterFragCoord is the pixel (top-left, the same way up
// as the uScene image), as in sjo.frag.
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
uniform float uPass;
uniform sampler2D uScene;

out vec4 fragColor;
float AA, T, LYS, FLD, RW;
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
  e += r * 0.24 * (vn(d * (2.4 / max(r * 0.5, 0.6)) + sd * 5.0) - 0.5);
  float dm = sqrt(max(e, 0.0) * max(2.0 * r - e, 0.0));
  vec3 nn = normalize(vec3(d.x, -d.y, max(dm, 0.2)));
  return vec3((0.45 + 0.62 * max(dot(nn, normalize(vec3(-0.5, 0.6, 0.62))), 0.0)) * (0.6 + 0.7 * vn(d * (3.0 / max(r * 0.5, 0.6)) + sd * 7.0)) * (0.76 + 0.48 * vn(d * (8.5 / max(r * 0.5, 0.6)) + sd * 3.0)), dm, 0.0);
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
        tc = lovFarge(k); tc = mix(tc, vec3(dot(tc, vec3(0.3, 0.55, 0.15))), 0.42) * (0.6 + 0.5 * h);
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
  if (fo > 0.01) {
    vec3 bl = lit(0.5 + 0.6 * (fo > 0.99 ? 0.6 + 0.5 * (h - 0.5) : k));
    vec3 sk = skog(p, bl, vec2(3.4, 2.8), 1.5, 1.1, 0.3);
    vec3 jv = mix(vec3(0.07, 0.11, 0.065), vec3(0.2, 0.17, 0.09), smoothstep(0.3, 0.7, vn(p * vec2(0.045, 0.07) + 2.0))) * (0.7 + 0.6 * vn(p * vec2(0.9, 1.3))) * bl;
    jv = mix(jv, vec3(0.8, 0.83, 0.88) * bl, uSnow * 0.6);
    c = mix(c, mix(sk, jv, 0.3 + 0.45 * smoothstep(128.0, 72.0, p.y)), fo);
  }
  return mix(c, FOGC, sat(uHz * mix(1.2, 0.45, smoothstep(20.0, 140.0, p.y))));
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
vec3 grade(vec3 col, vec2 p){
  col = max(col, 0.0);
  float lu = dot(col, vec3(0.3, 0.55, 0.15));
  col = mix(vec3(lu), col, 0.86);
  col += (vec3(-0.01, 0.002, 0.018) * (1.0 - smoothstep(0.0, 0.35, lu)) + vec3(0.018, 0.006, -0.014) * smoothstep(0.4, 1.0, lu)) * (1.0 - 0.6 * uNight);
  vec3 xe = col * (0.92 - 0.14 * uSun);
  col = clamp((xe * (2.51 * xe + 0.03)) / (xe * (2.43 * xe + 0.59) + 0.14), 0.0, 1.0);
  vec2 vq = p / uRes - 0.5;
  return col * (1.0 - 0.18 * smoothstep(0.35, 0.8, length(vq * vec2(1.0, 0.8))));
}
vec4 lag(vec4 ov, vec3 c, float a){ return vec4(mix(ov.rgb, c, a), ov.a + (1.0 - ov.a) * a); }
void tau(vec2 p, inout vec3 col){
  if (p.x < SA.x - 8.0 || p.x > SB.x + 8.0 || p.y < SB.y - 6.0 || p.y > SA.y + 14.0) return;
  vec3 rc = vec3(0.07, 0.07, 0.08) * (AMB + 0.15);
  float t = (p.x - SA.x) / (SB.x - SA.x);
  if (t > 0.0 && t < 1.0) for (int k = 0; k < 2; k++) {
    float dy = abs(p.y - ropeY(p.x, float(k) * 1.9)) * 0.86;
    col = mix(col, rc, (1.0 - smoothstep(0.1, 0.1 + 0.9 / uDpr, dy)) * 0.6);
  }
}
void kabiner(vec2 p, inout vec4 ov, inout vec3 glow){
  if (p.x < SA.x - 8.0 || p.x > SB.x + 8.0 || p.y < SB.y - 6.0 || p.y > SA.y + 14.0) return;
  float acc = uCab(T + 0.7) - 2.0 * uCab(T) + uCab(T - 0.7);
  for (int k = 0; k < 2; k++) {
    float fk = float(k), u = k == 0 ? uCab(T) : 1.0 - uCab(T);
    float x = mix(SA.x, SB.x, u), y = ropeY(x, fk * 1.9);
    float sw = 0.05 * sin(T * 1.25 + fk * 2.0) - clamp(acc * 30.0, -0.3, 0.3) * (k == 0 ? 1.0 : -1.0);
    vec2 d0 = p - vec2(x, y);
    glow += VARM * LYS * 0.5 * exp(-dot(d0 - vec2(0.0, 5.6), d0 - vec2(0.0, 5.6)) / 10.0);
    if (abs(d0.x) > 7.0 || d0.y < -2.0 || d0.y > 11.0) continue;
    ov = lag(ov, vec3(0.1) * (AMB + 0.2), cv(rb(d0, vec2(-1.7, -0.9), vec2(1.7, 0.6))));
    vec2 q = rot(d0, -sw);
    ov = lag(ov, vec3(0.12) * (AMB + 0.2), cv(rb(q, vec2(-0.28, 0.0), vec2(0.28, 3.7))));
    float bd = rb(q, vec2(-3.3, 3.5), vec2(3.3, 8.3)) - 0.45;
    if (bd < 1.0) {
      float sh = 0.72 + 0.38 * smoothstep(3.0, -3.0, q.x);
      vec3 c = vec3(0.68, 0.13, 0.11) * sh * lit(0.9);
      c = mix(c, vec3(0.82, 0.82, 0.8) * sh * lit(0.9), 1.0 - smoothstep(4.1, 4.3, q.y));
      float win = cv(max(abs(q.x) - 2.85, abs(q.y - 5.7) - 0.95)) * (1.0 - cv(abs(q.x) - 0.18));
      vec3 glz = mix(uSkB * 0.6, vec3(0.05, 0.06, 0.08), 0.45 + 0.4 * uNight) * (AMB + 0.25) + vec3(0.12) * smoothstep(0.4, 0.0, abs(q.x * 0.4 - q.y + 5.7 + 0.5)) * (1.0 - uNight);
      c = mix(c, glz + VARM * LYS * 1.1, win);
      c *= mix(1.0, 0.7, smoothstep(7.4, 8.4, q.y));
      c = mix(c, vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow * step(q.y, 3.9));
      ov = lag(ov, mix(c, FOGC, uHz * 0.5), cv(bd));
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
  col = mix(col, mix(c, FOGC, uHz * 0.55), a);
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
      col = mix(col, mix(c2, FOGC, uHz * (0.6 - 0.1 * fk)), ta); continue;
    }
    float hw = (3.4 + 2.2 * h4) * sc, rt = hw + min(hb * 0.7, 2.6 * sc) * sat(1.0 - ax / (hb + 0.4));
    float e = max(min(hb - ax, hw - bm), min(min(rt - bm, hb + 0.4 - ax), bm - hw + 0.02));
    float a = sat(e * uDpr * 0.8 + 0.5) * step(-0.5, bm);
    if (a < 0.01) continue;
    vec3 wc = h4 < 0.35 ? vec3(0.82, 0.81, 0.77) : (h4 < 0.55 ? vec3(0.8, 0.7, 0.46) : (h4 < 0.72 ? vec3(0.55, 0.21, 0.15) : (h4 < 0.86 ? vec3(0.7, 0.73, 0.74) : vec3(0.84, 0.82, 0.76))));
    vec3 rc = fract(h4 * 7.3) < 0.55 ? vec3(0.5, 0.2, 0.13) : vec3(0.17, 0.18, 0.2), c;
    if (bm > hw) c = rc * mix(1.05, 0.65, step(0.0, xm)) * lit(0.9) * (0.85 + 0.25 * vn(p * 2.0));
    else {
      c = mix(wc, vec3(dot(wc, vec3(0.33))), 0.3) * lit(0.85) * mix(1.0, 0.78, smoothstep(hb - 1.2, hb, xm)) * (0.8 + 0.3 * vn(p * 0.9 + ci)) * mix(0.8, 1.0, smoothstep(0.0, 2.0, bm));
      vec2 wq = vec2(mod(xm + hb, 2.0 * sc) - sc, mod(bm, 2.2 * sc) - 1.1 * sc);
      float wv = cv(max(abs(wq.x) - 0.45 * sc, abs(wq.y) - 0.5 * sc)) * step(0.8 * sc, bm) * step(bm, hw - 0.6) * step(ax, hb - 0.7);
      float hh = hs(vec2(ci * 5.0 + floor((xm + hb) / (2.0 * sc)), fk * 7.0 + floor(bm / (2.2 * sc))));
      vec3 glz = mix(uSkB * 0.45, vec3(0.05, 0.06, 0.08), 0.5 + 0.4 * uNight) * (AMB + 0.2);
      c = mix(c, glz + VARM * LYS * 1.2 * step(1.0 - 0.45 * uNight, hh), wv);
    }
    c = mix(c, vec3(0.88, 0.9, 0.94) * lit(1.0), uSnow * step(hw, bm) * 0.85);
    col = mix(col, mix(c, FOGC, uHz * (0.6 - 0.1 * fk)), a);
  }
}
float lnP(float dm, float pxm){ return 1.0 - smoothstep(0.25, 0.25 + 1.0 / uDpr, dm * pxm); }
vec3 publikum(vec2 q, float fyll){
  q.x += 0.5 * mod(floor(q.y), 2.0);
  vec2 id = floor(q), f = fract(q);
  float n2 = vn(id * vec2(0.22, 0.3) + 17.0), h = hs(id), h2 = hs(id + 5.7);
  float occ = step(0.5, h * 0.55 + n2 * 0.45 + fyll - 0.22);
  vec3 c = vec3(0.4, 0.06, 0.055) * (0.5 + 0.5 * smoothstep(0.95, 0.25, f.y));
  float hode = smoothstep(0.36, 0.2, length((f - vec2(0.5, 0.3)) * vec2(1.0, 1.25)));
  float kropp = smoothstep(0.52, 0.32, length((f - vec2(0.5, 0.8)) * vec2(0.95, 1.3)));
  vec3 jk = h2 < 0.5 ? vec3(0.5, 0.085, 0.075) : (h2 < 0.82 ? vec3(0.11, 0.1, 0.115) : (h2 < 0.93 ? vec3(0.6, 0.58, 0.55) : vec3(0.16, 0.2, 0.3)));
  jk *= 0.75 + 0.5 * hs(id + 11.3);
  vec3 hd = mix(vec3(0.56, 0.42, 0.34), vec3(0.13, 0.1, 0.09), step(0.55, hs(id + 2.9)));
  hd = mix(hd, vec3(0.55, 0.09, 0.08), step(0.8, hs(id + 8.1)));
  c = mix(c, jk, kropp * occ);
  c = mix(c, hd, hode * occ);
  return c;
}
vec3 stadion(vec2 p, vec3 col, inout vec3 glow){
  for (int k = 0; k < 2; k++) {
    vec2 M = vec2(k == 0 ? CX - HWF - 20.0 : CX + HWF + 20.0, 82.0);
    vec2 hq = p - M; float r2 = dot(hq, hq);
    glow += FL * FLD * (1.15 * exp(-r2 / 24.0) + 0.2 / (1.0 + r2 / 440.0) + 0.3 * exp(-hq.y * hq.y / 2.0 - hq.x * hq.x / 800.0));
    vec2 dr = normalize(vec2(CX, 152.0) - M);
    float al = dot(hq, dr), pe = abs(crs(dr, hq)), w = 4.0 + max(al, 0.0) * 0.5;
    glow += FL * FLD * (0.04 + 0.3 * max(uHz - 0.15, 0.0)) * smoothstep(w, w * 0.15, pe) * smoothstep(-2.0, 8.0, al) * exp(-max(al, 0.0) / 60.0) * (0.75 + 0.5 * vn(vec2(pe * 0.35 + T * 0.2, al * 0.12 - T * 0.6)));
  }
  { vec2 dq = (p - vec2(CX, 120.0)) / vec2(95.0, 26.0); glow += FL * FLD * (0.04 + 0.14 * uHz) * exp(-dot(dq, dq)); }
  if (p.x < 80.0 || p.x > 312.0 || p.y < 76.0) return col;
  { float gy = (p.y - (BT - 0.3)) / 2.2; glow += FL * FLD * 0.14 * exp(-gy * gy) * smoothstep(80.0, 72.0, abs(p.x - CX)); }
  for (int k = 0; k < 2; k++) {
    float mx = k == 0 ? CX - HWF - 20.0 : CX + HWF + 20.0;
    vec2 hq = p - vec2(mx, 82.0);
    if (abs(hq.x) < 7.0 && hq.y > -5.0 && hq.y < 33.0) {
      float pole = cv(max(abs(hq.x) - 0.75, max(-hq.y, hq.y - 32.0)));
      col = mix(col, vec3(0.4, 0.42, 0.44) * lit(0.75) * mix(1.0, 0.7, step(0.0, hq.x)) * (0.85 + 0.15 * step(0.5, fract(hq.y / 3.0))), pole);
      float head = cv(rb(hq, vec2(-5.2, -3.2), vec2(5.2, 2.0)));
      vec2 lg = vec2(mod(hq.x + 5.2, 2.6), mod(hq.y + 3.2, 2.6));
      float lamp = cv(rb(lg, vec2(0.45, 0.45), vec2(2.15, 2.15))) * head;
      col = mix(col, vec3(0.2, 0.21, 0.22) * lit(0.6), head);
      col = mix(col, mix(vec3(0.6, 0.62, 0.6) * lit(0.8), FL * 3.0, FLD), lamp);
    }
  }
  if (p.y > BT - 8.5 && p.y < YF + 0.5) {
    float v = sat((p.y - BT) / (YF - BT)), hwB = mix(78.0, HWF + 1.0, v), ux = (p.x - CX) / hwB, yy = p.y - BT;
    if (yy < 1.0) {
      float ty = yy + 8.0, hwT = mix(84.0, 79.0, ty / 9.0);
      float a = sat((hwT - abs(p.x - CX)) * uDpr + 0.5) * sat(ty * uDpr);
      if (a > 0.0) {
        float rib = cv(abs(mod(p.x - CX + 400.0, 5.0) - 2.5) - 0.2);
        vec3 c = vec3(0.5, 0.52, 0.54) * (0.84 + 0.16 * vn(p * vec2(0.5, 1.6)) - 0.1 * rib) * lit(0.95) * mix(1.0, 0.78, uWet);
        c += FOGC * uWet * 0.14 * smoothstep(6.5, 0.0, ty) * (0.6 + 0.4 * vn(vec2(p.x * 0.2, ty)));
        c = mix(c, vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow * 0.85);
        c = mix(c, vec3(0.8, 0.8, 0.78) * lit(0.9), cv(abs(ty - 6.7) - 0.45));
        c = mix(c, vec3(0.06, 0.06, 0.07) * (AMB + 0.2) + FL * FLD * 0.12, smoothstep(7.2, 7.6, ty));
        c += FL * 1.7 * FLD * smoothstep(0.4, 0.6, fract(p.x / 3.2)) * cv(abs(ty - 8.1) - 0.4);
        col = mix(col, c, a);
      }
    } else {
      float a = sat((hwB - abs(p.x - CX)) * uDpr + 0.5);
      if (a > 0.0) {
        vec2 q = vec2(ux * 92.0, yy / 1.25);
        vec3 c = publikum(q, 0.42 + 0.3 * FLD - 0.22 * abs(ux));
        float tr = abs(fract(ux * 4.0 + 0.5) - 0.5) * 0.25 * hwB;
        c = mix(c, vec3(0.5, 0.5, 0.49), (1.0 - smoothstep(0.2, 0.2 + AA, tr)) * 0.75);
        c = mix(c, vec3(0.04, 0.04, 0.05), cv(max(abs(fract(ux * 4.0) - 0.5) * 0.25 * hwB - 1.7, abs(yy - 15.4) - 1.1)));
        float bs = ux * 9.0 + 4.5, bh = hs(vec2(floor(bs), 5.0)), bf = fract(bs);
        vec3 bc = mix(vec3(0.66, 0.66, 0.64), bh > 0.75 ? vec3(0.86, 0.86, 0.83) : vec3(0.6, 0.09, 0.08), step(0.45, bh) * step(0.14, bf) * step(bf, 0.86));
        float br = cv(abs(yy - 10.4) - 0.9);
        c = mix(c, bc, br);
        c *= lit(0.62) * mix(0.38, 1.0, smoothstep(1.0, 10.0, yy)) + FL * FLD * (0.2 + 0.32 * exp(-yy / 5.0) + 0.3 * v);
        c *= 1.0 - 0.4 * cv(abs(yy - 11.8) - 0.45);
        c += FL * FLD * 1.4 * step(0.9993, hs(floor(q) + floor(T * 4.0) * 7.3)) * (1.0 - br);
        float ad = cv(abs(yy - 24.0) - 0.95), ah = hs(vec2(floor(ux * 13.0 + 6.5), 8.0));
        vec3 ac = ah < 0.3 ? vec3(0.82, 0.83, 0.8) : (ah < 0.55 ? vec3(0.12, 0.2, 0.42) : (ah < 0.8 ? vec3(0.62, 0.1, 0.08) : vec3(0.8, 0.64, 0.16)));
        ac *= 0.8 + 0.2 * step(0.4, vn(vec2(p.x * 1.4, 2.0)));
        c = mix(c, ac * (lit(0.85) + FL * FLD * 0.55), ad);
        c = mix(c, vec3(0.7, 0.69, 0.67) * (lit(0.8) + FL * FLD * 0.4), cv(abs(p.y - (YF - 0.6)) - 0.5));
        col = mix(col, c, a);
      }
    }
  }
  for (int k = 0; k < 2; k++) {
    float sg = k == 0 ? -1.0 : 1.0, ori = -sg;
    vec2 A = vec2(CX + sg * HWF, YF), B = vec2(CX + sg * HWN, YN), C = vec2(CX + sg * (HWN + 13.0), YN - 18.0), D = vec2(CX + sg * (HWF + 13.0), BT - 3.0);
    vec2 e0 = B - A, e1 = C - B, e2 = D - C, e3 = A - D;
    float d0 = crs(e0, p - A) / length(e0) * ori, d1 = crs(e1, p - B) / length(e1) * ori, d2 = crs(e2, p - C) / length(e2) * ori, d3 = crs(e3, p - D) / length(e3) * ori;
    float dm = min(min(d0, d1), min(d2, d3));
    if (dm < -1.0) continue;
    float a = sat(dm * uDpr + 0.5), s = sat(d0 / max(d0 + d2, 0.1));
    vec3 c = publikum(vec2(p.y * 1.15 + sg * 40.0, s * 12.0), 0.4 + 0.3 * FLD);
    c = mix(c, vec3(0.5, 0.5, 0.49), cv(abs(mod(p.y - YF, 9.0) - 4.5) - 0.28) * 0.7);
    c *= lit(k == 0 ? 0.4 : 0.75) * mix(0.42, 1.0, smoothstep(4.0, 9.0, d2)) + FL * FLD * (0.22 + 0.42 * (1.0 - s));
    vec3 tc = vec3(0.5, 0.52, 0.54) * (0.84 + 0.16 * vn(p * vec2(1.4, 0.5)) - 0.1 * cv(abs(mod(p.y, 4.0) - 2.0) - 0.2)) * lit(0.92) * mix(1.0, 0.78, uWet) + FOGC * uWet * 0.1;
    tc = mix(tc, vec3(0.9, 0.92, 0.96) * lit(1.0), uSnow * 0.85);
    c = mix(c, tc, 1.0 - smoothstep(3.6, 4.2, d2));
    c = mix(c, vec3(0.8, 0.8, 0.78) * lit(0.9), cv(abs(d2 - 4.1) - 0.4));
    c = mix(c, vec3(0.75, 0.74, 0.72) * (lit(0.8) + FL * FLD * 0.4), cv(d0 - 0.5));
    col = mix(col, c, a);
  }
  if (p.y >= YF - 0.5 && p.y <= YN + 0.5) {
    float v = sat((p.y - YF) / (YN - YF)), hw = mix(HWF, HWN, v), u = (p.x - CX) / hw;
    if (abs(u) < 1.02) {
      float a = sat((hw - abs(p.x - CX)) * uDpr + 0.5);
      float pv = 1.6 * v / (1.0 + 0.6 * v), fx = u * 55.0, fy = (pv - 0.5) * 74.0;
      float mx = hw / 55.0, my = (YN - YF) / 74.0 * (1.0 + 0.6 * v) * (1.0 + 0.6 * v) / 1.6;
      float s1 = smoothstep(0.42, 0.58, abs(fract((fx + 55.0) / 11.0) - 0.5) * 2.0);
      float s2 = smoothstep(0.42, 0.58, abs(fract((fy + 37.0) / 12.4) - 0.5) * 2.0);
      float gn = fbm(vec2(fx * 0.3, fy * 0.45) + 5.0), wq = (abs(fx) - 45.0) / 4.5;
      vec3 g = mix(vec3(0.12, 0.25, 0.1), vec3(0.2, 0.33, 0.13), 0.5 + 0.34 * (s1 - 0.5) + 0.16 * (s2 - 0.5));
      g *= 0.82 + 0.3 * gn + 0.08 * vn(vec2(fx, fy) * 2.6);
      g = mix(g, vec3(0.27, 0.3, 0.15), smoothstep(0.55, 0.8, vn(vec2(fx * 0.12, fy * 0.18) + 9.0)) * 0.3);
      float slit = sat(exp(-wq * wq - fy * fy / 50.0) + 0.6 * exp(-fx * fx / 40.0 - fy * fy / 50.0) + 0.3 * exp(-(fy + 35.0) * (fy + 35.0) / 6.0));
      g = mix(g, vec3(0.3, 0.27, 0.16), slit * 0.4 * (0.5 + gn));
      float Ln = 0.0, cr = length(vec2(fx, fy));
      Ln = max(Ln, lnP(abs(abs(fy) - 34.0), my) * step(abs(fx), 50.2));
      Ln = max(Ln, lnP(abs(abs(fx) - 50.0), mx) * step(abs(fy), 34.2));
      Ln = max(Ln, lnP(abs(fx), mx) * step(abs(fy), 34.0));
      Ln = max(Ln, lnP(abs(cr - 9.15), 0.5 * (mx + my)));
      Ln = max(Ln, lnP(abs(abs(fx) - 33.5), mx) * step(abs(fy), 20.2) * step(abs(fx), 50.0));
      Ln = max(Ln, lnP(abs(abs(fy) - 20.16), my) * step(33.5, abs(fx)) * step(abs(fx), 50.0));
      Ln = max(Ln, lnP(abs(abs(fx) - 44.5), mx) * step(abs(fy), 9.2));
      Ln = max(Ln, lnP(abs(abs(fy) - 9.16), my) * step(44.5, abs(fx)) * step(abs(fx), 50.0));
      g = mix(g, vec3(0.8, 0.83, 0.78), Ln * (0.5 + 0.3 * vn(vec2(fx, fy) * 0.8)));
      float pool = exp(-(fx * fx / 3200.0 + fy * fy / 1900.0));
      vec3 gl2 = g * (lit(0.85) + FL * FLD * (0.5 + 0.55 * pool));
      gl2 += FL * FLD * uWet * 0.07 * smoothstep(0.45, 0.0, pv) * (0.4 + vn(vec2(p.x * 0.5, p.y * 2.5 - T * 0.3)));
      gl2 *= 1.0 - 0.35 * uSun * smoothstep(0.16, 0.05, pv);
      gl2 *= 1.0 - 0.3 * smoothstep(YN - 2.5, YN + 0.5, p.y);
      for (int k = 0; k < 2; k++) {
        float gxs = CX + (k == 0 ? -1.0 : 1.0) * 50.0 / 55.0 * mix(HWF, HWN, 0.3846);
        float gd = rb(p - vec2(gxs, 149.5), vec2(-0.45, -3.4), vec2(0.45, 0.9));
        gl2 = mix(gl2, vec3(0.7) * lit(0.8), cv(gd) * 0.25);
        gl2 = mix(gl2, vec3(0.92) * (lit(0.9) + FL * FLD * 0.6), cv(abs(gd) - 0.22));
      }
      col = mix(col, gl2, a);
    }
  }
  if (p.y > YN - 0.5 && p.y < YN + 16.0 && abs(p.x - CX) < HWN + 13.0) {
    float yy = p.y - YN, ax = abs(p.x - CX), a = sat((HWN + 12.0 - ax) * uDpr + 0.5);
    vec3 c;
    if (yy < 2.2 && ax < HWN - 1.0) {
      float sx = p.x - T * 5.0, id = floor(sx / 26.0), f = fract(sx / 26.0), hh = hs(vec2(id, 4.0));
      vec3 led = hh < 0.4 ? vec3(0.74, 0.1, 0.09) : (hh < 0.7 ? vec3(0.82, 0.83, 0.81) : (hh < 0.85 ? vec3(0.1, 0.19, 0.42) : vec3(0.82, 0.64, 0.15)));
      float tegn = step(0.45, vn(vec2(sx * 1.3, id))) * step(0.18, f) * step(f, 0.82) * step(0.6, yy) * step(yy, 1.7);
      led = mix(led, (hh < 0.4 || (hh > 0.7 && hh < 0.85)) ? vec3(0.92) : vec3(0.1, 0.1, 0.14), tegn * 0.8);
      c = led * (0.42 + 0.33 * LYS + 0.4 * FLD);
    } else if (yy < 8.0) {
      float sk = vn(vec2(p.x * 0.9, yy * 0.18));
      c = vec3(0.56, 0.56, 0.54) * (0.8 + 0.14 * vn(p * 0.6) + 0.12 * sk) * (1.0 - 0.12 * cv(abs(mod(p.x, 6.0) - 3.0) - 0.15)) * mix(0.5, 1.0, smoothstep(2.2, 4.8, yy)) * lit(0.85) * mix(1.0, 0.8, uWet);
    } else {
      float lx = (mod(p.x - CX + 14.0, 28.0) - 14.0) / 9.0, spot = 0.7 + 0.5 * exp(-lx * lx) * smoothstep(16.0, 8.0, yy);
      vec3 rod = vec3(0.56, 0.085, 0.075) * (0.88 + 0.12 * vn(p * vec2(0.3, 1.2))) * (1.0 - 0.15 * cv(abs(mod(p.x - CX + 7.0, 14.0) - 7.0) - 0.12)) * (lit(0.9) + VARM * LYS * 0.55 * spot);
      vec3 btg = vec3(0.5, 0.5, 0.48) * (0.82 + 0.18 * vn(p * vec2(0.9, 0.25))) * lit(0.8) * mix(1.0, 0.8, uWet);
      c = mix(btg, rod, step(ax, 56.0)) * mix(0.75, 1.0, smoothstep(8.0, 9.5, yy));
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
void lykter(vec2 p, inout vec3 col){
  if (p.y < 100.0 || p.y > 150.0 || LYS < 0.3) return;
  vec2 CS = vec2(15.0, 7.0);
  vec2 q = vec2(p.x + floor(p.y / CS.y) * 6.3, p.y), id = floor(q / CS);
  float h = hs(id + 71.0);
  if (h < 0.35) return;
  vec2 d = q - (id + 0.5 + (vec2(hs(id + 3.0), hs(id + 9.0)) - 0.5) * 0.5) * CS;
  float r2 = dot(d, d);
  vec3 lc = h > 0.8 ? vec3(0.9, 0.95, 1.0) : vec3(1.0, 0.66, 0.32);
  col += lc * (LYS - 0.25) * (1.3 * exp(-r2 / 0.35) + 0.16 * exp(-r2 / 5.0)) * (1.0 - 0.3 * uHz);
}
void dis(vec2 p, inout vec3 col){
  float wet = max(uRain, uSnow), dy = (p.y - 107.0) / 8.0;
  float m = exp(-dy * dy) * (0.14 + 0.3 * wet + 0.12 * uNight) * (0.45 + 0.9 * fbm(vec2(p.x * 0.018 - T * 0.012, p.y * 0.07 + 2.0)));
  vec2 a = p - vec2(CX - HWF - 20.0, 90.0), b = p - vec2(CX + HWF + 20.0, 90.0);
  vec3 mc = FOGC + FL * FLD * 0.5 * (exp(-dot(a, a) / 1400.0) + exp(-dot(b, b) / 1400.0) + 0.6 * exp(-(p.x - CX) * (p.x - CX) / 9000.0));
  col = mix(col, mc, sat(m));
}
void spillere(vec2 p, inout vec3 col){
  if (p.y < YF - 4.0 || p.y > YN + 1.0 || abs(p.x - CX) > HWN + 3.0) return;
  vec3 Ls = lit(0.9) + FL * FLD * 0.8;
  float bx = 36.0 * sin(T * 0.07) + 8.0 * sin(T * 0.31), by = 22.0 * sin(T * 0.09 + 1.0);
  for (int i = 0; i < 13; i++) {
    float fi = float(i);
    float fxp = i == 12 ? bx : clamp(bx * 0.7 + 22.0 * sin(T * 0.19 + fi * 2.3) + 10.0 * sin(T * 0.47 + fi * 4.1), -48.0, 48.0);
    float fyp = i == 12 ? by : clamp(by * 0.6 + 16.0 * sin(T * 0.23 + fi * 1.7 + 1.0), -31.0, 31.0);
    float pvp = fyp / 74.0 + 0.5, vp = pvp / (1.6 - 0.6 * pvp);
    vec2 d = p - vec2(CX + fxp / 55.0 * mix(HWF, HWN, vp), YF + vp * (YN - YF));
    if (abs(d.x) > 2.6 || d.y > 0.8 || d.y < -3.2) continue;
    float sc = 0.85 + 0.3 * vp;
    if (i == 12) { col = mix(col, grade(vec3(0.97) * (lit(1.0) + FL * FLD), p), cv(length(d - vec2(0.0, -0.3)) - 0.32)); continue; }
    col *= 1.0 - 0.28 * (1.0 - smoothstep(0.2, 1.0, length(vec2(abs(d.x) - 0.9, d.y * 3.0)))) * step(-0.4, d.y);
    col *= 1.0 - 0.32 * (1.0 - smoothstep(0.3, 0.9, length(d * vec2(0.9, 2.6))));
    float body = rb(d, vec2(-0.42, -1.7) * sc, vec2(0.42, 0.0)) - 0.08, head = length(d - vec2(0.0, -2.05 * sc)) - 0.3 * sc;
    vec3 kit = i < 6 ? vec3(0.7, 0.1, 0.08) : vec3(0.82, 0.82, 0.84);
    vec3 pc = mix(kit, i < 6 ? vec3(0.86, 0.86, 0.84) : vec3(0.12, 0.13, 0.2), smoothstep(-0.75 * sc, -0.55 * sc, d.y));
    pc = mix(pc, vec3(0.66, 0.5, 0.4), cv(head));
    col = mix(col, grade(pc * Ls, p), cv(min(body, head)));
  }
}
void led(vec2 p, inout vec3 col){
  float yy = p.y - YN, ax = abs(p.x - CX);
  if (yy < -3.0 || yy > 2.8 || ax > HWN) return;
  float sx = p.x - T * 5.0, id = floor(sx / 26.0), f = fract(sx / 26.0) * 26.0, hh = hs(vec2(id, 4.0));
  vec3 bg = hh < 0.4 ? vec3(0.74, 0.1, 0.09) : (hh < 0.7 ? vec3(0.82, 0.83, 0.81) : (hh < 0.85 ? vec3(0.1, 0.19, 0.42) : vec3(0.82, 0.64, 0.15)));
  vec3 fg = (hh < 0.4 || (hh > 0.7 && hh < 0.85)) ? vec3(0.95) : vec3(0.1, 0.1, 0.14);
  float g = (f - 5.0) / 1.45, gi = floor(g), gf = fract(g) * 1.45;
  float on = step(0.0, g) * step(g, 11.0) * step(0.18, hs(vec2(gi, id + 2.0)));
  float tg = cv(rb(vec2(gf, yy), vec2(0.2, 0.6), vec2(1.15, 1.62))) * on;
  vec3 c = mix(bg, fg, tg * 0.85);
  c *= 0.55 + 0.45 * smoothstep(0.0, 0.5, min(f, 26.0 - f));
  c *= 0.42 + 0.33 * LYS + 0.4 * FLD;
  float kx = sat((HWN - 1.0 - ax) * uDpr + 0.5);
  if (yy < 0.0) { col += bg * (0.42 + 0.33 * LYS + 0.4 * FLD) * 0.1 * exp(yy / 1.2) * kx; return; }
  col = mix(col, grade(c, p), sat((2.2 - yy) * uDpr + 0.5) * sat(yy * uDpr + 0.5) * kx);
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
        tc = lovFarge(sat(vn(ctr * 0.05 + 4.0) * 0.8 + h3 * 0.3)); tc = mix(tc, vec3(dot(tc, vec3(0.3, 0.55, 0.15))), 0.3) * (0.6 + 0.45 * h); sh *= 0.72 + 0.5 * vn(d * 3.6 + cid * 2.0);
      }
      float cov = sat(e * uDpr * 0.6 + 0.5);
      if (cov <= 0.0) continue;
      vec3 tl = tc * sh * (lit(0.9) * mix(0.68, 1.0, smoothstep(r, -r, d.y)) + FL * FLD * 0.45 * smoothstep(-0.3, 0.9, d.x / r) * smoothstep(40.0, 112.0, ctr.x));
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
  AA = 1.0 / uDpr; T = uT; RW = sat(uDpr * 1.2 - 0.6); LYS = 0.22 + 0.78 * uNight; FLD = max(smoothstep(0.3, 0.7, uNight), uRain * 0.55);
  VARM = vec3(1.0, 0.74, 0.42);
  AMB = max(mix(uSkM, uSkB, 0.5) * mix(1.0, 0.4, uNight) * mix(1.0, 0.62, uSun), vec3(0.07, 0.08, 0.1)) + vec3(0.05, 0.035, 0.02) * uNight;
  SUNC = vec3(1.0, 0.93, 0.8) * 0.8; SSC = vec3(1.0, 0.6, 0.34) * 0.85;
  FOGC = mix(uSkB, uSkM, 0.3) + vec3(0.1, 0.06, 0.02) * uNight * 0.5;
  CLDC = mix(uSkB, uSkM, 0.55) * 1.02 + vec3(0.12, 0.07, 0.02) * uNight * 0.55;
  if (uPass > 0.5) {
    vec2 uv = FlutterFragCoord().xy / (uRes * uDpr);
    vec3 sc = texture(uScene, uv).rgb;
    float iB = (1.0 - smoothstep(86.0, 112.0, abs(p.x - CX))) * smoothstep(70.0, 80.0, p.y);
    float bl = 0.6 * smoothstep(118.0, 92.0, p.y) * (1.0 - iB);
    if (bl > 0.02) {
      vec2 o = vec2(bl) / uRes;
      sc = (sc * 2.0 + texture(uScene, uv + vec2(o.x, 0.0)).rgb + texture(uScene, uv - vec2(o.x, 0.0)).rgb + texture(uScene, uv + vec2(0.0, o.y)).rgb + texture(uScene, uv - vec2(0.0, o.y)).rgb) / 6.0;
    }
    vec4 ov = vec4(0.0); vec3 gw = vec3(0.0);
    kabiner(p, ov, gw);
    float cf = uCY > -5.0 ? mix(0.12, 1.0, smoothstep(uCY - 12.0, uCY + 10.0, p.y)) : 1.0;
    if (ov.a > 0.001) sc = mix(sc, grade(ov.rgb / ov.a, p), ov.a * cf);
    sc += gw * 0.7 * cf;
    float bk = step(0.55, fract(T * 0.7));
    for (int k = 0; k < 2; k++) { vec2 dd = p - vec2(244.0, k == 0 ? -2.0 : 9.0); float r2 = dot(dd, dd); sc += vec3(1.0, 0.12, 0.08) * bk * (1.2 * exp(-r2 / 0.6) + 0.15 * exp(-r2 / 8.0)) * (0.35 + 0.65 * LYS); }
    spillere(p, sc);
    led(p, sc);
    if (uRain > 0.0) { float r = regn(p, 3.0, 380.0, 9.0, 1.0) * 0.25 + regn(p, 5.0, 560.0, 16.0, 7.0) * 0.4 + regn(p, 8.0, 760.0, 26.0, 13.0) * 0.5;
      sc += (vec3(0.75, 0.8, 0.85) * (0.06 + 0.2 * (1.0 - uNight)) + sc * 0.5) * r * uRain; }
    if (uSnow > 0.0) { float sn = sno(p, 9.0, 14.0, 1.0) * 0.55 + sno(p, 16.0, 24.0, 5.0) * 0.85 + sno(p, 28.0, 40.0, 9.0);
      sc = mix(sc, vec3(0.93, 0.95, 1.0) * (0.6 + 0.35 * (1.0 - uNight)), sat(sn) * uSnow); }
    sc += (hs(floor(p * uDpr) + fract(T * 7.0) * 91.0) - 0.5) * 0.012;
    fragColor = vec4(sc, 1.0);
    return;
  }
  vec3 glow = vec3(0.0), col = vec3(0.0);
  bool skjult = (p.y > 113.0 && abs(p.x - CX) < 64.0) || (p.y > 184.5 && p.x > 104.0 && p.x < 296.0);
  if (!skjult) {
    col = p.y < ridge(p.x) ? himmel(p) : fjell(p);
    toppen(p, col, glow);
    tau(p, col);
    col = skyer(p, col);
    sykehus(p, col);
    husrad(p, col);
    lykter(p, col);
    dis(p, col);
  }
  col = stadion(p, col, glow);
  venstre(p, col);
  hoyre(p, col);
  col = mix(col, FOGC, 0.02 + 0.03 * uHz);
  col += glow;
  fragColor = vec4(grade(col, p), 1.0);
}
