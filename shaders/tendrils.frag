#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

vec2 sampleBinRange(float binStart, float binEnd) {
  vec2 acc = vec2(0.0);
  float count = 0.0;
  for (int i = 0; i < 256; i++) {
    float fi = binStart + float(i);
    if (fi >= binEnd)
      break;
    float u = (fi + 0.5) / 256.0;
    vec4 s = texture(u_fftData, vec2(u, 0.5));
    acc += vec2(s.r, (s.g - 0.5) * 2.0);
    count += 1.0;
  }
  return acc / count;
}

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

float hash1(float n) { return fract(sin(n) * 43758.5453); }

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 res = u_resolution.xy;

  vec2 world = vec2(fragCoord.x / res.x, 1.0 - fragCoord.y / res.y);

  vec2 fcBass = sampleBinRange(1.0, 6.0);
  vec2 fcMid = sampleBinRange(20.0, 60.0);
  vec2 fcHigh = sampleBinRange(120.0, 180.0);

  float bassMag = fcBass.x;
  float midMag = fcMid.x;
  float midCharge = fcMid.y;
  float highCharge = fcHigh.y;

  float t = u_time * u_speed;

  float windBase = sin(t * 0.5) * 0.6 + sin(t * 0.19 + 1.3) * 0.3 +
                   sin(t * 0.37 + 2.7) * 0.15;
  float windBeat = pow(bassMag, 1.5) * 0.8;
  float wind = (windBase + windBeat) * u_warp;

  int total = int(u_countPrimary);
  int extra = total / 4;
  float spacing = 1.0 / float(total);

  float glow = 0.0;
  float hueAcc = 0.0;
  float valAcc = 0.0;
  float wgtTotal = 0.0;

  for (int i = 0; i < 512; i++) {
    if (i >= total + extra)
      break;

    float fi = float(i);
    float h1 = hash1(fi * 7.3 + 1.0);
    float h2 = hash1(fi * 3.1 + 2.0);
    float h3 = hash1(fi * 13.7 + 3.0);
    float h4 = hash1(fi * 5.9 + 4.0);
    float h5 = hash1(fi * 2.7 + 5.0);

    float rootX;
    if (i < total) {
      rootX = (fi + 0.5 + (h1 - 0.5) * 0.8) * spacing;
    } else {
      float gi = float(i - total);
      rootX = -(gi + 0.5 + (h1 - 0.5) * 0.8) * spacing;
    }

    float myLen = u_zoom * (0.4 + h2 * 0.35 + h4 * 0.25);

    if (world.y > myLen)
      continue;

    float myPhase = h1 * 6.28318;
    float myWindResp = 0.5 + h3 * 0.7;
    float myFreq = 0.8 + h4 * 0.5;
    float depth = h5;

    float ht = world.y / u_zoom;

    // Arc-length correction: a bending blade spends length on horizontal
    // travel, so compress the vertical coordinate proportionally.
    // We compute sway at ht first, then correct, then recompute with
    // correctedHt.
    float globalSway = sin(t * 0.5) * 0.6 + sin(t * 0.19 + 1.3) * 0.3 +
                       sin(t * 0.37 + 2.7) * 0.15 + pow(bassMag, 1.5) * 0.8;

    float swayFactor = pow(ht, 1.4);
    float curl = u_warp * (0.3 + h3 * 0.4) * swayFactor;
    float primarySway =
        (globalSway * myWindResp + curl) * u_zoom * 0.35 * swayFactor;
    float midRipple = sin(myFreq * ht * 3.14159 + t * 0.9 + myPhase) * midMag *
                      0.04 * swayFactor * swayFactor;

    float bendAmount = abs(primarySway + midRipple) / max(myLen, 0.001);
    float arcCorrection = sqrt(max(0.0, 1.0 - bendAmount * bendAmount));
    float correctedHt = ht / max(arcCorrection, 0.3);

    if (correctedHt > 1.0)
      continue;

    // Recompute sway-dependent values with corrected ht
    swayFactor = pow(correctedHt, 1.4);
    curl = u_warp * (0.3 + h3 * 0.4) * swayFactor;
    primarySway = (globalSway * myWindResp + curl) * u_zoom * 0.35 * swayFactor;
    midRipple = sin(myFreq * correctedHt * 3.14159 + t * 0.9 + myPhase) *
                midMag * 0.04 * swayFactor * swayFactor;

    float tipFlutter = sin(t * 3.5 + myPhase * 1.7) * highCharge * 0.012 *
                       pow(correctedHt, 3.0);

    float tendrilX = rootX + primarySway + midRipple + tipFlutter;

    float dx = world.x - tendrilX;
    float width = u_size * (1.0 - correctedHt * 0.88);

    float coverage = exp(-dx * dx / (width * width * 0.04));
    if (coverage < 0.005)
      continue;

    float tipGlow = 0.25 + pow(correctedHt, 1.8) * 0.75;
    float depthVal = 0.25 + depth * 0.75;
    float tendrilVal = tipGlow * depthVal;

    glow += coverage * depthVal;
    hueAcc += (h1 + midMag * 0.3) * coverage;
    valAcc += tendrilVal * coverage;
    wgtTotal += coverage;
  }

  if (glow < 0.005) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  float avgHue = hueAcc / wgtTotal;
  float avgVal = valAcc / wgtTotal;

  float hue = u_hueShift + avgHue * u_hueRange;
  float sat = 0.7;
  float val = clamp(avgVal, 0.0, 1.0);

  vec3 col = hsv2rgb(hue, sat, val);
  col = pow(col, vec3(u_emphasis));
  col *= clamp(glow, 0.0, 1.0);

  fragColor = vec4(col, 1.0);
}
