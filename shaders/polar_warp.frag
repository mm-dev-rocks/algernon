#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

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

// pi — defined locally, not relying on any extension constants.
const float PI = 3.14159265;

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct; p is in roughly -0.5..0.5 on the short axis.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- Polar decomposition ---
  //
  // Everything from here works in polar coordinates (radius, angle) rather
  // than Cartesian (x, y). The twist is applied as an additive rotation to
  // the angle, leaving the radius unchanged.
  float radius = length(p) * 0.5;
  float angle = atan(p.y, p.x); // -pi..pi

  int nBands =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);
  // --- Per-ring twist ---
  //
  // Map this fragment's radius to a radial band index (0..BAND_COUNT-1).
  // We treat 0.5 as "full radius" — the edge midpoints of a square canvas.
  // Beyond that (screen corners) the band index saturates at BAND_COUNT-1.
  float bandIndex = clamp(radius * 2.0 * nBands, 0.0, nBands - 1.0);

  // Map band index to a bin index, spreading nBands bands evenly across
  // the 256 bins so bass covers the inner rings, treble the outer.
  float binsPerBand = 256.0 / nBands;
  float binIndex = floor(bandIndex) * binsPerBand + binsPerBand * 0.5;
  vec4 fftSample = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5));
  float magnitude = fftSample.r;             // 0..1, raw bin energy
  float charge = (fftSample.g - 0.5) * 20.0; // -1..1, louder-than-avg > 0
  // float sectionRatio = fftSample.b * 2.0;    // un-normalise back to 0..2
  // rangie
  float sectionRatio = texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * 2.0;

  // The twist applied to this ring: loud bin → large twist angle.
  // The twist is also scaled by an inverse-radius factor so that outer rings
  // (which are physically longer arcs) don't appear to twist more than inner
  // rings — this keeps the visual weight perceptually even across the disc.
  float radiusDamp = 1.0 / (1.0 + radius * 2.0); // falls from 1 → ~0.5 at edge
  float twistAngle = magnitude * u_warp * radiusDamp;

  // Apply the twist: rotate this fragment's angle by the computed twist.
  float twistedAngle = angle + twistAngle;

  // --- Spiral arm pattern ---
  //
  // Map the twisted angle onto u_countSecondary arms using a cosine wave.
  // The argument is (twistedAngle / pi) * u_countSecondary * pi = twistedAngle
  // * u_countSecondary, which goes through u_countSecondary full oscillations
  // per full circle.
  float armSignal = cos(twistedAngle * u_countSecondary);
  // float noise = sin(radius * 20.0 + charge * 10.0);
  // float armSignal = cos(twistedAngle * u_countSecondary + noise * 0.3);

  // Remap -1..1 → 0..1 and apply contrast.
  // float armBrightness = pow(armSignal * 0.5 + 0.5, u_emphasis);
  float contrast = u_emphasis + charge * 2.0;
  float armBrightness = pow(armSignal * 0.5 + 0.5, contrast);

  // --- Radial attenuation ---
  //
  // Fade toward black at the centre (avoids a blown-out point singularity)
  // and at the outer edge (keeps the pattern contained within a soft circle).
  float innerFade = clamp(radius * 5.0, 0.0, 1.0); // black at exact centre
  float outerFade =
      clamp(1.0 - (radius - 0.35) * 4.0, 0.0, 1.0); // soft outer edge
  float radialMask = innerFade * outerFade;

  // --- Colour ---
  //
  // Hue varies with radius so inner rings (bass-driven) are warm and outer
  // rings (treble-driven) are cool. magnitude also modulates brightness so
  // quiet rings are dark even if the arm pattern says they should be lit.
  float hueShift = u_hueShift / 360.0;
  // float hueT = fract(radius * 2.2 + u_hueShift / 360.0);
  float hueT = fract(radius * 2.2 + u_hueShift / 360.0 + sectionRatio * 0.5);
  float shift = u_hueShift / 360.0;

  float rBase = 1.0 - hueT * 0.8;
  float gBase = 0.4 + hueT * 0.5;
  float bBase = 0.2 + hueT * 0.8;

  // rotate palette by mixing channels
  float r = mix(rBase, gBase, shift);
  float g = mix(gBase, bBase, shift);
  float b = mix(bBase, rBase, shift);

  vec3 col = vec3(r, g, b) * armBrightness * magnitude * radialMask;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
