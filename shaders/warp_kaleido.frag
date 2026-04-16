#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_warp_kaleido.frag
//
// Visualisation strategy: kaleidoscopic domain folding.
//
// Rather than mapping bins directly to screen regions, this shader uses the
// FFT data to *warp* the coordinate space before sampling a colour pattern.
// The result looks organic and ever-shifting — bright at peaks, dark in
// troughs — without any explicit geometry (no bars, no rings, no grid).
//
// Technique overview:
//   1. Fold the screen into angular sectors (kaleidoscope symmetry).
//   2. Use a handful of low-frequency bins to warp the folded coordinates.
//   3. Use the overall spectral energy to drive the brightness/saturation.
//
// This is the most "generative" shader in the set — the visual form emerges
// from the audio rather than being predetermined by the layout.

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

// 0.09 - 0.5
uniform float u_warpStrength;
uniform float u_foldCount;

out vec4 fragColor;

// Number of mirror-fold axes. 6 gives hexagonal kaleidoscope symmetry.
// Must be a positive integer; non-integer values produce asymmetric tears.
// const float FOLD_COUNT = 6.0;

// How strongly the FFT bins push and pull the coordinate field.
// Larger values = more dramatic warping; above ~0.3 it can fold on itself.
// const float WARP_STRENGTH = 0.18;

// pi — defined locally so we don't rely on any extension constants.
const float PI = 3.14159265;

// Helper: reads a single bin by integer index and returns its amplitude 0..1.
// The +0.5 texel-centre offset is the same convention used throughout
// this codebase — it prevents bleeding across texel boundaries.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

// Helper: folds an angle into the first sector of a FOLD_COUNT-way symmetry.
// Works by repeatedly reflecting the angle until it lands in [0, sectorAngle].
//   - atan2 gives -pi..pi, so we first shift to 0..2pi
//   - then fold into one sector using mod and mirror
float foldAngle(float theta) {
  // Shift from -pi..pi → 0..2pi
  float t = mod(theta + PI, 2.0 * PI);

  // Width of one sector in radians
  float sectorAngle = PI / u_foldCount;

  // Map t into 0..2pi, then into the nearest sector
  t = mod(t, 2.0 * sectorAngle);

  // Mirror: if we're in the second half of the sector, reflect back
  if (t > sectorAngle) {
    t = 2.0 * sectorAngle - t;
  }
  return t;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre the coordinate system; p is now in roughly -0.5..0.5 on each axis.
  vec2 p = st - vec2(0.5, 0.5);

  // Correct for non-square canvases so the kaleidoscope isn't squashed.
  // Without this, a landscape screen gives oval sectors instead of equal ones.
  p.x *= u_resolution.x / u_resolution.y;

  // --- FFT-driven coordinate warp ---
  //
  // We pick four low-frequency bins to drive displacement offsets in x and y.
  // Bins 2..8 (sub-bass and bass) are used because they tend to have the most
  // energy in music and therefore produce the most dramatic motion.
  //
  // Each pair of bins pushes in perpendicular directions, so loud bass causes
  // the whole field to breathe/pulse while the midrange makes it shimmer.
  float warpX = (sampleBin(2.0) - sampleBin(4.0)) * u_warpStrength;
  float warpY = (sampleBin(6.0) - sampleBin(8.0)) * u_warpStrength;
  p += vec2(warpX, warpY);

  // --- Kaleidoscope fold ---
  //
  // Convert to polar coordinates, fold the angle into one sector, then convert
  // back to Cartesian for the colour computation. The radius is unchanged —
  // only the angular position is mirrored.
  float radius = length(p);
  float angle = atan(p.y, p.x);         // raw angle, -pi..pi
  float foldedAngle = foldAngle(angle); // mirrored into first sector

  // Reconstruct a Cartesian point inside the folded sector.
  // This is what actually creates the kaleidoscope symmetry.
  vec2 q = vec2(cos(foldedAngle), sin(foldedAngle)) * radius;

  // --- Colour computation ---
  //
  // We build colour from the folded-space coordinates (q) modulated by FFT
  // energy bands. Three broad bands — bass, mid, treble — drive R, G, B.
  //
  // sampleBin ranges: 0..10 = sub-bass, 11..50 = bass/low-mid, 51..120 = mid.
  // Each is averaged across a few neighbouring bins (manual box average) to
  // reduce the "jittery single bin" effect and give smoother colour shifts.
  float bass = (sampleBin(3.0) + sampleBin(5.0) + sampleBin(7.0)) / 3.0;
  float mid = (sampleBin(20.0) + sampleBin(30.0) + sampleBin(40.0)) / 3.0;
  float treble = (sampleBin(80.0) + sampleBin(100.0) + sampleBin(120.0)) / 3.0;

  // The folded coordinate q.x / q.y create interference-pattern-like stripes
  // across the sectors. sin() oscillates smoothly between -1 and 1; the
  // *0.5+0.5 remaps it to 0..1 for use as a brightness factor.
  float stripeX = sin(q.x * 12.0) * 0.5 + 0.5;
  float stripeY = sin(q.y * 12.0) * 0.5 + 0.5;
  float pattern = stripeX * stripeY; // product gives a grid/moiré

  // Attenuate pattern by distance from centre so the middle is always dark
  // (avoids a blown-out bright centre that would obscure the structure).
  float radialFade = 1.0 - clamp(radius * 1.4, 0.0, 1.0);
  pattern *= radialFade;

  // Final RGB: each channel is the audio band × the geometric pattern.
  // This means colour shifts with frequency content AND with the kaleidoscope
  // geometry simultaneously — neither dominates independently.
  float r = bass * pattern;
  float g = mid * pattern;
  float b = treble * pattern;

  // Boost overall brightness slightly during loud passages by adding a small
  // fraction of the combined energy. Keeps the shader visible at low volumes.
  float loudness = (bass + mid + treble) / 3.0;
  r += loudness * 0.08;
  g += loudness * 0.08;
  b += loudness * 0.08;

  fragColor =
      vec4(clamp(r, 0.0, 1.0), clamp(g, 0.0, 0.5), clamp(b, 0.0, 1.0), 1.0);
}
