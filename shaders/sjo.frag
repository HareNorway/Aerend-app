// Vågen water — 1:1 port of the `canvas[data-sjogl]` fragment shader in
// `Design-New/Ærend Kunde Launch.dc.html` (sjoGlInit). Gerstner-like wave
// sum with analytic anti-aliasing, rain rings, Fresnel reflection of the
// Bryggen texture, sky fallback and distance fog. Rendered offscreen into an
// image whose pixel grid is (uRes * uDpr), so FlutterFragCoord is the pixel.
// Tap ripples (uRip) and the boat wake (uDons) are left out: no screen that
// uses this shader yet drives them.
#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uRes;
uniform float uDpr;
uniform float uT;
uniform float uHz;
uniform float uF;
uniform float uZ0;
uniform float uAmp;
uniform float uSunPow;
uniform float uSunAmt;
uniform float uFogAmt;
uniform float uRegn;
uniform float uRefl;
uniform vec3 uDeep;
uniform vec3 uShal;
uniform vec3 uSkyHi;
uniform vec3 uSkyLo;
uniform vec3 uFog;
uniform vec3 uSun;
uniform vec3 uL;
uniform sampler2D uRef;

out vec4 fragColor;

float hs(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vn(vec2 p) {
  vec2 i = floor(p), f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hs(i), hs(i + vec2(1.0, 0.0)), f.x),
             mix(hs(i + vec2(0.0, 1.0)), hs(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main() {
  vec2 pix = FlutterFragCoord().xy;
  vec2 fc = pix / uDpr;
  // WebGL's gl_FragCoord is bottom-up; the prototype flips it to py.
  float px = fc.x, py = fc.y, cx = uRes.x * 0.5;
  float Hc = uZ0 * uHz / uF, dy = py + uHz;
  float z = Hc * uF / dy, x = (px - cx) * z / uF;
  float fx = z / uF / uDpr, fz = z * z / (Hc * uF) / uDpr;
  vec2 p = vec2(x, z), q = p, d = vec2(0.6442, 0.7648), g = vec2(0.0);
  float fr = 0.5, sp = 1.2, w = 1.0, sw = 0.0, h = 0.0, lost = 0.0;
  for (int i = 0; i < 24; i++) {
    float fp = abs(d.x) * fx + abs(d.y) * fz;
    float aa = clamp((6.2832 / fr / fp - 2.0) * 0.5, 0.0, 1.0);
    float ph = dot(d, q) * fr + uT * sp;
    float e = exp(sin(ph) - 1.0), de = e * cos(ph);
    h += e * w * aa;
    g += d * de * fr * w * aa;
    lost += w * (1.0 - aa);
    q -= d * de * w * 0.4 * aa;
    sw += w;
    w *= 0.8;
    fr *= 1.2;
    sp *= 1.095;
    d = vec2(d.x * -0.7374 - d.y * 0.6755, d.x * 0.6755 + d.y * -0.7374);
  }
  h /= sw;
  lost /= sw;
  float slick = 0.7 + 0.6 * vn(p * vec2(0.022, 0.13) + vec2(uT * 0.03, uT * 0.006));
  vec2 s = g / sw * uAmp * slick;
  if (uRegn > 0.0) {
    for (int l = 0; l < 2; l++) {
      float cs = 1.5 + float(l) * 0.7;
      float aaR = clamp((cs / max(fx, fz) - 7.0) * 0.2, 0.0, 1.0);
      if (aaR > 0.0) {
        vec2 gp = p / cs + float(l) * 0.37, id = floor(gp) + float(l) * 31.0, f = fract(gp) - 0.5;
        float r1 = hs(id), r2 = hs(id + 17.3), r3 = hs(id + 41.9);
        float ph = fract(uT * (0.32 + r1 * 0.25) + r1 * 7.0);
        vec2 dv = f - (vec2(r2, r3) - 0.5) * 0.36;
        float r = length(dv) + 1e-4, rad = ph * 0.34;
        float ring = sin((r - rad) * 62.0) * exp(-abs(r - rad) * 24.0) * (1.0 - ph) * (1.0 - ph);
        s += dv / r * ring * 0.2 * uRegn * aaR;
      }
    }
  }
  vec3 N = normalize(vec3(-s.x, 1.0, -s.y));
  vec3 V = normalize(vec3(x, -Hc, z));
  vec3 R = reflect(V, N);
  float ci = max(dot(N, -V), 0.0);
  float F = clamp(0.04 + 0.96 * pow(1.0 - ci, 5.0), 0.0, 1.0);
  float tz = max(uZ0 - z, 0.0) / max(R.z, 0.04);
  float ry = uF * max(R.y, 0.0) * tz / uZ0;
  float sx = cx + uF * (x + R.x * tz) / uZ0;
  float vv = ry / 200.0;
  vec3 refl = texture(uRef, vec2(clamp(sx / 390.0, 0.0, 1.0), clamp(vv, 0.0, 1.0))).rgb;
  vec3 sky = mix(uSkyLo, uSkyHi, smoothstep(0.03, 0.75, R.y / max(length(R.xz), 1e-3)));
  refl = mix(refl, sky, smoothstep(0.8, 1.5, vv));
  if (R.z < 0.04) refl = sky;
  float look = smoothstep(0.1, 0.9, ci);
  vec3 body = mix(uShal, uDeep, 0.45 + 0.55 * look);
  body += uShal * smoothstep(0.35, 0.9, h) * 0.26;
  body *= 1.0 + clamp(s.y * 1.3, -0.2, 0.25);
  vec3 col = mix(body, refl * uRefl, F);
  col += uSun * pow(max(dot(R, uL), 0.0), uSunPow) * uSunAmt * (1.0 - lost * 0.7);
  col = mix(col, uFog, smoothstep(uZ0 * 0.4, uZ0, z) * uFogAmt);
  col += (hs(pix + fract(uT * 7.0)) - 0.5) / 255.0;
  fragColor = vec4(col, 1.0);
}
