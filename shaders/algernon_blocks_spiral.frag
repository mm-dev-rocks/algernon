#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform sampler2D u_fftData;
out vec4 fragColor;

// This shader is very similar to `algernon_blocks_simple`. The only difference
// is the position/order in which the blocks are drawn. They start (lowest freq)
// in the centre and spiral outwards so that highest frequencies are at the
// outer edges.
float spiralIndex(float x, float y) {
  float cx = x - 7.5;
  float cy = y - 7.5;

  if (cx == 0.0 && cy == 0.0)
    return 0.0;

  float ring = max(abs(cx), abs(cy));
  float ringStart = (2.0 * ring - 1.0) * (2.0 * ring - 1.0);

  float pos;
  if (cy == -ring) {
    pos = cx + ring;
  } else if (cx == ring) {
    pos = 2.0 * ring + cy + ring;
  } else if (cy == ring) {
    pos = 4.0 * ring - (cx + ring);
  } else {
    pos = 6.0 * ring - (cy + ring);
  }

  return ringStart + pos;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  vec2 cell = floor(st * 16.0);
  float binIndex = spiralIndex(cell.x, cell.y);
  float binValue = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
  fragColor = vec4(binValue, binValue, binValue, 1.0);
}
