#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

void main() {
  // GLSL texture coordinate naming convention:
  // (s, t, r, q) maps to (x, y, z, w)
  //
  // x/y/z being 3D coordinates
  // NB: w is used for perspective division --- it's what makes things look
  // smaller as they get further away In a perspective projection matrix the
  // math works out so that dividing xyz by w gives you the final screen
  // position. Normalised from 0.0 to 1.0.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // We have 256 bytes of frequency data/bins in `u_fftData`. A simple way to
  // represent them on-screen is in a 16x16 grid. In this case the lowest
  // frequencies are at top-left, they are drawn in R-to-L, T-to-B (reading)
  // order. So highest frequencies are at bottom-right.
  vec2 cell = floor(st * 16.0);
  float binIndex = cell.y * 16.0 + cell.x;
  // 0.5 is the centre of the pixel
  float binValue = texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;

  // Output the calculated colour
  fragColor = vec4(binValue, binValue, binValue, 1.0);
}
