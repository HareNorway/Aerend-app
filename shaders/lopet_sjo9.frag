// Design (9) 1:1 plan D2: the play field's water, a line-by-line port of the design's `FS` (Fjordlopet.dc.html in
// designs/21nov-kunde/proto, Kunde Bergen (9)): «the same water as Vågen on Home, seen from above» — 18 exponential sine
// waves with antialiasing, the Vågen colours per sea mode, sky reflection, sun glitter, caustics in the shallows, cloud
// shadows (Dag, High), rain rings, ripples, the lane seams, the lap at the quay wall, the boat's V wake from its track,
// foam round each object, and the foam map. Scroll arrives as phases (uPh) and remainders (uZs, uZr), so the water
// never shimmers after kilometres.
//
// Differences from the WebGL source, none visible: Flutter's coordinates start top left (no y flip), and the float
// arrays are packed in vec4s (uPh4 = uPh[18], uTr4 = uTr[8]).
#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uR;        // the offscreen image (px)
uniform vec2 uOf;       // shake offset (field px)
uniform float uS;       // image px per field px
uniform float uT;
uniform float uM;       // zoom: field px per metre
uniform float uBy;      // the boat's row (field px)
uniform float uV;       // speed share 0–1
uniform float uW;
uniform float uH;
uniform float uE;       // quay edge (field px)
uniform float uRegn;
uniform float uFr;
uniform float uBaat;
uniform float uDod;
uniform float uKjA;
uniform float uKau;
uniform float uAmp;
uniform float uRefl;
uniform float uSunPow;
uniform float uSunAmt;
uniform float uLw;
uniform float uCs;
uniform vec3 uKj;
uniform vec3 uDeep;
uniform vec3 uShal;
uniform vec3 uSkyHi;
uniform vec3 uSkyLo;
uniform vec3 uSun;
uniform vec3 uL;
uniform vec3 uGrunn;
uniform vec3 uMur;
uniform vec3 uSkum;
uniform vec3 uLX;
uniform vec2 uZr;
uniform vec4 uZs;
// No uniform arrays: under Impeller their layout differed and the object list read other uniforms (giant foam
// outlines on the water, 2026-11-24). The same floats in the same order, one vec4 each.
uniform vec4 uTrA;
uniform vec4 uTrB;
uniform vec4 uPhA;
uniform vec4 uPhB;
uniform vec4 uPhC;
uniform vec4 uPhD;
uniform vec4 uPhE;
uniform vec4 uO0;
uniform vec4 uO1;
uniform vec4 uO2;
uniform vec4 uO3;
uniform vec4 uO4;
uniform vec4 uO5;
uniform vec4 uO6;
uniform vec4 uO7;
uniform vec4 uO8;
uniform vec4 uO9;
uniform vec4 uO10;
uniform vec4 uO11;
uniform vec4 uRp0;
uniform vec4 uRp1;
uniform vec4 uRp2;
uniform vec4 uRp3;
uniform vec4 uRp4;
uniform vec4 uRp5;
uniform vec4 uRp6;
uniform vec4 uRp7;
uniform sampler2D uSk;

out vec4 fragColor;

float ss(float a, float b, float x) { float t = clamp((x - a) / (b - a), 0., 1.); return t * t * (3. - 2. * t); }
float hs(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnP(vec2 p, float per) {
  vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  float y0 = mod(i.y, per), y1 = mod(i.y + 1., per);
  return mix(mix(hs(vec2(i.x, y0)), hs(vec2(i.x + 1., y0)), f.x), mix(hs(vec2(i.x, y1)), hs(vec2(i.x + 1., y1)), f.x), f.y);
}
float kau(vec2 p, float t) {
  vec2 q = mod(p * 6.2831853, 6.2831853) - 250.; vec2 i = q; float c = 1.;
  for (int n = 0; n < 4; n++) {
    float tt = t * (1. - (3.5 / float(n + 1)));
    i = q + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
    c += 1. / length(vec2(q.x / (sin(i.x + tt) / .005), q.y / (cos(i.y + tt) / .005)));
  }
  c /= 4.; c = 1.17 - pow(c, 1.4); return pow(abs(c), 8.);
}
float sdb(vec2 p, vec2 b) { float r = min(b.x, b.y); vec2 q = abs(p) - b + r; return length(max(q, 0.)) + min(max(q.x, q.y), 0.) - r; }
// One wave of the sum (the design's loop body); called 18 times with the phases in order (SkSL indexes uniform arrays
// only by a loop index, so the packed phases are read component by component).
void wave(float phs, float fp0, inout vec2 q, inout vec2 d, inout vec2 g, inout float fr, inout float sp, inout float w,
          inout float sw, inout float h, inout float lost) {
  float fp = (abs(d.x) + abs(d.y)) * fp0;
  float aa = clamp((6.2832 / fr / fp - 2.) * .5, 0., 1.);
  float p = dot(d, q) * fr + phs + uT * sp;
  float e = exp(sin(p) - 1.), de = e * cos(p);
  h += e * w * aa; g += d * de * fr * w * aa; lost += w * (1. - aa); q -= d * de * w * .4 * aa;
  sw += w; w *= .8; fr *= 1.2; sp *= 1.095;
  d = vec2(d.x * -.7374 - d.y * .6755, d.x * .6755 + d.y * -.7374);
}

vec2 rip(vec4 R, float xm, float zl) {
  if (R.w <= 0.) return vec2(0.);
  vec2 dv = vec2(xm, zl) - R.xy; float r = length(dv) + 1e-4, rad = R.z * 2.6;
  float env = exp(-pow((r - rad) * 1.1, 2.)) * exp(-R.z * 1.3) * R.w;
  return dv / r * cos((r - rad) * 5.5) * env * .35;
}
// Foam round one object (x, y, half width, half height); .z = 0 means none.
void obj(vec4 o, vec2 px, float fn, float t, inout float foam, inout float sk) {
  if (o.z <= 0.) return;
  float dd = sdb(px - o.xy, o.zw);
  foam += ss(6., 1.2, dd) * ss(-3., 0., dd) * (.5 + .5 * fn);
  foam += ss(26., 7., dd) * ss(1., 6., dd) * (.5 + .5 * sin(dd * .5 - t * 4.5)) * .18;
  sk = max(sk, ss(8., -4., sdb(px - o.xy - vec2(5., 7.), o.zw)) * .8);
}

void main() {
  vec2 px = FlutterFragCoord().xy / uS - uOf;
  float xm = (px.x - uW * .5) / uM, zl = (uBy - px.y) / uM, t = uT, fp0 = 1. / (uM * uS), zz = uZs.y + zl, zf = uZs.x + zl;
  float dpx = min(px.x - uE, uW - uE - px.x);
  float dl = min(min(abs(px.x - uLX.x), abs(px.x - uLX.y)), abs(px.x - uLX.z));
  float calm = 1. - .3 * exp(-dl * dl / (uLw * uLw * .07));
  vec2 q = vec2(xm, zl), d = vec2(.6442, .7648), g = vec2(0.);
  float fr = .34, sp = 1.2, w = 1., sw = 0., h = 0., lost = 0.;
  wave(uPhA.x, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhA.y, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhA.z, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhA.w, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhB.x, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhB.y, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhB.z, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhB.w, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhC.x, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhC.y, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhC.z, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhC.w, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhD.x, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhD.y, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhD.z, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhD.w, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhE.x, fp0, q, d, g, fr, sp, w, sw, h, lost);
  wave(uPhE.y, fp0, q, d, g, fr, sp, w, sw, h, lost);
  h /= sw; lost /= sw;
  float slick = .7 + .6 * vnP(vec2(xm * .034, zz * .125), 125.);
  vec2 s = g / sw * uAmp * slick * calm;
  if (uRegn > 0.) {
    for (int l = 0; l < 2; l++) {
      float cs = 1.2 + float(l) * .55; float zr = (l == 0 ? uZr.x : uZr.y) + zl;
      vec2 gp = vec2(xm, zr) / cs + float(l) * .37; vec2 id = floor(gp); id.y = mod(id.y, 64.); id += float(l) * 31.;
      vec2 f = fract(gp) - .5; float r1 = hs(id), r2 = hs(id + 17.3), r3 = hs(id + 41.9);
      float rp = fract(t * (.32 + r1 * .25) + r1 * 7.); vec2 dv = f - (vec2(r2, r3) - .5) * .36;
      float r = length(dv) + 1e-4, rad = rp * .34;
      float ring = sin((r - rad) * 62.) * exp(-abs(r - rad) * 24.) * (1. - rp) * (1. - rp);
      s += dv / r * ring * .2 * uRegn;
    }
  }
  s += rip(uRp0, xm, zl);
  s += rip(uRp1, xm, zl);
  s += rip(uRp2, xm, zl);
  s += rip(uRp3, xm, zl);
  s += rip(uRp4, xm, zl);
  s += rip(uRp5, xm, zl);
  s += rip(uRp6, xm, zl);
  s += rip(uRp7, xm, zl);
  vec3 N = normalize(vec3(-s.x, 1., -s.y));
  vec3 V = normalize(vec3((px.x - uW * .5) / uW * .4, -1., .45 + .5 * (1. - px.y / uH)));
  vec3 Rf = reflect(V, N); float ci = max(dot(N, -V), 0.);
  float F = clamp(.04 + .96 * pow(1. - ci, 5.), 0., 1.);
  vec3 sky = mix(uSkyLo, uSkyHi, ss(.03, .75, Rf.y / max(length(Rf.xz), 1e-3)));
  float look = ss(.1, .9, ci);
  vec3 body = mix(uShal, uDeep, .45 + .55 * look); body += uShal * ss(.35, .9, h) * .26; body *= 1. + clamp(s.y * 1.3, -.2, .25);
  float gr = 1. - ss(0., uE * 2.6, dpx); body = mix(body, uGrunn, gr * .62);
  vec3 col = mix(body, sky * uRefl, F);
  col += uSun * pow(max(dot(Rf, uL), 0.), uSunPow) * uSunAmt * (1. - lost * .7);
  col += uGrunn * kau(vec2(xm, uZs.z + zl) / 12. + vec2(t * .012, 0.), t * .6) * uKau * gr * gr;
  if (uCs > 0.) {
    float cl = vnP(vec2(xm * .014 + t * .012, zz * .014), 14.) * .65 + vnP(vec2(xm * .031 - t * .008, zz * .028), 28.) * .35;
    col *= 1. - uCs * .24 * ss(.48, .72, cl);
  }
  float fn = vnP(vec2(xm * 1.5, zf * 1.5), 192.) * .6 + vnP(vec2(xm * 3., zf * 3.), 384.) * .4, foam = 0., sk = 0., wk = 0.;
  float lap = 2. + 1.6 * sin(t * 1.3 + zz * .35186);
  foam += ss(lap + 4., lap - 1., dpx) * (.35 + .55 * ss(.3, .6, fn));
  foam += ss(2.2, 0., abs(dpx - (11. + 4. * sin(t * .8 + zz * .21991)))) * .22 * fn;
  sk = max(sk, ss(uE * .75, 0., dpx) * .5);
  col = mix(col, uMur, ss(uE * .6, 0., dpx + s.x * 18.) * .3);
  float xb1 = (uLX.x + uLX.y) * .5, xb2 = (uLX.y + uLX.z) * .5;
  foam += ss(1.8, .2, abs(px.x - xb1)) * ss(.4, .62, vnP(vec2(3., zz * .75), 750.)) * .48;
  foam += ss(1.8, .2, abs(px.x - xb2)) * ss(.4, .62, vnP(vec2(11., zz * .75), 750.)) * .48;
  foam += uV * .42 * ss(.74, .92, vnP(vec2(xm * 2.2, zz * .125), 125.)) * ss(0., 30., dpx);
  float sb = (px.y - uBy) / uM - 1.5; float wl = 15. + 15. * uV;
  if (uBaat > 0. && sb > 0. && sb < wl) {
    float u = sb / 2.2; float fi = u < uFr ? u / max(uFr, .001) : u - uFr + 1.;
    vec4 ta = uTrA, tb = uTrB;
    float tx = ta.x;
    tx = mix(tx, ta.y, clamp(fi, 0., 1.)); tx = mix(tx, ta.z, clamp(fi - 1., 0., 1.)); tx = mix(tx, ta.w, clamp(fi - 2., 0., 1.));
    tx = mix(tx, tb.x, clamp(fi - 3., 0., 1.)); tx = mix(tx, tb.y, clamp(fi - 4., 0., 1.)); tx = mix(tx, tb.z, clamp(fi - 5., 0., 1.));
    tx = mix(tx, tb.w, clamp(fi - 6., 0., 1.));
    float dx = abs(px.x - tx) / uM, hb = .45 + sb * .33;
    float arm = ss(.75, 0., abs(dx - hb)) * ss(wl, 2., sb);
    float kj = ss(hb * .85, 0., dx) * ss(6. + 6. * uV, 0., sb);
    wk = (arm * ss(.2, .55, fn + arm * .35) * 1.1 + kj * ss(.25, .55, fn + kj * .3)) * (.7 + .4 * uV) * uBaat * ss(70., 14., abs(tx - ta.x));
  }
  obj(uO0, px, fn, t, foam, sk);
  obj(uO1, px, fn, t, foam, sk);
  obj(uO2, px, fn, t, foam, sk);
  obj(uO3, px, fn, t, foam, sk);
  obj(uO4, px, fn, t, foam, sk);
  obj(uO5, px, fn, t, foam, sk);
  obj(uO6, px, fn, t, foam, sk);
  obj(uO7, px, fn, t, foam, sk);
  obj(uO8, px, fn, t, foam, sk);
  obj(uO9, px, fn, t, foam, sk);
  obj(uO10, px, fn, t, foam, sk);
  obj(uO11, px, fn, t, foam, sk);
  // The foam map is stored top-down: row 0 is the far end of its 128 m loop (the design's texture is bottom-up).
  float fm = texture(uSk, vec2(px.x / uW, 1. - fract(zf / 128.))).r;
  foam += fm * (.45 + .75 * fn);
  col *= 1. - .34 * sk;
  col = mix(col, uSkum, clamp(foam + wk * (1. - uKjA), 0., 1.) * .9);
  col = mix(col, uKj, clamp(wk, 0., 1.) * .92 * uKjA);
  if (dpx < 0.) col = mix(col, uMur * .8, ss(0., -2., dpx));
  vec2 vq = px / vec2(uW, uH) - .5;
  col *= 1. - .22 * ss(.45, .95, length(vq * vec2(1.15, 1.)));
  col = mix(col, vec3(dot(col, vec3(.3, .59, .11))) * .85, uDod * .45);
  col += (hs(FlutterFragCoord().xy + fract(t * 7.)) - .5) / 255.;
  fragColor = vec4(col, 1.);
}
