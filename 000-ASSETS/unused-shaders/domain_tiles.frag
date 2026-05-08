#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// algernon_domain_tiles.frag
//
// Visualisation strategy: tiled domain repetition with per-tile polar plots.
//
// Tiles are arranged in a centre-outward spiral: tile 0 is the centre cell
// (lowest frequencies), winding clockwise outward so the highest frequencies
// reach the corners.
//
// precision mediump float;
//
// uniform vec2 u_resolution;
// uniform float u_time;
// uniform sampler2D u_fftData;
//
// uniform float u_energyMin;
// uniform float u_energyMax;
//
// uniform float u_countPrimary;
//
// out vec4 fragColor;

const int ANGULAR_SAMPLES = 200;
const float PLOT_SCALE = 0.85;
const float OUTLINE_WIDTH = 0.25;
const float PI = 3.14159265;

float spiralIndex(float dx, float dy) {
  float r = max(abs(dx), abs(dy));

  if (r == 0.0)
    return 0.0;

  float ringStart = (2.0 * r - 1.0) * (2.0 * r - 1.0);
  float posOnSide = 0.0;

  bool onRight = dx == r && dy > -r;
  bool onTop = dy == r && !onRight;
  bool onLeft = dx == -r && !onRight && !onTop;
  bool onBottom = !onRight && !onTop && !onLeft;

  if (onRight)
    posOnSide = dy + (r - 1.0);
  if (onTop)
    posOnSide = 2.0 * r + (r - 1.0 - dx);
  if (onLeft)
    posOnSide = 4.0 * r + (r - 1.0 - dy);
  if (onBottom)
    posOnSide = 6.0 * r + (dx + r - 1.0);

  return ringStart + posOnSide;
}

float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

float plotRadius(float tileIndex, float angle) {
  int nBands =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);
  float binsPerTile = 256.0 / float(nBands * nBands);
  float angleFrac = (angle + PI) / (2.0 * PI);
  float binStart = tileIndex * binsPerTile;
  float binIndex = binStart + angleFrac * binsPerTile;
  float amp = sampleBin(binIndex);
  return amp * PLOT_SCALE * 0.5;
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  int nBands =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);
  vec2 tileCoord = floor(st * float(nBands));
  vec2 localST = fract(st * float(nBands));

  float gridCentre = float(nBands) * 0.5 - 0.5;
  float dx = floor(tileCoord.x - gridCentre + 0.5);
  float dy = floor(tileCoord.y - gridCentre + 0.5);
  float tileIndex = spiralIndex(dx, dy);

  vec2 localP = localST - vec2(0.5);
  float charge =
      (texture(u_fftData, vec2((tileIndex + 0.5) / 256.0, 0.5)).g - 0.5) * 8.0;
  float localRadius = length(localP * charge);
  float localAngle = atan(localP.y, localP.x);

  float boundary = plotRadius(tileIndex, localAngle);

  bool inside = localRadius < boundary;
  bool onLine =
      localRadius >= boundary && localRadius < boundary + OUTLINE_WIDTH;

  float hueT = tileIndex / float(nBands * nBands);

  float r = clamp(1.0 - abs(hueT * 3.0 - 0.0), 0.0, 1.0) +
            clamp(1.0 - abs(hueT * 3.0 - 3.0), 0.0, 1.0);
  float g = clamp(1.0 - abs(hueT * 3.0 - 1.0), 0.0, 1.0);
  float b = clamp(1.0 - abs(hueT * 3.0 - 2.0), 0.0, 1.0);

  float binsPerTile = 256.0 / float(nBands * nBands);
  float binMid = tileIndex * binsPerTile + binsPerTile * 0.5;
  float tileAmp = sampleBin(binMid);

  vec3 fillColor = vec3(r, g, b) * tileAmp;
  vec3 outlineColor = vec3(r * 0.6 + 0.4, g * 0.6 + 0.4, b * 0.6 + 0.4);
  vec3 bgColor = vec3(r, g, b) * 0.04;

  vec3 color = bgColor;
  if (inside)
    color = fillColor;
  if (onLine)
    color = outlineColor;

  fragColor = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
