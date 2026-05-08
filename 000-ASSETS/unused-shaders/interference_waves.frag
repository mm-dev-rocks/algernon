#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

const int SOURCE_COUNT = 5;

vec2 sampleBin(float binIndex) {
  float u = clamp((binIndex + 0.5) / 256.0, 0.0, 1.0);
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  // .r = magnitude, .g remapped to signed charge [-1..1]
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- FFT bands (magnitude + charge) ---
  vec2 fcBass  = sampleBin(3.0);
  vec2 fcLowMid = sampleBin(35.0);
  vec2 fcMid   = sampleBin(80.0);
  vec2 fcHiMid = sampleBin(130.0);
  vec2 fcHigh  = sampleBin(170.0);

  float amp[5];
  amp[0] = fcBass.x;
  amp[1] = fcLowMid.x;
  amp[2] = fcMid.x;
  amp[3] = fcHiMid.x;
  amp[4] = fcHigh.x;

  // --- Source positions drift slowly with u_time for continuous life ---
  // Base positions are the original hand-placed ones; each drifts on its own
  // Lissajous path scaled by u_spread so the user controls how much they wander.
  vec2 bases[5];
  bases[0] = vec2( 0.00,  0.00);
  bases[1] = vec2(-0.30,  0.20);
  bases[2] = vec2( 0.30,  0.20);
  bases[3] = vec2(-0.20, -0.28);
  bases[4] = vec2( 0.25, -0.22);

  // Each source also gets a charge-driven positional nudge so beats
  // physically shift the interference pattern.
  float charges[5];
  charges[0] = fcBass.y;
  charges[1] = fcLowMid.y;
  charges[2] = fcMid.y;
  charges[3] = fcHiMid.y;
  charges[4] = fcHigh.y;

  vec2 sources[5];
  for (int i = 0; i < SOURCE_COUNT; i++) {
    float fi = float(i);
    float t = u_time * u_speed * (0.07 + fi * 0.03);
    // Slow Lissajous drift
    vec2 drift = vec2(
      sin(t + fi * 1.3) * u_spread,
      cos(t * 0.7 + fi * 0.9) * u_spread
    );
    // Beat nudge: charge pushes source toward/away from centre
    vec2 nudge = bases[i] * charges[i] * 0.12;
    sources[i] = bases[i] + drift + nudge;
  }

  // --- Wave superposition ---
  // u_zoom controls spatial frequency (ring tightness).
  // u_warp adds a time-animated phase offset per source so rings
  // appear to radiate outward continuously even on silent audio.
  float waveSum = 0.0;
  for (int i = 0; i < SOURCE_COUNT; i++) {
    float dist = length(p - sources[i]);
    // Phase: u_warp * u_time makes rings animate outward at a rate the
    // user controls. charge shifts phase on beats for a pulse effect.
    float phase = u_zoom * dist - u_warp * u_time * (0.4 + float(i) * 0.1)
                  + charges[i] * 0.4;
    float height = amp[i] * sin(phase);
    waveSum += height;
  }

  float normalised = waveSum / float(SOURCE_COUNT) * 0.5 + 0.5;
  // u_emphasis as pow contrast on the interference pattern
  float contrasted = pow(clamp(normalised, 0.0, 1.0), u_emphasis);

  // --- Colour: R/G/B driven by frequency register with phase separation ---
  float bassAmp   = amp[0] + amp[1];
  float midAmp    = amp[2];
  float trebleAmp = amp[3] + amp[4];

  // Charge-driven hue shift: beats warm (positive charge) or cool (negative)
  float globalCharge = (charges[0] + charges[1] + charges[2]) / 3.0;
  float hueShift = globalCharge * u_hueShift; // u_hueShift ± degrees on beat

  float r = pow(clamp(sin(contrasted * 3.14159 + hueShift * 0.017 + 0.0 ) * bassAmp   + contrasted * 0.5, 0.0, 1.0), 1.2);
  float g = pow(clamp(sin(contrasted * 3.14159 + hueShift * 0.017 + 2.09) * midAmp    + contrasted * 0.4, 0.0, 1.0), 1.2);
  float b = pow(clamp(sin(contrasted * 3.14159 + hueShift * 0.017 + 4.19) * trebleAmp + contrasted * 0.3, 0.0, 1.0), 1.2);

  // Apply final gamma contrast so u_emphasis affects the whole image
  vec3 col = pow(vec3(r, g, b), vec3(u_emphasis * 0.5 + 0.5));

  fragColor = vec4(col, 1.0);
}
