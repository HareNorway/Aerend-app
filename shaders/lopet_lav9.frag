// Design (9) 1:1 plan D2: the play field's water at Lav, a port of the design's `LAV_FS`: a ready-made 256 × 256 water
// texture (seamless, made per sea mode at session open, the design's `lavTex`) in two layers scrolling at different
// speeds, the shallows by the quay, the lap, the lane seams, the boat's V wake from its track, foam round each object,
// the quay wall and the vignette. No foam map. Flutter's coordinates start top left; the texture repeats via fract().
#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uR;
uniform vec2 uOf;
uniform float uS;
uniform float uT;
uniform float uM;
uniform float uBy;
uniform float uV;
uniform float uW;
uniform float uH;
uniform float uE;
uniform float uFr;
uniform float uBaat;
uniform float uDod;
uniform float uZ;
uniform vec3 uGrunn;
uniform vec3 uMur;
uniform vec3 uSkum;
uniform vec3 uLX;
uniform vec4 uTr4[2];
uniform vec4 uO[12];
uniform sampler2D uTx;

out vec4 fragColor;

float ss(float a, float b, float x) { float t = clamp((x - a) / (b - a), 0., 1.); return t * t * (3. - 2. * t); }
float sdb(vec2 p, vec2 b) { float r = min(b.x, b.y); vec2 q = abs(p) - b + r; return length(max(q, 0.)) + min(max(q.x, q.y), 0.) - r; }

void main() {
  vec2 px = FlutterFragCoord().xy / uS - uOf;
  float xm = (px.x - uW * .5) / uM, zz = uZ + (uBy - px.y) / uM;
  vec3 a = texture(uTx, fract(vec2(xm / 32. + uT * .006, -zz / 32.))).rgb;
  vec3 b = texture(uTx, fract(vec2(.37 - xm / 16., uT * .03 - zz / 16.))).rgb;
  vec3 col = mix(a, b, .4);
  float dpx = min(px.x - uE, uW - uE - px.x), gr = 1. - ss(0., uE * 2.6, dpx);
  col = mix(col, uGrunn, gr * .55);
  float foam = ss(5., 0., dpx) * .65 + ss(2., 0., abs(dpx - 10.)) * .18;
  float xb1 = (uLX.x + uLX.y) * .5, xb2 = (uLX.y + uLX.z) * .5;
  foam += (ss(1.6, .2, abs(px.x - xb1)) + ss(1.6, .2, abs(px.x - xb2))) * .4 * step(.45, fract(zz * .25));
  float sb = (px.y - uBy) / uM - 1.5, wl = 15. + 15. * uV;
  if (uBaat > 0. && sb > 0. && sb < wl) {
    float u = sb / 2.2; float fi = u < uFr ? u / max(uFr, .001) : u - uFr + 1.;
    vec4 ta = uTr4[0], tb = uTr4[1];
    float tx = ta.x;
    tx = mix(tx, ta.y, clamp(fi, 0., 1.)); tx = mix(tx, ta.z, clamp(fi - 1., 0., 1.)); tx = mix(tx, ta.w, clamp(fi - 2., 0., 1.));
    tx = mix(tx, tb.x, clamp(fi - 3., 0., 1.)); tx = mix(tx, tb.y, clamp(fi - 4., 0., 1.)); tx = mix(tx, tb.z, clamp(fi - 5., 0., 1.));
    tx = mix(tx, tb.w, clamp(fi - 6., 0., 1.));
    float dx = abs(px.x - tx) / uM, hb = .45 + sb * .33;
    foam += (ss(.75, 0., abs(dx - hb)) * ss(wl, 2., sb) + ss(hb * .85, 0., dx) * ss(8., 0., sb) * .6) * .8 * uBaat;
  }
  float sk = 0.;
  for (int i = 0; i < 12; i++) {
    vec4 o = uO[i];
    if (o.z > 0.) {
      float dd = sdb(px - o.xy, o.zw);
      foam += ss(5., 1., dd) * ss(-3., 0., dd) * .6;
      sk = max(sk, ss(8., -4., sdb(px - o.xy - vec2(5., 7.), o.zw)) * .8);
    }
  }
  col *= 1. - .3 * sk;
  col = mix(col, uSkum, clamp(foam, 0., 1.) * .85);
  if (dpx < 0.) col = mix(col, uMur * .8, ss(0., -2., dpx));
  vec2 vq = px / vec2(uW, uH) - .5;
  col *= 1. - .22 * ss(.45, .95, length(vq * vec2(1.15, 1.)));
  col = mix(col, vec3(dot(col, vec3(.3, .59, .11))) * .85, uDod * .45);
  fragColor = vec4(col, 1.);
}
