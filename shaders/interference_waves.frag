#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_interference_waves.frag
//
// Visualisation strategy: summed radial wave interference.
//
// Multiple point sources radiate sine waves outward. The amplitude of each
// source is driven by a frequency band. The colour at each pixel is derived
// from the *sum* of all wave heights at that point — where waves reinforce
// (constructive interference) the pixel is bright; where they cancel
// (destructive interference) it is dark.
//
// This produces concentric ripple rings around each source, and a complex
// moiré/interference pattern where they overlap — similar to dropping several
// pebbles into a pond simultaneously.
//
// The geometry is fully emergent: no bins map directly to pixels. Instead,
// the *shape* of the interference pattern changes continuously with the audio.
//
// Method contrast vs other shaders in this set:
//   warp_kaleido        — coordinate fold/warp, angular symmetry
//   voronoi_cells       — nearest-neighbour partition, discrete regions
//   lissajous_web       — single SDF curve
//   rings_radial        — static concentric bands, bin → radius
//   THIS SHADER         — summed sinusoidal wave fields, emergent interference

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// Number of wave sources. Each source sits at a fixed position on screen and
// radiates at a spatial frequency (tightness of rings) driven by an FFT band.
// 5 sources gives a rich interference pattern without the loop becoming costly.
const int SOURCE_COUNT = 5;

// Spatial frequency scale: higher = tighter, more numerous rings per unit
// distance. This is a "zoom" on the wave pattern, not the audio frequency.
const float WAVE_SCALE = 18.0;

// How sharply the interference sum is thresholded into bright/dark bands.
// 1.0 = soft sine gradient; higher values snap toward hard bright rings.
const float CONTRAST = 1.6;

// Helper: reads a single bin by float index and returns amplitude 0..1.
// +0.5 texel-centre offset — the codebase convention for bin sampling.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct so the pattern is not squashed on wide canvases.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- Fixed source positions ---
  //
  // Sources are placed by hand at visually interesting asymmetric positions
  // (not a regular grid, not a circle) so the interference pattern has no
  // simple symmetry — it remains complex across all audio states.
  // Coordinates are in the same aspect-corrected space as p above.
  vec2 sources[5];
  sources[0] = vec2(0.00, 0.00);   // centre
  sources[1] = vec2(-0.30, 0.20);  // upper-left
  sources[2] = vec2(0.30, 0.20);   // upper-right
  sources[3] = vec2(-0.20, -0.28); // lower-left
  sources[4] = vec2(0.25, -0.22);  // lower-right

  // --- FFT band mapping ---
  //
  // Each source is driven by a broad average over a frequency sub-band.
  // Using averages over several bins smooths out single-bin jitter and gives
  // each source a sense of "weight" corresponding to a musical register.
  //
  // Bin ranges (approximate musical registers at 44.1 kHz, 256-bin FFT):
  //   0..5    sub-bass (kick drum body, synthesiser root notes)
  //   6..20   bass (bass guitar, lower piano keys)
  //   21..60  low-mid (vocals, guitar body, snare fundamental)
  //   61..120 upper-mid / presence (consonants, plucks, hi-hat body)
  //   121..180 treble (cymbals, air, shimmer)
  float amp[5];
  amp[0] = (sampleBin(2.0) + sampleBin(4.0) + sampleBin(6.0)) / 3.0; // sub-bass
  amp[1] = (sampleBin(10.0) + sampleBin(14.0) + sampleBin(18.0)) / 3.0; // bass
  amp[2] =
      (sampleBin(30.0) + sampleBin(40.0) + sampleBin(50.0)) / 3.0; // low-mid
  amp[3] =
      (sampleBin(80.0) + sampleBin(95.0) + sampleBin(110.0)) / 3.0; // upper-mid
  amp[4] =
      (sampleBin(130.0) + sampleBin(150.0) + sampleBin(170.0)) / 3.0; // treble

  // --- Wave superposition ---
  //
  // For each source, compute the wave height at this fragment:
  //   height = amplitude * sin(WAVE_SCALE * distFromSource)
  //
  // sin() oscillates -1..1, creating alternating crests and troughs as
  // distance increases. Multiplying by the bin amplitude gates the source:
  // a silent bin contributes no wave, so its rings vanish completely.
  //
  // The sum of all heights is then normalised into 0..1 for colour use.
  float waveSum = 0.0;

  for (int i = 0; i < SOURCE_COUNT; i++) {
    float dist = length(p - sources[i]);
    float height = amp[i] * sin(WAVE_SCALE * dist);
    waveSum += height;
  }

  // waveSum is in the range -(SOURCE_COUNT)..(SOURCE_COUNT).
  // Remap to 0..1 by shifting and scaling, then apply contrast curve.
  float normalised = waveSum / float(SOURCE_COUNT) * 0.5 + 0.5; // 0..1
  float contrasted = pow(clamp(normalised, 0.0, 1.0), CONTRAST);

  // --- Colour ---
  //
  // Split the interference pattern across three colour channels using the same
  // audio bands, but phase-shifted so R / G / B respond to different registers.
  // This means a bass-heavy mix glows red, a treble-heavy mix glows blue, and
  // a balanced mix produces near-white interference bands.
  //
  // Each channel is also shifted in phase (by 0 / 0.33 / 0.67 of the cycle)
  // so that the R/G/B fringes land on *different* wavefronts — preventing the
  // trivially boring case where all three channels are identical.
  float bassAmp = amp[0] + amp[1];   // combined low-end weight
  float midAmp = amp[2];             // mid weight
  float trebleAmp = amp[3] + amp[4]; // combined high-end weight

  // Phase offsets create colour separation between wavefronts.
  // The sin() input is the same as the interference calculation above, but
  // here we re-derive it per-channel for the phase shift — the extra sin()
  // calls are on scalars, not vectors, so cost is modest.
  float r = pow(
      clamp(sin(contrasted * 3.14159265 + 0.0) * bassAmp + 0.3, 0.0, 1.0), 1.2);
  float g = pow(
      clamp(sin(contrasted * 3.14159265 + 2.09) * midAmp + 0.3, 0.0, 1.0), 1.2);
  float b = pow(
      clamp(sin(contrasted * 3.14159265 + 4.19) * trebleAmp + 0.3, 0.0, 1.0),
      1.2);

  // Add a base luminance proportional to overall loudness so the visualiser
  // stays visible on near-silent audio (avoids a completely black screen).
  float loudness = (bassAmp + midAmp + trebleAmp) / 5.0;
  r = clamp(r + loudness * 0.05, 0.0, 1.0);
  g = clamp(g + loudness * 0.05, 0.0, 1.0);
  b = clamp(b + loudness * 0.05, 0.0, 1.0);

  fragColor = vec4(r, g, b, 1.0);
}
