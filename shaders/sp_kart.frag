// Sporing · På vei — the Launch prototype's own WebGL scene (`spKartInit / spKartTegn` in
// «Ærend Kunde Launch.dc.html»), ported as is: the 2.5D night map of the centre: houses, shadows, trees, water, boats, cars, street lights, people and the route on the ground.
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
uniform float uProg;
uniform sampler2D uA;
uniform sampler2D uB;
uniform sampler2D uC;
uniform sampler2D uD;
out vec4 fragColor;
float AA, T, N, SUNI;
vec3 L, SUNC, AMB, SKY;
vec2 SH;
vec4 BR[11]; float BH[11]; float BY[11];
vec3 TR[21];
vec3 WR; vec4 WA[12]; vec2 WM[12];
const vec2 OB = vec2(0.26, -0.74);
const vec3 VARM = vec3(1.0, 0.76, 0.46);
vec2 FUV(vec2 uv){ return vec2(uv.x, 1.0 - uv.y); }
float hs(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x), mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = mat2(1.6, 1.2, -1.2, 1.6) * p; a *= 0.5; } return s; }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float rb(vec2 p, vec2 a, vec2 b){ vec2 c = (a + b) * 0.5, h = (b - a) * 0.5; vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float cv(float d){ return 1.0 - smoothstep(-AA, AA, d); }
float LYSV;
float he(vec2 p, vec2 a, vec2 b){ vec2 e = normalize(b - a); return dot(p - a, vec2(e.y, -e.x)); }
float hull(vec2 p, vec2 a, vec2 b, vec2 d){
  vec2 v0 = a + d, v1 = vec2(b.x, a.y) + d, v2 = b + d, v3 = b, v4 = vec2(a.x, b.y);
  return max(max(max(he(p, v0, v1), he(p, v1, v2)), max(he(p, v2, v3), he(p, v3, v4))), max(he(p, v4, a), he(p, a, v0)));
}
vec3 lysN(vec3 n){ return AMB * (0.75 + 0.25 * n.z) + SUNC * SUNI * max(dot(n, L), 0.0); }
vec2 ringer(vec2 w, float cs){
  vec2 gp = w / cs, id = floor(gp), f = fract(gp) - 0.5;
  float r1 = hs(id), ph = fract(T * (0.7 + r1 * 0.5) + r1 * 7.0);
  vec2 dv = f - (vec2(hs(id + 3.1), hs(id + 5.7)) - 0.5) * 0.5;
  float r = length(dv) + 1e-4, rad = ph * 0.45;
  return dv / r * sin((r - rad) * 40.0) * exp(-abs(r - rad) * 22.0) * (1.0 - ph) * (1.0 - ph);
}
vec2 BOAT; vec2 BDIR;
vec3 vann(vec2 p, float wB, float vag){
  vec2 g = vec2(0.0), dr = vec2(0.8, 0.6);
  float fr = mix(0.95, 0.55, vag), am = 1.0, sw = 0.0;
  for (int i = 0; i < 6; i++) {
    float ph = dot(dr, p) * fr + T * (1.1 + fr * 0.9), e = exp(sin(ph) - 1.0);
    g += dr * e * cos(ph) * fr * am; sw += am;
    dr = vec2(dr.x * 0.74 - dr.y * 0.67, dr.x * 0.67 + dr.y * 0.74); fr *= 1.32; am *= 0.72;
  }
  g *= mix(0.22, 0.4, vag) / sw;
  vec2 F = vec2(192.0, 259.0); float rf = length(p - F);
  g += (1.0 - vag) * (p - F) / (rf + 0.01) * sin(rf * 1.3 - T * 5.0) * 0.16 * exp(-rf * 0.06);
  if (uRain > 0.0) g += (ringer(p, 7.0) + ringer(p + 3.3, 10.0) * 0.7) * 0.9 * uRain;
  float wk = 0.0;
  if (vag > 0.5) {
    vec2 q = vec2(dot(p - BOAT, BDIR), dot(p - BOAT, vec2(-BDIR.y, BDIR.x)));
    float bk = smoothstep(2.0, -6.0, q.x) * exp(q.x / 70.0), arm = abs(abs(q.y) - (-q.x) * 0.32);
    wk = (exp(-arm * arm / 2.5) * 0.8 + exp(-q.y * q.y / 3.0) * 0.6 * smoothstep(0.35, 0.8, vn(q * 0.5 + vec2(T * 3.0, 0.0)))) * bk;
    g += vec2(0.0, sign(q.y)) * sin(arm * 2.2 - T * 6.0) * bk * exp(-arm * 0.25) * 0.25;
  }
  vec3 n = normalize(vec3(-g.x, g.y, 1.0)), V = normalize(vec3(0.0, -0.55, 1.0));
  float dep = smoothstep(0.5, 0.98, wB);
  vec3 shal = mix(vec3(0.3, 0.55, 0.56), vec3(0.2, 0.36, 0.4), N), deep = mix(vec3(0.08, 0.26, 0.32), vec3(0.05, 0.15, 0.2), N);
  vec3 body = mix(shal, deep, dep) * (1.0 - 0.18 * uRain);
  float ra = sat(0.16 + (1.0 - dot(n, V)) * 3.2);
  vec3 sky = SKY * (0.85 + 0.3 * fbm(p * 0.02 + vec2(T * 0.01, 0.0)));
  vec3 col = mix(body, sky, ra);
  vec3 H = normalize(mix(vec3(0.0, 0.0, 1.0), normalize(L + V), 0.4));
  col += SUNC * SUNI * pow(max(dot(n, H), 0.0), 900.0) * 6.0;
  col += SUNC * SUNI * pow(max(dot(n, H), 0.0), 120.0) * 0.12;
  float shore = 1.0 - smoothstep(0.42, 0.7, wB);
  float lap = smoothstep(0.55, 0.95, sin(wB * 46.0 - T * 2.2) * 0.5 + 0.5) * smoothstep(0.35, 0.7, vn(p * 0.45 + T * 0.3));
  col = mix(col, vec3(0.86, 0.92, 0.93) * (AMB + SUNC * SUNI * 0.5), sat(lap * shore * 0.55 + exp(-pow((wB - 0.5) / 0.035, 2.0)) * 0.35));
  col *= 1.0 - 0.3 * vag * shore;
  col = mix(col, vec3(0.9, 0.95, 0.96) * (AMB + SUNC * SUNI * 0.6), sat(wk) * 0.8);
  return col;
}
void baat(vec2 p, vec2 c, vec2 f, float s, vec3 farge, inout vec3 col){
  vec2 r = vec2(-f.y, f.x);
  vec2 ps = p - SH * 1.2 * s; vec2 qs = vec2(dot(ps - c, f), dot(ps - c, r)) / s;
  col *= 1.0 - 0.3 * SUNI * cv((length(qs / vec2(4.6, 1.6)) - 1.0) * 1.6 * s);
  vec2 q = vec2(dot(p - c - OB * s, f), dot(p - c - OB * s, r)) / s;
  float bow = q.x > 0.0 ? q.x * 0.28 : 0.0;
  float d = (length(vec2(q.x / 4.5, q.y / (1.55 - bow))) - 1.0) * 1.6 * s;
  if (d < 1.0) {
    float rim = smoothstep(-0.9, 0.0, d);
    vec3 C = farge * lysN(normalize(vec3(0.0, -q.y * 0.3, 1.0)));
    C = mix(C, vec3(0.92) * lysN(vec3(0.0, 0.0, 1.0)), smoothstep(0.35, 0.0, abs(q.x + 0.4)) * step(abs(q.y), 0.9) * 0.0);
    float cab = rb(q, vec2(-2.2, -0.75), vec2(0.6, 0.75)) - 0.2;
    C = mix(C, vec3(0.94, 0.95, 0.94) * lysN(vec3(0.0, 0.0, 1.0)), cv(cab * s));
    C = mix(C, vec3(0.15, 0.22, 0.27) + SKY * 0.15, cv((rb(q, vec2(0.0, -0.6), vec2(0.55, 0.6)) - 0.05) * s));
    C = mix(C, farge * 0.6, rim);
    col = mix(col, C, cv(d));
    float lyk = length(p - (c + f * 3.8 * s + OB * s * 1.6)); col += VARM * N * (exp(-lyk * lyk / 0.6) * 1.4 + exp(-lyk * lyk / 12.0) * 0.12);
  }
}
void bil(vec2 p, vec2 c, vec2 f, vec3 bc, inout vec3 col){
  vec2 r = vec2(-f.y, f.x);
  vec2 q0 = vec2(dot(p - c, f), dot(p - c, r));
  if (abs(q0.y) > 14.0 || q0.x < -10.0 || q0.x > 30.0) return;
  col *= 1.0 - 0.32 * cv(rb(q0, vec2(-3.8, -1.9), vec2(3.8, 1.9)) - 0.9);
  vec2 ps = p - SH * 1.5; vec2 qs = vec2(dot(ps - c, f), dot(ps - c, r));
  col *= 1.0 - 0.35 * SUNI * cv(rb(qs, vec2(-3.5, -1.7), vec2(3.5, 1.7)) - 0.5);
  if (q0.x > 3.6) { float cone = smoothstep(1.4 + (q0.x - 3.6) * 0.42, 0.0, abs(q0.y)) * exp(-(q0.x - 3.6) / 9.0); col += vec3(1.0, 0.93, 0.78) * cone * N * 0.4; }
  vec2 q = vec2(dot(p - OB * 1.5 - c, f), dot(p - OB * 1.5 - c, r));
  float d = rb(q, vec2(-3.4, -1.65), vec2(3.4, 1.65)) - 0.45;
  if (d < 1.0) {
    vec3 C = bc * lysN(vec3(0.0, 0.0, 1.0)) * (0.85 + 0.25 * smoothstep(1.9, 0.0, abs(q.y)));
    float gl = rb(q, vec2(-1.9, -1.35), vec2(1.7, 1.35)) - 0.25;
    C = mix(C, vec3(0.08, 0.11, 0.13) + SKY * 0.18, cv(gl));
    C = mix(C, bc * lysN(vec3(0.0, 0.0, 1.0)) * 1.1, cv(rb(q, vec2(-1.2, -1.15), vec2(0.8, 1.15)) - 0.15));
    C += vec3(1.0) * 0.18 * smoothstep(0.6, 0.0, abs(q.y + 0.9)) * step(abs(q.x), 3.0);
    col = mix(col, C, cv(d));
  }
  float hl = min(length(q - vec2(3.75, 1.1)), length(q - vec2(3.75, -1.1)));
  col += vec3(1.0, 0.95, 0.85) * N * (cv(hl - 0.5) * 1.5 + exp(-hl * hl / 3.0) * 0.4);
  float tl = min(length(q - vec2(-3.75, 1.15)), length(q - vec2(-3.75, -1.15)));
  col += vec3(1.0, 0.12, 0.08) * N * (cv(tl - 0.45) * 1.1 + exp(-tl * tl / 2.0) * 0.25);
}
float lykt(vec2 p, vec2 b, inout vec3 col, inout vec3 add){
  vec2 d = p - b; float r2 = dot(d, d);
  add += VARM * N * 0.9 * exp(-r2 / 70.0);
  vec2 dr = vec2(d.x * 1.6, d.y - 6.0); add += VARM * N * uWet * 0.2 * exp(-dot(dr, dr) / 30.0);
  float sy = d.y - 9.0; WR += VARM * N * exp(-d.x * d.x / 2.6 - sy * sy / 70.0);
  return r2;
}
void lyktHode(vec2 p, vec2 b, inout vec3 col){
  vec2 hd = b + OB * 7.0, e = hd - b; float t = sat(dot(p - b, e) / dot(e, e));
  float ds = length(p - b - e * t);
  col = mix(col, vec3(0.08, 0.09, 0.1), cv(ds - 0.32) * 0.9);
  float r = length(p - hd);
  col = mix(col, mix(vec3(0.2), vec3(1.6, 1.35, 1.0), N), cv(r - 0.85));
  col += VARM * N * (exp(-r * r / 4.0) * 0.7 + exp(-r * r / 40.0) * 0.12);
}
vec3 bakke(vec2 p, vec2 uv){
  vec3 m = texture(uA, FUV(uv)).rgb, mb = texture(uB, FUV(uv)).rgb;
  vec4 bz = texture(uC, FUV(uv)); float rdB = bz.r, wB = bz.g;
  float road = m.r, water = m.b, grass = m.g * (1.0 - road);
  float lane = smoothstep(0.7, 0.92, mb.b) * road;
  float path = smoothstep(0.22, 0.42, mb.b) * (1.0 - smoothstep(0.62, 0.8, mb.b)) * (1.0 - road);
  float side = smoothstep(0.04, 0.16, rdB) * (1.0 - road);
  float fw = 0.8 / uDpr;
  vec2 cq = p / 1.7; float row = floor(cq.y); vec2 ci = floor(vec2(cq.x + mod(row, 2.0) * 0.5, cq.y));
  vec2 cf = vec2(fract(cq.x + mod(row, 2.0) * 0.5), fract(cq.y)) - 0.5;
  float jt = smoothstep(0.5 - fw, 0.5 - fw * 3.0, max(abs(cf.x), abs(cf.y)));
  float blk = fbm(p * 0.018);
  vec3 A = mix(vec3(0.66, 0.62, 0.56), vec3(0.76, 0.72, 0.65), hs(ci)) * mix(0.78, 1.0, jt) * (0.9 + 0.14 * vn(p * 0.15));
  A *= mix(vec3(0.94, 0.96, 1.0), vec3(1.05, 1.0, 0.94), blk);
  vec2 sq = p / 3.2; vec2 sf = fract(sq) - 0.5;
  vec3 SW = vec3(0.82, 0.81, 0.78) * (0.94 + 0.08 * hs(floor(sq))) * mix(0.84, 1.0, smoothstep(0.5 - fw * 0.6, 0.5 - fw * 1.8, max(abs(sf.x), abs(sf.y))));
  A = mix(A, SW, side);
  vec3 G = mix(vec3(0.27, 0.43, 0.2), vec3(0.37, 0.52, 0.24), fbm(p * 0.09)) * (0.94 + 0.08 * step(0.5, fract((p.x + p.y) / 9.0)));
  G *= 0.9 + 0.2 * vn(p * 1.3);
  A = mix(A, G, grass);
  vec3 PA = vec3(0.76, 0.69, 0.56) * (0.88 + 0.2 * hs(floor(p * 1.5)));
  A = mix(A, PA, path);
  vec3 RD = vec3(0.24, 0.25, 0.27) * (0.88 + 0.18 * vn(p * 0.9) + 0.08 * fbm(p * 0.05));
  RD = mix(RD, vec3(0.9, 0.9, 0.86), lane);
  RD = mix(RD, vec3(0.8, 0.8, 0.78), smoothstep(0.3, 0.45, road) * (1.0 - smoothstep(0.55, 0.7, road)) * 0.8);
  A = mix(A, RD, smoothstep(0.45, 0.55, road));
  float wet = uWet * (0.3 + 0.7 * road);
  A *= mix(1.0, 0.66, wet);
  if (uSnow > 0.0) { float sn = uSnow * (1.0 - road * 0.75) * smoothstep(0.25, 0.55, fbm(p * 0.2) * 0.6 + 0.35);
    A = mix(A, vec3(0.88, 0.91, 0.95), sn); A = mix(A, vec3(0.5, 0.5, 0.52) * (0.8 + 0.3 * vn(vec2(p.x * 0.2, p.y * 2.0))), uSnow * road * 0.5); }
  float shad = 1.0, ao = 1.0;
  for (int i = 0; i < 11; i++) {
    vec2 a = BR[i].xy, b = BR[i].zw; float h = BH[i];
    float ds = rb(p, a, b);
    if (ds > 60.0) continue;
    ao *= 1.0 - 0.4 * exp(-max(ds, 0.0) / 2.6);
    float sd = hull(p, a, b, SH * h);
    shad *= mix(1.0, 0.0, 1.0 - smoothstep(-1.2, 1.4, sd));
  }
  for (int i = 0; i < 21; i++) { vec3 tr = TR[i]; float dd = length(p - tr.xy - SH * tr.z * 1.4) - tr.z * 0.95;
    shad *= smoothstep(-1.5, 1.5, dd) * 0.9 + 0.1;
    ao *= 1.0 - 0.22 * exp(-max(length(p - tr.xy) - tr.z * 0.6, 0.0) / 3.0); }
  vec2 cq2 = (p - SH * 34.0) * 0.0052 + vec2(T * 0.011, T * 0.004);
  float cs = smoothstep(0.5, 0.78, fbm(cq2 + fbm(cq2 * 1.7) * 0.6));
  shad *= 1.0 - cs * 0.55;
  vec3 lit = AMB * ao + SUNC * SUNI * L.z * shad * mix(1.0, 0.85, 1.0 - ao);
  vec3 col = A * lit;
  if (wet > 0.0) col = mix(col, SKY * 0.55 * ao, wet * 0.16 * smoothstep(0.4, 0.6, road));
  vec3 add = vec3(0.0); WR = vec3(0.0);
  if (p.x < 192.0 && abs(p.y - 110.0) < 26.0) { float k = clamp(floor((p.x - 14.0) / 32.0 + 0.5), 0.0, 5.0); lykt(p, vec2(14.0 + 32.0 * k, 102.6), col, add); }
  if (abs(p.x - 100.0) < 26.0) { float k = floor((p.y - 14.0) / 32.0 + 0.5); lykt(p, vec2(92.6, 14.0 + 32.0 * k), col, add); }
  if (p.x < 162.0 && abs(p.y - 300.0) < 26.0) { float k = clamp(floor((p.x - 10.0) / 32.0 + 0.5), 0.0, 4.0); lykt(p, vec2(10.0 + 32.0 * k, 292.6), col, add); }
  col += A * add * 1.4 + add * 0.08;
  col += WR * wet * smoothstep(0.4, 0.6, road) * (0.4 + 0.6 * vn(vec2(p.x * 0.7, p.y * 0.18 - T * 1.4))) * 0.75;
  if (water > 0.0) {
    float vag = step(p.y, 100.0); vec3 wc = vann(p, wB, vag);
    if (uSnow > 0.0 && vag < 0.5) {
      vec3 IL = AMB + SUNC * SUNI * L.z * 0.75;
      vec3 ice = mix(vec3(0.5, 0.62, 0.69), vec3(0.76, 0.84, 0.88), smoothstep(0.3, 0.75, fbm(p * 0.07))) * IL;
      float cr = fbm(p * 0.2 + 7.0); ice *= 1.0 - 0.22 * (1.0 - smoothstep(0.0, 0.025, abs(cr - 0.5)));
      ice += vec3(1.0) * 0.5 * pow(vn(p * 1.7), 18.0) * SUNI;
      ice = mix(ice, vec3(0.9, 0.93, 0.97) * IL, sat(smoothstep(0.5, 0.78, fbm(p * 0.11 + 3.0)) * 0.75 + (1.0 - smoothstep(0.5, 0.72, wB)) * 0.7));
      wc = mix(wc, ice, uSnow);
    }
    col = mix(col, wc, water);
  }
  float rc = mb.r, rcas = smoothstep(0.06, 0.32, bz.b), rgl = texture(uD, FUV(uv)).r;
  float on = step(0.003, mb.g), pr = (mb.g * 255.0 - 1.0) / 254.0;
  float ah = on * smoothstep(uProg - 0.003, uProg + 0.003, pr);
  vec3 OR = vec3(0.97, 0.43, 0.2);
  col = mix(col, vec3(0.45, 0.16, 0.06), rcas * 0.85 * ah);
  float flow = 0.78 + 0.5 * pow(0.5 + 0.5 * sin(pr * 150.0 - T * 4.5), 4.0);
  col = mix(col, OR * flow * 1.1, rc * ah);
  col = mix(col, mix(col, vec3(0.7, 0.86, 0.88), 0.55), smoothstep(0.35, 0.8, rc) * (1.0 - ah) * on);
  col += OR * rgl * ah * (0.22 + 0.4 * N);
  float near = on * exp(-pow((pr - uProg) * 80.0, 2.0));
  col += OR * near * 0.55 * sat(rgl * 2.0 + rc);
  return col;
}
vec3 vegg(vec2 p, vec2 a, vec2 b, vec2 d, float h, float ty, float id){
  vec2 D0 = vec2(a.x, b.y);
  float cr = (d.x * (p.y - D0.y) - d.y * (p.x - D0.x)) / length(d);
  float south = smoothstep(-AA, AA, -cr);
  float tS = sat((b.y - p.y) / -d.y), uS = p.x - tS * d.x - a.x;
  float tW = sat((p.x - a.x) / d.x), uW = p.y - tW * d.y - a.y;
  float t = mix(tW, tS, south), u = mix(uW, uS, south), len = mix(b.y - a.y, b.x - a.x, south);
  float z = t * h;
  vec3 n = mix(vec3(-1.0, 0.0, 0.0), vec3(0.0, -1.0, 0.0), south);
  vec3 W = ty < 0.5 ? vec3(0.7, 0.69, 0.66) : ty < 1.5 ? vec3(0.9, 0.84, 0.72) : ty < 2.5 ? vec3(0.72, 0.62, 0.5) : ty < 3.5 ? vec3(0.62, 0.66, 0.6) : ty < 4.5 ? vec3(0.64, 0.66, 0.7) : ty < 5.5 ? vec3(0.66, 0.3, 0.2) : vec3(0.92, 0.88, 0.8);
  if (ty > 4.5 && ty < 5.5) { vec2 bq = vec2(u / 1.4 + mod(floor(z / 0.7), 2.0) * 0.5, z / 0.7); W *= mix(0.78, 1.0, smoothstep(0.0, 0.18, min(fract(bq.x), fract(bq.y)))) * (0.9 + 0.2 * hs(floor(bq))); }
  else if (ty > 0.5 && ty < 3.5) W *= 0.94 + 0.06 * step(0.5, fract(u / 1.2));
  vec3 C = W * lysN(n);
  C *= 0.72 + 0.28 * smoothstep(0.0, 3.5, z);
  float fh = 4.0, cw = ty > 5.5 ? 4.6 : 3.4;
  vec2 cell = vec2(u / cw, z / fh), ci = floor(cell), cf = fract(cell) - 0.5;
  float inside = step(0.8, u) * step(u, len - 0.8) * step(1.4, z) * step(z, h - 1.0);
  float win = inside * smoothstep(0.36, 0.28, abs(cf.x)) * smoothstep(0.34, 0.26, abs(cf.y - 0.04));
  float on = step(0.38, hs(ci + id * 13.0 + south * 7.0)) * LYSV;
  vec3 gls = mix(vec3(0.12, 0.16, 0.2) + SKY * 0.3 * (1.0 - N), VARM * (1.15 + 0.3 * hs(ci + id)) * (0.92 + 0.08 * sin(T * (0.6 + hs(ci) * 1.5) + hs(ci) * 20.0)), on);
  C *= 1.0 - 0.2 * inside * smoothstep(0.5, 0.4, abs(cf.y - 0.04)) * smoothstep(0.46, 0.36, abs(cf.x)) * (1.0 - win);
  C = mix(C, gls, win);
  C += VARM * on * 0.3 * inside * exp(-dot(cf, cf) * 5.0) * smoothstep(0.24, 0.5, abs(cf.y - 0.04));
  if (ty > 4.5 && ty < 5.5 && south > 0.5) {
    float aw = step(2.6, z) * step(z, 4.4) * step(0.6, u) * step(u, len - 0.6);
    vec3 AWc = mix(vec3(0.78, 0.18, 0.08), vec3(0.96, 0.92, 0.86), step(0.5, fract(u / 2.2))) * lysN(vec3(0.0, -0.6, 0.8));
    C = mix(C, AWc * mix(0.75, 1.0, smoothstep(2.6, 3.4, z)), aw);
    float sh = step(z, 2.6) * step(1.0, u) * step(u, len - 1.0) * step(0.3, z);
    C = mix(C, mix(vec3(0.2, 0.22, 0.24) + SKY * 0.2, VARM * 1.1, 0.35 + 0.65 * N), sh * smoothstep(0.3, 0.2, abs(fract(u / 6.0) - 0.5) - 0.18));
  }
  C *= 1.0 - 0.25 * smoothstep(1.2, 0.0, abs(cr)) * (1.0 - south) * 0.0;
  C = mix(C, C * 1.18 + 0.03, smoothstep(h - 0.6, h, z));
  if (uSnow > 0.0) C = mix(C, vec3(0.9, 0.93, 0.97) * lysN(vec3(0.0, 0.0, 1.0)), uSnow * smoothstep(1.2, 0.0, z) * 0.6);
  return C;
}
vec3 tak(vec2 p, vec2 a, vec2 b, float h, float ty, float id){
  vec2 s = b - a, q = p - a;
  bool flatt = ty < 0.5 || (ty > 1.5 && ty < 2.5);
  vec3 R = ty < 0.5 ? vec3(0.6, 0.62, 0.6) : ty < 1.5 ? vec3(0.72, 0.38, 0.26) : ty < 2.5 ? vec3(0.66, 0.6, 0.5) : ty < 3.5 ? vec3(0.42, 0.4, 0.38) : ty < 4.5 ? vec3(0.5, 0.53, 0.55) : ty < 5.5 ? vec3(0.36, 0.17, 0.12) : vec3(0.22, 0.27, 0.29);
  vec3 C; float sn = uSnow;
  if (flatt) {
    float e = -rb(p, a, b);
    vec3 n = vec3(0.0, 0.0, 1.0);
    vec3 A = R * (0.9 + 0.14 * vn(p * 1.8) + 0.06 * fbm(p * 0.3));
    float par = smoothstep(1.4, 0.9, e);
    bool lx = s.x >= s.y; float acr = lx ? q.y : q.x, alo = lx ? q.x : q.y, Ll = lx ? s.x : s.y, Ls = lx ? s.y : s.x;
    A *= 1.0 - 0.08 * smoothstep(0.44, 0.5, abs(fract(acr / 3.4) - 0.5)) * (1.0 - par);
    A *= 1.0 - 0.14 * smoothstep(0.55, 0.85, fbm(p * 0.09 + id * 3.7)) * (1.0 - par);
    A = mix(A, R * 1.25, par);
    C = A * lysN(n) * mix(1.0, 0.82, smoothstep(1.0, 2.6, e) * smoothstep(3.6, 1.6, e));
    float skm = 0.0;
    if (s.x * s.y > 2400.0) {
      vec2 lq = vec2(alo - Ll * 0.5, acr - Ls * 0.5);
      float kx = floor(lq.x / 7.0 + 0.5), fx = lq.x - kx * 7.0;
      float on = step(abs(kx * 7.0), Ll * 0.5 - 7.0);
      vec2 sq = vec2(fx, lq.y);
      C *= 1.0 - 0.35 * SUNI * on * cv(rb(sq - (lx ? SH : SH.yx) * 0.7, vec2(-1.9, -2.7), vec2(1.9, 2.7)) - 0.3);
      float fr = rb(sq, vec2(-1.9, -2.7), vec2(1.9, 2.7)) - 0.35;
      float gd = rb(sq, vec2(-1.5, -2.3), vec2(1.5, 2.3));
      vec3 G = mix(vec3(0.08, 0.11, 0.14), SKY * 0.75, smoothstep(-2.6, 2.6, sq.y + sq.x * 0.4)) + vec3(1.0) * 0.25 * smoothstep(0.4, 0.0, abs(sq.y - sq.x * 0.9 + 0.6));
      G = mix(G, VARM * (0.9 + 0.3 * hs(vec2(kx, id))), LYSV * step(0.35, hs(vec2(kx + 3.0, id))) * 0.85);
      vec3 FR = vec3(0.78, 0.8, 0.8) * lysN(n);
      skm = on * cv(fr);
      C = mix(C, mix(FR, G, cv(gd)), skm);
    }
    if (uWet > 0.0) {
      float pud = smoothstep(0.6, 0.74, fbm(p * 0.075 + id * 5.1)) * uWet * (1.0 - par) * (1.0 - skm);
      vec2 rg = uRain > 0.0 ? ringer(p, 4.5) * uRain : vec2(0.0);
      vec3 PU = SKY * (0.45 + 0.2 * fbm(p * 0.04 + vec2(T * 0.02, 0.0))) + vec3(1.0) * 0.35 * sat(length(rg) * 0.8);
      C = mix(C, PU * mix(1.0, 0.6, N), pud * 0.75);
    }
    for (int k = 0; k < 2; k++) {
      float fk = float(k);
      vec2 bc = a + s * vec2(0.25 + 0.5 * hs(vec2(id, fk)), 0.3 + 0.4 * hs(vec2(id, fk + 3.0)));
      vec2 bs = vec2(2.0 + 1.6 * hs(vec2(id, fk + 5.0)), 1.6);
      C *= 1.0 - 0.4 * SUNI * cv(rb(p - SH * 1.4, bc - bs, bc + bs) - 0.3) * (1.0 - cv(rb(p - OB * 1.4, bc - bs, bc + bs)));
      float bd = rb(p - OB * 1.4, bc - bs, bc + bs) - 0.3;
      vec3 BX = vec3(0.7, 0.72, 0.72) * lysN(n) * (0.9 + 0.1 * step(0.5, fract((p.x - bc.x) / 0.8)));
      vec2 fq = p - OB * 1.4 - bc - vec2(bs.x * 0.45, 0.0); float fr2 = length(fq);
      if (fr2 < 1.4) { float ang = atan(fq.y, fq.x) + T * (9.0 + fk * 3.0) + id; float bl = smoothstep(0.55, 0.15, abs(sin(ang * 1.5)));
        BX = mix(BX, mix(vec3(0.08), vec3(0.42) * lysN(n), bl * step(0.35, fr2)), cv(fr2 - 1.15)); }
      C = mix(C, BX, cv(bd));
    }
    if (sn > 0.0) C = mix(C, vec3(0.9, 0.93, 0.97) * lysN(n), sn * (1.0 - par * 0.6));
  } else {
    bool ax = s.x >= s.y;
    float v = ax ? q.y / s.y : q.x / s.x, along = ax ? q.x : q.y;
    float side = step(0.5, v);
    vec3 n = ax ? (side > 0.5 ? vec3(0.0, -0.55, 0.84) : vec3(0.0, 0.55, 0.84)) : (side > 0.5 ? vec3(0.55, 0.0, 0.84) : vec3(-0.55, 0.0, 0.84));
    float w = abs(v - 0.5) * (ax ? s.y : s.x);
    float tr = floor(w / 1.3), tf = fract(w / 1.3);
    float tc = fract(along / 1.7 + mod(tr, 2.0) * 0.5);
    vec3 A = R * (0.82 + 0.22 * hs(vec2(floor(along / 1.7 + mod(tr, 2.0) * 0.5), tr + id * 9.0)));
    A *= mix(0.72, 1.0, smoothstep(0.0, 0.3, tf)) * mix(0.85, 1.0, smoothstep(0.0, 0.12, min(tc, 1.0 - tc)));
    C = A * lysN(n);
    float ridge = smoothstep(0.8, 0.2, w);
    C = mix(C, R * 1.15 * lysN(vec3(0.0, 0.0, 1.0)), ridge * 0.7);
    float eave = smoothstep(1.0, 0.0, min(v, 1.0 - v) * (ax ? s.y : s.x));
    C *= 1.0 - 0.3 * eave;
    if (sn > 0.0) C = mix(C, vec3(0.9, 0.93, 0.97) * lysN(n), sn * smoothstep(0.2, 0.5, vn(p * 0.5) * 0.5 + 0.4 + ridge * 0.3));
    if (uWet > 0.0) C += SKY * 0.08 * uWet * pow(max(dot(n, normalize(vec3(0.0, -0.55, 1.0))), 0.0), 8.0);
    if (ty > 5.5) { vec2 ch = a + vec2(s.x * 0.72, s.y * 0.3); float cd = rb(p, ch - 1.2, ch + 1.2); C = mix(C, vec3(0.35, 0.3, 0.28) * lysN(vec3(0.0, 0.0, 1.0)), cv(cd)); }
  }
  return C;
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
  return smoothstep(r, r * 0.2, d) * step(0.42, h);
}
void telt(vec2 p, vec2 c, inout vec3 col){
  vec2 hz = vec2(6.0, 4.4), dp = p - c;
  if (abs(dp.x) > 12.0 || abs(dp.y) > 12.0) return;
  col *= 1.0 - 0.38 * (0.35 + 0.65 * SUNI) * cv(rb(p - SH * 3.2, c - hz, c + hz) - 0.4);
  col *= 1.0 - 0.15 * (1.0 - smoothstep(0.0, 2.5, rb(p, c - hz, c + hz)));
  vec2 q = p - OB * 3.2 - c;
  float d = rb(q, -hz, hz) - 0.35;
  if (d < 1.0) {
    float v = q.y / hz.y, sv = sign(v) * smoothstep(0.0, 0.14, abs(v));
    vec3 n = normalize(vec3(0.0, -0.95 * sv, 0.62));
    float st = step(0.5, fract((q.x + hz.x) / 2.0));
    vec3 A = mix(vec3(0.82, 0.13, 0.1), vec3(0.96, 0.94, 0.9), st) * (0.92 + 0.1 * vn(q * 2.0));
    vec3 C = A * lysN(n);
    C *= mix(1.0, 0.78, smoothstep(0.82, 1.0, abs(v)));
    C += vec3(1.0) * 0.1 * (1.0 - smoothstep(0.0, 0.1, abs(v))) * (AMB.r + SUNI * 0.5);
    if (uWet > 0.0) C += SKY * 0.1 * uWet * pow(max(dot(n, normalize(vec3(0.0, -0.55, 1.0))), 0.0), 6.0);
    if (uSnow > 0.0) C = mix(C, vec3(0.9, 0.93, 0.97) * lysN(n), uSnow * 0.75);
    col = mix(col, C, cv(d));
  }
  float r = length((p - c - vec2(0.0, hz.y + 1.5)) * vec2(0.6, 1.0));
  col += VARM * LYSV * N * 0.35 * exp(-r * r / 16.0);
}
void folk(vec2 p, vec2 pos, vec2 dir, float id, inout vec3 col){
  vec2 d0 = p - pos; if (dot(d0, d0) > 36.0) return;
  float um = step(0.5, uRain);
  float hgt = mix(1.5, 2.3, um), rr = mix(1.0, 2.25, um);
  col *= 1.0 - 0.38 * (0.35 + 0.65 * SUNI) * (1.0 - smoothstep(rr - 0.7, rr + 0.6, length(p - pos - SH * hgt * 1.1)));
  vec2 q = p - pos - OB * hgt;
  if (um > 0.5) {
    float l = length(q);
    if (l < 2.9) {
      float ang = atan(q.y, q.x) + id * 1.3, rib = abs(fract(ang / 0.7854) - 0.5) * 2.0;
      float h1 = hs(vec2(id, 1.0));
      vec3 uc = h1 < 0.45 ? vec3(0.1, 0.11, 0.13) : h1 < 0.7 ? vec3(0.72, 0.14, 0.12) : h1 < 0.85 ? vec3(0.16, 0.34, 0.55) : vec3(0.9, 0.72, 0.2);
      vec3 n = normalize(vec3(q.x / rr * 0.6, -q.y / rr * 0.6, 1.0));
      vec3 C = uc * lysN(n) * (0.82 + 0.25 * smoothstep(0.0, 0.6, rib));
      C += SKY * 0.18 * pow(max(n.z, 0.0), 6.0) + VARM * N * 0.08;
      col = mix(col, C, cv(l - rr));
    }
  } else {
    vec2 rt = vec2(-dir.y, dir.x), b = vec2(dot(q, dir), dot(q, rt));
    float body = (length(b / vec2(0.62, 1.05)) - 1.0) * 0.7;
    float h1 = hs(vec2(id, 3.0));
    vec3 cc = h1 < 0.4 ? vec3(0.14, 0.16, 0.2) : h1 < 0.7 ? vec3(0.5, 0.3, 0.2) : h1 < 0.85 ? vec3(0.62, 0.6, 0.55) : vec3(0.7, 0.2, 0.15);
    col = mix(col, cc * lysN(vec3(0.0, 0.0, 1.0)), cv(body));
    float hd = length(b - vec2(0.1, 0.0)) - 0.52;
    col = mix(col, mix(vec3(0.22, 0.15, 0.09), vec3(0.8, 0.66, 0.42), step(0.65, hs(vec2(id, 4.0)))) * lysN(vec3(0.0, 0.0, 1.0)), cv(hd));
  }
}
vec3 tm(vec3 c){ vec3 k = max(c - 0.64, 0.0); return min(c, 0.64) + 0.36 * (1.0 - exp(-k / 0.36)); }
void main(){
  vec2 p = (FlutterFragCoord().xy / uDpr);
  AA = 0.7 / uDpr; T = uT; N = uNight;
  LYSV = smoothstep(0.12, 0.42, N + uRain * 0.12);
  L = normalize(mix(vec3(-0.5, -0.42, 0.76), vec3(-0.84, -0.32, 0.44), N));
  SH = vec2(-L.x, L.y) / L.z * 0.85;
  SUNI = (1.0 - 0.82 * uRain) * (1.0 - 0.5 * uSnow);
  SUNC = mix(vec3(1.0, 0.95, 0.86), vec3(1.0, 0.7, 0.46), N) * mix(1.0, 0.92, N);
  AMB = mix(vec3(0.6, 0.65, 0.72), vec3(0.4, 0.44, 0.55), N);
  AMB = mix(AMB, vec3(0.84, 0.87, 0.9) * mix(1.0, 0.8, N), max(uRain, uSnow) * 0.7);
  SKY = mix(mix(vec3(0.62, 0.78, 0.9), vec3(0.78, 0.64, 0.62), N), vec3(0.62, 0.66, 0.69) * mix(1.0, 0.7, N), max(uRain, uSnow));
  BR[0] = vec4(284.0, 58.0, 316.0, 80.0); BH[0] = 13.0; BY[0] = 5.0;
  BR[1] = vec4(110.0, 26.0, 168.0, 88.0); BH[1] = 24.0; BY[1] = 1.0;
  BR[2] = vec4(18.0, 36.0, 90.0, 94.0); BH[2] = 18.0; BY[2] = 0.0;
  BR[3] = vec4(186.0, 112.0, 232.0, 148.0); BH[3] = 14.0; BY[3] = 2.0;
  BR[4] = vec4(38.0, 128.0, 92.0, 190.0); BH[4] = 20.0; BY[4] = 3.0;
  BR[5] = vec4(263.0, 186.0, 279.0, 238.0); BH[5] = 26.0; BY[5] = 0.0;
  BR[6] = vec4(18.0, 228.0, 80.0, 280.0); BH[6] = 18.0; BY[6] = 1.0;
  BR[7] = vec4(296.0, 258.0, 352.0, 316.0); BH[7] = 16.0; BY[7] = 1.0;
  BR[8] = vec4(54.0, 340.0, 82.0, 364.0); BH[8] = 9.0; BY[8] = 6.0;
  BR[9] = vec4(146.0, 310.0, 238.0, 366.0); BH[9] = 12.0; BY[9] = 2.0;
  BR[10] = vec4(16.0, 334.0, 46.0, 380.0); BH[10] = 12.0; BY[10] = 4.0;
  TR[0] = vec3(128.0, 216.0, 6.0); TR[1] = vec3(116.0, 240.0, 5.0); TR[2] = vec3(150.0, 228.0, 6.0); TR[3] = vec3(176.0, 214.0, 5.5);
  TR[4] = vec3(214.0, 228.0, 5.0); TR[5] = vec3(248.0, 236.0, 5.0); TR[6] = vec3(232.0, 278.0, 6.0); TR[7] = vec3(206.0, 292.0, 5.0);
  TR[8] = vec3(166.0, 293.0, 5.0); TR[9] = vec3(138.0, 279.0, 5.0); TR[10] = vec3(252.0, 258.0, 4.5); TR[11] = vec3(316.0, 382.0, 7.0);
  TR[12] = vec3(342.0, 404.0, 5.5); TR[13] = vec3(296.0, 404.0, 5.0); TR[14] = vec3(338.0, 368.0, 4.5); TR[15] = vec3(130.0, 125.0, 4.5);
  TR[16] = vec3(332.0, 86.0, 6.0); TR[17] = vec3(172.0, 140.0, 5.0); TR[18] = vec3(322.0, 150.0, 5.0); TR[19] = vec3(346.0, 202.0, 6.0); TR[20] = vec3(328.0, 232.0, 5.0);
  WA[0] = vec4(-6.0, 119.5, 186.0, 119.5); WM[0] = vec2(0.0, 2.1);
  WA[1] = vec4(186.0, 100.8, -6.0, 100.8); WM[1] = vec2(0.0, 1.8);
  WA[2] = vec4(108.3, -6.0, 108.3, 426.0); WM[2] = vec2(0.0, 2.0);
  WA[3] = vec4(108.3, 426.0, 108.3, -6.0); WM[3] = vec2(0.0, 1.7);
  WA[4] = vec4(-6.0, 308.0, 146.0, 308.0); WM[4] = vec2(1.0, 1.9);
  WA[5] = vec4(122.0, 128.0, 176.0, 190.0); WM[5] = vec2(1.0, 1.6);
  WA[6] = vec4(176.0, 79.5, 232.0, 79.5); WM[6] = vec2(1.0, 1.4);
  WA[7] = vec4(230.0, 48.0, 176.0, 48.0); WM[7] = vec2(1.0, 1.2);
  WA[8] = vec4(192.0, 262.0, 47.0, 26.0); WM[8] = vec2(2.0, 0.045);
  WA[9] = vec4(192.0, 262.0, 47.0, 26.0); WM[9] = vec2(2.0, -0.038);
  WA[10] = vec4(10.0, 218.5, 88.0, 217.0); WM[10] = vec2(1.0, 1.5);
  WA[11] = vec4(288.0, 400.0, 362.0, 380.0); WM[11] = vec2(1.0, 1.3);
  float bt = fract(T / 46.0); BDIR = normalize(vec2(1.0, 0.18)); BOAT = vec2(180.0, 8.0) + BDIR * bt * 230.0;
  vec2 uv = vec2(p.x / uRes.x, 1.0 - p.y / uRes.y);
  vec3 col = bakke(p, uv);
  if (p.y < 100.0) {
    baat(p, vec2(236.0, 36.0) + vec2(0.0, sin(T * 1.3) * 0.3), normalize(vec2(1.0, 0.32)), 1.0, vec3(0.86, 0.32, 0.22), col);
    baat(p, vec2(338.0, 54.0) + vec2(0.0, sin(T * 1.1 + 2.0) * 0.3), normalize(vec2(1.0, 0.2)), 0.9, vec3(0.2, 0.42, 0.55), col);
    if (texture(uA, FUV(uv)).b > 0.5) baat(p, BOAT, BDIR, 1.35, vec3(0.92, 0.93, 0.92), col);
  }
  if (abs(p.y - 110.0) < 20.0 && p.x < 200.0) { bil(p, vec2(mod(T * 14.0, 250.0) - 30.0, 107.4), vec2(1.0, 0.0), vec3(0.78, 0.2, 0.16), col); bil(p, vec2(205.0 - mod(T * 11.0 + 90.0, 250.0), 112.6), vec2(-1.0, 0.0), vec3(0.9, 0.9, 0.88), col); }
  if (abs(p.x - 100.0) < 20.0) { bil(p, vec2(97.4, mod(T * 16.0, 480.0) - 30.0), vec2(0.0, 1.0), vec3(0.2, 0.32, 0.5), col); bil(p, vec2(102.6, 450.0 - mod(T * 13.0 + 200.0, 480.0)), vec2(0.0, -1.0), vec3(0.16, 0.17, 0.18), col); }
  if (abs(p.y - 300.0) < 20.0 && p.x < 165.0) bil(p, vec2(mod(T * 12.0 + 40.0, 200.0) - 25.0, 297.6), vec2(1.0, 0.0), vec3(0.88, 0.7, 0.3), col);
  if (p.x < 192.0 && abs(p.y - 103.0) < 14.0) { float k = clamp(floor((p.x - 14.0) / 32.0 + 0.5), 0.0, 5.0); lyktHode(p, vec2(14.0 + 32.0 * k, 102.6), col); }
  if (abs(p.x - 94.0) < 10.0) { float k = floor((p.y - 14.0 + 4.0) / 32.0 + 0.5); lyktHode(p, vec2(92.6, 14.0 + 32.0 * k), col); }
  if (p.x < 162.0 && abs(p.y - 293.0) < 14.0) { float k = clamp(floor((p.x - 10.0) / 32.0 + 0.5), 0.0, 4.0); lyktHode(p, vec2(10.0 + 32.0 * k, 292.6), col); }
  for (int i = 0; i < 12; i++) {
    float fi = float(i); vec4 w = WA[i]; vec2 m = WM[i], pos, dir;
    if (m.x > 1.5) { float th = T * m.y + fi * 2.1; pos = w.xy + vec2(cos(th), sin(th)) * w.zw; dir = normalize(vec2(-sin(th) * w.z, cos(th) * w.w) * sign(m.y)); }
    else {
      vec2 a = w.xy, b = w.zw; float len = length(b - a);
      if (m.x > 0.5) { float t = fract(T * m.y / (2.0 * len) + hs(vec2(fi, 9.0))); pos = mix(a, b, 1.0 - abs(1.0 - 2.0 * t)); dir = normalize(b - a) * (t < 0.5 ? 1.0 : -1.0); }
      else { float t = fract(T * m.y / len + hs(vec2(fi, 9.0))); pos = mix(a, b, t); dir = normalize(b - a); }
    }
    pos += vec2(-dir.y, dir.x) * sin(T * 8.5 + fi * 3.0) * 0.12;
    folk(p, pos, dir, fi, col);
  }
  for (int i = 0; i < 11; i++) {
    vec2 a = BR[i].xy, b = BR[i].zw; float h = BH[i], ty = BY[i]; vec2 d = OB * h;
    float sd = hull(p, a, b, d);
    if (sd > 1.2) continue;
    float rs = rb(p - d, a, b), rm = cv(rs);
    vec3 C = tak(p - d, a, b, h, ty, float(i));
    if (rm < 0.999) C = mix(vegg(p, a, b, d, h, ty, float(i)), C, rm);
    C = mix(C, C * 0.7, (1.0 - smoothstep(0.0, 1.0, abs(rs))) * 0.6);
    col = mix(col, C, cv(sd));
  }
  if (p.x > 168.0 && p.x < 234.0 && p.y > 40.0 && p.y < 92.0) { telt(p, vec2(186.0, 58.0), col); telt(p, vec2(200.0, 58.0), col); telt(p, vec2(214.0, 58.0), col); telt(p, vec2(186.0, 71.0), col); telt(p, vec2(200.0, 71.0), col); telt(p, vec2(214.0, 71.0), col); }
  vec2 fF = vec2(192.0, 259.0), fT = fF + OB * 11.0, fe = fT - fF;
  float ft = sat(dot(p - fF, fe) / dot(fe, fe)), fd = length(p - fF - fe * ft);
  float spray = exp(-fd * fd / (0.5 + ft * 3.5)) * (0.55 + 0.45 * vn(vec2(fd * 3.0, ft * 9.0 - T * 6.0))) * smoothstep(1.0, 0.75, ft);
  col = mix(col, vec3(0.92, 0.96, 0.97) * (AMB + SUNC * SUNI * 0.6) + VARM * N * 0.15, sat(spray * 0.9 * (1.0 - uSnow)));
  for (int i = 0; i < 21; i++) {
    vec3 tr = TR[i]; float fi = float(i);
    vec2 c = tr.xy + OB * tr.z * 1.4 + vec2(sin(T * 0.83 + fi * 1.7) + 0.4 * sin(T * 2.1 + fi), cos(T * 0.67 + fi * 2.3)) * tr.z * 0.035, q = p - c; float r = tr.z;
    if (dot(q, q) > (r + 2.5) * (r + 2.5)) continue;
    float ang = atan(q.y, q.x);
    float lump = (vn(vec2(ang * 2.2 + fi * 7.0, fi + T * 0.1)) - 0.5) * 0.24 + (vn(q * 0.9 + fi) - 0.5) * 0.14;
    float sd = length(q) - r * (1.0 + lump);
    if (sd > 1.0) continue;
    vec2 e = q / r; float z = sqrt(max(1.0 - dot(e, e), 0.0));
    vec2 cl = q * 0.8 + fi * 3.1;
    vec3 n = normalize(vec3(e.x, -e.y, z * 0.9 + 0.12) + vec3(vn(cl + 1.7 + T * 0.35) - 0.5, vn(cl + 4.1 - T * 0.3) - 0.5, 0.0) * 0.9);
    float hk = hs(vec2(fi, 2.0));
    vec3 A = hk > 0.82 ? mix(vec3(0.75, 0.42, 0.12), vec3(0.85, 0.62, 0.18), hs(vec2(fi, 4.0))) : mix(vec3(0.15, 0.32, 0.15), vec3(0.28, 0.45, 0.2), hk);
    A *= 0.78 + 0.44 * vn(cl);
    vec3 Cc = A * lysN(n) * (0.7 + 0.3 * z);
    if (uSnow > 0.0) Cc = mix(Cc, vec3(0.9, 0.93, 0.97) * lysN(n), uSnow * smoothstep(0.55, 0.85, n.z) * 0.8);
    Cc *= 1.0 - 0.35 * smoothstep(-2.0, 0.0, sd) * step(0.0, -e.y * -1.0 + 0.2);
    col = mix(col, Cc, cv(sd));
  }
  vec2 cq = p * 0.0052 + vec2(T * 0.011, T * 0.004);
  float cl = fbm(cq + fbm(cq * 1.7) * 0.6), cd = smoothstep(0.55, 0.85, cl) * mix(0.26, 0.4, uRain);
  vec3 CC = mix(vec3(0.95, 0.96, 0.97), vec3(1.0, 0.82, 0.74), N * 0.7) * (0.75 + 0.3 * smoothstep(0.55, 0.9, cl));
  col = mix(col, CC, cd);
  if (uRain > 0.0) { float r = regn(p, 4.0, 380.0, 12.0, 1.0) * 0.3 + regn(p, 7.0, 560.0, 20.0, 7.0) * 0.45 + regn(p, 11.0, 760.0, 32.0, 13.0) * 0.55;
    col += vec3(0.75, 0.82, 0.86) * r * uRain * (0.22 + 0.25 * (1.0 - N)); }
  if (uSnow > 0.0) { float s = sno(p, 11.0, 18.0, 1.0) * 0.55 + sno(p, 19.0, 28.0, 5.0) * 0.8 + sno(p, 32.0, 44.0, 9.0);
    col = mix(col, vec3(0.95, 0.97, 1.0), sat(s) * uSnow); }
  col = mix(col, SKY * 0.92, smoothstep(0.3, 0.0, p.y / uRes.y) * 0.1);
  vec2 vq = p / uRes - 0.5;
  col *= 1.0 - 0.28 * smoothstep(0.38, 0.85, length(vq * vec2(1.05, 0.95)));
  col = tm(max(col * 1.12, 0.0)) + (hs(FlutterFragCoord().xy + fract(T * 7.0) * 91.0) - 0.5) * 0.016;
  fragColor = vec4(col, 1.0);
}
