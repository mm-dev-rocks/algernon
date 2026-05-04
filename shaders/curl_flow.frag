#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// curl_flow.frag
//
// Flow field strand visualiser.
// A value noise field is advected along a curl vector field.
// Noise grains are stretched into strands by the flow — the result
// looks like hair, smoke trails, or ink wisps.
//
// Key insight: we don't march a single point. At each pixel we sample
// a noise function at multiple points offset along the flow direction,
// and sum them. This creates visible strand-like contrast between
// pixels that align with the flow and those that don't.

vec2 sampleBin(float binIndex) {
  float u = clamp((binIndex + 0.5) / 256.0, 0.0, 1.0);
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

vec2 sampleBinRange(float binStart, float binEnd) {
  vec2 acc = vec2(0.0);
  float count = 0.0;
  for (int i = 0; i < 256; i++) {
    float fi = binStart + float(i);
    if (fi >= binEnd) break;
    acc += sampleBin(fi);
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
  if      (h < 60.0)  rgb = vec3(c, x, 0.0);
  else if (h < 120.0) rgb = vec3(x, c, 0.0);
  else if (h < 180.0) rgb = vec3(0.0, c, x);
  else if (h < 240.0) rgb = vec3(0.0, x, c);
  else if (h < 300.0) rgb = vec3(x, 0.0, c);
  else                rgb = vec3(c, 0.0, x);
  return rgb + m;
}

// Value noise — returns 0..1
float hash(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p.yx + 19.19);
  return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep
  return mix(
    mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
    mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
    u.y
  );
}

// Curl of a smooth noise potential field — divergence-free flow
vec2 curl(vec2 p, float scale, float t) {
  float eps = 0.01;
  float n  = valueNoise(p * scale + vec2(t * 0.3, t * 0.17));
  float nx = valueNoise((p + vec2(eps, 0.0)) * scale + vec2(t * 0.3, t * 0.17));
  float ny = valueNoise((p + vec2(0.0, eps)) * scale + vec2(t * 0.3, t * 0.17));
  return vec2(-(ny - n), (nx - n)) / eps;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 res = u_resolution.xy;
  float asp = res.x / res.y;

  vec2 p = (fragCoord / res) * vec2(asp, 1.0);

  // FFT
  vec2 fcBass = sampleBinRange(1.0,   6.0);
  vec2 fcMid  = sampleBinRange(20.0,  60.0);
  vec2 fcHigh = sampleBinRange(120.0, 180.0);

  float bassCharge = fcBass.y;
  float midAmp     = fcMid.x;
  float highCharge = fcHigh.y;

  float t = u_time * u_speed;

  // Flow scale: u_warp controls curl tightness.
  // Beat charge increases flow strength so strands whip on a kick.
  float flowScale    = u_warp * 2.0;
  float flowStrength = 0.15 + max(0.0, bassCharge) * 0.35;

  // Secondary layer adds mid-freq complexity
  float flow2Strength = midAmp * 0.12;

  // Number of LIC (line integral convolution) samples along flow.
  // u_zoom controls strand length: more steps = longer strands.
  int steps = int(clamp(u_zoom * 36.0, 4.0, 36.0));
  float stepSize = u_spread;

  // Seed noise scale — controls how fine-grained the initial texture is.
  // Higher = finer, more numerous strands.
  float noiseScale = u_countPrimary;

  float density = 0.0;
  vec2 pos = p;

  // Line Integral Convolution: march along the flow field, sampling
  // a noise texture at each step. Pixels aligned with the flow integrate
  // to high values (bright strands); perpendicular pixels cancel out (dark gaps).
  for (int i = 0; i < 36; i++) {
    if (i >= steps) break;

    float fi = float(i) / float(steps);

    // Primary flow
    vec2 f1 = curl(pos, flowScale, t) * flowStrength;
    // Secondary layer
    vec2 f2 = curl(pos, flowScale * 2.2, t * 1.4 + 5.3) * flow2Strength;
    // High-freq turbulence
    vec2 f3 = curl(pos, flowScale * 5.0, t * 2.5 + 2.1)
              * abs(highCharge) * 0.05;

    vec2 flow = f1 + f2 + f3;

    pos += flow * stepSize;

    // Sample noise at this position — this is the "seed texture"
    float n = valueNoise(pos * noiseScale);

    // Weight: taper toward the end of the strand (root heavier than tip)
    float w = 1.0 - fi * 0.6;
    density += n * w;
  }

  density /= float(steps);

  // Sharpen into strands — contrast pulls bright seeds into thin lines
  density = pow(clamp(density * 2.2 - 0.3, 0.0, 1.0), u_emphasis);

  if (density < 0.01) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // Colour
  float hue = u_hueShift
            + density * u_hueRange
            + max(0.0, bassCharge) * 25.0;
  float sat = 0.65 + midAmp * 0.35;
  float val = 0.2 + density * 0.8;

  vec3 col = hsv2rgb(hue, sat, val);

  fragColor = vec4(col, 1.0);
}
