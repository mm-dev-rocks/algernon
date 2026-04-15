#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_domain_tiles.frag
//
// Visualisation strategy: tiled domain repetition with per-tile polar plots.
//
// The screen is divided into a grid of small square tiles. Each tile contains
// a miniature polar amplitude plot — a filled disc whose radius at each angle
// reflects the FFT amplitude of a specific frequency sub-band. Tiles are
// arranged so that low-frequency sub-bands occupy the top-left tile, high
// frequencies the bottom-right, matching the reading-order convention
// established in algernon_blocks_simple.
//
// Within each tile the polar plot is computed entirely in local (0..1) tile
// space: the tile centre is the plot origin, and the plot radius grows or
// shrinks at each angle according to the bin amplitudes in that sub-band.
//
// This is fundamentally different from the block shaders: those colour an
// entire cell uniformly with one bin value; this shader draws a shaped object
// (a polar plot) inside each cell driven by a range of bins.
//
// Method contrast vs other shaders in this set:
//   blocks_simple / spiral  — uniform colour per cell, single bin per cell
//   rings_radial            — one global polar field, radius → bin
//   rose_tunnel             — one global polar field, angle → bin
//   THIS SHADER             — tiled repetition, each tile its own polar plot
//                             driven by a sub-band of multiple bins

precision mediump float;

uniform vec2      u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// How many tiles across and down. 8×8 = 64 tiles, each covering 4 bins
// (256 / 64 = 4). Increase for more tiles with finer per-tile detail;
// decrease for fewer, larger, more legible plots.
const float TILE_COUNT     = 8.0;

// Number of angular samples used to evaluate the polar plot boundary at each
// fragment. More samples = smoother plot edges, higher cost.
// 48 is a good mediump-safe balance for mobile.
const int   ANGULAR_SAMPLES = 48;

// Fraction of the tile radius that the polar plot occupies at maximum
// amplitude. 0.85 leaves a small gap between tiles.
const float PLOT_SCALE     = 0.85;

// Width of the glowing outline drawn just outside the polar plot boundary.
// In normalised tile units (0..0.5 = half the tile).
const float OUTLINE_WIDTH  = 0.025;

// pi — defined locally.
const float PI = 3.14159265;

// Helper: reads a single bin by float index and returns amplitude 0..1.
// +0.5 texel-centre offset — codebase convention.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

// Helper: for a given tile (tileX, tileY) and a given angle, return the
// polar radius of the plot boundary at that angle.
//
// Strategy: map the angle (0..2*pi) linearly onto the bins allocated to this
// tile. A tile owns (256 / TILE_COUNT^2) consecutive bins; we sample across
// them proportionally to the angle.
float plotRadius(float tileIndex, float angle) {
  float binsPerTile = 256.0 / (TILE_COUNT * TILE_COUNT);

  // Normalise angle to 0..1 across the full circle.
  float angleFrac = (angle + PI) / (2.0 * PI);

  // Map to the bin range for this tile.
  float binStart = tileIndex * binsPerTile;
  float binIndex = binStart + angleFrac * binsPerTile;

  float amp = sampleBin(binIndex);

  // The plot radius is the bin amplitude scaled to PLOT_SCALE.
  // A silent bin → radius 0 (the plot collapses to a point).
  return amp * PLOT_SCALE * 0.5;   // *0.5 because tile space is -0.5..0.5
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // --- Tile decomposition ---
  //
  // Which tile are we in? tileCoord is the integer (column, row) index.
  // localST is the fractional position within that tile, in 0..1.
  vec2 tileCoord = floor(st * TILE_COUNT);
  vec2 localST   = fract(st * TILE_COUNT);

  // Reading-order tile index: leftmost column of top row = tile 0,
  // rightmost column of bottom row = tile TILE_COUNT^2 - 1.
  // Same convention as algernon_blocks_simple.
  float tileIndex = tileCoord.y * TILE_COUNT + tileCoord.x;

  // Local polar coordinates, centred in the tile.
  // localP is in -0.5..0.5 on each axis within the tile.
  vec2  localP      = localST - vec2(0.5, 0.5);
  float localRadius = length(localP);
  float localAngle  = atan(localP.y, localP.x);   // -pi..pi

  // --- Polar plot boundary at this angle ---
  float boundary = plotRadius(tileIndex, localAngle);

  // --- Inside / outside / outline test ---
  //
  // A fragment is "inside" the plot if its local radius is less than the
  // boundary radius at its angle.
  // The outline zone is the thin band just outside the boundary.
  bool  inside   = localRadius < boundary;
  bool  onLine   = localRadius >= boundary && localRadius < boundary + OUTLINE_WIDTH;

  // --- Per-tile colour ---
  //
  // Hue varies with tile index so each tile has a distinct colour identity.
  // This makes it easy to associate a tile's shape with its frequency band
  // at a glance.
  float hueT = tileIndex / (TILE_COUNT * TILE_COUNT);

  // Simple hue-to-RGB using three offset triangle waves (same approach as
  // algernon_voronoi_cells — no trig, mediump-safe).
  float r = clamp(1.0 - abs(hueT * 3.0 - 0.0), 0.0, 1.0)
          + clamp(1.0 - abs(hueT * 3.0 - 3.0), 0.0, 1.0);
  float g = clamp(1.0 - abs(hueT * 3.0 - 1.0), 0.0, 1.0);
  float b = clamp(1.0 - abs(hueT * 3.0 - 2.0), 0.0, 1.0);

  // --- Overall amplitude of this tile's sub-band ---
  //
  // Used to modulate brightness: a quiet tile is dark even at the plot edge.
  float binsPerTile = 256.0 / (TILE_COUNT * TILE_COUNT);
  float binMid      = tileIndex * binsPerTile + binsPerTile * 0.5;
  float tileAmp     = sampleBin(binMid);

  // --- Combine fill, outline, and background ---
  //
  // Fill: inside the polar plot — hue-coloured, brightness = tile amplitude.
  // Outline: thin bright ring at the plot boundary — always white-ish so it
  //          reads clearly against both dark fill and dark background.
  // Background: the unused tile area — near-black with a faint hue tint.
  vec3 fillColor    = vec3(r, g, b) * tileAmp;
  vec3 outlineColor = vec3(r * 0.6 + 0.4, g * 0.6 + 0.4, b * 0.6 + 0.4);
  vec3 bgColor      = vec3(r, g, b) * 0.04;   // very faint hue ghost

  vec3 color = bgColor;
  if (inside)  color = fillColor;
  if (onLine)  color = outlineColor;

  fragColor = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
