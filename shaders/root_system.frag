#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

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

float armSway(float fi, float t, float warp) {
  float slowSway = sin(u_time * 0.7 + fi * 1.37 + t * 1.1) * 0.6 +
                   sin(u_time * 0.3 + fi * 2.71 + t * 0.8) * 0.3;
  float fastJitter = sin(u_time * 2.3 + fi * 0.89 + t * 2.3) * 0.2;
  return (slowSway + fastJitter) * warp;
}

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

vec2 sampleBinRange(float binStart, float binEnd) {
  vec2 acc = vec2(0.0);
  float count = 0.0;
  for (int i = 0; i < 256; i++) {
    float fi = binStart + float(i);
    if (fi >= binEnd)
      break;
    acc += sampleBin(fi);
    count += 1.0;
  }
  return acc / count;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float asp = u_resolution.x / u_resolution.y;
  vec2 p = (st - 0.5) * vec2(asp, 1.0);

  vec2 fcLow = sampleBinRange(1.0, 4.0);
  vec2 fcHigh = sampleBin(170.0);

  float dynamicWarp = u_warp - max(0.0, fcLow.y) * 1.2;
  float fcLowMod = fcLow.x * 0.8 + fcLow.y * 0.4;

  float glowTotal = 0.0;
  vec3 colTotal = vec3(0.0);

  int nArms =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);
  // int nDepths = int(u_countSecondary);

  // Continuous taper: global t runs 0→1 from centre to outermost tip.
  // Proportional lengths: arm=1, branch=0.45, sub=0.45*0.45
  float lenArm = 1.0;
  float lenBranch = 0.45;
  float lenSub = 0.45 * 0.45;
  float totalReach = lenArm + lenBranch + lenSub;      // ~1.6525
  float tArmEnd = lenArm / totalReach;                 // ~0.605
  float tBranchEnd = tArmEnd + lenBranch / totalReach; // ~0.878

// Width at global t: starts at mainWidth, tapers to ~5% at tip.
// Adjust the 0.95 to taste (1.0 = taper to nothing, 0.0 = no taper).
#define taperWidth(baseWidth, globalT) ((baseWidth) * (1.0 - (globalT) * 0.9))

  for (int arm = 0; arm < 999; arm++) {
    if (arm >= nArms)
      break;

    float fi = float(arm);
    float baseAngle = (fi / float(nArms)) * 6.2832;

    float binsPerArm = 256.0 / float(nArms);
    float armBinStart = fi * binsPerArm;
    float armBinEnd = armBinStart + binsPerArm;
    vec2 fcArm = sampleBinRange(armBinStart, armBinEnd);

    float armLen = clamp(0.28 + fcArm.x * 0.25 + fcArm.y * 0.1, 0.05, u_zoom);
    float mainWidth = u_size + fcArm.x * 0.005;

    float hue = u_hueShift + (fi / float(nArms)) * 60.0 + fcArm.y * 25.0;
    float val = clamp(fcArm.x * 1.6 + 0.1, 0.0, 1.0);
    float sat = 0.9 - fcArm.x * 0.2;

    vec3 armCol = hsv2rgb(hue, sat, val);
    vec3 bCol = hsv2rgb(hue + 20.0 * sign(fcArm.y), sat, val * 0.8);
    vec3 b2Col = hsv2rgb(hue + 35.0 * sign(fcArm.y), sat, val * 0.6);

    // --- Depth 1: main arm (4 segments) ---
    float segLen = armLen / 4.0;
    vec2 segStart = vec2(0.0);

    for (int seg = 0; seg < 4; seg++) {
      float t = float(seg) / 4.0;
      float globalT = t * tArmEnd;
      float angle =
          baseAngle + armSway(fi, t, dynamicWarp) + fcLowMod * sin(t * 3.14);
      vec2 segEnd = segStart + vec2(cos(angle), sin(angle)) * segLen;

      float g = lineSDF(p, segStart, segEnd, taperWidth(mainWidth, globalT));
      glowTotal += g;
      colTotal += armCol * g;

      segStart = segEnd;
    }

    vec2 tip = segStart;

    // --- Depth 2: sub-branches from arm tip ---
    // if (nDepths >= 2) {
    for (int sub = 0; sub < 2; sub++) {
      float bHash = hash(fi * 17.3 + float(sub) * 3.1);
      float bAngle = baseAngle + armSway(fi, 1.0, dynamicWarp) +
                     (bHash - 0.5) * 2.0 + fcArm.y * 0.3;

      float bLen = armLen * 0.45;
      float bSegLen = bLen / 3.0;
      vec2 bStart = tip;

      for (int bseg = 0; bseg < 3; bseg++) {
        float bt = float(bseg) / 3.0;
        float globalT = tArmEnd + bt * (tBranchEnd - tArmEnd);
        float ba = bAngle +
                   armSway(fi + float(sub) * 3.7, bt, dynamicWarp) * 0.6 +
                   sin(u_time * 1.4 + fi * 2.1 + bt * 2.0 + float(sub)) * 0.3 *
                       fcHigh.x;
        vec2 bEnd = bStart + vec2(cos(ba), sin(ba)) * bSegLen;

        float bg = lineSDF(p, bStart, bEnd, taperWidth(mainWidth, globalT));
        glowTotal += bg;
        colTotal += bCol * bg;

        bStart = bEnd;
      }

      // --- Depth 3: sub-sub-branches ---
      // if (nDepths >= 3) {
      vec2 bTip = bStart;
      for (int sub2 = 0; sub2 < 2; sub2++) {
        float b2Hash = hash(fi * 5.1 + float(sub) * 7.3 + float(sub2) * 2.9);
        float b2Angle =
            bAngle + armSway(fi + float(sub2) * 5.3, 1.0, dynamicWarp) * 0.4 +
            (b2Hash - 0.5) * 1.8;

        float b2Len = bLen * 0.45;
        float b2SegLen = b2Len / 2.0;
        vec2 b2Start = bTip;

        for (int b2seg = 0; b2seg < 2; b2seg++) {
          float b2t = float(b2seg) / 2.0;
          float globalT = tBranchEnd + b2t * (1.0 - tBranchEnd);
          float b2a =
              b2Angle + armSway(fi + float(sub2) * 7.1, b2t, dynamicWarp) * 0.4;
          vec2 b2End = b2Start + vec2(cos(b2a), sin(b2a)) * b2SegLen;

          float b2g =
              lineSDF(p, b2Start, b2End, taperWidth(mainWidth, globalT));
          glowTotal += b2g;
          colTotal += b2Col * b2g;

          b2Start = b2End;
        }
      }
      //}
    }
    //}
  }

  glowTotal = min(glowTotal, 1.5);
  vec3 colour = (glowTotal > 0.001) ? colTotal / glowTotal : vec3(0.0);
  float brightness = clamp(glowTotal, 0.0, u_emphasis);

  fragColor = vec4(colour * brightness, 1.0);
}
