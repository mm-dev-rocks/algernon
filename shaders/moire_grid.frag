#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_moire_grid.frag
//
// Visualisation strategy: moiré interference between two concentric circle
// fields.
//
// A single field of concentric circles (rings at regular radial intervals) is
// a smooth, boring pattern. But overlay TWO such fields with their centres
// slightly offset from each other, and the beating between them produces a
// complex, slowly-shifting moiré — emergent geometry that neither field
// contains alone.
//
// Here:
//   - Field A is centred slightly left/up of screen centre.
//   - Field B is centred slightly right/down.
//   - The offset between them is driven by bass energy, so heavy beats
//     pull the two centres apart, stretching and morphing the moiré.
//   - Ring density (spatial frequency) is driven by treble, so bright
//     high-frequency content tightens the pattern into fine detail.
//   - Colour is split across the two fields so they appear different hues,
//     and their interference zone glows where both fields are "in phase".
//
// The visual form is entirely emergent — there is no explicit geometry
// being drawn, just two scalar fields multiplied together.
//
// Method contrast vs other shaders in this set:
//   interference_waves   — sums sinusoidal waves from point sources
//   rings_radial         — single polar field, bins → radius bands
//   THIS SHADER          — product of two offset circular fields, moiré beating

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

uniform float u_ringDensity;
uniform float u_ringContrast;
uniform float u_maxOffset;

// Hue rotation in degrees. 0.0 = original colours.
// Recommended range: 0.0 to 360.0 (wraps around the colour wheel).
// Interesting fixed points: 120.0 (shifts red→green→blue),
// 180.0 (full complement), 240.0, etc.
uniform float u_hueShift;

out vec4 fragColor;

// --- Hue rotation helpers ---

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Helper: reads a single bin by float index and returns amplitude 0..1.
// +0.5 texel-centre offset prevents bleeding — codebase convention.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

// Helper: evaluate the concentric-circle scalar field at point p, centred
// on 'centre', with the given ring spacing (rings per unit).
// Returns a value in 0..1 where 1.0 = ring crest, 0.0 = ring trough.
float circleField(vec2 p, vec2 centre, float ringsPerUnit) {
  float dist = length(p - centre);
  // sin() oscillates -1..1; remap to 0..1 for a clean brightness value.
  return sin(dist * ringsPerUnit * 6.28318530) * 0.5 + 0.5;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct so circles are round on non-square screens.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- FFT band averages ---
  //
  // Using averages over several adjacent bins reduces single-bin jitter and
  // gives each parameter a sense of weight/momentum.
  float bassEnergy =
      (sampleBin(2.0) + sampleBin(4.0) + sampleBin(6.0) + sampleBin(8.0)) / 4.0;
  float midEnergy = (sampleBin(25.0) + sampleBin(35.0) + sampleBin(45.0)) / 3.0;
  float trebleEnergy =
      (sampleBin(90.0) + sampleBin(110.0) + sampleBin(130.0)) / 3.0;

  // --- Field centre positions ---
  //
  // Field A is displaced toward upper-left, field B toward lower-right.
  // Bass energy controls the separation — a kick drum physically pulls
  // the two centres apart, dramatically reshaping the moiré.
  float offset = bassEnergy * u_maxOffset;
  vec2 centreA = vec2(-offset, offset * 0.6); // upper-left quadrant
  vec2 centreB = vec2(offset, -offset * 0.6); // lower-right quadrant

  // Mid energy adds a slow lateral drift to break left-right symmetry and
  // keep the pattern interesting during sustained mid-heavy passages.
  centreA.x -= midEnergy * 0.08;
  centreB.x += midEnergy * 0.08;

  // --- Ring density ---
  //
  // Treble energy adds extra ring density: bright cymbals / hi-hats tighten
  // the concentric rings into fine detail, making the moiré more intricate.
  float ringsPerUnit = u_ringDensity + trebleEnergy * 10.0;

  // --- Evaluate both fields ---
  float fieldA = circleField(p, centreA, ringsPerUnit);
  float fieldB = circleField(p, centreB, ringsPerUnit);

  // Apply contrast curve to each field independently.
  // pow() with RING_CONTRAST > 1 darkens the troughs and brightens the crests,
  // sharpening the ring edges from a soft gradient into distinct bright bands.
  fieldA = pow(fieldA, u_ringContrast);
  fieldB = pow(fieldB, u_ringContrast);

  // --- Moiré: multiply the two fields ---
  //
  // Multiplication is the key operation: the product is bright (near 1.0) only
  // where BOTH fields are simultaneously at a crest. This is constructive
  // interference. Where either field is at a trough the product collapses
  // toward zero — destructive interference. The beating between the two
  // incommensurate ring spacings (they are at the same density but different
  // centres) produces the moiré.
  float moire = fieldA * fieldB;

  // --- Colour ---
  //
  // Field A contributes to the red/magenta channel, field B to blue/cyan.
  // Their overlap zone (the moiré bands) naturally produces purple/white
  // where both are simultaneously bright.
  float r = fieldA * (0.5 + bassEnergy * 0.5);
  float g = moire * (0.3 + midEnergy * 0.7); // moiré zones glow green
  float b = fieldB * (0.5 + trebleEnergy * 0.5);

  // Boost all channels slightly by overall loudness so the shader doesn't
  // go fully black during quiet passages.
  float loudness = (bassEnergy + midEnergy + trebleEnergy) / 50.0;
  r = clamp(r + loudness * 0.04, 0.0, 1.0);
  g = clamp(g + loudness * 0.04, 0.0, 1.0);
  b = clamp(b + loudness * 0.04, 0.0, 1.0);

  // --- Hue rotation ---
  vec3 col = vec3(r, g, b);
  vec3 hsv = rgb2hsv(col);
  hsv.x = fract(hsv.x + u_hueShift / 360.0); // rotate hue, wrap at 1.0
  col = hsv2rgb(hsv);

  fragColor = vec4(col, 1.0);
}
