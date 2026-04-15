#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_moire_grid.frag
//
// Visualisation strategy: moiré interference between two concentric circle fields.
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

uniform vec2      u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// Baseline ring density: how many full ring cycles fit across the screen
// at silence. Higher = finer rings, more detail in the moiré pattern.
const float RING_DENSITY   = 14.0;

// Maximum offset of each field centre from screen centre, in normalised
// units (0..1 space). At full bass energy both centres reach this distance
// from the middle, so the total spread is 2 × MAX_OFFSET.
const float MAX_OFFSET     = 0.22;

// Controls how sharply the ring edges are defined.
// 1.0 = smooth sine gradient, higher values → harder, brighter ring edges.
const float RING_CONTRAST  = 1.8;

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
  vec2 p   = st - vec2(0.5, 0.5);
  p.x     *= u_resolution.x / u_resolution.y;

  // --- FFT band averages ---
  //
  // Using averages over several adjacent bins reduces single-bin jitter and
  // gives each parameter a sense of weight/momentum.
  float bassEnergy   = (sampleBin(2.0)  + sampleBin(4.0)  + sampleBin(6.0)  + sampleBin(8.0))  / 4.0;
  float midEnergy    = (sampleBin(25.0) + sampleBin(35.0) + sampleBin(45.0))                    / 3.0;
  float trebleEnergy = (sampleBin(90.0) + sampleBin(110.0)+ sampleBin(130.0))                   / 3.0;

  // --- Field centre positions ---
  //
  // Field A is displaced toward upper-left, field B toward lower-right.
  // Bass energy controls the separation — a kick drum physically pulls
  // the two centres apart, dramatically reshaping the moiré.
  float offset   = bassEnergy * MAX_OFFSET;
  vec2  centreA  = vec2(-offset,  offset * 0.6);   // upper-left quadrant
  vec2  centreB  = vec2( offset, -offset * 0.6);   // lower-right quadrant

  // Mid energy adds a slow lateral drift to break left-right symmetry and
  // keep the pattern interesting during sustained mid-heavy passages.
  centreA.x -= midEnergy * 0.08;
  centreB.x += midEnergy * 0.08;

  // --- Ring density ---
  //
  // Treble energy adds extra ring density: bright cymbals / hi-hats tighten
  // the concentric rings into fine detail, making the moiré more intricate.
  float ringsPerUnit = RING_DENSITY + trebleEnergy * 10.0;

  // --- Evaluate both fields ---
  float fieldA = circleField(p, centreA, ringsPerUnit);
  float fieldB = circleField(p, centreB, ringsPerUnit);

  // Apply contrast curve to each field independently.
  // pow() with RING_CONTRAST > 1 darkens the troughs and brightens the crests,
  // sharpening the ring edges from a soft gradient into distinct bright bands.
  fieldA = pow(fieldA, RING_CONTRAST);
  fieldB = pow(fieldB, RING_CONTRAST);

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
  float r = fieldA * (0.5 + bassEnergy   * 0.5);
  float g = moire  * (0.3 + midEnergy    * 0.7);   // moiré zones glow green
  float b = fieldB * (0.5 + trebleEnergy * 0.5);

  // Boost all channels slightly by overall loudness so the shader doesn't
  // go fully black during quiet passages.
  float loudness = (bassEnergy + midEnergy + trebleEnergy) / 3.0;
  r = clamp(r + loudness * 0.04, 0.0, 1.0);
  g = clamp(g + loudness * 0.04, 0.0, 1.0);
  b = clamp(b + loudness * 0.04, 0.0, 1.0);

  fragColor = vec4(r, g, b, 1.0);
}
