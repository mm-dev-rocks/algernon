#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>
#include <precision.frag>

out vec4 fragColor;

// algernon_lissajous_web.frag
//
// Visualisation strategy: signed-distance field of a Lissajous-like curve.
//
// A Lissajous figure is a parametric curve traced by:
//   x(t) = sin(a*t + phase)
//   y(t) = sin(b*t)
//
// Here the frequency ratios (a, b) and phase are driven by FFT bins, so the
// shape of the knot continuously morphs with the music.
//
// Rather than rasterising the curve explicitly (which is expensive), each
// pixel computes its minimum distance to the curve by sampling N points along
// it and taking the minimum. This is an *approximate* SDF — not analytically
// exact, but fast and visually smooth enough at these sample counts.
//
// Method contrast vs other shaders in this set:
//   warp_kaleido        — domain warp + angular fold, grid pattern
//   rings_radial        — pure polar, concentric bands
//   rose_tunnel         — polar angle, radial gradient
//   THIS SHADER         — parametric SDF, no predetermined geometry
//
// Uniforms:
//
//   u_zoom      — TweakType.uniformZoom
//                 Glow radius in normalised screen units. Larger = softer/wider
//                 blobs. min: 0.05  max: 1.0  default: 0.35
//
//   u_emphasis  — TweakType.uniformEmphasis
//                 Glow falloff exponent. Higher = sharper, thinner line.
//                 2.0 = soft neon glow; 6.0+ = fine wire.
//                 min: 1.0  max: 10.0  default: 4.0
//
//   u_hueShift  — TweakType.uniformHueShift
//                 Base hue offset in degrees. Rotates the entire colour palette
//                 around the wheel regardless of signal content.
//                 min: 0.0  max: 360.0  default: 200.0
//
//   u_hueRange  — TweakType.uniformHueRange
//                 Hue sweep range in degrees. Controls how far the hue travels
//                 as the spectral balance shifts from bass-heavy →
//                 treble-heavy. 0 = single fixed hue; 360 = full rainbow sweep.
//                 min: 0.0  max: 360.0  default: 120.0
//
//   u_size      — TweakType.uniformSize  (repurposed as saturation)
//                 Colour saturation. 0.0 = fully desaturated (greyscale glow),
//                 1.0 = fully vivid. Values around 0.8–1.0 recommended.
//                 min: 0.0  max: 1.0  default: 0.9
//
//   u_speed     — TweakType.uniformSpeed  (repurposed as spectral pull)
//                 How strongly the spectral balance (bass vs treble ratio)
//                 pulls the hue away from u_hueShift. 0.0 = hue locked to shift
//                 only; 1.0 = full spectral modulation. Lets you dial between a
//                 fixed colour palette and one that chases the music's tonal
//                 character. min: 0.0  max: 1.0  default: 0.7

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

// Helper: reads a single bin by float index and returns amplitude 0..1.
// The +0.5 texel-centre offset prevents bleeding across texel boundaries —
// consistent with the convention used throughout this codebase.
float sampleBin(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).r;
}

float sampleCharge(float binIndex) {
  return texture(u_fftData, vec2((binIndex + 0.5) / 256.0, 0.5)).g;
}

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

// Smooth a raw FFT band value to reduce jitter.
//
// Raw bin samples jump frame-to-frame even after the host-side smoothing
// because we're reading sparse individual bins and mapping them nonlinearly
// onto curve parameters. A second cheap smoothing pass here — mixing the
// current reading toward a slower-moving target — prevents the sharp
// discontinuities that cause flickery motion.
//
// alpha controls how quickly the output tracks the input:
//   0.0 = frozen, 1.0 = no smoothing (raw value).
// 0.08–0.15 gives fluid motion while still reacting to transients.
//
// NOTE: GLSL fragment shaders have no persistent state between frames, so
// true per-frame IIR filtering is not possible here. Instead we approximate
// it by blending across a *spatial* neighbourhood of nearby bins — averaging
// a wider window around each band centre. This gives a reading that is
// inherently less sensitive to single-bin spikes, achieving smoothness
// without needing frame history.
float smoothBand(float centre, float halfWidth) {
  float sum = 0.0;
  float w = 0.0;
  // Sample 7 bins across the band with a triangular weight (peak at centre).
  for (int k = -3; k <= 3; k++) {
    float weight = 1.0 - abs(float(k)) / 4.0; // triangular window
    sum += sampleBin(centre + float(k) * halfWidth / 3.0) * weight;
    w += weight;
  }
  return sum / w;
}

void main() {
  // Mnemonic: st = 'space transform' — normalised 0..1 screen coords.
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;

  // Centre and aspect-correct the coordinate space.
  // p is now in roughly -0.5..0.5 on the short axis, wider on the long axis.
  vec2 p = st - vec2(0.5, 0.5);
  p.x *= u_resolution.x / u_resolution.y;

  int nBlobs =
      u_countPrimary == -1.0 ? energyDerivedCount() : int(u_countPrimary);

  // --- FFT-driven curve parameters ---
  //
  // Use smoothBand() instead of averaging just 3 sparse bins.
  // Each call blends 7 neighbouring bins with a triangular window, which
  // dramatically reduces the per-frame variance that causes flickery motion.
  //
  // Band centres and half-widths chosen to cover bass / mid / treble ranges
  // without overlapping so the three colour channels stay independent.
  float bassEnergy = smoothBand(7.0, 6.0);      // ~20–250 Hz region
  float midEnergy = smoothBand(40.0, 18.0);     // ~250 Hz–2 kHz region
  float trebleEnergy = smoothBand(110.0, 30.0); // ~2 kHz–8 kHz region

  // The horizontal frequency ratio: bass pushes it from 1→3.
  // Adding 1.0 ensures we never get ratio 0 (degenerate straight line).
  float freqA = 1.0 + bassEnergy * 2.0;

  // The vertical frequency ratio: treble pushes it from 1→4.
  float freqB = 1.0 + trebleEnergy * 3.0;

  // Phase offset between the two axes: mid energy rotates the knot.
  // Without a phase offset, Lissajous figures collapse to diagonal lines.
  // 1.5708 ≈ pi/2, which gives the classic open figure-eight at ratio 1:1.
  float phase = 1.5708 + midEnergy * 3.14159265;

  // Scale factor: loud overall signal expands the figure toward the edges.
  float scale = 0.35 + (bassEnergy + trebleEnergy) * 0.08;

  // --- Broad energy envelope (B channel of bin 0) ---
  //
  // Pre-computed low-frequency RMS-like envelope baked into the texture by
  // the host. Moves more slowly and smoothly than any individual bin average,
  // making it ideal for global breathing effects that shouldn't flicker.
  float globalEnergy = texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b;

  // --- Charge from mid band (G channel, remapped 0..1 → −1..+1) ---
  //
  // More transient and immediate than the smoothed magnitude. Reading from
  // bin 40 (mid band centre) captures vocal and snare-hit character.
  float midCharge = (sampleCharge(40.0) - 0.5) * 2.0; // −1..+1

  // Breathe the figure scale with global energy — blobs expand on loud
  // passages independently of the shape parameters.
  scale *= 1.0 + globalEnergy * 0.18;

  // --- Approximate SDF: minimum distance to the parametric curve ---
  //
  // We step t uniformly through 0..2*pi and find the curve point closest
  // to this fragment. The curve is periodic with period 2*pi regardless of
  // freqA / freqB (the figure may not close in that interval for irrational
  // ratios, but it gets close enough for a visual approximation).
  float minDist = 1.0e6; // initialise to a large sentinel distance
  float tStep = 6.28318530 / float(nBlobs);

  for (int i = 0; i < 999; i++) {
    if (i >= nBlobs)
      break;

    float t = float(i) * tStep;

    // Standard Lissajous parametric equations.
    vec2 curvePoint = vec2(sin(freqA * t + phase), sin(freqB * t)) * scale;

    // Euclidean distance from this fragment to this point on the curve.
    float d = length(p - curvePoint);
    minDist = min(minDist, d);
  }

  // --- Glow from the curve ---
  //
  // Map minDist → brightness using an inverse power curve.
  // clamp ensures we don't go negative or above 1.0 before the pow().
  float distNorm = clamp(1.0 - minDist / u_zoom, 0.0, 1.0);
  float intensity = pow(distNorm, u_emphasis);

  // --- Colour ---
  //
  // Colour is expressed in HSV so hue, saturation and brightness are
  // independently controllable.
  //
  // HUE — three additive contributions:
  //
  //   1. u_hueShift — static anchor, sets the base palette zone.
  //
  //   2. Time drift — u_time * u_speed keeps the hue slowly cycling so
  //      colour is always in motion even on a steady-state signal.
  //
  //   3. spectralTilt — signed difference (treble − bass) normalised by
  //      total band energy. Range −1..+1. Pulls the hue across u_hueRange
  //      as the mix shifts from bass-heavy to treble-heavy. Using the
  //      signed difference rather than a ratio gives a much larger and more
  //      musically meaningful excursion.
  //
  //   4. midCharge — fast transient nudge from the mid-band charge value.
  //      Because charge is not smoothed it reacts to individual hits and
  //      note attacks, adding a snappy secondary colour flicker on top of
  //      the slower spectral drift. Scaled to ±20° so it's felt without
  //      overwhelming the tilt signal.
  //
  float totalEnergy = bassEnergy + midEnergy + trebleEnergy;

  float spectralTilt = totalEnergy > 0.001
                           ? (trebleEnergy - bassEnergy) / totalEnergy // −1..+1
                           : 0.0;

  float hue = u_hueShift + u_time * u_speed * 10.0 // slow continuous drift
              + spectralTilt * u_hueRange * 0.5    // musical tilt ±halfRange
              + midCharge * 20.0;                  // transient charge flicker

  // SATURATION — u_size sets the base level (0 = grey, 1 = vivid).
  // globalEnergy boosts saturation on loud passages so the palette gets
  // richer when the music is full, and gentler in quiet moments.
  float sat = clamp(u_size + globalEnergy * 0.2, 0.0, 1.0);

  // VALUE — intensity is the primary brightness driver (glow shape).
  // globalEnergy adds a small ambient floor so the background lifts
  // slightly on loud passages rather than staying absolute black —
  // this gives the blobs a sense of radiating into their surroundings.
  float val = clamp(intensity + globalEnergy * 0.06, 0.0, 1.0);

  vec3 rgb = hsv2rgb(hue, sat, val);

  fragColor = vec4(rgb, 1.0);
}
