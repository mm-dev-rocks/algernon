#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_lissajous_web.frag
//
// Visualisation strategy: signed-distance field of a Lissajous-like curve.
//
// A Lissajous figure is a parametric curve traced by:
//   x(t) = sin(a*t + phase)
//   y(t) = sin(b*t)
//
// Here the frequency ratios (a, b) and phase are driven by FFT bins, so the
// shape of the knot continuously morphs with the music.
//
// Rather than rasterising the curve explicitly (which is expensive), each
// pixel computes its minimum distance to the curve by sampling N points along
// it and taking the minimum. This is an *approximate* SDF — not analytically
// exact, but fast and visually smooth enough at these sample counts.
//
// Method contrast vs other shaders in this set:
//   warp_kaleido        — domain warp + angular fold, grid pattern
//   rings_radial        — pure polar, concentric bands
//   rose_tunnel         — polar angle, radial gradient
//   THIS SHADER         — parametric SDF, no predetermined geometry

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// How many points to sample along the parametric curve when computing the
// approximate distance. More samples = smoother curve, higher cost.
// 80 is a good balance for mediump precision on mobile GPUs.
const int SAMPLE_COUNT = 40;

// The glow falloff exponent. Higher = thinner, sharper line.
// 2.0 gives a soft neon glow; 4.0+ gives a fine wire look.
const float GLOW_POWER = 6.5;

// Half-width of the curve in normalised screen units (0..1 range).
// The glow fades to zero beyond this distance from the curve.
const float GLOW_RADIUS = 0.82;

// Helper: reads a single bin by float index and returns amplitude 0..1.
// The +0.5 texel-centre offset prevents bleeding across texel boundaries —
// consistent with the convention used throughout this codebase.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

float sampleCharge(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).g;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct the coordinate space.
  // p is now in roughly -0.5..0.5 on the short axis, wider on the long axis.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- FFT-driven curve parameters ---
  //
  // We use broad frequency band averages rather than individual bins so the
  // shape morphs smoothly rather than jittering on every frame.
  //
  // frequencyRatioA / B control the Lissajous knot complexity.
  // Clamping to a small integer-ish range (1..4) keeps the figure legible;
  // large ratios produce dense, unreadable webs.
  float bassEnergy = (sampleBin(2.0) + sampleBin(4.0) + sampleBin(6.0)) / 3.0;
  float midEnergy = (sampleBin(20.0) + sampleBin(30.0) + sampleBin(40.0)) / 3.0;
  float trebleEnergy =
      (sampleBin(80.0) + sampleBin(100.0) + sampleBin(120.0)) / 3.0;

  // The horizontal frequency ratio: bass pushes it from 1→3.
  // Adding 1.0 ensures we never get ratio 0 (degenerate straight line).
  float freqA = 1.0 + bassEnergy * 2.0;

  // The vertical frequency ratio: treble pushes it from 1→4.
  float freqB = 1.0 + trebleEnergy * 3.0;

  // Phase offset between the two axes: mid energy rotates the knot.
  // Without a phase offset, Lissajous figures collapse to diagonal lines.
  // 1.5708 ≈ pi/2, which gives the classic open figure-eight at ratio 1:1.
  float phase = 1.5708 + midEnergy * 3.14159265;

  // Scale factor: loud overall signal expands the figure toward the edges.
  float scale = 0.35 + (bassEnergy + trebleEnergy) * 0.08;
  // float scale = 0.35 + (bassEnergy + trebleEnergy) * 0.08 * sampleCharge(60);

  // --- Approximate SDF: minimum distance to the parametric curve ---
  //
  // We step t uniformly through 0..2*pi and find the curve point closest
  // to this fragment. The curve is periodic with period 2*pi regardless of
  // freqA / freqB (the figure may not close in that interval for irrational
  // ratios, but it gets close enough for a visual approximation).
  float minDist = 1.0e6; // initialise to a large sentinel distance
  float tStep = 6.28318530 / float(SAMPLE_COUNT);

  for (int i = 0; i < SAMPLE_COUNT; i++) {
    float t = float(i) * tStep;

    // Standard Lissajous parametric equations.
    vec2 curvePoint = vec2(sin(freqA * t + phase), sin(freqB * t)) * scale;

    // Euclidean distance from this fragment to this point on the curve.
    float d = length(p - curvePoint);
    minDist = min(minDist, d);
  }

  // --- Glow from the curve ---
  //
  // Map minDist → brightness using an inverse power curve.
  // clamp ensures we don't go negative or above 1.0 before the pow().
  float distNorm = clamp(1.0 - minDist / GLOW_RADIUS, 0.0, 1.0);
  float intensity = pow(distNorm, GLOW_POWER);

  // --- Colour ---
  //
  // Three-band RGB so the colour of the glow shifts with the spectral balance:
  // bass → warm red/orange, mid → green, treble → blue/violet.
  // All three add together, so a full-spectrum signal gives near-white glow.
  float r = intensity * (0.6 + bassEnergy * 0.4);
  float g = intensity * (0.3 + midEnergy * 0.7);
  float b = intensity * (0.8 + trebleEnergy * 0.2);

  fragColor =
      vec4(clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), 1.0);
}
