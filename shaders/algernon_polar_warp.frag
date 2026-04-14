#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_polar_warp.frag
//
// Visualisation strategy: per-ring angular twist driven by FFT bins.
//
// Every radial distance band from the centre has its own twist angle applied
// before colour is computed. The twist amount at each radius is set by the
// FFT bin that corresponds to that distance band — bass bins twist the
// innermost rings hard, treble bins twist the outer edge.
//
// The result looks like a whirlpool or a wound spring: in a bass-heavy mix
// the centre rotates aggressively while the edges stay calm; a treble-heavy
// mix twists the outer rings into fine tendrils while the centre is still.
//
// After twisting, the colour pattern is a simple angular stripe — but because
// each ring is twisted by a different amount, the stripes become spiralling
// arms rather than radial lines. The number of arms is a constant, but their
// curvature is entirely FFT-driven.
//
// Method contrast vs other shaders in this set:
//   warp_kaleido    — folds angle into fixed sectors, warps coordinates by
//                     a global displacement; produces angular symmetry
//   rings_radial    — maps radius directly to bin brightness, no rotation
//   THIS SHADER     — each radius band independently rotated by its own bin;
//                     no folding, no symmetry, produces spiral/tendril forms

precision mediump float;

uniform vec2      u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// Number of spiral arms. Even numbers give point-symmetric patterns;
// odd numbers give more organic asymmetric spirals. 5 is a good default.
const float ARM_COUNT      = 5.0;

// Maximum twist in radians that a bin at full amplitude can apply to its ring.
// pi (3.14) = half a full rotation; 2*pi = one full rotation per ring.
const float MAX_TWIST      = 5.0;

// How many radial bands to map across the 256 FFT bins.
// 32 gives smooth transitions between adjacent rings while still showing
// fine per-ring variation. Must divide evenly into 256.
const float BAND_COUNT     = 32.0;

// Controls the sharpness of the spiral arm edges.
// 1.0 = smooth cosine gradient, higher values → sharper arm boundaries.
const float ARM_CONTRAST   = 2.2;

// pi — defined locally, not relying on any extension constants.
const float PI             = 3.14159265;

// Helper: reads a single bin by float index and returns amplitude 0..1.
// +0.5 texel-centre offset is the codebase convention for centred sampling.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct; p is in roughly -0.5..0.5 on the short axis.
  vec2 p   = st - vec2(0.5, 0.5);
  p.x     *= u_resolution.x / u_resolution.y;

  // --- Polar decomposition ---
  //
  // Everything from here works in polar coordinates (radius, angle) rather
  // than Cartesian (x, y). The twist is applied as an additive rotation to
  // the angle, leaving the radius unchanged.
  float radius = length(p);
  float angle  = atan(p.y, p.x);   // -pi..pi

  // --- Per-ring twist ---
  //
  // Map this fragment's radius to a radial band index (0..BAND_COUNT-1).
  // We treat 0.5 as "full radius" — the edge midpoints of a square canvas.
  // Beyond that (screen corners) the band index saturates at BAND_COUNT-1.
  float bandIndex = clamp(radius * 2.0 * BAND_COUNT, 0.0, BAND_COUNT - 1.0);

  // Map band index to a bin index, spreading BAND_COUNT bands evenly across
  // the 256 bins so bass covers the inner rings, treble the outer.
  float binsPerBand = 256.0 / BAND_COUNT;
  float binIndex    = floor(bandIndex) * binsPerBand + binsPerBand * 0.5;
  float binAmp      = sampleBin(binIndex);

  // The twist applied to this ring: loud bin → large twist angle.
  // The twist is also scaled by an inverse-radius factor so that outer rings
  // (which are physically longer arcs) don't appear to twist more than inner
  // rings — this keeps the visual weight perceptually even across the disc.
  float radiusDamp  = 1.0 / (1.0 + radius * 2.0);   // falls from 1 → ~0.5 at edge
  float twistAngle  = binAmp * MAX_TWIST * radiusDamp;

  // Apply the twist: rotate this fragment's angle by the computed twist.
  float twistedAngle = angle + twistAngle;

  // --- Spiral arm pattern ---
  //
  // Map the twisted angle onto ARM_COUNT arms using a cosine wave.
  // The argument is (twistedAngle / pi) * ARM_COUNT * pi = twistedAngle * ARM_COUNT,
  // which goes through ARM_COUNT full oscillations per full circle.
  float armSignal = cos(twistedAngle * ARM_COUNT);

  // Remap -1..1 → 0..1 and apply contrast.
  float armBrightness = pow(armSignal * 0.5 + 0.5, ARM_CONTRAST);

  // --- Radial attenuation ---
  //
  // Fade toward black at the centre (avoids a blown-out point singularity)
  // and at the outer edge (keeps the pattern contained within a soft circle).
  float innerFade = clamp(radius * 5.0, 0.0, 1.0);           // black at exact centre
  float outerFade = clamp(1.0 - (radius - 0.35) * 4.0, 0.0, 1.0); // soft outer edge
  float radialMask = innerFade * outerFade;

  // --- Colour ---
  //
  // Hue varies with radius so inner rings (bass-driven) are warm and outer
  // rings (treble-driven) are cool. binAmp also modulates brightness so
  // quiet rings are dark even if the arm pattern says they should be lit.
  float hueT = clamp(radius * 2.2, 0.0, 1.0);   // 0 = inner/bass, 1 = outer/treble

  float r = (1.0 - hueT * 0.8) * armBrightness * binAmp * radialMask;
  float g = (0.4 + hueT * 0.3) * armBrightness * binAmp * radialMask * 0.7;
  float b = (0.2 + hueT * 0.8) * armBrightness * binAmp * radialMask;

  fragColor = vec4(clamp(r, 0.0, 1.0),
                   clamp(g, 0.0, 1.0),
                   clamp(b, 0.0, 1.0),
                   1.0);
}
