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

  // Sway uses raw u_time so the speed slider cannot scrub position.
  // Amplitudes kept modest so bass (windBeat) is the dominant driver.
  float windBase = sin(u_time * 0.5)            * 0.25
                 + sin(u_time * 0.19 + 1.5708)  * 0.12
                 + sin(u_time * 0.37 + 3.14159) * 0.06;

  // Lower pow exponent so bass registers at moderate levels, not just peaks.
  float windBeat = pow(bassMag, 0.7) * 0.8;
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
    float myFreq = (0.8 + h4 * 0.5) * u_speed;  // u_speed = ripple density

    // z: 0 = back, 1 = front. Drives spectral layering and parallax.
    // Back blades are bass-driven, darker, narrower, less mobile.
    // Front blades are treble/mid-driven, brighter, wider, more reactive.
    float z = h5;

    // Spectral energy for this blade — crossfade from bass (z=0) to high (z=1).
    // A blade at z=0.5 is equally driven by bass and treble (mid territory).
    float myBassAmt   = 1.0 - z;
    float myTrebleAmt = z;
    float myMidAmt    = 1.0 - abs(z - 0.5) * 2.0;  // peaks at z=0.5

    // abs() guards against negative charge values causing NaN in pow().
    float myEnergy = myBassAmt   * pow(max(bassMag,           0.0), 0.7)
                   + myMidAmt    * pow(max(midMag,            0.0), 0.7) * 0.6
                   + myTrebleAmt * pow(max(abs(highCharge),   0.0), 0.7) * 0.5;
    myEnergy = clamp(myEnergy, 0.0, 1.0);

    // Parallax: front blades shift more with wind than back blades.
    // wind is the global sway signal — multiplying by z gives near blades
    // a larger lateral offset, creating a sense of spatial depth.
    float parallax = wind * z * 0.18;
    float rootXp = rootX + parallax;

    float ht = world.y / u_zoom;

    // Global sway signal — shared by all blades, modulated by their spectral
    // energy so bass-heavy moments push the back more, treble pushes the front.
    float globalSway = sin(u_time * 0.5)            * 0.25
                     + sin(u_time * 0.19 + 1.5708)  * 0.12
                     + sin(u_time * 0.37 + 3.14159) * 0.06
                     + myEnergy * 0.8;

    float swayFactor = pow(ht, 1.4);
    // Front blades (high z) sway more — they catch the wind more readily.
    float swayScale = 0.25 + z * 0.20;
    float curl = u_warp * (0.05 + h3 * 0.10) * swayFactor;
    float primarySway =
        (globalSway * myWindResp + curl) * u_zoom * swayScale * swayFactor;
    float midRipple = sin(myFreq * ht * 3.14159 + u_time * 0.9 + myPhase)
                      * midMag * 0.18 * swayFactor * swayFactor;

    float bendAmount = abs(primarySway + midRipple) / max(myLen, 0.001);
    float arcCorrection = sqrt(max(0.0, 1.0 - bendAmount * bendAmount));
    float correctedHt = ht / max(arcCorrection, 0.3);

    if (correctedHt > 1.0)
      continue;

    // Recompute sway-dependent values with corrected ht.
    swayFactor = pow(correctedHt, 1.4);
    curl = u_warp * (0.05 + h3 * 0.10) * swayFactor;
    primarySway = (globalSway * myWindResp + curl) * u_zoom * swayScale * swayFactor;
    midRipple = sin(myFreq * correctedHt * 3.14159 + u_time * 0.9 + myPhase)
                * midMag * 0.18 * swayFactor * swayFactor;

    // Tip flutter: treble-driven, more pronounced on front blades.
    float tipFlutter = sin(u_time * 3.5 + myPhase * 1.7)
                       * highCharge * 0.05 * (0.3 + z * 0.7) * pow(correctedHt, 3.0);

    float tendrilX = rootXp + primarySway + midRipple + tipFlutter;

    float dx = world.x - tendrilX;
    // Front blades are wider (closer), back blades are narrower (distant).
    // min 0.3 factor ensures back blades never become invisibly thin.
    float width = u_size * max(0.4 + z * 0.6, 0.3) * (1.0 - correctedHt * 0.88);

    float coverage = exp(-dx * dx / (width * width * 0.04));
    if (coverage < 0.005)
      continue;

    float tipGlow  = 0.25 + pow(correctedHt, 1.8) * 0.75;
    // Back blades darker, front blades brighter.
    float depthVal = 0.25 + z * 0.75;
    float tendrilVal = tipGlow * depthVal;

    glow     += coverage * depthVal;
    hueAcc   += (h1 + myMidAmt * 0.3) * coverage;
    valAcc   += tendrilVal * coverage;
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
