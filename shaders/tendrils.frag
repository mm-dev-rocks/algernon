#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>
#include <precision.frag>

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

  int total = int(u_countPrimary);
  float ftotal = float(total);

  float numLayers = clamp(ftotal / 60.0, 3.0, 5.0);
  float bladesPerLayer = ftotal / numLayers;

  float binsPerBlade = 256.0 / ftotal;

  // Global bass reference for wind.
  vec2 fcBassGlobal = sampleBinRange(0.0, binsPerBlade);
  float globalBassMag = fcBassGlobal.x;

  // Ambient wind — slow, time-only oscillation. No music here.
  float windBase = sin(u_time * 0.5) * 0.25 +
                   sin(u_time * 0.19 + 1.5708) * 0.12 +
                   sin(u_time * 0.37 + 3.14159) * 0.06;

  // swaySignal is per-blade below — each blade responds to its own FFT bin.

  float xBleed = 0.2;
  float xScale = 1.0 + xBleed;

  float glow = 0.0;
  float hueAcc = 0.0;
  float valAcc = 0.0;
  float wgtTotal = 0.0;

  for (int i = 0; i < 512; i++) {
    if (i >= total)
      break;

    float fi = float(i);
    float h1 = hash1(fi * 7.3 + 1.0);
    float h2 = hash1(fi * 3.1 + 2.0);
    float h3 = hash1(fi * 13.7 + 3.0);
    float h4 = hash1(fi * 5.9 + 4.0);

    float row = floor(fi / bladesPerLayer);
    float col = fi - row * bladesPerLayer;

    // z: 0 = back, 1 = front.
    float z = row / max(numLayers - 1.0, 1.0);

    float rootX =
        -xBleed + (col + 0.5 + (h1 - 0.5) * 0.8) * (xScale / bladesPerLayer);

    // Per-blade FFT slice.
    float binStart = fi * binsPerBlade;
    vec2 fc = sampleBinRange(binStart, binStart + binsPerBlade);
    float myMag = fc.x;
    float myCharge = fc.y;

    // float musicalDisplacement = 0.5;

    // Soften per-blade energy — drives ripple and flutter character,
    // not the main sway. Clamped so a loud bin can't spike wildly.
    float myEnergy = clamp(pow(max(myMag, 0.0), 0.6), 0.0, 0.8);

    float myLen = u_zoom * (0.4 + h2 * 0.35 + h4 * 0.25);
    if (world.y > myLen)
      continue;

    float myPhase = h1 * 6.28318;
    float myWindResp = 0.6 + h3 * 0.4; // tighter range, less variance
    float myFreq = 0.8 + h4 * 0.5;

    // Parallax: front blades shift slightly with ambient wind only.
    float parallax = windBase * z * 0.18;
    float rootXp = rootX + parallax;

    float ht = world.y / u_zoom;
    float swayFactor = pow(ht, 1.4);

    // Each blade responds to its own bin energy, not a global music signal.
    float swayScale = 0.3 + z * 0.2;
    // float swaySignal = (windBase + myEnergy * 0.35) * u_spread;
    float swaySignal = windBase * u_spread + myEnergy * u_warp;
    float primarySway = swaySignal * myWindResp * swayScale * swayFactor;

    // Ripple: u_speed controls frequency, myEnergy controls amplitude.
    // u_spread also scales it so at warp=0 ripple is minimal.
    float rippleAmp = 0.0;
    float myRipple = sin(myFreq * ht * 3.14159 + u_time * 0.9 + myPhase) *
                     rippleAmp * swayFactor * swayFactor;

    float bendAmount = abs(primarySway + myRipple) / max(myLen, 0.001);
    float arcCorrection = sqrt(max(0.0, 1.0 - bendAmount * bendAmount));
    float correctedHt = ht / max(arcCorrection, 0.3);

    if (correctedHt > 1.0)
      continue;

    swayFactor = pow(correctedHt, 1.4);
    // primarySway = (windBase + myEnergy * 0.35) * u_spread * myWindResp *
    // swayScale * swayFactor;
    primarySway = (windBase * u_spread + myEnergy * u_warp) * myWindResp *
                  swayScale * swayFactor;
    myRipple = sin(myFreq * correctedHt * 3.14159 + u_time * 0.9 + myPhase) *
               rippleAmp * swayFactor * swayFactor;

    // Tip flutter: driven by charge (phase proxy), scaled by warp.
    // Slow independent drift per blade — organic restlessness, no music
    // connection.
    float drift =
        sin(u_time * (0.2 + h3 * 0.15) + myPhase) * 0.015 * swayFactor;

    float tendrilX = rootXp + primarySway + myRipple + drift;

    float dx = world.x - tendrilX;
    float width = u_size * max(0.4 + z * 0.6, 0.3) * (1.0 - correctedHt * 0.88);

    float coverage = exp(-dx * dx / (width * width * 0.04));
    if (coverage < 0.005)
      continue;

    float tipGlow = 0.25 + pow(correctedHt, 1.8) * 0.75;
    float depthVal = 0.25 + z * 0.75;
    float tendrilVal = tipGlow * depthVal;

    glow += coverage * depthVal;
    hueAcc += (h1 + myCharge * 0.15) * coverage;
    valAcc += tendrilVal * coverage;
    wgtTotal += coverage;
  }

  if (glow < 0.001) {
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
