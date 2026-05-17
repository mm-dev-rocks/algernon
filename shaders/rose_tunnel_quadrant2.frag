#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>
#include <precision.frag>

out vec4 fragColor;

// rose_tunnel_quadrant.frag
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_hueShift  — TweakType.uniformHueShift (already exists)
//                 min: 0.0   max: 360.0   default: 0.0
//                 Rotates the final RGB output around the colour wheel.
//                 White (all channels equal) is invariant.
//
//   u_speed     — TweakType.uniformSpeed (already exists)
//                 min: 0.0   max: 1.0    default: 0.1
//                 Speed of the slow rotation of the seam/fold points
//                 around the circle.
//
//   u_emphasis  — TweakType.uniformEmphasis (already exists)
//                 min: 0.1   max: 4.0    default: 1.0
//                 Controls the width of the white→colour gradient band.
//                 Higher = softer/wider transition; lower = sharper edge.
//                 Does NOT affect how much of the radius is covered —
//                 that is determined entirely by the FFT data range.

const float PI = 3.14159265;

// ---------------------------------------------------------------------------
// Hue rotation matrix — rotates RGB around the neutral (grey) axis by angle
// a (in radians). White and black are invariant.
// ---------------------------------------------------------------------------
vec3 hueRotate(vec3 col, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec3(col.r * (0.299 + 0.701 * c + 0.168 * s) +
                  col.g * (0.587 - 0.587 * c - 0.330 * s) +
                  col.b * (0.114 - 0.114 * c + 0.497 * s),
              col.r * (0.299 - 0.299 * c + 0.328 * s) +
                  col.g * (0.587 + 0.413 * c + 0.035 * s) +
                  col.b * (0.114 - 0.114 * c - 0.292 * s),
              col.r * (0.299 - 0.300 * c - 0.900 * s) +
                  col.g * (0.587 - 0.588 * c + 1.050 * s) +
                  col.b * (0.114 + 0.886 * c - 0.203 * s));
}

float energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return count;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  vec2 centre = vec2(0.5, 0.5);
  vec2 fragmentOffset = st - centre;

  float angle = atan(fragmentOffset.y, fragmentOffset.x);
  float circleDivisor = 0.2;
  float rotatedAngle = mod(angle + u_time * u_speed + PI, PI * 2.0) - PI;
  float t = (rotatedAngle / PI + 1.0) / 2.0;
  float mirroredFraction = (t < 0.5 ? t : 1.0 - t) * circleDivisor;

  // ---------------------------------------------------------------------------
  // FFT → radius mapping
  //
  // Instead of using binValue as a raw multiplier that blows out near centre,
  // we treat the FFT value as a *target radius*. The fragment's actual distance
  // from centre is compared to that target, and the result is a smooth 0..1
  // intensity that:
  //   • peaks at 1.0 (white) when dist == fftRadius  (the "surface" of the rose)
  //   • falls off to the base colour outward and to 0 inward
  //   • covers the full radius range because fftRadius itself spans 0..maxRadius
  // ---------------------------------------------------------------------------

  // Raw FFT value in 0..1 (texture red channel)
  float binValue = texture(u_fftData, vec2(mirroredFraction, 0.5)).r;

  // Map FFT range so that the min FFT value maps to radius ~0 and max maps to
  // the corner of the viewport (~0.707 for a square). We normalise via the
  // actual live min/max energy so the full dynamic range always fills the disc.
  // u_fftMin / u_fftMax are the rolling per-frame min and max of u_fftData.
  // If your uniform block doesn't expose those, the fallback (commented below)
  // uses a fixed assumed range of 0.0..1.0 which still beats the old approach.
#ifdef HAS_FFT_RANGE
  float normBin = clamp((binValue - u_fftMin) / max(u_fftMax - u_fftMin, 0.001), 0.0, 1.0);
#else
  // Fallback: treat the raw 0..1 texture value as already normalised.
  // If quiet passages are always near zero, raise the lower end slightly so
  // even quiet frames still paint most of the disc.
  float normBin = clamp(binValue / 0.6, 0.0, 1.0);   // tweak 0.6 to taste
#endif

  // Maximum radius we ever want the rose to reach (half the shorter viewport
  // dimension keeps it inside the screen on portrait displays).
  float maxRadius = 0.48;

  // The FFT value drives the target radius for this angular slice.
  float fftRadius = normBin * maxRadius;

  float distFromCentre = length(fragmentOffset);

  // ---------------------------------------------------------------------------
  // Smooth band centred on fftRadius.
  // u_emphasis controls the half-width of the gradient (in radius units).
  // A narrow band → sharp edge with crisp colour; wide band → soft glow.
  // Either way the centre never blows out because intensity is always ≤ 1.
  // ---------------------------------------------------------------------------
  float bandWidth = 0.02 * u_emphasis;   // 0.02 = ~4 % of screen at emphasis=1

  // Gaussian-style falloff from the surface — guarantees a smooth, bounded peak
  float delta = distFromCentre - fftRadius;
  float intensity = exp(-(delta * delta) / (2.0 * bandWidth * bandWidth));

  // Hue rotation applied to the base colour; multiply by intensity so the
  // surface is the full colour and both sides fade to black.
  vec3 baseColour = hueRotate(vec3(1.0, 0.6, 0.3), u_hueShift * PI / 180.0);
  vec3 colour = baseColour * intensity;

  fragColor = vec4(colour, 1.0);
}
