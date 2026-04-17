#version 460 core
#include <flutter/runtime_effect.glsl>
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
//   u_ringDensity    — TweakType.uniformRingDensity (already exists)
//                     min: 4.0   max: 64.0   default: 16.0
//                     Note: pass as float, no divisions needed.
//
//   u_ringFill     — TweakType.uniformRingFill (NEW enum value needed)
//                     min: 0.05   max: 0.99   default: 0.75
//                     Fraction of each ring's width that is lit vs gap.
//
// fftDataSmoothing — same as all other shaders, no changes needed.

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

// min: 0.0  max: 360.0  default: 200.0
// Hue of the bass (innermost) ring in degrees. Shift this to rotate the
// whole palette. 200 = a cool blue starting point.
uniform float u_hueShift;

// min: 0.0  max: 360.0  default: 120.0
// How many degrees of hue are swept from bass ring to treble ring.
// 120 = bass-to-treble sweeps a third of the colour wheel (e.g. blue->green).
// 360 = full rainbow across the rings.
// 0   = all rings share the same hue (monochrome, still uses saturation/value).
uniform float u_hueRange;

// min: 4.0  max: 64.0  default: 16.0
// Number of concentric rings. Low = bold graphic shapes. High = fine detail.
uniform float u_ringDensity;

// min: 0.05  max: 0.99  default: 0.75
// Fraction of each ring's radial width that is lit. The remainder is a dark
// gap that separates rings. Charge widens/narrows this dynamically on top.
uniform float u_ringFill;

out vec4 fragColor;

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
  // Final multiplier scales the entire thing up, but inversely (<1 scales up,
  // >1 scales down)
  float distFromCentre = length(fragmentOffset) * 0.5;

  // Map 0..0.5 radial distance onto u_ringDensity rings.
  float ringPosition = distFromCentre * 2.0 * u_ringDensity;
  float ringIndex = floor(ringPosition);
  float ringFrac = fract(ringPosition);

  // Pixels beyond the last ring (corners, etc.) stay black.
  if (ringIndex >= u_ringDensity) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // ---------------------------------------------------------------------------
  // Sample FFT texture — both magnitude (R) and charge (G).
  // Each ring covers (256 / u_ringDensity) bins; sample at block midpoint.
  // ---------------------------------------------------------------------------
  float binsPerRing = 256.0 / u_ringDensity;
  float binIndex = ringIndex * binsPerRing + binsPerRing * 0.5;
  vec4 fftSample = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5));

  float magnitude = fftSample.r;            // 0..1, raw bin energy
  float charge = (fftSample.g - 0.5) * 2.0; // -1..1, louder-than-avg > 0

  // ---------------------------------------------------------------------------
  // Ring fill: charge expands (+) or contracts (-) the lit band.
  // The +/-0.18 influence keeps the effect readable without being frantic.
  // Clamped so a ring never fully disappears or bleeds into the gap.
  // ---------------------------------------------------------------------------
  float dynamicFill = clamp(u_ringFill + charge * 0.18, 0.02, 0.99);
  // float inBand = step(ringFrac, dynamicFill);
  float edgeWidth = 0.5; // tweak to taste
  float inBand = smoothstep(dynamicFill, dynamicFill - edgeWidth, ringFrac);

  // ---------------------------------------------------------------------------
  // Colour: HSV with hue swept bass->treble across u_hueRange degrees.
  // Charge nudges hue warm (+) or cool (-) by up to 20 degrees on top,
  // so transient hits blush toward the warm side of the current hue.
  // Value is magnitude-driven with a small floor so quiet rings stay visible.
  // ---------------------------------------------------------------------------
  float hueT = ringIndex / u_ringDensity; // 0.0 (bass) .. 1.0 (treble)
  float hue = u_hueShift + hueT * u_hueRange + charge * 20.0;
  float sat = 1.0;
  float val = clamp(magnitude * 1.4 + 0.05, 0.0, 1.0);

  vec3 colour = hsv2rgb(hue, sat, val);

  // Mask the gap between rings.
  fragColor = vec4(colour * inBand, 1.0);
}
