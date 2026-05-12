#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>
#include <precision.frag>

out vec4 fragColor;

// algernon_rings_radial_2.frag
//
// Visualisation strategy: concentric rings with a full HSV palette,
// charge-driven width pulsing and colour temperature shifts, and
// runtime-tweakable ring count, fill, hue base, and hue range.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 200.0
//
//   u_hueRange     — TweakType.uniformHueRange (NEW enum value needed)
//                     min: 0.0   max: 360.0   default: 120.0
//                     Controls how many degrees of hue are spread across
//                     the rings, bass-to-treble. 0 = monochrome, 360 = full
//                     spectrum lap.
//
//   u_countPrimary    — TweakType.uniformRingDensity (already exists)
//                     min: 4.0   max: 64.0   default: 16.0
//                     Note: pass as float, no divisions needed.
//
//   u_emphasis     — TweakType.uniformRingFill (NEW enum value needed)
//                     min: 0.05   max: 0.99   default: 0.75
//                     Fraction of each ring's width that is lit vs gap.
//
// fftDataSmoothing — same as all other shaders, no changes needed.

// ---------------------------------------------------------------------------
// HSV -> RGB conversion. H in [0, 360], S and V in [0, 1].
// Standard six-sector formula — no trig needed.
// ---------------------------------------------------------------------------
vec3 hsv2rgb(float h, float s, float v) {
  h = mod(h, 360.0);
  float c = v * s;
  float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
  float m = v - c;
  vec3 rgb;
  if (h < 60.0)
    rgb = vec3(c, x, 0.0);
  else if (h < 120.0)
    rgb = vec3(x, c, 0.0);
  else if (h < 180.0)
    rgb = vec3(0.0, c, x);
  else if (h < 240.0)
    rgb = vec3(0.0, x, c);
  else if (h < 300.0)
    rgb = vec3(x, 0.0, c);
  else
    rgb = vec3(c, 0.0, x);
  return rgb + m;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  vec2 fragmentOffset = st - vec2(0.5, 0.5);
  float distFromCentre = length(fragmentOffset) * 0.5;

  // Map 0..0.5 radial distance onto u_countPrimary rings.
  float ringPosition = distFromCentre * 2.0 * u_countPrimary;
  float ringIndex = floor(ringPosition);
  float ringFrac = fract(ringPosition);

  // Pixels beyond the last ring (corners, etc.) stay black.
  if (ringIndex >= u_countPrimary) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // ---------------------------------------------------------------------------
  // Sample FFT texture — both magnitude (R) and charge (G).
  // Each ring covers (256 / u_countPrimary) bins; sample at block midpoint.
  // ---------------------------------------------------------------------------
  float binsPerRing = 256.0 / u_countPrimary;
  float binIndex = ringIndex * binsPerRing + binsPerRing * 0.5;
  vec4 fftSample = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5));

  float magnitude = fftSample.r;            // 0..1, raw bin energy
  float charge = (fftSample.g - 0.5) * 2.0; // -1..1, louder-than-avg > 0

  // ---------------------------------------------------------------------------
  // Ring fill: charge expands (+) or contracts (-) the lit band.
  // Cosine falloff at the edge avoids the hard step that caused aliasing.
  // ---------------------------------------------------------------------------
  float dynamicFill = clamp(u_emphasis + charge * 0.18, 0.02, 0.99);
  // float inBand = ringFrac < dynamicFill ? 1.0 : clamp(cos((ringFrac -
  // dynamicFill) * 3.14159 / (1.0 - dynamicFill)) * 0.5 + 0.5, 0.0, 1.0);
  float inBand =
      1.0 - smoothstep(dynamicFill - 0.3, dynamicFill + 0.3, ringFrac);

  // ---------------------------------------------------------------------------
  // Colour: HSV with hue swept bass->treble across u_hueRange degrees.
  // Charge nudges hue warm (+) or cool (-) by up to 20 degrees on top,
  // so transient hits blush toward the warm side of the current hue.
  // Value is magnitude-driven with a small floor so quiet rings stay visible.
  // ---------------------------------------------------------------------------
  float hueT = ringIndex / u_countPrimary; // 0.0 (bass) .. 1.0 (treble)
  float hue = u_hueShift + hueT * u_hueRange + charge * 20.0;
  float sat = 1.0;
  float val = clamp(magnitude * 1.4 + 0.05, 0.0, 1.0);

  vec3 colour = hsv2rgb(hue, sat, val);

  fragColor = vec4(colour * inBand, 1.0);
}
