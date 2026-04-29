#version 460 core
#include <flutter/runtime_effect.glsl>
// algernon_root_system.frag
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_countPrimary      — TweakType.uniformArmCount (already exists)
//                     min: 3.0   max: 12.0   default: 6.0   divisions: 9
//
//   u_countSecondary   — TweakType.uniformBranchDepth (NEW enum value needed)
//                     min: 1.0   max: 3.0   default: 2.0   divisions: 2
//                     1 = arms only, 2 = +sub-branches, 3 = +sub-sub-branches
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 30.0
//
//   u_warp      — TweakType.uniformMaxTwist (already exists)
//                     min: 0.1   max: 2.5   default: 1.2
//
// fftDataSmoothing — same as all other shaders.

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_fftData;

uniform float u_energyMin;
uniform float u_energyMax;

uniform float u_countPrimary;
uniform float u_emphasis;
uniform float u_zoom;
uniform float u_countSecondary;
uniform float u_hueShift;
uniform float u_warp;

out vec4 fragColor;

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

float hash(float n) { return fract(sin(n) * 43758.5453123); }

float lineSDF(vec2 p, vec2 a, vec2 b, float width) {
  vec2 ab = b - a;
  vec2 ap = p - a;
  float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
  float dist = length(ap - ab * t);
  return 1.0 - smoothstep(0.0, width, dist);
}

float armSway(float fi, float t) {
  float slowSway = sin(u_time * 0.7 + fi * 1.37 + t * 1.1) * 0.6 +
                   sin(u_time * 0.3 + fi * 2.71 + t * 0.8) * 0.3;
  float fastJitter = sin(u_time * 2.3 + fi * 0.89 + t * 2.3) * 0.2;
  return (slowSway + fastJitter) * u_warp;
}

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float asp = u_resolution.x / u_resolution.y;
  vec2 p = (st - 0.5) * vec2(asp, 1.0);

  vec2 fcLow = sampleBin(12.0);
  vec2 fcHigh = sampleBin(200.0);

  // Precompute the low-frequency combined sway modifier
  float fcLowMod = fcLow.x * 0.8 + fcLow.y * 0.4;

  float glowTotal = 0.0;
  vec3 colTotal = vec3(0.0);

  // int nArms = int(u_countPrimary);
  int nArms =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);
  int nDepths = int(u_countSecondary);

  for (int arm = 0; arm < 999; arm++) {
    if (arm >= nArms)
      break;

    float fi = float(arm);
    float baseAngle = (fi / float(nArms)) * 6.2832;

    float armBin = fi * (64.0 / float(nArms));
    vec2 fcArm = sampleBin(armBin);
    float armLen = clamp(0.28 + fcArm.x * 0.25 + fcArm.y * 0.1, 0.05, u_zoom);
    float mainWidth = 0.012 + fcArm.x * 0.006;

    float hue = u_hueShift + (fi / float(nArms)) * 60.0 + fcArm.y * 25.0;
    float val = clamp(fcArm.x * 1.6 + 0.1, 0.0, 1.0);
    float sat = 0.9 - fcArm.x * 0.2;

    // Precompute colours for all three depth levels — hoisted out of segment
    // loops
    vec3 armCol = hsv2rgb(hue, sat, val);
    vec3 bCol = hsv2rgb(hue + 20.0 * sign(fcArm.y), sat, val * 0.8);
    vec3 b2Col = hsv2rgb(hue + 35.0 * sign(fcArm.y), sat, val * 0.6);

    // --- Depth 1: main arm (4 segments) ---
    float segLen = armLen / 4.0;
    vec2 segStart = vec2(0.0);

    for (int seg = 0; seg < 4; seg++) {
      float t = float(seg) / 4.0;
      float angle = baseAngle + armSway(fi, t) + fcLowMod * sin(t * 3.14);
      vec2 segEnd = segStart + vec2(cos(angle), sin(angle)) * segLen;

      float g = lineSDF(p, segStart, segEnd, mainWidth * (1.0 - t * 0.4));
      glowTotal += g;
      colTotal += armCol * g;

      segStart = segEnd;
    }

    // segStart now holds the arm tip — no need to recalculate
    vec2 tip = segStart;

    // --- Depth 2: sub-branches from arm tip (3 segments each) ---
    if (nDepths >= 2) {
      for (int sub = 0; sub < 2; sub++) {
        float bHash = hash(fi * 17.3 + float(sub) * 3.1);
        float bAngle =
            baseAngle + armSway(fi, 1.0) + (bHash - 0.5) * 2.0 + fcArm.y * 0.3;

        float bLen = armLen * 0.45;
        float bSegLen = bLen / 3.0;
        vec2 bStart = tip;

        for (int bseg = 0; bseg < 3; bseg++) {
          float bt = float(bseg) / 3.0;
          float ba = bAngle + armSway(fi + float(sub) * 3.7, bt) * 0.6 +
                     sin(u_time * 1.4 + fi * 2.1 + bt * 2.0 + float(sub)) *
                         0.3 * fcHigh.x;
          vec2 bEnd = bStart + vec2(cos(ba), sin(ba)) * bSegLen;

          float bg =
              lineSDF(p, bStart, bEnd, mainWidth * 0.5 * (1.0 - bt * 0.5));
          glowTotal += bg;
          colTotal += bCol * bg;

          bStart = bEnd;
        }

        // --- Depth 3: sub-sub-branches from sub-branch tips (2 segments each)
        // ---
        if (nDepths >= 3) {
          vec2 bTip = bStart;
          for (int sub2 = 0; sub2 < 2; sub2++) {
            float b2Hash =
                hash(fi * 5.1 + float(sub) * 7.3 + float(sub2) * 2.9);
            float b2Angle = bAngle +
                            armSway(fi + float(sub2) * 5.3, 1.0) * 0.4 +
                            (b2Hash - 0.5) * 1.8;

            float b2Len = bLen * 0.45;
            float b2SegLen = b2Len / 2.0;
            vec2 b2Start = bTip;

            for (int b2seg = 0; b2seg < 2; b2seg++) {
              float b2t = float(b2seg) / 2.0;
              float b2a = b2Angle + armSway(fi + float(sub2) * 7.1, b2t) * 0.4;
              vec2 b2End = b2Start + vec2(cos(b2a), sin(b2a)) * b2SegLen;

              float b2g = lineSDF(p, b2Start, b2End,
                                  mainWidth * 0.25 * (1.0 - b2t * 0.5));
              glowTotal += b2g;
              colTotal += b2Col * b2g;

              b2Start = b2End;
            }
          }
        }
      }
    }
  }

  glowTotal = min(glowTotal, 1.5);
  vec3 colour = (glowTotal > 0.001) ? colTotal / glowTotal : vec3(0.0);
  float brightness = clamp(glowTotal, 0.0, u_emphasis);

  fragColor = vec4(colour * brightness, 1.0);
}
