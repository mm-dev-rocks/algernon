#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision mediump float;

out vec4 fragColor;

// algernon_spectral_sphere.frag
//
// Visualisation strategy: a transparent sphere whose surface is populated by
// 256 glowing blobs — one per FFT bin — distributed evenly using a Fibonacci
// lattice. Each blob glows brighter when its bin magnitude (R channel) is high.
// The green channel (charge, remapped to -1..1) pushes a blob radially outward
// (positive) or inward / below the surface (negative). The blue channel drives
// a broad low-frequency breathing of the whole sphere. Soft sinusoidal motion
// from u_time gives the sphere a slow living rotation.
//
// Rendering method: ray-marching is too heavy for mobile. Instead we project
// each blob's 3-D surface point to screen space and accumulate a soft radial
// glow at that projected position. The sphere is rendered as a transparent
// shell; blobs behind the equator are attenuated so near-side blobs dominate.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 200.0
//
//   u_hueRange      — TweakType.uniformHueRange (already exists)
//                     min: 0.0   max: 360.0   default: 140.0
//                     Hue spread from bin 0 (bass) to bin 255 (treble).
//
//   u_zoom  — TweakType.uniformSphereRadius (NEW enum value needed)
//                     min: 0.15  max: 0.48   default: 0.32
//                     Radius of the sphere in normalised canvas units.
//
//   u_size      — TweakType.uniformBlobSize (already exists)
//                     min: 0.01  max: 0.12   default: 0.038
//                     Base half-width of each blob in screen units.
//
//   u_emphasis  — TweakType.uniformGlowStrength (NEW enum value needed)
//                     min: 0.5   max: 4.0    default: 1.8
//                     Multiplier on each blob's brightness contribution.
//
//   u_speed         — TweakType.uniformSpeed (already exists)
//                     min: 0.05  max: 1.0    default: 0.18
//                     Overall rotation speed.
//
// fftDataSmoothing — same as all other shaders.
//
//precision mediump float;
//
//uniform vec2 u_resolution;
//uniform float u_time;
//uniform sampler2D u_fftData;
//
//uniform float u_hueShift;
//uniform float u_hueRange;
//uniform float u_zoom;
//uniform float u_size;
//uniform float u_emphasis;
//uniform float u_speed;
//uniform float u_countPrimary;
//
//out vec4 fragColor;

const float PI = 3.14159265;
const float TAU = 6.28318530;
// const int BINS = 256;
// const int BINS = 128;
// const int BINS = 64;
int BINS = int(u_countPrimary);

// ---------------------------------------------------------------------------
// HSV → RGB — H in [0,360], S/V in [0,1].
// Identical implementation used across all shaders in this project.
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

// ---------------------------------------------------------------------------
// Sample a single FFT bin.
//   .x = magnitude  (R channel, 0..1)
//   .y = charge      (G channel, remapped from 0..1 → -1..1)
//   .z = energy      (B channel, 0..1, first bin only used globally)
// ---------------------------------------------------------------------------
vec3 sampleBin(float binIdx) {
  // float u = (binIdx + 0.5) / 256.0;
  // float u = (binIdx * 2.0 + 0.5) / 256.0;
  float binFix = 256 / BINS;
  float u = (binIdx * binFix + 0.5) / 256.0;
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec3(s.r, (s.g - 0.5) * 2.0, s.b);
}

// ---------------------------------------------------------------------------
// Fibonacci lattice on the unit sphere.
// Maps integer index i (0..N-1) to a 3-D unit vector.
// The golden angle keeps points maximally spread.
// ---------------------------------------------------------------------------
vec3 fibonacciPoint(int i, int N) {
  float fi = float(i);
  float fN = float(N);
  float phi = acos(1.0 - 2.0 * (fi + 0.5) / fN); // polar angle  0..PI
  float th = TAU * fi / 1.6180339887;            // azimuth, golden angle
  return vec3(sin(phi) * cos(th), sin(phi) * sin(th), cos(phi));
}

// ---------------------------------------------------------------------------
// 3×3 rotation matrix around Y axis — used for the slow time rotation.
// ---------------------------------------------------------------------------
mat3 rotY(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

// ---------------------------------------------------------------------------
// 3×3 rotation matrix around X axis — slight tilt so the poles aren't flat.
// ---------------------------------------------------------------------------
mat3 rotX(float a) {
  float c = cos(a), s = sin(a);
  return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
}

void main() {
  // --- Screen-space setup ---
  // st: normalised 0..1 coords. p: centred, aspect-corrected (-asp/2 .. asp/2,
  // -0.5..0.5).
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float aspect = u_resolution.x / u_resolution.y;
  vec2 p = (st - 0.5) * vec2(aspect, 1.0);

  // --- Global energy (blue channel from bin 0) ---
  // Used to breathe the sphere size and add broad motion.
  float energy = sampleBin(0.0).z; // 0..1, chunky/broad

  // Sphere radius breathes gently with energy, plus a slow sinusoidal pulse.
  float breathe = 1.0 + energy * 0.12 + sin(u_time * 0.4) * 0.03;
  float radius = u_zoom * breathe;

  // --- Slow orientation drift driven by u_time and energy ---
  float rotAngleY = u_time * u_speed + energy * 0.6;
  float rotAngleX = sin(u_time * u_speed * 0.37) * 0.4 + energy * 0.2;
  mat3 orient = rotX(rotAngleX) * rotY(rotAngleY);

  // --- Accumulate blob contributions ---
  vec3 colourAcc = vec3(0.0);
  float alphaAcc = 0.0;

  // Soft ambient sphere rim — a faint halo so the sphere reads even in silence.
  float rimDist = abs(length(p) - radius);
  float rimGlow = exp(-rimDist * rimDist * 800.0) * 0.07;
  vec3 rimColour = hsv2rgb(u_hueShift, 0.5, 0.4);

  for (int i = 0; i < 999; i++) {
    if (i >= BINS)
      break;

    float fi = float(i);
    float t = fi / float(BINS - 1); // 0..1, bass→treble

    // Sample FFT for this bin.
    vec3 fc = sampleBin(fi);
    // float mag = fc.x;    // 0..1
    float mag = max(fc.x, 0.21); // floor: quiet bins still show faintly
    float charge = fc.y;         // -1..1

    // Skip bins that contribute nothing — saves fillrate on quiet passages.
    // if (mag < 0.005 && abs(charge) < 0.02) continue;
    if (mag < 0.005 && abs(charge) < 0.02)
      continue;

    // --- 3-D position of this blob ---
    // Base point on unit sphere from Fibonacci lattice.
    vec3 base = fibonacciPoint(i, BINS);

    // Radial displacement: positive charge lifts blob above surface,
    // negative charge sinks it inward. Energy adds a gentle global push.
    float displacement = charge * 0.33 + energy * 0.06 +
                         sin(u_time * (0.3 + t * 0.7) + fi * 0.41) * 0.015;
    float r3d = radius * (1.0 + displacement);

    vec3 pos3d = orient * (base * r3d); // rotated world-space position

    // --- Project to screen (simple orthographic, sphere centred at origin) ---
    vec2 screenPos = pos3d.xy; // z handled via depth-attenuation below

    // --- Depth cue: blobs behind the sphere (z < 0) are dimmer and slightly
    //     smaller, giving transparent-sphere depth without ray-marching.
    float depth = pos3d.z;                                     // -r3d .. r3d
    float depthFade = 0.35 + 0.65 * (depth / r3d + 1.0) * 0.5; // 0.35..1.0
    // Behind-surface blobs also get a soft occlusion from the sphere shell.
    float occlude = (depth < 0.0) ? 0.55 : 1.0;
    float visibility = depthFade * occlude;

    // --- Blob size: larger when charge is high, modulated by mag and depth.
    // ---
    float blobR = u_size * (1.0 + mag * 0.8 + max(charge, 0.0) * 0.5) *
                  (0.7 + 0.3 * depthFade);

    // --- Soft Gaussian blob ---
    vec2 diff = p - screenPos;
    float d2 = dot(diff, diff);
    float blob = exp(-d2 / (blobR * blobR)) * visibility;

    // Extra core: a tight bright centre when magnitude is high.
    float core = exp(-d2 / (blobR * blobR * 0.08)) * mag * 0.6 * visibility;

    float contribution = (blob + core) * mag * u_emphasis;

    // --- Colour: hue sweeps bass→treble across u_hueRange.
    //     Charge nudges hue warm (positive) or cool (negative).
    //     Value is magnitude-driven with a small floor. ---
    float hue = u_hueShift + t * u_hueRange + charge * 18.0;
    float sat = 0.85 + mag * 0.15;
    float val = clamp(mag * 1.5 + 0.08, 0.0, 1.0);
    vec3 blobColour = hsv2rgb(hue, sat, val);

    colourAcc += blobColour * contribution;
    alphaAcc += contribution;
  }

  // --- Composite ---
  // Normalise colour by accumulated weight; add rim ambient.
  vec3 finalColour = rimColour * rimGlow;
  if (alphaAcc > 0.001) {
    finalColour += colourAcc / alphaAcc * clamp(alphaAcc, 0.0, 1.0);
  }

  // Soft vignette so the canvas edges fade to black cleanly.
  // float vignette = 1.0 - smoothstep(0.38, 0.52, length(p));

  // finalColour *= vignette;

  // Alpha: use accumulated brightness so transparent areas (no blobs, no rim)
  // stay fully transparent — important if composited over a dark background.
  // float finalAlpha = clamp(alphaAcc + rimGlow * 0.6, 0.0, 1.0);

  fragColor = vec4(finalColour, 1.0);
}
