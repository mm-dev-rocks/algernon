#version 460 core
#include <flutter/runtime_effect.glsl>

// algernon_oscilloscope_columns.frag
//
// Visualisation strategy: vertical bar graph / oscilloscope columns.
//
// The screen is divided into 256 vertical columns, one per FFT bin. Each
// column is filled from the bottom upward to a height proportional to the
// bin's amplitude. This is the classic "spectrum analyser" look — the kind
// you'd see on a hardware stereo equaliser display.
//
// Method contrast vs other shaders in this set:
//   blocks_simple    — 2D grid, luminance only, reading order
//   blocks_spiral    — 2D grid, luminance only, spiral order
//   rose_tunnel      — polar angle → bin, radial gradient, full colour
//   rings_radial     — polar radius → bin, concentric bands, colour
//   THIS SHADER      — Cartesian columns, filled bars, colour by height
//   warp_kaleido     — domain distortion, symmetry, no direct bin→pixel map

precision mediump float;

uniform vec2      u_resolution;
uniform sampler2D u_fftData;

out vec4 fragColor;

// Gamma for the bar brightness falloff near the top of each bar.
// 1.0 = flat (uniform brightness), >1.0 = bright base, dimmer tip.
// Kept as a constant so it can be tweaked without touching logic.
const float BAR_GAMMA = 1.4;

// Number of frequency bins, matching the texture width used throughout
// this codebase (256 bytes of FFT data packed into a 256x1 texture).
const float BIN_COUNT = 256.0;

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  // st.x runs left-to-right, st.y runs top-to-bottom in Flutter's coordinate
  // system (origin at top-left, same as the rest of Flutter's canvas).
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Which of the 256 frequency bins does this column belong to?
  // floor() snaps to integer bin index; the column is exactly 1/256th of the
  // screen wide. Low frequencies (bin 0) are at the left edge.
  float binIndex = floor(st.x * BIN_COUNT);

  // Sample this bin's amplitude from the FFT texture.
  // The +0.5 offset centres the sample in the texel, avoiding interpolation
  // bleeding at texel boundaries — consistent with the rest of this codebase.
  float binValue = texture(u_fftData, vec2((binIndex + 0.5) / BIN_COUNT, 0.5)).r;

  // Flutter's y-axis: 0.0 is at the TOP of the screen, 1.0 is the BOTTOM.
  // We want bars to grow upward from the bottom, so we invert st.y.
  // invertedY = 0.0 at the bottom of the screen, 1.0 at the top.
  float invertedY = 1.0 - st.y;

  // A pixel is "inside" its bar if the inverted-y position is below the bin's
  // amplitude level. step() returns 1.0 when invertedY <= binValue.
  float insideBar = step(invertedY, binValue);

  // --- Colour mapping ---
  // Two-axis colour: hue varies with frequency (x), brightness varies with
  // height within the bar (y). This gives a "heat map" look where bass is
  // warm (red/orange) and treble is cool (blue/cyan), and bars glow brightest
  // at their base and fade toward their tip.

  // hueT: 0.0 at left (bass) → 1.0 at right (treble).
  float hueT = st.x;

  // heightT: how far up the bar is this pixel? 0.0 = bottom of bar, 1.0 = tip.
  // Clamping avoids divide-by-zero on silent bins (binValue == 0.0).
  float heightT = (binValue > 0.001) ? (invertedY / binValue) : 0.0;
  heightT = clamp(heightT, 0.0, 1.0);

  // Brightness falls off toward the tip using BAR_GAMMA power curve.
  float brightness = pow(1.0 - heightT, BAR_GAMMA);

  // RGB: bass → red, mid → yellow/green, treble → cyan/blue.
  // These are hand-tuned to give warm bass, neutral mids, cool treble.
  float r = (1.0 - hueT) * brightness;           // full red only at bass end
  float g = (1.0 - abs(hueT - 0.5) * 2.0) * brightness; // peaks in the midrange
  float b = hueT * brightness;                    // full blue only at treble end

  // Multiply everything by insideBar to black-out pixels above the bar tip.
  fragColor = vec4(r * insideBar,
                   g * insideBar,
                   b * insideBar,
                   1.0);
}
