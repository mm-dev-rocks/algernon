#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// tendrils.frag
//
// Dense field of tapered sine-curve tendrils rooted at the bottom.
// Each tendril is a vertical sine wave with individual variation in
// frequency, phase, amplitude and length. No SDF — instead we ask
// "which tendril is closest to this pixel's x position, and what is
// that tendril's y-profile at this pixel's height?" This makes cost
// proportional to tendrils-per-x-slice, not total tendrils.
//
// FFT:
//   bass charge  → wind burst (lateral sway amplitude on beats)
//   bass mag     → overall tendril brightness / saturation
//   mid charge   → secondary ripple along the tendril length
//   high charge  → tip flutter

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

// Given a tendril index, return its x root position in [0..asp]
// and a set of variation hashes
void tendrilParams(float idx, float asp, out float rootX, out float h1,
                   out float h2, out float h3, out float h4) {
  h1 = hash1(idx * 7.3 + 1.0);
  h2 = hash1(idx * 3.1 + 2.0);
  h3 = hash1(idx * 13.7 + 3.0);
  h4 = hash1(idx * 5.9 + 4.0);
  // Spread roots across screen width with slight randomness
  float spacing = asp / u_countPrimary;
  rootX = (idx + h1 * 0.8) * spacing;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 res = u_resolution.xy;
  float asp = res.x / res.y;

  // World: x in [0..asp], y in [0..1], y=0 at bottom
  vec2 world = vec2(fragCoord.x / res.x * asp, 1.0 - fragCoord.y / res.y);

  // FFT
  vec2 fcBass = sampleBinRange(1.0, 6.0);
  vec2 fcMid = sampleBinRange(20.0, 60.0);
  vec2 fcHigh = sampleBinRange(120.0, 180.0);

  float bassCharge = fcBass.y;
  float bassMag = fcBass.x;
  float midCharge = fcMid.y;
  float highCharge = fcHigh.y;

  float t = u_time * u_speed;

  // Wind: resting sway + beat kick
  float wind = sin(t * 0.6) * u_warp + max(0.0, bassCharge) * u_warp * 3.0;

  // How many tendrils to check around this pixel's x position.
  // We only need to check tendrils whose root is within max-sway distance.
  float totalTendrils = u_countPrimary;
  float spacing = asp / totalTendrils;
  float maxSwayX = u_zoom * 1.5; // max possible x deflection

  // Find range of tendril indices that could reach this pixel
  float xSearchMin = world.x - maxSwayX;
  float xSearchMax = world.x + maxSwayX;
  int idxMin = max(0, int(floor(xSearchMin / spacing)) - 1);
  int idxMax = min(int(totalTendrils), int(ceil(xSearchMax / spacing)) + 1);

  float glow = 0.0;
  float hueAcc = 0.0;
  float depthAcc = 0.0; // for layering darker tendrils behind brighter
  float wgtTotal = 0.0;

  for (int i = 0; i < 512; i++) {
    if (i >= idxMax - idxMin)
      break;
    float idx = float(i + idxMin);

    float rootX, h1, h2, h3, h4;
    tendrilParams(idx, asp, rootX, h1, h2, h3, h4);

    // Per-tendril variation
    float myLen = u_zoom * (0.5 + h2 * 0.5); // length variation
    float mySway = wind * (0.5 + h3 * 0.7);  // sway response variation
    float myFreq = 1.5 + h4 * 2.5;           // sine curve frequency
    float myPhase = h1 * 6.28;               // phase offset

    // Only draw up to this tendril's length
    if (world.y > myLen)
      continue;

    // Normalised height along tendril: 0=root, 1=tip
    float ht = world.y / myLen;

    // X position of this tendril at this height.
    // Sway increases toward tip (ht^1.5 weighting).
    // Secondary mid-freq ripple adds S-curve character.
    // High-freq flutter at tip only.
    float swayFactor = pow(ht, 1.5);
    float primarySway = sin(mySway * swayFactor + myPhase) * u_zoom * 0.4;
    float midRipple = sin(myFreq * ht * 3.14 + t * 1.2 + myPhase) * midCharge *
                      0.04 * swayFactor;
    float tipFlutter =
        sin(t * 4.0 + myPhase) * highCharge * 0.02 * pow(ht, 3.0);

    float tendrilX = rootX + primarySway + midRipple + tipFlutter;

    // Distance from pixel to tendril centreline at this height
    float dx = world.x - tendrilX;

    // Width tapers root→tip. u_size is base width.
    float width = u_size * (1.0 - ht * 0.85);

    // Soft coverage — Gaussian profile gives smooth anti-aliased edge
    float coverage = exp(-dx * dx / (width * width * 0.5));

    if (coverage < 0.01)
      continue;

    // Depth: use h1 to fake layering — some tendrils "in front"
    float depth = 0.3 + h1 * 0.7;

    glow += coverage * depth;
    hueAcc += h1 * coverage;
    depthAcc += depth * coverage;
    wgtTotal += coverage;
  }

  if (glow < 0.005) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  float avgHue = wgtTotal > 0.0 ? hueAcc / wgtTotal : 0.0;
  float avgDepth = wgtTotal > 0.0 ? depthAcc / wgtTotal : 0.5;

  // Height of pixel used for root→tip colour gradient
  float ht = world.y / u_zoom;

  float hue = u_hueShift + avgHue * u_hueRange + bassMag * 15.0;
  float sat = 0.6 + bassMag * 0.4;
  float val = clamp((0.15 + ht * 0.5 + bassMag * 0.25) * avgDepth, 0.0, 1.0);

  vec3 col = hsv2rgb(hue, sat, val);
  col = pow(col, vec3(u_emphasis));

  // Soft glow accumulation — clamp so overlapping tendrils don't blow out
  float alpha = clamp(glow, 0.0, 1.0);
  col *= alpha;

  // fragColor = vec4(col, 1.0);
  fragColor = vec4(float(idxMax - idxMin) / 20.0, 0.0, 0.0, 1.0);
}
