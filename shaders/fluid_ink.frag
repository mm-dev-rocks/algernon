#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// algernon_fluid_ink.frag
//
// Visualisation strategy: iterated domain warping builds curling ink-in-water
// tendrils. Each warp layer is driven by u_time at a different speed so the
// large structure and fine detail animate independently. FFT adds music
// reactivity on top of the continuous motion. Charge shifts colour temperature
// warm/cool across the whole field.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_warp  — TweakType.uniformWarpStrength (already exists)
//                     min: 0.1   max: 1.5   default: 0.7
//
//   u_countPrimary     — TweakType.uniformBandCount (already exists)
//                     min: 1.0   max: 4.0   default: 3.0   divisions: 3
//                     Number of warp iterations.
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 25.0
//
//   u_emphasis  — TweakType.uniformRingContrast (already exists)
//                     min: 0.3   max: 3.0   default: 1.4
//
// fftDataSmoothing — same as all other shaders.

vec3 hsv2rgb(float h, float s, float v) {
  h = mod(h, 360.0);
  float c = v * s;
  float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
  float m = v - c;
  vec3 rgb;
  if (h < 60.0)
    rgb = vec3(c, x, 0.0);
  else if (h < 120.0)
    rgb = vec3(x, c, 0.0);
  else if (h < 180.0)
    rgb = vec3(0.0, c, x);
  else if (h < 240.0)
    rgb = vec3(0.0, x, c);
  else if (h < 300.0)
    rgb = vec3(x, 0.0, c);
  else
    rgb = vec3(c, 0.0, x);
  return rgb + m;
}

vec2 sampleBin(float binIndex) {
  float u = clamp((binIndex + 0.5) / 256.0, 0.0, 1.0);
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

vec2 rot2d(vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Warp displacement for one layer. timeOffset gives each layer its own speed
// so they don't all move together.
vec2 warpDisplace(vec2 p, float bandLow, float timeOffset, float strength) {
  vec2 fc = sampleBin(bandLow);
  float mag = fc.x;
  float charge = fc.y;
  float freq = 2.5 + mag * 1.0; // was 3.0
  // float angle = timeOffset + charge * 0.05; // was 0.2
  float angle = timeOffset; // was 0.2

  vec2 pRot = rot2d(p, angle);
  float wx = sin(pRot.x * freq + timeOffset) *
             cos(pRot.y * freq * 0.7 + timeOffset * 1.3);
  float wy = cos(pRot.x * freq * 0.8 - timeOffset * 0.9) *
             sin(pRot.y * freq * 1.1 + timeOffset * 0.6);

  // return vec2(wx, wy) * strength * (0.5 + mag * 0.3); // was 0.8
  return vec2(wx, wy) * strength * (0.5 + mag * 0.1);
}

float inkField(vec2 p) {
  float v = 0.0;
  float amp = 1.0;
  float freq = 1.0;
  for (int i = 0; i < 5; i++) {
    v += sin(p.x * freq + p.y * freq * 0.7) * amp;
    p = rot2d(p, 0.2);
    freq *= 1.4;
    amp *= 0.55;
  }
  return v;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float asp = u_resolution.x / u_resolution.y;
  vec2 p = (st - 0.5) * vec2(asp, 1.0);

  vec2 fcBass = sampleBin(6.0);
  vec2 fcMid = sampleBin(64.0);
  vec2 fcHigh = sampleBin(180.0);

  // Each layer gets a different time speed so structure and detail
  // animate at different rates. FFT energy adds music reactivity on top.
  // float bassPhase = u_time * 0.3 + fcBass.x * 0.3 + fcBass.y * 0.1;
  // float midPhase = u_time * 0.5 + fcMid.x * 0.2 + fcMid.y * 0.05;
  // float highPhase = u_time * 0.8 + fcHigh.x * 0.1 + fcHigh.y * 0.02;
  float bassPhase = u_time * 0.3;
  float midPhase = u_time * 0.5;
  float highPhase = u_time * 0.8;

  int nLayers = int(clamp(u_countPrimary, 1.0, 4.0));
  vec2 wp = p;

  // if (nLayers >= 1)
  //   wp += warpDisplace(wp, 8.0, bassPhase, u_warp * 0.50);
  // if (nLayers >= 2)
  //   wp += warpDisplace(wp, 48.0, midPhase, u_warp * 0.30);
  // if (nLayers >= 3)
  //   wp += warpDisplace(wp, 120.0, highPhase, u_warp * 0.15);
  // if (nLayers >= 4)
  //   wp += warpDisplace(wp, 200.0, highPhase * 1.7, u_warp * 0.07);
  // if (nLayers >= 1)
  //  wp += warpDisplace(wp, 8.0, bassPhase, u_warp * 0.20);
  // if (nLayers >= 2)
  //  wp += warpDisplace(wp, 48.0, midPhase, u_warp * 0.12);
  // if (nLayers >= 3)
  //  wp += warpDisplace(wp, 120.0, highPhase, u_warp * 0.06);
  // if (nLayers >= 4)
  // wp += warpDisplace(wp, 200.0, highPhase * 1.7, u_warp * 0.03);

  if (nLayers >= 1)
    wp += warpDisplace(wp, 8.0, bassPhase, u_warp * (0.20 + fcBass.x * 0.15));
  if (nLayers >= 2)
    wp += warpDisplace(wp, 48.0, midPhase, u_warp * (0.12 + fcMid.x * 0.10));
  if (nLayers >= 3)
    wp += warpDisplace(wp, 120.0, highPhase, u_warp * (0.06 + fcHigh.x * 0.06));
  if (nLayers >= 4)
    wp += warpDisplace(wp, 200.0, highPhase * 1.7,
                       u_warp * (0.03 + fcHigh.x * 0.03));

  float ink = inkField(wp * 2.5);
  // float brightness = pow(clamp(ink * 0.5 + 0.5, 0.0, 1.0), u_emphasis);
  // float brightness = pow(clamp(ink * 0.5 + 0.5, 0.0, 1.0), u_emphasis);
  // float fade = smoothstep(0.0, 0.4, brightness);
  // brightness = mix(0.1, brightness, fade);

  float brightness = pow(clamp(ink * 0.8 + 0.5, 0.0, 1.0), u_emphasis);
  // float brightness = pow(clamp(ink * 0.5 + 0.5, 0.0, 1.0), u_emphasis);
  // brightness = max(brightness, 0.15); // lift black floor

  float globalCharge = 0.0;
  for (int b = 0; b < 6; b++)
    globalCharge += sampleBin(float(b) * 10.0).y;
  globalCharge /= 6.0;

  float localBin = clamp((wp.x * 0.5 + 0.5) * 200.0, 0.0, 255.0);
  vec2 fcLocal = sampleBin(localBin);
  float chargeBlend = clamp(globalCharge * 0.5 + fcLocal.y * 0.5, -1.0, 1.0);

  // float hue = mix(u_hueShift + 160.0, u_hueShift, chargeBlend * 0.5 + 0.5);
  // float sat = 0.7 + brightness * 0.3;
  // float val = clamp(brightness * 1.3 + 0.05, 0.0, 1.0);
  // float hue2 = hue + fcMid.x * 40.0 * sign(chargeBlend);
  float darknesss = 1.0 - brightness;
  float hueOffset = darknesss * 180.0; // complementary hue in dark regions
  float hue = mix(u_hueShift + 160.0, u_hueShift, chargeBlend * 0.5 + 0.5);
  float sat = 0.7 + brightness * 0.3;
  // float val = clamp(brightness * 0.8 + 0.25, 0.0, 1.0); // never goes below
  // 0.25
  float val = mix(0.6, 1.0, brightness);
  float hue2 = hue + hueOffset + fcMid.x * 40.0 * sign(chargeBlend);

  // vec3 finalCol = mix(hsv2rgb(hue, sat, val),
  // hsv2rgb(hue2, sat * 0.8, val * 0.8), fcLocal.x * 0.4);
  vec3 finalCol = mix(hsv2rgb(hue, sat, val),
                      hsv2rgb(hue2, sat * 0.8, val * 0.8), fcLocal.x * 0.4);

  finalCol = pow(finalCol, vec3(u_emphasis));

  fragColor = vec4(finalCol, 1.0);
}
