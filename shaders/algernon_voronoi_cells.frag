#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_voronoi_cells.frag
//
// Visualisation strategy: dynamic Voronoi diagram.
//
// A Voronoi diagram partitions the plane into cells, one per "site" point.
// Every pixel belongs to the cell of whichever site is nearest to it.
//
// Here we place CELL_COUNT site points on a circle, then let FFT bins push
// each site radially inward/outward from that circle. Loud bins create sites
// that bulge outward, carving large cells; quiet bins retract, leaving small
// tight cells near the centre.
//
// Each cell is coloured by its site's bin amplitude — loud = bright — with
// a cell-edge darkening effect derived from the *second* nearest distance
// (the classic Voronoi border trick: border proximity = |d1 - d2|).
//
// Method contrast vs other shaders in this set:
//   warp_kaleido        — continuous domain warp, no discrete cells
//   lissajous_web       — single parametric curve SDF
//   rings_radial        — concentric bands, polar
//   THIS SHADER         — nearest-neighbour partition, discrete cells

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// Number of Voronoi cells / FFT bins used. 16 is legible and maps naturally
// onto the low-frequency end of the 256-bin array where energy concentrates.
// Keeping it modest also caps the O(N) per-pixel loop cost.
const int CELL_COUNT = 16;

// Radius of the circle on which the sites rest when their bin is silent.
// 0.35 fills roughly 70 % of the shorter screen dimension nicely.
const float BASE_RADIUS = 0.35;

// How far a site can move radially beyond BASE_RADIUS at full amplitude.
// Larger values = more dramatic cell-size swings.
const float PUSH_RANGE = 0.18;

// Border darkness: pixels within this normalised distance of a cell edge
// are darkened toward black. Higher = wider, more visible borders.
const float BORDER_WIDTH = 0.04;

// pi — defined locally so we don't rely on any extension constants.
const float PI = 3.14159265;

// Helper: reads a single bin by float index and returns amplitude 0..1.
// The +0.5 texel-centre offset is the codebase convention for texel-centred
// sampling, preventing interpolation bleed across bin boundaries.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct. p is in roughly -0.5..0.5 on the short axis.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  // --- Voronoi nearest-neighbour search ---
  //
  // For each site we compute its screen position from the bin amplitude, then
  // track the two smallest distances (d1 = nearest, d2 = second nearest).
  // The ratio (d1 / d2) gives a smooth border signal: near 1.0 = near an edge.
  float d1 = 1.0e6;    // distance to nearest site
  float d2 = 1.0e6;    // distance to second nearest site
  float nearAmp = 0.0; // amplitude of the nearest site's bin
  float nearHue = 0.0; // normalised index of the nearest site (for colour)

  for (int i = 0; i < CELL_COUNT; i++) {
    // Evenly space sites around a circle. angleStep = 2*pi / CELL_COUNT.
    float angle = (float(i) / float(CELL_COUNT)) * 2.0 * PI;

    // Bin index: sites map to the first CELL_COUNT bins (bass end of spectrum).
    float binAmp = sampleBin(float(i));

    // Radial position: silent bin → sites sit on BASE_RADIUS; loud → pushed
    // out.
    float radius = BASE_RADIUS + binAmp * PUSH_RANGE;

    // Site position in aspect-corrected screen space.
    vec2 site = vec2(cos(angle), sin(angle)) * radius;

    // Euclidean distance from this fragment to this site.
    float d = length(p - site);

    // Update the two smallest distances.
    if (d < d1) {
      d2 = d1; // old nearest becomes second nearest
      d1 = d;
      nearAmp = binAmp;
      nearHue = float(i) / float(CELL_COUNT); // 0..1 across the site ring
    } else if (d < d2) {
      d2 = d; // only update second nearest
    }
  }

  // --- Border detection ---
  //
  // The border of a Voronoi cell is the locus where d1 == d2 (equidistant
  // from two sites). We approximate border proximity as (d2 - d1), remapped
  // to a 0..1 signal that is 0 at the border and 1 well inside a cell.
  // Dividing by BORDER_WIDTH normalises the width of the dark border line.
  float borderProximity = clamp((d2 - d1) / BORDER_WIDTH, 0.0, 1.0);

  // --- Colour ---
  //
  // Hue rotates around the colour wheel as sites go around the circle.
  // We use a simple RGB decomposition of hue rather than a full HSV conversion
  // to keep the shader compatible with mediump and avoid extra trig.
  //
  // The pattern: hue 0 → red, hue 0.33 → green, hue 0.67 → blue, hue 1 → red.
  // This uses three overlapping triangle waves, each offset by 1/3 of the
  // cycle.
  float r = clamp(1.0 - abs(nearHue * 3.0 - 0.0), 0.0, 1.0)    // red lobe
            + clamp(1.0 - abs(nearHue * 3.0 - 3.0), 0.0, 1.0); // red lobe wraps
  float g = clamp(1.0 - abs(nearHue * 3.0 - 1.0), 0.0, 1.0);   // green lobe
  float b = clamp(1.0 - abs(nearHue * 3.0 - 2.0), 0.0, 1.0);   // blue lobe

  // Scale colour by bin amplitude (quiet cells are dark) and border mask
  // (borders are always dark regardless of amplitude).
  float cellBrightness = nearAmp * borderProximity;

  fragColor =
      vec4(r * cellBrightness, g * cellBrightness, b * cellBrightness, 1.0);
}
