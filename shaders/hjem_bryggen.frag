// Hjem · Bryggen — the Launch prototype's own WebGL scene (`brGlInit / brGlTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: Bryggen seen from Nordnes: the sixteen wharf houses, the town and Fløyen behind, the quay lamps, mist, rain and the lit windows.
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
uniform float uOff;
uniform float uNight;
uniform float uSun;
uniform float uSunset;
uniform float uRain;
uniform float uSnow;
uniform float uWet;
uniform float uVeil;
uniform float uCB;
uniform float uVis;
uniform vec3 uSkT;
uniform vec3 uSkM;
uniform vec3 uSkB;
const vec4 uH[16] = vec4[16](vec4(40.17857, 55.17857, 104.542854, 92.540352), vec4(55.17857, 72.321426, 103.471428, 88.625282), vec4(72.321426, 88.39286, 105.614288, 93.240372), vec4(88.39286, 106.60714, 102.400002, 85.970276), vec4(106.60714, 125.89286, 103.471428, 87.423019), vec4(125.89286, 140.892853, 104.542854, 92.540352), vec4(140.892853, 158.035721, 103.471428, 88.625282), vec4(158.035721, 181.607147, 102.400002, 84.251595), vec4(181.607147, 205.178574, 101.328575, 81.713852), vec4(205.178574, 224.464279, 103.471428, 86.769508), vec4(224.464279, 241.607147, 104.542854, 90.825706), vec4(241.607147, 269.464294, 101.328575, 80.678612), vec4(269.464294, 286.607147, 103.471428, 88.625282), vec4(286.607147, 303.75, 104.542854, 90.277603), vec4(303.75, 321.964294, 103.471428, 88.89695), vec4(321.964294, 349.821442, 102.400002, 82.507942));
const vec4 uHC[16] = vec4[16](vec4(0.92549, 0.905882, 0.858824, 0), vec4(0.611765, 0.203922, 0.14902, 1), vec4(0.901961, 0.827451, 0.639216, 0), vec4(0.937255, 0.921569, 0.886275, 2), vec4(0.541176, 0.180392, 0.133333, 5), vec4(0.847059, 0.647059, 0.282353, 0), vec4(0.933333, 0.913725, 0.870588, 1), vec4(0.65098, 0.227451, 0.172549, 20), vec4(0.909804, 0.796078, 0.494118, 9), vec4(0.721569, 0.290196, 0.25098, 6), vec4(0.85098, 0.52549, 0.203922, 1), vec4(0.839216, 0.478431, 0.164706, 23), vec4(0.929412, 0.913725, 0.87451, 0), vec4(0.866667, 0.694118, 0.352941, 5), vec4(0.6, 0.196078, 0.141176, 2), vec4(0.431373, 0.172549, 0.12549, 5));
const vec2 uFB0 = vec2(292.894737, 81.719406);
const vec2 uFB1 = vec2(329.042553, 47.382214);
const vec2 uFB2 = vec2(366.428571, 19.299132);
float AA, T, LYS;
vec3 AMB, SUNC, SSC, FOGC, CLDC, VARM;
const float F = 900.0, CX = 195.0, HY = 109.9, EYE = 8.0, ZB = 420.0, PXM = 2.142857, QY = 123.2;
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
vec4 over(vec4 acc, vec3 c, float a){ return vec4(acc.rgb + (1.0 - acc.a) * a * c, acc.a + (1.0 - acc.a) * a); }
float altF(float d, float X){ return 8.0 + 0.06 * d + 0.00028 * d * d + (16.0 * sin(X * 0.0042 + 0.9) + 7.0 * sin(X * 0.013 + 2.1)) * smoothstep(60.0, 420.0, d); }
float skyF(float X){ float b = 272.0 + 40.0 * sin(X * 0.0021 + 1.4) + 18.0 * vn(vec2(X * 0.008, 3.0)); float cl = floor(X / 3.4), h = hs(vec2(cl, 9.0)); return b + (3.0 + 8.0 * h) * (1.0 - abs(fract(X / 3.4) * 2.0 - 1.0)) * step(0.22, h); }
float tyF(float d, float sx){ float Z = ZB + d; return HY - F * (altF(d, (sx - CX) * Z / F) - EYE) / Z; }
float terrD(vec2 s){ float lo = 20.0, hi = 1500.0; for (int i = 0; i < 14; i++) { float m = 0.5 * (lo + hi); if (tyF(m, s.x) > s.y) lo = m; else hi = m; } return 0.5 * (lo + hi); }
float skyg(float X, float a){ return 1.0 - 0.6 * smoothstep(0.5, 0.74, fbm(vec2(X * 0.0042 - T * 0.018, a * 0.005 + 1.3))); }
vec3 luft(vec3 c, float Z, float a, float X){
  c = mix(c, FOGC, 1.0 - exp(-max(Z - 360.0, 0.0) / uVis));
  float wet = max(uRain, uSnow);
  float b1 = exp(-pow((a - 95.0) / 18.0, 2.0)) * smoothstep(0.45, 0.8, fbm(vec2(X * 0.0045 - T * 0.02, a * 0.04 + 1.7)));
  float b2 = exp(-pow((a - 170.0) / 26.0, 2.0)) * smoothstep(0.4, 0.78, fbm(vec2(X * 0.0032 + T * 0.014, a * 0.03 + 5.1)));
  float cb = uCB + (fbm(vec2(X * 0.0035 + T * 0.008, 2.0)) - 0.5) * 70.0;
  float cd = smoothstep(cb - 25.0, cb + 50.0, a) * (0.78 + 0.22 * fbm(vec2(X * 0.006 + T * 0.01, a * 0.02)));
  return mix(c, CLDC, sat(max((b1 * 0.62 + b2 * 0.7) * (0.35 + 0.65 * wet), cd)));
}
vec3 himmel(vec2 s){
  vec3 c = mix(uSkT, uSkB, sat((s.y + 200.0) / 300.0));
  return mix(c, CLDC, smoothstep(0.45, 0.8, fbm(vec2(s.x * 0.007 + T * 0.005, s.y * 0.018 + 3.0))) * 0.6);
}
vec4 hageTre(vec2 q, float r, float k2, float id, float aB, float X, float Z){
  float an = atan(q.y, q.x);
  float e = r * (0.76 + 0.2 * vn(vec2(an * 2.8 + id * 9.0, id)) + 0.1 * vn(vec2(an * 8.0, id + 3.0)) + 0.06 * vn(q * 2.6 + id)) - length(q * vec2(1.0, 1.1));
  float ta = sat(e * k2 * uDpr * 0.6 + 0.5);
  if (ta < 0.01) return vec4(0.0);
  float k = fract(id * 7.13 + 0.37);
  vec3 tc = k < 0.32 ? vec3(0.16, 0.25, 0.1) : (k < 0.52 ? vec3(0.34, 0.38, 0.13) : (k < 0.72 ? vec3(0.6, 0.47, 0.13) : (k < 0.88 ? vec3(0.58, 0.29, 0.09) : vec3(0.07, 0.14, 0.08))));
  float lf = vn(q * 3.3 + id * 5.0) * 0.55 + vn(q * 7.0 + id) * 0.45;
  float dm = sqrt(max(e, 0.0) * (2.0 * r - max(e, 0.0))); vec3 nn = normalize(vec3(q.x, q.y * 1.1, max(dm, 0.2)));
  float sh = (0.46 + 0.6 * max(dot(nn, normalize(vec3(-0.5, 0.6, 0.62))), 0.0)) * (0.55 + 0.8 * lf) * (0.82 + 0.18 * smoothstep(0.0, 0.6, e));
  vec3 c = tc * sh * (AMB * 0.92 + SUNC * uSun * skyg(X, aB) * (0.3 + 0.7 * sh) + SSC * uSunset * 0.6);
  c = mix(c, vec3(0.86, 0.89, 0.93) * (AMB + 0.1) * (0.7 + 0.3 * sh), uSnow * smoothstep(0.5, 0.85, sh) * 0.8);
  return vec4(luft(c, Z, aB + 3.0, X), ta);
}
vec4 rader(vec2 s, float dp){
  vec4 acc = vec4(0.0);
  float rp = floor((dp - 40.0) / 22.0);
  for (int k = 0; k < 7; k++) {
    float r = rp - 6.0 + float(k);
    if (r < 0.0 || acc.a > 0.985) continue;
    float dr = 40.0 + (r + 0.5) * 22.0, Z = ZB + dr, kk = F / Z, X = (s.x - CX) / kk;
    float CW = 11.0 + 4.5 * hs(vec2(r, 19.0)), sh = hs(vec2(r, 7.0)), ci = floor(X / CW + sh);
    float h1 = hs(vec2(ci, r)), h2 = hs(vec2(ci, r + 31.0)), h3 = hs(vec2(ci + 17.0, r)), h4 = hs(vec2(ci - 5.0, r + 9.0)), h5 = hs(vec2(ci + 3.0, r - 11.0));
    float bw = CW * (0.44 + 0.5 * h2), Xc = (ci + 0.5 - sh) * CW + (h3 - 0.5) * (CW - bw);
    dr += (h5 - 0.5) * 9.0; Z = ZB + dr; float k2 = F / Z;
    float aB = altF(dr, Xc);
    if (aB > 96.0) continue;
    float dens = 0.76 * (1.0 - smoothstep(42.0, 60.0, aB + (vn(vec2(Xc * 0.02, 4.0)) - 0.5) * 18.0)) + 0.08 * (1.0 - smoothstep(60.0, 92.0, aB));
    float yB = HY - k2 * (aB - EYE), bm = (yB - s.y) / k2;
    if (h1 > dens) {
      if (h1 > dens + (1.0 - dens) * 0.72 || aB > 66.0) continue;
      float rt = 1.6 + 1.7 * h2, con = step(0.62 - smoothstep(90.0, 170.0, aB) * 0.45, fract(h4 * 5.3)), tx = X - ((ci + 0.5 - sh) * CW + (h3 - 0.5) * CW * 0.5);
      if (con > 0.5) {
        float th = rt * 3.4, wc0 = rt * 0.95 * sat(1.0 - bm / th);
        float e = min(wc0 * (0.82 + 0.3 * vn(vec2(bm * 2.2, ci + r))) - abs(tx), th - bm);
        float ta = sat(e * k2 * uDpr * 0.6 + 0.5) * step(-1.0, bm);
        if (ta < 0.01) continue;
        float nd = vn(vec2(tx * 5.0, bm * 2.2) + ci * 3.0);
        vec3 tc = vec3(0.06, 0.13, 0.09) * (0.6 + 0.6 * nd) * (0.7 + 0.45 * smoothstep(0.3, -0.3, tx / max(wc0, 0.3))) * (AMB * 0.92 + SUNC * uSun * skyg(X, aB) * 0.6);
        tc = mix(tc, vec3(0.86, 0.89, 0.93) * (AMB + 0.1), uSnow * smoothstep(0.5, 0.8, nd) * 0.75);
        acc = over(acc, luft(tc, Z, aB + max(bm, 0.0), X), ta);
      } else {
        vec4 tg = hageTre(vec2(tx, bm - rt * 1.15), rt, k2, ci * 3.1 + r * 1.7, aB, X, Z);
        acc = over(acc, tg.rgb, tg.a);
      }
      continue;
    }
    float xm = X - Xc, hb = bw * 0.5, ax = abs(xm);
    float big = step(aB, 40.0) * step(0.84, h4);
    float fl = 2.0 + floor(fract(h4 * 3.7) * 2.6) + big * 2.0, hw = 0.8 + fl * 2.8, rt = fract(h4 * 7.31);
    kk = k2;
    float top = (big > 0.5 || rt > 0.9) ? hw + 0.45 : (rt < 0.45 ? hw + (hb + 0.3 - ax) * 0.95 : hw + min(3.1, (hb + 0.35 - ax) * 1.6));
    float e = max(min(hb - ax, hw - bm), min(min(top - bm, hb + 0.35 - ax), bm - hw + 0.02)), eo = e;
    float chx = (fract(h4 * 41.0) - 0.5) * hb * 1.1, chE = -1e3;
    if (big < 0.5 && fract(h4 * 43.0) > 0.5 && bm > hw) chE = min(0.26 - abs(xm - chx), top + 0.7 - bm);
    e = max(e, chE);
    float a = sat(e * kk * uDpr * 0.6 + 0.5) * step(-2.0, bm);
    float h6 = hs(vec2(ci - 9.0, r + 23.0)), h7 = hs(vec2(ci + 29.0, r - 3.0));
    if (h6 < 0.42 + 0.3 * smoothstep(30.0, 70.0, aB)) {
      float tr = 1.2 + 1.0 * h7, txo = (h7 < 0.5 ? -1.0 : 1.0) * hb * (0.4 + 0.7 * fract(h7 * 5.7));
      vec4 tg = hageTre(vec2(xm - txo, bm - tr * 0.85), tr, k2, ci * 1.7 + r * 3.3 + 0.5, aB, X, Z);
      acc = over(acc, tg.rgb, tg.a);
      if (acc.a > 0.985) continue;
    }
    float shA = 0.32 * (1.0 - smoothstep(0.0, 1.6, -bm)) * step(bm, 0.05) * step(ax, hb + 0.5)
      + 0.3 * uSun * smoothstep(hb - 0.3, hb + 0.1, xm) * (1.0 - smoothstep(hb + 1.8, hb + 2.6, xm)) * step(-1.2, bm) * (1.0 - smoothstep(-0.3, 0.3, bm - hw * 0.85 + (xm - hb) * 0.5));
    acc = over(acc, vec3(0.0), sat(shA) * (1.0 - a));
    if (a < 0.01) continue;
    float pal = hs(vec2(ci, r + 3.0));
    vec3 wc = pal < 0.34 ? vec3(0.8, 0.79, 0.76) : (pal < 0.46 ? vec3(0.88, 0.85, 0.76) : (pal < 0.55 ? vec3(0.76, 0.77, 0.76) : (pal < 0.63 ? vec3(0.87, 0.79, 0.58) : (pal < 0.72 ? vec3(0.66, 0.72, 0.74) : (pal < 0.82 ? vec3(0.55, 0.22, 0.16) : (pal < 0.9 ? vec3(0.8, 0.67, 0.42) : vec3(0.82, 0.8, 0.75)))))));
    if (dr < 80.0) wc = pal < 0.4 ? vec3(0.55, 0.2, 0.15) : (pal < 0.65 ? vec3(0.85, 0.66, 0.36) : (pal < 0.85 ? vec3(0.86, 0.84, 0.78) : vec3(0.75, 0.45, 0.22)));
    wc *= 0.84 + 0.22 * hs(vec2(ci, r + 51.0)); wc = mix(wc, wc * vec3(1.03, 0.98, 0.9), hs(vec2(ci, r + 61.0)) * 0.7);
    float rk = fract(pal * 13.7);
    vec3 rc = rk < 0.26 ? vec3(0.14, 0.15, 0.17) : (rk < 0.8 ? mix(vec3(0.5, 0.19, 0.12), vec3(0.62, 0.27, 0.16), fract(rk * 9.0)) : vec3(0.32, 0.3, 0.28));
    rc = mix(rc, vec3(0.86, 0.88, 0.92), uSnow * 0.85);
    vec3 col;
    float orient = 0.62 + 0.5 * hs(vec2(ci, r + 77.0)), clS = skyg(X, aB);
    float swd = clamp(abs(Xc) / Z * 10.0, 0.0, bw * 0.32), sdir = Xc < 0.0 ? 1.0 : -1.0;
    float sideF = smoothstep(-0.08, 0.08, xm * sdir - (hb - swd));
    float sunK = mix(orient, sdir < 0.0 ? 1.25 : 0.42, sideF);
    vec3 Lw = AMB * (0.78 + 0.2 * sunK) + SUNC * uSun * 0.95 * sunK * clS + SSC * uSunset * smoothstep(60.0, 220.0, aB) * 0.8 * sunK;
    if (chE > eo) {
      col = mix(vec3(0.42, 0.2, 0.14), vec3(0.3, 0.29, 0.28), step(0.5, fract(h4 * 47.0))) * (0.75 + 0.35 * step(xm, chx)) * (AMB + SUNC * uSun * clS * 0.7);
      col = mix(col, vec3(0.86, 0.89, 0.93) * (AMB + 0.1), uSnow * step(top + 0.55, bm) * 0.9);
    } else if (bm > hw) {
      float sl = rt < 0.45 ? (xm < 0.0 ? 1.15 : 0.6) : (rt < 0.9 ? mix(1.1, 0.6, smoothstep(-hb * 0.4, hb * 0.4, xm)) : 0.9);
      float tl = 0.86 + 0.24 * vn(vec2(X * 1.6, bm * 1.6) + ci);
      col = rc * tl * (AMB * (0.85 + 0.3 * sl) + SUNC * uSun * 0.75 * sl * clS + SSC * uSunset * 0.6 * sl) * (0.72 + 0.36 * sat((bm - hw) / max(top - hw, 0.5)));
      col *= 1.0 - 0.3 * cv((bm - hw - 0.12) * kk) * (1.0 - uSnow);
      if (rt < 0.9 && big < 0.5 && fract(h4 * 17.3) > 0.5 && top - hw > 1.6) {
        float dx0 = (fract(h4 * 29.0) - 0.5) * hb * 0.5;
        float dbx = max(abs(xm - dx0) - 0.85, max(hw - bm, bm - hw - 1.25));
        float drf = max(abs(xm - dx0) - 1.05 + (bm - hw - 1.25) * 1.1, max(hw + 1.2 - bm, bm - hw - 1.75));
        if (drf < 0.0) col = rc * 0.9 * (AMB * 1.1 + SUNC * uSun * 0.8 * clS);
        else if (dbx < 0.0) {
          float dw = max(abs(xm - dx0) - 0.42, abs(bm - hw - 0.62) - 0.42), dOn = step(1.0 - 0.6 * uNight, fract(h4 * 61.0));
          col = mix(wc * Lw * 0.92, vec3(0.06, 0.07, 0.09) * (AMB + 0.25), cv(dw * kk) * 0.8) + VARM * LYS * 1.2 * dOn * cv(dw * kk);
        }
      }
    } else {
      float wsc = 0.85 + 0.3 * fract(h4 * 13.1);
      float n = max(1.0, floor((bw - 1.4) / (2.3 * wsc))), sp = (bw - 1.4) / n;
      float j = floor((xm + hb - 0.7) / sp), lx = xm + hb - 0.7 - (j + 0.5) * sp;
      float fy = (bm - 0.9) / 2.8, fiw = floor(fy), ly = (fy - fiw) * 2.8 - 1.35;
      float hh = hs(vec2(ci * 7.0 + j, r * 5.0 + fiw));
      float inW = step(0.0, j) * step(j, n - 1.0) * step(0.0, fiw) * step(fiw, fl - 1.0) * (1.0 - sideF) * step(0.08, fract(hh * 3.3));
      float wd = max(abs(lx) - 0.4 * wsc, abs(ly) - 0.62), wg = cv(wd * kk) * inW;
      float on = step(1.0 - 0.34 * uNight, hh) * step(0.1, hs(vec2(hh * 91.0, floor(T / 23.0 + hh * 7.0))));
      vec3 Ew = mix(VARM, vec3(0.8, 0.88, 1.0), step(0.86, fract(hh * 17.0))) * (0.75 + 0.5 * fract(hh * 37.0)) * LYS * 1.3;
      col = wc * (1.0 - 0.1 * vn(vec2(X * 0.8, bm * 0.6))) * Lw * (0.78 + 0.22 * smoothstep(0.0, 1.2, bm)) * (1.0 - (0.22 + 0.3 * uSun * clS) * smoothstep(hw - 0.9, hw, bm)) * (0.8 + 0.2 * smoothstep(0.0, 0.9, hb - ax)) * (0.78 + 0.32 * vn(vec2(X * 1.1, bm * 0.4) + ci)) * (0.86 + 0.18 * hs(vec2(ci, r + 91.0)));
      float sok = 1.0 - smoothstep(0.55, 0.85, bm), flD = (0.5 - abs(fract(fy) - 0.5)) * 2.8;
      col = mix(col, col * vec3(0.62, 0.62, 0.64), sok * 0.6);
      col *= 1.0 - 0.08 * cv((flD - 0.07) * kk) * step(1.0, fy) * step(fy, fl);
      col = mix(col, vec3(0.9, 0.9, 0.88) * Lw, cv((wd - 0.1) * kk) * inW * (1.0 - wg) * 0.35);
      float rf = fract(hh * 53.0);
      vec3 gls = mix(vec3(0.05, 0.06, 0.08), mix(uSkT, uSkB, 0.6) * 0.8, rf * rf * (1.0 - uNight) * (0.35 + 0.65 * uSun)) * (1.0 - 0.3 * smoothstep(-0.3, 0.6, ly));
      col = mix(col, gls * (AMB + 0.25), wg * mix(0.85, 0.45, smoothstep(90.0, 260.0, dr)));
      col += Ew * on * inW * (wg + 0.22 * exp(-max(wd, 0.0) * kk * 1.1) * (1.0 - wg));
    }
    acc = over(acc, luft(col, Z, aB + max(bm, 0.0), X), a);
  }
  return acc;
}
vec3 terreng(vec2 s, float dp, float Z, float X, float a){
  float kk = F / Z;
  vec3 Lt = AMB * 0.9 + SSC * uSunset * smoothstep(60.0, 220.0, a) * 0.85; float clS = skyg(X, a);
  float town = 1.0 - smoothstep(56.0, 82.0, a);
  vec2 P = vec2(X, a), CS = vec2(4.2, 3.5), gi = floor(P / CS);
  float sprB = smoothstep(0.46, 0.62, vn(P * vec2(0.022, 0.03) + 2.0) * 0.62 + vn(P * 0.07 + 5.0) * 0.2 + 0.07 + (a - 200.0) / 210.0);
  vec3 base = mix(mix(vec3(0.16, 0.2, 0.09), vec3(0.4, 0.26, 0.09), vn(P * vec2(0.03, 0.045) + 9.0)), vec3(0.05, 0.1, 0.06), sprB);
  base = mix(base, vec3(0.22, 0.21, 0.2), town * 0.6 * smoothstep(0.45, 0.7, vn(P * vec2(0.12, 0.3) + 4.0)));
  vec3 c = base * (0.3 + 0.22 * vn(P * 0.7)) * (Lt + SUNC * uSun * clS * 0.35);
  float wy = a / 4.6 + vn(vec2(X * 0.05, 1.0)) * 0.6, wD = (0.5 - abs(fract(wy) - 0.5)) * 4.6;
  c = mix(c, vec3(0.44, 0.43, 0.4) * (Lt + SUNC * uSun * clS * 0.6), town * cv((wD - 0.16) * kk) * step(0.55, vn(vec2(X * 0.06, floor(wy)))) * 0.55);
  float bK = -1e3, bA = 0.0; vec3 bC = vec3(0.0);
  for (int jj = 0; jj < 4; jj++) {
    for (int ii = 0; ii < 3; ii++) {
      vec2 cid = gi + vec2(float(ii) - 1.0, 1.0 - float(jj));
      float h = hs(cid), h2 = hs(cid + 7.3), h3 = hs(cid + 13.1);
      vec2 ctr = (cid + 0.5 + (vec2(h2, h3) - 0.5) * 0.7) * CS, d = P - ctr;
      float spr = smoothstep(0.46, 0.62, vn(ctr * vec2(0.022, 0.03) + 2.0) * 0.62 + vn(ctr * 0.07 + 5.0) * 0.2 + h * 0.14 + 0.1 + (ctr.y - 200.0) / 210.0);
      float e, sh, rr; vec3 tc;
      if (h < spr) {
        float ht = 6.5 + 3.0 * h2, wb = 1.6 + 0.6 * h3, u = sat((d.y + 3.0) / ht);
        float jag = 0.35 * (0.5 + 0.5 * sin(d.y * 4.2 + h * 20.0));
        e = min(min(wb * (1.0 - u) * (0.85 + jag) - abs(d.x), d.y + 3.5), ht - 3.0 - d.y);
        sh = (0.6 + 0.4 * smoothstep(0.6, -0.6, d.x / max(wb * (1.0 - u), 0.3))) * (0.7 + 0.45 * vn(d * vec2(5.0, 2.4) + cid * 3.0));
        tc = mix(vec3(0.045, 0.11, 0.065), vec3(0.085, 0.16, 0.085), h3); rr = wb * 1.4;
      } else {
        float r = (1.5 + 1.7 * h2 * h2 + 0.2 * h3) * (1.0 - 0.2 * town), an = atan(d.y, d.x);
        e = r * (0.82 + 0.1 * vn(vec2(an * 2.5 + h * 9.0, h)) + 0.08 * vn(vec2(an * 6.0, h + 3.0))) - length(d * vec2(1.0, 1.12));
        float lf = vn(d * 3.1 + cid * 7.0) * 0.55 + vn(d * 6.8 + cid) * 0.45;
        float dm = sqrt(max(e, 0.0) * (2.0 * r - max(e, 0.0))); vec3 nn = normalize(vec3(d.x, d.y * 1.12, max(dm, 0.2)));
        sh = (0.48 + 0.58 * max(dot(nn, normalize(vec3(-0.5 + (h3 - 0.5) * 0.7, 0.6 + (h2 - 0.5) * 0.3, 0.62))), 0.0)) * (0.55 + 0.8 * lf); rr = r;
        float k = sat(vn(ctr * vec2(0.03, 0.045) + 9.0) * 0.75 + h3 * 0.35 - 0.05);
        tc = k < 0.24 ? vec3(0.22, 0.33, 0.13) : (k < 0.42 ? vec3(0.44, 0.47, 0.16) : (k < 0.62 ? vec3(0.72, 0.55, 0.15) : (k < 0.82 ? vec3(0.7, 0.36, 0.1) : vec3(0.5, 0.2, 0.08))));
        tc *= 0.6 + 0.6 * h;
        tc = mix(tc, vec3(dot(tc, vec3(0.3, 0.55, 0.15))), 0.26) * 0.88;
      }
      sh *= 0.78 + 0.22 * smoothstep(0.0, 0.6, e);
      float cov = sat(e * kk * uDpr * 0.55 + 0.5);
      if (cov <= 0.0) continue;
      vec3 tl = tc * sh * (Lt + SUNC * uSun * clS * (0.35 + 0.7 * sh));
      tl = mix(tl, vec3(0.86, 0.89, 0.93) * (Lt + SUNC * uSun * 0.6) * (0.75 + 0.3 * sh), uSnow * smoothstep(0.55, 0.85, sh + 0.15 * vn(P * 2.0)));
      float key = (e > 0.0 ? sqrt(max(e * (2.0 * rr - e), 0.0)) : e * 2.0) - ctr.y * 0.22 + (h < spr ? 0.8 : 0.0);
      if (key > bK) { bK = key; bC = tl; bA = cov; }
    }
  }
  c = mix(c, bC, bA);
  float gu = fbm(vec2(X * 0.011 + 3.0, a * 0.018));
  c *= (0.62 + 0.62 * gu) * (0.75 + 0.45 * fbm(vec2(X * 0.0045 + 7.0, a * 0.009)));
  float ra = 146.0 + 7.0 * sin(X * 0.009 + 0.5);
  c = mix(c, vec3(0.2, 0.2, 0.21) * (AMB + 0.1), cv((abs(a - ra) - 1.3) * kk) * 0.85);
  float li = floor(X / 24.0), ld = length(vec2((X - (li + 0.5) * 24.0) * kk, (a - ra - 2.0) * kk));
  c += VARM * LYS * (1.6 * exp(-ld * ld / 0.8) + 0.25 * exp(-ld * ld / 12.0)) * step(0.2, hs(vec2(li, 5.0))) * step(a, ra + 8.0);
  return luft(c, Z, a, X);
}
float segD(vec2 p, vec2 a, vec2 b, out float t){ vec2 ab = b - a; t = sat(dot(p - a, ab) / dot(ab, ab)); return length(p - a - ab * t); }
vec3 floibanen(vec2 s, float ap, float Zp, vec3 c){
  if (ap < 70.0) return c;
  float t1, t2, d1 = segD(s, uFB0, uFB1, t1), d2 = segD(s, uFB1, uFB2, t2);
  float L1 = length(uFB1 - uFB0), L2 = length(uFB2 - uFB1), dd = min(d1, d2), al = d1 < d2 ? t1 * L1 : L1 + t2 * L2, sc = F / Zp;
  float fo = smoothstep(105.0, 150.0, ap);
  c = mix(c, vec3(0.4, 0.4, 0.35) * (AMB + 0.1), cv(dd - 3.0 * sc) * fo * 0.45);
  c = mix(c, vec3(0.05), cv(dd - 0.3) * 0.75);
  float u = 0.5 - 0.5 * cos(T * 0.1), hl = 0.0115 * (L1 + L2);
  for (int i = 0; i < 2; i++) {
    float ui = i == 0 ? u : 1.0 - u, ca = ui * (L1 + L2);
    float cm = cv(max(abs(al - ca) - hl, dd - 1.5 * sc));
    vec3 cc = (i == 0 ? vec3(0.16, 0.36, 0.62) : vec3(0.68, 0.14, 0.1)) * (AMB * 1.1 + SUNC * uSun * 0.6);
    cc = mix(cc, VARM * 1.4 * LYS + AMB * 0.2, step(dd, 0.55 * sc) * step(abs(al - ca), hl * 0.8) * 0.7);
    c = mix(c, cc, cm);
  }
  float rs = cv(rb(s, uFB2 + vec2(-4.0, -3.2), uFB2 + vec2(4.0, 0.2)));
  c = mix(c, vec3(0.86, 0.84, 0.8) * (AMB + 0.1) + VARM * LYS * step(0.5, fract(s.x * 0.6)) * step(abs(s.y - uFB2.y + 1.4), 0.6), rs * (1.0 - smoothstep(0.6, 1.0, max(uRain, uSnow) * 0.7)));
  return c;
}
vec4 kirke(vec2 s){
  if (s.x < 88.0 || s.x > 118.0 || s.y < 40.0 || s.y > 92.0) return vec4(0.0);
  float a = 0.0; vec3 c = vec3(0.0);
  for (int i = 0; i < 2; i++) {
    float x0 = i == 0 ? 90.4 : 105.7, x1 = x0 + 9.3, cx = (x0 + x1) * 0.5;
    float body = rb(s, vec2(x0, 60.7), vec2(x1, 95.0));
    float sp = max(abs(s.x - cx) - 4.9 * sat((s.y - 42.0) / 18.7), max(42.0 - s.y, s.y - 61.0));
    float ab = cv(body), as = cv(sp);
    vec3 st = vec3(0.72, 0.69, 0.63) * (0.82 + 0.25 * vn(s * vec2(0.9, 1.6) + float(i) * 5.0)) * mix(1.0, 0.72, smoothstep(cx - 1.0, x1, s.x));
    float lv = cv(rb(s, vec2(cx - 1.3, 63.0), vec2(cx + 1.3, 67.5))) + cv(rb(s, vec2(cx - 1.1, 72.0), vec2(cx + 1.1, 75.0)));
    st = mix(st, vec3(0.05), sat(lv));
    vec3 sc = vec3(0.17, 0.2, 0.21) * mix(1.0, 0.7, smoothstep(cx, x1, s.x));
    vec3 cc = ab > 0.0 ? st : sc;
    float aa = max(ab, as);
    c = mix(c, cc, aa); a = max(a, aa);
  }
  float nave = max(abs(s.x - 102.5) - 6.0, 72.0 - s.y);
  if (cv(nave) > a) { c = mix(c, vec3(0.2, 0.17, 0.16), cv(nave)); a = max(a, cv(nave)); }
  c *= AMB * 0.95 + SUNC * uSun * 0.8 + SSC * uSunset * 0.9;
  c += VARM * 0.22 * uNight * smoothstep(60.0, 95.0, s.y);
  return vec4(luft(c, 530.0, 40.0, -56.0), a);
}
vec4 bryggen(vec2 s){
  for (int i = 0; i < 16; i++) {
    vec4 H = uH[i];
    if (s.x < H.x - 2.0 || s.x > H.y + 2.0) continue;
    float fi = float(i), hy = QY - s.y;
    float x = s.x - hy * (hs(vec2(fi, 4.0)) - 0.5) * 0.024;
    float cx = (H.x + H.y) * 0.5, hwp = (H.y - H.x) * 0.5, k = (H.z - H.w) / hwp;
    float dx = abs(x - cx), dv = (s.y - (H.w + dx * k)) / sqrt(1.0 + k * k), side = hwp - dx;
    float wA = sat(min(side, dv) * uDpr * 0.65 + 0.5);
    float vA = s.y < H.z + 0.8 ? sat((dv + 0.7) * uDpr + 0.5) * sat((hwp + 0.9 - dx) * uDpr + 0.5) * (1.0 - wA) : 0.0;
    if (wA + vA < 0.01) continue;
    vec4 C = uHC[i]; float gab = mod(C.a, 4.0), sg = mod(floor(C.a / 4.0), 4.0), ar = floor(C.a / 16.0);
    float wm = (H.y - H.x) / PXM, m = hy / PXM, xm = (x - H.x) / PXM, em = (QY - H.z) / PXM, rm = (QY - H.w) / PXM, gh = rm - em;
    float lb = dot(C.rgb, vec3(0.3, 0.55, 0.15)), wh = step(0.8, lb);
    vec3 trim = wh > 0.5 ? vec3(0.8, 0.78, 0.73) : vec3(0.93, 0.91, 0.86);
    float tex = 1.0 - 0.07 * vn(vec2(xm * 4.0 + fi * 9.0, m * 0.35)) - 0.12 * smoothstep(0.5, 0.85, fbm(vec2(xm * 1.4 + fi * 3.1, m * 0.09))) - 0.05 * vn(vec2(xm * 9.0, fi));
    vec3 hv = C.rgb * (0.92 + 0.12 * hs(vec2(fi, 21.0)));
    hv = mix(hv, hv * vec3(0.9, 0.88, 0.86) + 0.02, smoothstep(0.4, 0.9, fbm(vec2(xm * 0.6, m * 0.18) + fi)) * 0.45);
    vec3 c = hv * tex * (1.0 - 0.18 * uWet * (1.0 - wh * 0.5)) * (1.0 + (hs(vec2(fi, 33.0)) - 0.5) * 0.2 * (xm / wm - 0.5));
    c = mix(c, trim, cv((min(xm, wm - xm) - 0.28) * PXM) * 0.85);
    vec3 E = vec3(0.0);
    vec3 glassD = mix(mix(uSkT, uSkB, 0.4) * 0.55, vec3(0.05, 0.06, 0.07), 0.5 + 0.4 * uNight);
    if (m < 3.45) {
      float np = max(2.0, floor(wm / 2.4)), sp = (wm - 0.6) / np, j = floor((xm - 0.3) / sp), lx = xm - 0.3 - (j + 0.5) * sp;
      float g = cv(max(abs(lx) - sp * 0.5 + 0.24, abs(m - 1.75) - 1.3) * PXM) * step(0.0, j) * step(j, np - 1.0);
      float on = step(0.22, hs(vec2(fi, j + 40.0)));
      vec3 shop = mix(vec3(1.0, 0.8, 0.52), vec3(0.96, 0.92, 0.84), hs(vec2(fi, j + 2.0))) * (0.7 + 0.55 * vn(vec2(xm * 3.0, m * 2.0) + fi));
      c = mix(c, glassD, g);
      E += shop * g * on * (0.22 + 1.0 * LYS);
      if (ar > 0.5) { float ax = xm - 1.8, ad = max(m < 2.0 ? abs(ax) - 1.15 : length(vec2(ax, m - 2.0)) - 1.15, -m), ga = cv(ad * PXM);
        c = mix(c, vec3(0.035, 0.03, 0.03), ga); E = mix(E, VARM * 0.45 * LYS * (1.0 - m / 3.2), ga); }
    }
    float nc = max(2.0, floor((wm - 0.8) / 2.0)), sc = (wm - 0.8) / nc, jc = floor((xm - 0.4) / sc), lxw = xm - 0.4 - (jc + 0.5) * sc;
    float fy = (m - 4.15) / 2.55, fw = floor(fy), ly = (fy - fw) * 2.55 - 0.72;
    float inW = step(0.0, jc) * step(jc, nc - 1.0) * step(0.0, fw) * step(4.15 + fw * 2.55 + 1.45, em - 0.15);
    float wd = max(abs(lxw) - 0.43, abs(ly) - 0.66), wid = fi * 13.0 + jc + fw * 5.0;
    if (m > em) {
      float gx = xm - wm * 0.5, n1 = wm > 10.0 ? 3.0 : 2.0, j1 = floor(gx / 1.9 + n1 * 0.5), l1 = gx - (j1 + 0.5 - n1 * 0.5) * 1.9;
      float w1 = max(abs(l1) - 0.42, abs(m - em - 1.15) - 0.62) + 10.0 * (1.0 - step(0.0, j1) * step(j1, n1 - 1.0));
      float n2 = wm > 10.0 ? 2.0 : 1.0, j2 = floor(gx / 1.7 + n2 * 0.5), l2 = gx - (j2 + 0.5 - n2 * 0.5) * 1.7;
      float w2 = max(abs(l2) - 0.4, abs(m - em - 3.35) - 0.58) + 10.0 * (1.0 - step(0.0, j2) * step(j2, n2 - 1.0)) + 10.0 * step(gh, 6.2);
      wd = min(w1, w2); inW = 1.0; wid = fi * 13.0 + 50.0 + (w1 < w2 ? j1 : 7.0 + j2);
      float fm = m - (rm - 2.3);
      if (gh > 5.5) {
        if (gab > 2.5) { float r0 = length(vec2(gx, fm)); c = mix(c, vec3(0.12), cv((r0 - 0.92) * PXM)); c = mix(c, vec3(0.95, 0.94, 0.9), cv((r0 - 0.78) * PXM)); E += vec3(1.0, 0.92, 0.75) * cv((r0 - 0.78) * PXM) * 0.6 * LYS; }
        else if (gab > 1.5) { float r0 = length(vec2(gx, fm)); c = mix(c, trim, cv((r0 - 0.55) * PXM)); wd = min(wd, r0 - 0.4); }
        else if (gab > 0.5) { c = mix(c, vec3(0.07, 0.06, 0.05), cv(max(abs(gx) - 0.5, abs(fm + 0.2) - 0.75) * PXM)); c = mix(c, vec3(0.1, 0.07, 0.05), cv(max(abs(gx) - 0.16, abs(fm - 1.0) - 0.2) * PXM)); }
      }
      if (sg > 1.5) { float bd = max(abs(gx) - min(2.8, wm * 0.3), abs(m - em - 2.25) - 0.27);
        float lt = step(0.32, hs(vec2(floor((gx + 3.0) / 0.42), fi))) * step(0.2, fract((gx + 3.0) / 0.42)) * step(0.0, -bd);
        c = mix(c, vec3(0.16, 0.13, 0.1), lt * cv(bd * PXM) * 0.9); }
    }
    float wg = cv(wd * PXM) * inW, fr = sat(cv((wd - 0.13) * PXM) * inW - wg);
    float hh = hs(vec2(wid, 3.0)), on = step(1.0 - 0.5 * uNight, hh);
    c = mix(c, trim, fr * 0.6);
    c = mix(c, (glassD + vec3(0.07) * smoothstep(0.3, 0.0, abs(fract(xm * 0.7 + m * 0.4) - 0.5)) * (1.0 - uNight)) * (1.0 - 0.32 * smoothstep(-0.3, 0.7, ly)), wg);
    vec3 Ew = mix(VARM, vec3(1.0, 0.9, 0.78), step(0.7, fract(hh * 11.0))) * (0.7 + 0.5 * fract(hh * 29.0)) * LYS * 1.25;
    E += Ew * on * (wg + 0.2 * exp(-max(wd, 0.0) * PXM * 1.2) * (1.0 - wg) * inW);
    if (sg > 0.5) { float bd = max(abs(xm - wm * 0.5) - wm * 0.5 + 0.9, abs(m - 3.75) - 0.27);
      float lt = step(0.3, hs(vec2(floor(xm / 0.42), fi + 2.0))) * step(0.22, fract(xm / 0.42)) * step(0.06, hs(vec2(floor(xm / 2.1), fi + 9.0)));
      c = mix(c, wh > 0.5 || lb > 0.55 ? vec3(0.14, 0.12, 0.1) : vec3(0.95, 0.93, 0.88), lt * cv(bd * PXM) * 0.9);
      if (sg > 1.5) { float b2 = max(abs(xm - wm * 0.5) - wm * 0.5 + 0.9, abs(m - 6.15) - 0.25);
        float l2 = step(0.3, hs(vec2(floor(xm / 0.4), fi + 5.0))) * step(0.22, fract(xm / 0.4));
        c = mix(c, vec3(0.16, 0.13, 0.1), l2 * cv(b2 * PXM) * 0.9); } }
    float ao = (1.0 - (0.3 + 0.3 * uSun) * (1.0 - smoothstep(0.0, 1.4 + 1.2 * uSun, max(dv, 0.0))) * step(m, em + gh)) * (0.74 + 0.26 * smoothstep(0.0, 2.6, m));
    float lpx = s.x - (floor((s.x - 22.0) / 53.6 + 0.5) * 53.6 + 22.0);
    vec3 L = AMB * (0.9 + 0.12 * sat(m / 18.0)) + SUNC * uSun * 0.95 * skyg((s.x - CX) / PXM, 10.0 + m) + SSC * uSunset * 0.95 + VARM * LYS * 0.55 * exp(-lpx * lpx / 160.0) * exp(-m / 4.0) + VARM * uNight * (0.12 + 0.22 * exp(-m / 6.0));
    c = c * L * ao + E;
    vec3 vc = mix(vec3(0.42, 0.23, 0.17), vec3(0.32, 0.31, 0.31), step(0.62, hs(vec2(fi, 8.0)))) * (0.8 + 0.3 * vn(vec2(s.x * 1.3, s.y))) * (AMB * 1.15 + SUNC * uSun * 0.5 + SSC * uSunset * 0.5);
    vc = mix(vc, vec3(0.88, 0.9, 0.94) * (AMB + 0.1), uSnow * smoothstep(-1.3, -0.3, dv) * 0.9);
    vec3 bb = mix(trim, C.rgb, 0.5) * (AMB * 0.95 + SUNC * uSun * 0.8);
    c = mix(c, bb, cv(dv - 0.5) * step(0.0, dv) * 0.4);
    vec3 col = (c * wA + vc * vA) / max(wA + vA, 1e-3);
    return vec4(luft(col, 420.0, 10.0, (s.x - CX) / PXM), sat(wA + vA));
  }
  return vec4(0.0);
}
vec4 sider(vec2 s){
  float x0 = uH[0].x, x1 = uH[15].y;
  if (s.x >= x0 && s.x <= x1) return vec4(0.0);
  vec4 acc = vec4(0.0);
  vec3 L = AMB * 0.95 + SUNC * uSun * 0.9 + SSC * uSunset * 0.9;
  if (s.x < x0) {
    float md = rb(s, vec2(23.0, 106.0), vec2(x0 + 0.5, QY));
    if (md < 1.0) { vec3 mc = vec3(0.62, 0.6, 0.56) * (0.9 + 0.1 * vn(s * 2.0));
      float band = cv(abs(s.y - 111.5) - 1.5);
      mc = mix(mc, mix(vec3(0.08, 0.09, 0.1), VARM * 1.2, LYS * step(0.3, fract(s.x * 0.37))), band);
      acc = over(acc, mc * L + VARM * band * LYS * 0.6 * step(0.3, fract(s.x * 0.37)), cv(md)); }
    float tn = 103.0 + 4.0 * vn(vec2(s.x * 0.35, 1.0)) + 2.0 * vn(vec2(s.x * 1.1, 2.0));
    float ta = sat((s.y - tn) * uDpr + 0.5) * step(s.x, 25.0);
    vec2 q = s * vec2(0.6, 0.7);
    vec3 tc = mix(vec3(0.08, 0.15, 0.09), vec3(0.5, 0.38, 0.12), smoothstep(0.55, 0.78, vn(q * 0.8 + 3.0))) * (0.5 + 0.7 * (vn(q * 1.3) * 0.6 + vn(q * 3.1) * 0.4));
    acc = over(acc, tc * L, ta);
    float tw = rb(s, vec2(5.0, 77.0), vec2(26.0, 118.0)), tr = max(abs(s.x - 15.5) - 11.0 * sat((s.y - 64.0) / 13.0), max(64.0 - s.y, s.y - 77.5));
    float sp = max(abs(s.x - 15.5) - 0.5, max(58.0 - s.y, s.y - 65.0)), tu = rb(s, vec2(24.0, 74.0), vec2(30.0, 118.0)) - 0.6, tuc = max(abs(s.x - 27.0) - 3.4 * sat((s.y - 67.0) / 7.0), max(67.0 - s.y, s.y - 74.5));
    vec3 stn = vec3(0.6, 0.56, 0.5) * (0.78 + 0.32 * fbm(s * vec2(0.5, 0.8))) * mix(1.0, 0.75, smoothstep(18.0, 26.0, s.x));
    float wn = cv(rb(vec2(mod(s.x - 7.0, 5.0), mod(s.y - 80.0, 8.0)), vec2(1.8, 2.0), vec2(2.8, 4.6))) * step(s.x, 23.0) * step(s.y, 112.0);
    stn = mix(stn, mix(vec3(0.06), VARM * 1.2, LYS * step(0.55, hs(floor(vec2(s.x / 5.0, s.y / 8.0))))), wn);
    vec3 roof = vec3(0.2, 0.24, 0.24) * (0.85 + 0.2 * vn(s * 1.5));
    float tA = max(cv(tw), cv(tu)), rA = max(max(cv(tr), cv(sp)), cv(tuc));
    vec3 tcol = tA > rA ? stn * L : roof * (AMB * 1.05 + SUNC * uSun * 0.5);
    acc = over(acc, luft(tcol, 500.0, 25.0, -92.0), max(tA, rA));
  } else {
    float bA = rb(s, vec2(x1 - 0.5, 89.0), vec2(375.0, QY)), bB = rb(s, vec2(375.0, 93.5), vec2(395.0, QY));
    float aA = cv(bA), aB = cv(bB);
    if (aA + aB > 0.0) {
      vec3 pc = aA > 0.0 ? vec3(0.86, 0.84, 0.8) : vec3(0.84, 0.73, 0.5);
      float ox = aA > 0.0 ? x1 + 1.5 : 377.0;
      vec2 g = vec2(mod(s.x - ox, 3.4), mod(s.y - 92.0, 5.4));
      float wd = rb(g, vec2(0.7, 1.2), vec2(2.5, 4.2)), wg = cv(wd) * step(s.y, 117.0) * step(95.5, s.y);
      float on = step(1.0 - 0.55 * uNight, hs(floor(vec2((s.x - ox) / 3.4, s.y / 5.4)) + 3.0));
      pc = pc * (0.92 + 0.08 * vn(s)) * L;
      pc = mix(pc, mix(FOGC * 0.4, vec3(0.06), 0.5), wg) + VARM * 1.2 * LYS * wg * on;
      pc = mix(pc, vec3(0.3, 0.28, 0.26) * L, cv(abs(s.y - (aA > 0.0 ? 89.6 : 94.1)) - 0.6));
      float sh = cv(rb(s, vec2(x1, 118.0), vec2(395.0, QY))) * (0.5 + 0.5 * step(0.5, fract(s.x * 0.21)));
      pc = mix(pc, mix(vec3(0.07), vec3(1.0, 0.85, 0.6) * 1.2, LYS), sh);
      acc = over(acc, luft(pc, 430.0, 12.0, 80.0), max(aA, aB));
    }
  }
  return acc;
}
vec4 lykter(vec2 s, inout vec3 glow){
  float lx = floor((s.x - 22.0) / 53.6 + 0.5) * 53.6 + 22.0, dx = s.x - lx;
  vec2 lc = vec2(lx, QY - 10.25); vec2 dl = s - lc; float r2 = dot(dl, dl);
  glow += VARM * (0.85 * exp(-r2 / 4.5) + 0.2 / (1.0 + r2 / (50.0 + 60.0 * uRain))) * LYS * (1.0 + 0.5 * uRain);
  float post = cv(abs(dx) - 0.3) * step(QY - 9.3, s.y);
  float cap = cv(max(abs(dx) - 1.2 + (QY - 11.4 - s.y) * 0.6, max(QY - 12.4 - s.y, s.y - (QY - 11.3))));
  float lg = cv(rb(s, vec2(lx - 0.9, QY - 11.3), vec2(lx + 0.9, QY - 9.2)));
  vec3 dark = vec3(0.04, 0.045, 0.05) * (AMB + 0.25);
  vec3 lamp = mix(vec3(0.5, 0.48, 0.42) * AMB, vec3(1.0, 0.88, 0.62) * 2.4, LYS);
  float a = max(max(post, cap), lg);
  return vec4(lg > max(post, cap) ? lamp : dark, a);
}
vec4 folk(vec2 s){
  vec4 acc = vec4(0.0);
  if (s.y < QY - 6.0) return acc;
  for (int i = 0; i < 9; i++) {
    float fi = float(i), h = hs(vec2(fi, 11.0)), dir = h < 0.5 ? -1.0 : 1.0;
    float x = mod(fi * 47.0 + T * dir * (2.0 + 1.6 * fract(h * 7.0)), 440.0) - 25.0;
    if (abs(s.x - x) > 2.0) continue;
    float bob = abs(sin(T * 5.5 + fi * 2.0)) * 0.18;
    float body = rb(s, vec2(x - 0.52, QY - 3.25 - bob), vec2(x + 0.52, QY)) - 0.06, head = length(s - vec2(x, QY - 3.58 - bob)) - 0.4;
    float hc = fract(h * 13.0);
    vec3 cc = hc < 0.55 ? vec3(0.07, 0.08, 0.1) : (hc < 0.72 ? vec3(0.78, 0.62, 0.14) : (hc < 0.86 ? vec3(0.55, 0.12, 0.1) : vec3(0.2, 0.3, 0.46)));
    vec3 Lp = AMB * 0.85 + SUNC * uSun * 0.8 + VARM * LYS * 0.4;
    if (uRain > 0.5) {
      float um = max(length((s - vec2(x + dir * 0.2, QY - 4.0 - bob)) * vec2(1.0, 2.4)) - 1.25, s.y - (QY - 3.95 - bob));
      vec3 uc = fract(h * 29.0) < 0.6 ? vec3(0.06, 0.06, 0.07) : (fract(h * 29.0) < 0.8 ? vec3(0.6, 0.1, 0.1) : vec3(0.15, 0.3, 0.5));
      acc = over(acc, uc * Lp, cv(um));
    }
    acc = over(acc, mix(cc, vec3(0.72, 0.56, 0.45), cv(head)) * Lp, cv(min(body, head)));
  }
  return acc;
}
vec4 biler(vec2 s, inout vec3 glow){
  vec4 acc = vec4(0.0);
  for (int i = 0; i < 3; i++) {
    float fi = float(i), bus = step(1.5, fi), dir = i == 1 ? -1.0 : 1.0;
    float len = bus > 0.5 ? 25.7 : 9.4, hgt = bus > 0.5 ? 6.6 : 3.2;
    float x0 = mod(T * (bus > 0.5 ? 11.0 : 15.0 + fi * 3.0) + fi * 190.0, 600.0 + bus * 260.0) - 110.0;
    if (dir < 0.0) x0 = 390.0 - x0;
    vec2 fl = vec2(x0 + dir * len * 0.5, QY - hgt * 0.32), rl = vec2(x0 - dir * len * 0.5, QY - hgt * 0.36);
    vec2 d1 = (s - fl) * vec2(0.5, 1.0), d2 = s - rl;
    glow += vec3(1.0, 0.95, 0.85) * (1.2 * exp(-dot(d1, d1) / 0.8) + 0.12 * exp(-dot(d1, d1) / 20.0)) * LYS * 0.9;
    glow += vec3(1.0, 0.1, 0.05) * exp(-dot(d2, d2) / 0.6) * 0.8 * LYS;
    if (abs(s.x - x0) > len * 0.5 + 1.0 || s.y < QY - hgt - 1.0) continue;
    float body = rb(s, vec2(x0 - len * 0.5, QY - hgt * (bus > 0.5 ? 1.0 : 0.55)), vec2(x0 + len * 0.5, QY - 0.7)) - 0.4;
    float cab = bus > 0.5 ? 1e3 : rb(s, vec2(x0 - len * 0.3 - dir * 0.6, QY - hgt), vec2(x0 + len * 0.22 - dir * 0.6, QY - hgt * 0.5)) - 0.5;
    vec3 bc = i == 0 ? vec3(0.12, 0.14, 0.18) : (i == 1 ? vec3(0.8, 0.8, 0.78) : vec3(0.62, 0.1, 0.1));
    vec3 Lb = AMB * 0.9 + SUNC * uSun * 0.8;
    vec3 c = bc * Lb;
    float win = bus > 0.5 ? cv(rb(s, vec2(x0 - len * 0.45, QY - hgt * 0.88), vec2(x0 + len * 0.45, QY - hgt * 0.45))) : cv(cab + 0.6) * step(QY - hgt * 0.95, s.y);
    c = mix(c, mix(FOGC * 0.4, vec3(0.05), 0.5) + (bus > 0.5 ? VARM * LYS * 0.9 : vec3(0.0)), win * (bus > 0.5 ? step(0.18, fract((s.x - x0) * 0.32)) : 1.0));
    float wh = min(length(s - vec2(x0 - len * 0.32, QY - 0.6)), length(s - vec2(x0 + len * 0.32, QY - 0.6))) - 0.75;
    c = mix(c, vec3(0.03), cv(wh));
    acc = over(acc, c, max(cv(min(body, cab)), cv(wh)));
  }
  return acc;
}
vec3 kai(vec2 s){
  float m = (s.y - QY) / PXM, row = floor(m / 0.55), xx = s.x / PXM + mod(row, 2.0) * 0.6, id = floor(xx / 1.2);
  vec3 c = vec3(0.43, 0.43, 0.42) * (0.8 + 0.3 * hs(vec2(id, row))) * (0.92 + 0.12 * vn(s * 1.7));
  float jn = max(cv((fract(xx / 1.2) - 0.05) * PXM * 1.2), cv((fract(m / 0.55) - 0.09) * PXM * 0.55));
  c = mix(c, vec3(0.12), jn * 0.6);
  c = mix(c, vec3(0.58, 0.58, 0.56), step(m, 0.22));
  c *= mix(1.0, 0.45, smoothstep(0.4, 1.6, m) * (0.6 + 0.4 * uWet));
  c = mix(c, vec3(0.06, 0.08, 0.06), smoothstep(1.3, 1.6, m) * 0.7);
  c = mix(c, vec3(0.88, 0.9, 0.94), uSnow * step(m, 0.22));
  float lpx = s.x - (floor((s.x - 22.0) / 53.6 + 0.5) * 53.6 + 22.0);
  return c * (AMB * 0.9 + SUNC * uSun * 0.7) + VARM * LYS * 0.45 * exp(-lpx * lpx / 30.0) * step(m, 0.25);
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
vec3 tm(vec3 c){ vec3 k = max(c - 0.64, 0.0); return min(c, 0.64) + 0.36 * (1.0 - exp(-k / 0.36)); }
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  vec2 s = vec2(p.x, p.y + uOff);
  AA = 1.15 / uDpr; T = uT; LYS = 0.22 + 0.78 * uNight;
  VARM = vec3(1.0, 0.74, 0.42);
  AMB = max(mix(uSkM, uSkB, 0.5) * mix(1.0, 0.4, uNight) * mix(1.0, 0.62, uSun), vec3(0.07, 0.08, 0.1)) + vec3(0.05, 0.035, 0.02) * uNight;
  SUNC = vec3(1.0, 0.93, 0.8) * 0.8; SSC = vec3(1.0, 0.6, 0.34) * 0.85;
  FOGC = mix(uSkB, uSkM, 0.3) + vec3(0.1, 0.06, 0.02) * uNight * 0.5;
  CLDC = mix(uSkB, uSkM, 0.55) * 1.02 + vec3(0.12, 0.07, 0.02) * uNight * 0.55;
  vec4 acc = vec4(0.0); vec3 glow = vec3(0.0); vec4 f;
  if (s.y >= QY) acc = vec4(kai(s), 1.0);
  else {
    f = folk(s); acc = over(acc, f.rgb, f.a);
    if (s.y > QY - 8.0) { f = biler(s, glow); acc = over(acc, f.rgb, f.a); }
    f = lykter(s, glow); acc = over(acc, f.rgb, f.a);
    if (acc.a < 0.99) { f = bryggen(s); acc = over(acc, f.rgb, f.a); }
    if (acc.a < 0.99) { f = sider(s); acc = over(acc, f.rgb, f.a); }
    if (acc.a < 0.99) {
      float dp = terrD(s), Zp = ZB + dp, Xp = (s.x - CX) * Zp / F, ap = altF(dp, Xp);
      vec4 ch = kirke(s);
      vec4 rw = rader(s, ch.a > 0.0 ? min(dp, 104.0) : dp);
      acc = over(acc, rw.rgb, rw.a);
      acc = over(acc, ch.rgb, ch.a);
      if (acc.a < 0.99) {
        vec3 bg = ap > skyF(Xp) ? luft(himmel(s), 360.0, ap, Xp) : floibanen(s, ap, Zp, terreng(s, dp, Zp, Xp, ap));
        acc = over(acc, bg, 1.0);
      }
    }
  }
  vec3 col = acc.rgb + glow;
  if (s.y < QY) col *= 0.9 + 0.2 * (vn(s * 0.85 + 7.0) * 0.55 + vn(s * 2.4 + 3.0) * 0.45);
  if (uRain > 0.0) { float r = regn(p, 3.0, 380.0, 9.0, 1.0) * 0.25 + regn(p, 5.0, 560.0, 16.0, 7.0) * 0.4;
    col += (vec3(0.75, 0.8, 0.85) * (0.08 + 0.26 * (1.0 - uNight)) + glow * 1.4) * r * uRain; }
  if (uSnow > 0.0) { float sn = sno(p, 9.0, 14.0, 1.0) * 0.55 + sno(p, 16.0, 24.0, 5.0) * 0.85;
    col = mix(col, vec3(0.93, 0.95, 1.0) * (0.6 + 0.35 * (1.0 - uNight)) + glow * 1.5, sat(sn) * uSnow); }
  col = max(col, 0.0);
  float lu = dot(col, vec3(0.3, 0.55, 0.15));
  col = mix(vec3(lu), col, 0.84);
  col += (vec3(-0.01, 0.002, 0.018) * (1.0 - smoothstep(0.0, 0.35, lu)) + vec3(0.018, 0.006, -0.014) * smoothstep(0.4, 1.0, lu)) * (1.0 - 0.6 * uNight);
  vec3 xe = col * (0.92 - 0.14 * uSun);
  col = clamp((xe * (2.51 * xe + 0.03)) / (xe * (2.43 * xe + 0.59) + 0.14), 0.0, 1.0);
  col = mix(col, uSkB * 0.98 + 0.03, uVeil * (0.34 - 0.16 * uSun) * smoothstep(80.0, 6.0, p.y));
  vec2 vq = p / uRes - 0.5; col *= 1.0 - 0.12 * smoothstep(0.35, 0.8, length(vq * vec2(1.0, 0.7)));
  col += (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
