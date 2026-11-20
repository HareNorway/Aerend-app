// Fjordløpet v1.3 plan Step 9 (spec §12.2 layer 1, §12.5, §12.6): Vågen seen from above.
//
// Drawn into a smaller offscreen image (0.75 of the field at High, 0.5 at Medium) and scaled up. Deep water in the
// middle and shallow towards the banks, with caustics only in the shallows; a long swell and a small chop that do not
// flicker; sky tint and sun glitter; rain rings in Regn; the lanes as calmer strips; and the foam map (wakes, rings,
// splashes stamped by the painter) laid on top.
//
// The scroll offset arrives modulo uPeriod, and every term that depends on y repeats over uPeriod (whole multiples of
// 2π/uPeriod), so the water never jumps and never shimmers on low-precision GPUs. The foam map is sampled inside
// [0, 1] (samplers clamp; nothing repeats through the sampler). The output is opaque, so it is premultiplied as is.
#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;      // 0, 1  the offscreen image (px)
uniform float uScroll;   // 2     metres flowed past, in px of this image, modulo uPeriod
uniform float uT;        // 3     seconds, modulo 600
uniform float uPeriod;   // 4     the pattern's length in y (px of this image)
uniform float uBank;     // 5     the bank's width on each side (px of this image)
uniform float uLaneW;    // 6     one lane (px); lanes centred at 0.24, 0.5 and 0.76 of the width
uniform float uDetail;   // 7     1 = High, 0.67 = Medium
uniform float uGlitter;  // 8     sun glitter (Dag 1, Kveld 0.35, Regn 0)
uniform float uRegn;     // 9     rain rings (0 or 1)
uniform float uFoamOn;   // 10    the foam map is sampled (High and Medium)
uniform vec3 uDeep;      // 11–13
uniform vec3 uShal;      // 14–16
uniform vec3 uSkyHi;     // 17–19
uniform vec3 uSun;       // 20–22
uniform vec3 uMist;      // 23–25
uniform float uMistA;    // 26
uniform sampler2D uFoam; // the foam map, the size of the field

out vec4 fragColor;

const float TAU = 6.2831853;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
  vec2 px = FlutterFragCoord().xy;
  float y = px.y - uScroll;              // water coordinates: the pattern moves down as the boat sails
  float wy = y * (TAU / uPeriod);        // one turn per period
  float x = px.x;

  // Deep in the middle, shallow towards the banks.
  float edge = min(x, uSize.x - x);
  float shallow = 1.0 - smoothstep(uBank, uBank + uSize.x * 0.22, edge);

  // The long swell (two whole-period waves) and the chop (more of them at High).
  float swell = sin(wy * 2.0 + x * 0.012 + uT * 0.45) * 0.5 + sin(wy * 3.0 - x * 0.02 + uT * 0.3) * 0.3;
  float chop = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 4; i++) {
    if (float(i) >= 1.0 + 3.0 * uDetail) break;
    float k = 7.0 + float(i) * 6.0;
    chop += amp * sin(wy * k + x * (0.08 + 0.05 * float(i)) + uT * (1.3 + 0.4 * float(i)) + swell);
    amp *= 0.55;
  }

  // The lanes read as calmer strips: less chop on the lane centres.
  float lx = abs(fract((x - uSize.x * 0.24) / uLaneW + 0.5) - 0.5);
  float calm = mix(0.55, 1.0, smoothstep(0.12, 0.42, lx));

  vec3 col = mix(uDeep, uShal, clamp(shallow * 0.85 + swell * 0.06, 0.0, 1.0));
  col += vec3(0.035) * chop * calm;

  // Sky tint where the surface faces it.
  col = mix(col, uSkyHi, clamp(0.08 + 0.05 * swell + 0.04 * chop, 0.0, 0.2));

  // Caustics only in the shallows: a light net.
  if (shallow > 0.02) {
    vec2 q = vec2(x * 0.045, wy * 9.0 / TAU * 1.0);
    float n = abs(sin(q.x * 1.7 + sin(wy * 9.0 + uT * 0.8))) * abs(sin(wy * 9.0 + sin(q.x * 1.3 - uT * 0.6)));
    col += uSun * pow(1.0 - n, 6.0) * 0.18 * shallow;
  }

  // Sun glitter: sparse cells that blink, more at High.
  if (uGlitter > 0.0) {
    vec2 cell = floor(vec2(x / 7.0, (y - floor(y / uPeriod) * uPeriod) / 7.0));
    float h = hash(cell);
    float tw = sin(uT * (3.0 + h * 4.0) + h * 40.0);
    float g = step(0.985 - 0.01 * uDetail, h) * smoothstep(0.6, 1.0, tw) * (0.5 + 0.5 * chop);
    col += uSun * g * 0.55 * uGlitter;
  }

  // Rain rings in Regn.
  if (uRegn > 0.0) {
    vec2 cell = floor(vec2(x / 46.0, (y - floor(y / uPeriod) * uPeriod) / 46.0));
    vec2 centre = (cell + vec2(hash(cell), hash(cell + 7.1))) * 46.0;
    float age = fract(uT * 0.7 + hash(cell + 3.3));
    float r = length(vec2(x, (y - floor(y / uPeriod) * uPeriod)) - centre);
    float ring = smoothstep(1.4, 0.0, abs(r - age * 18.0)) * (1.0 - age);
    col += vec3(0.16) * ring;
  }

  // The foam map: wakes, bow waves, rings and splashes.
  if (uFoamOn > 0.0) {
    vec2 uv = clamp(px / uSize, vec2(0.0), vec2(1.0));
    float f = texture(uFoam, uv).a;
    col = mix(col, vec3(0.95, 0.97, 0.97), clamp(f * 0.75, 0.0, 0.75));
  }

  // Mist over all.
  col = mix(col, uMist, uMistA * 0.5);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
