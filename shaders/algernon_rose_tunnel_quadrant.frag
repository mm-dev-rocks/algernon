#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform sampler2D u_fftData;
out vec4 fragmentColor;

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
  // divide by pi to get -1..1, then shift and scale to 0..1 for use as texture
  // coordinate
  float angleFraction = ((angle / 3.14159265 + 1.0) / 2.0) * circleDivisor;
  float distFromCentre = length(fragmentOffset);
  float binValue = texture(u_fftData, vec2(angleFraction, 0.5)).r;
  float intensity = binValue / distFromCentre * 0.15;
  // Normalised 0..1 across the colour range
  float colorPosition = angleFraction * 2.0;
  fragmentColor = vec4(intensity * (2.0 - colorPosition),
                       intensity * colorPosition * 0.5, intensity, 1.0);
}
