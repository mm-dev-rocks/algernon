#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

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

// How many points to sample along the parametric curve when computing the
// approximate distance. More samples = smoother curve, higher cost.
// 80 is a good balance for mediump precision on mobile GPUs.
// const int SAMPLE_COUNT = 40;

// The glow falloff exponent. Higher = thinner, sharper line.
// 2.0 gives a soft neon glow; 4.0+ gives a fine wire look.
// const float GLOW_POWER = 6.5;

// Half-width of the curve in normalised screen units (0..1 range).
// The glow fades to zero beyond this distance from the curve.
// const float GLOW_RADIUS = 0.82;

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
  float bassEnergy   = smoothBand( 7.0, 6.0);   // ~20–250 Hz region
  float midEnergy    = smoothBand(40.0, 18.0);  // ~250 Hz–2 kHz region
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
  // FIX: the original code added large fixed baselines (0.6, 0.3, 0.8) to
  // every channel, so when music is playing all three bands saturate near
  // 1.0 and the result is always white. Colour only appeared during fade-out
  // when energy dropped low enough for the band ratios to matter.
  //
  // The corrected approach removes the baselines entirely and normalises the
  // band sum so the channels *compete* rather than all adding toward white:
  //
  //   total = bass + mid + treble  (varies with signal but > 0)
  //   r = bass   / total  →  warm when bass dominates
  //   g = mid    / total  →  green when mids dominate
  //   b = treble / total  →  cool when treble dominates
  //
  // A small epsilon prevents division-by-zero during silence.
  // The result is then modulated by intensity so dark areas stay dark.
  float total = bassEnergy + midEnergy + trebleEnergy + 0.001;
  float r = intensity * (bassEnergy   / total);
  float g = intensity * (midEnergy    / total);
  float b = intensity * (trebleEnergy / total);

  fragColor =
      vec4(clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), 1.0);
}
