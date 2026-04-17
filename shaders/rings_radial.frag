#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_rings_radial.frag
//
// Visualisation strategy: concentric rings.
//
// The screen is divided into radial distance bands from the centre. Each band
// maps to a frequency bin: bass frequencies live in the innermost rings,
// treble at the outermost edge. A ring lights up brightly when its bin is
// loud, and dims when quiet.
//
// This is the spatial opposite of the rose_tunnel_quadrant shader: that one
// maps frequency to *angle*; this one maps frequency to *radius*.

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// How many concentric rings to draw. 16 divides cleanly into our 256-bin
// texture (16 bins per ring), giving a nice coarse-but-readable display.
const float RING_COUNT = 16.0;

// Fraction of each ring's width that is the lit band vs the dark gap.
// 0.8 = 80 % lit, 20 % gap. Purely aesthetic — adjust to taste.
const float RING_FILL = 0.8;

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Shift origin to screen centre so distance/angle are measured from there.
  vec2 fragmentOffset = st - vec2(0.5, 0.5);

  // Euclidean distance from centre, in normalised units.
  // At the corners of a square canvas this reaches ~0.707; at the edge
  // midpoints it is exactly 0.5. We treat 0.5 as "full radius" for mapping.
  float distFromCentre = length(fragmentOffset);

  // Map the radial distance 0..0.5 onto RING_COUNT rings.
  // Multiplying by 2.0 stretches the range to 0..1 before scaling by
  // RING_COUNT, so the outermost ring reaches the edge midpoints cleanly.
  float ringPosition = distFromCentre * 2.0 * RING_COUNT;

  // Which ring are we in? (integer, 0-indexed from centre outward)
  float ringIndex = floor(ringPosition);

  // Fractional position *within* this ring (0.0 = inner edge, 1.0 = outer).
  float ringFrac = fract(ringPosition);

  // Clamp so pixels beyond the last ring (corners, etc.) stay black.
  if (ringIndex >= RING_COUNT) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // Each ring averages over a block of (256 / RING_COUNT) = 16 consecutive
  // bins. We sample at the midpoint of that block, matching the +0.5 offset
  // convention used elsewhere in this codebase.
  float binsPerRing = 256.0 / RING_COUNT;
  float binIndex = ringIndex * binsPerRing + binsPerRing * 0.5;
  vec4 fftSample = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5));
  float binValue = fftSample.r;
  // Unpack charge back to [-1, 1]
  float charge = (fftSample.g - 0.5) * 2.0;

  // The lit band occupies the inner RING_FILL fraction of the ring.
  // Pixels in the outer gap fraction are always dark, creating separation
  // between rings regardless of audio level.
  float inBand = step(ringFrac, RING_FILL);
  // float dynamicFill = RING_FILL + charge * 0.15;
  // float inBand = step(ringFrac, clamp(dynamicFill, 0.0, 1.0));

  // Colour: map ring index to a hue shift from deep blue (bass) to cyan/green
  // (treble). Using simple RGB mixing rather than a full HSV conversion keeps
  // this shader free of trig-heavy code and maximises compatibility.
  float hueT = ringIndex / RING_COUNT; // 0.0 (bass) .. 1.0 (treble)
  // float r = 0.0;                       // no red — keeps it cool-toned
  float r = charge * 0.4;     // sudden hits blush red; drops go teal
  float g = hueT * 0.8;       // treble frequencies go green
  float b = 1.0 - hueT * 0.5; // bass frequencies are fully blue

  // Scale colour by the bin amplitude and band mask.
  // binValue drives brightness; inBand masks the gap between rings.
  fragColor = vec4(r * binValue * inBand, g * binValue * inBand,
                   b * binValue * inBand, 1.0);
}
