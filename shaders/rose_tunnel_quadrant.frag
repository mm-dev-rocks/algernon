#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// rose_tunnel_quadrant.frag
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_hueShift  — TweakType.uniformHueShift (already exists)
//                 min: 0.0   max: 360.0   default: 0.0
//                 Rotates the final RGB output around the colour wheel.
//                 Because the rotation is applied after the intensity
//                 calculation, white (all channels equal) is unaffected
//                 and the full dynamic range including blow-out is preserved.
//
//   u_speed     — TweakType.uniformSpeed (already exists)
//                 min: 0.0   max: 1.0    default: 0.1
//                 Speed of the slow rotation of the seam/fold points
//                 around the circle.
//
//   u_emphasis  — TweakType.uniformEmphasis (already exists)
//                 min: 0.1   max: 4.0    default: 1.0
//                 Multiplier on intensity — higher values brighten the
//                 image and push the core toward white.

const float PI = 3.14159265;

// ---------------------------------------------------------------------------
// Hue rotation matrix — rotates RGB around the neutral (grey) axis by angle
// a (in radians). White and black are invariant. Based on the standard
// luminance-preserving hue rotation derivation.
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
  // return int(round(count));
  return count;
}

void main() {
  // Mnemonic: st = 'space transform'
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  vec2 centre = vec2(0.5, 0.5);
  vec2 fragmentOffset = st - centre;

  // NB: angles in shaders can usually be assumed to be in radians
  float angle = atan(fragmentOffset.y, fragmentOffset.x);
  // Use varying proportions of the circle to match the full bins
  float circleDivisor = 0.2;
  // atan returns radians in range -pi..pi (half circle each side of centre)
  // u_speed drives a slow continuous rotation of the whole mapping so the
  // seam and fold points drift around the circle over time rather than
  // sitting at fixed clock positions.
  float rotatedAngle = mod(angle + u_time * u_speed + PI, PI * 2.0) - PI;
  // Normalise rotated angle to 0..1
  float t = (rotatedAngle / PI + 1.0) / 2.0;
  // Ping-pong: fold at t=0.5 so the texture is sampled 0→N→0 around the circle.
  // Both edges of the seam land on texture coordinate 0, and the fold point
  // lands on circleDivisor/2 — matching values on both sides of every join,
  // eliminating any visible seam by construction.
  float mirroredFraction = (t < 0.5 ? t : 1.0 - t) * circleDivisor;

  float distFromCentre = length(fragmentOffset);
  float binValue = texture(u_fftData, vec2(mirroredFraction, 0.5)).r;
  float finalEmphasis =
      u_emphasis == -1.0 ? energyDerivedCount() : float(u_emphasis);
  float intensity =
      binValue / distFromCentre * 0.15 * 4.0 * (finalEmphasis / 100);
  // Normalised 0..1 across the colour range — drives the original RGB formula
  // which naturally blows out to white when intensity exceeds 1.0
  float colorPosition = mirroredFraction * 2.0;
  // vec3 colour = vec3(intensity * (2.0 - colorPosition),
  // intensity * colorPosition * 0.5,
  // intensity);

  // Hue rotation applied after intensity so white (all channels equal
  // above 1.0) remains white — the full dynamic range including blow-out is
  // preserved
  // colour = hueRotate(colour, u_hueShift * PI / 180.0);
  vec3 colour =
      hueRotate(vec3(1.0, 0.6, 0.3), u_hueShift * PI / 180.0) * intensity;

  fragColor = vec4(colour, 1.0);
}
