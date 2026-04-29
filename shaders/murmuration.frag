#version 460 core
#include <flutter/runtime_effect.glsl>
// algernon_murmuration.frag
//
// Visualisation strategy: a 2D flow field built from layered sine waves drives
// a dense signed-distance "dot field", creating the impression of hundreds of
// tiny particles all moving in coherent but slightly offset directions — like a
// flock of starlings or a school of fish.
//
// Each screen position looks up its local flow direction (sum of 4 sine-wave
// layers, each animated by a different FFT slice). The flow magnitude at that
// point determines brightness. Charge drives a convergence pulse — on high
// charge the flock collapses toward the screen centre, then releases outward.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_flockDensity  — TweakType.uniformRingDensity (reuse)
//                     min: 4.0   max: 64.0   default: 28.0
//                     Grid frequency of the dot / particle field.
//
//   u_flockContrast — TweakType.uniformRingContrast (reuse)
//                     min: 0.5   max: 4.0   default: 2.0
//                     Sharpness of individual particle dots.
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 200.0
//
//   u_cohesion      — TweakType.uniformAttenuation (reuse — charge pull
//   strength)
//                     min: 0.0   max: 2.0   default: 0.8
//                     How strongly charge pulls the flock toward centre.
//
// fftDataSmoothing — same as all other shaders.

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_fftData;

// min: 4.0  max: 64.0  default: 28.0
uniform float u_countPrimary; // used as flockDensity

// min: 0.5  max: 4.0  default: 2.0
uniform float u_emphasis; // used as flockContrast

// min: 0.0  max: 360.0  default: 200.0
uniform float u_hueShift;

// min: 0.0  max: 2.0  default: 0.8
uniform float u_spread; // used as cohesion

out vec4 fragColor;

// ---------------------------------------------------------------------------
// HSV -> RGB. H in [0,360], S and V in [0,1].
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
// Sample an FFT bin — returns (magnitude, charge) with charge in [-1,1].
// ---------------------------------------------------------------------------
vec2 sampleBin(float binIndex) {
  float u = clamp((binIndex + 0.5) / 256.0, 0.0, 1.0);
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

// ---------------------------------------------------------------------------
// Flow field: 4 sine-wave layers at different orientations and FFT-driven
// frequencies. Returns a 2D flow vector at position p.
// p is in aspect-corrected space, roughly [-0.5,0.5].
// ---------------------------------------------------------------------------
vec2 flowField(vec2 p, float phaseShift) {
  // Layer 0: bass — slow large-scale horizontal waves
  vec2 fc0 = sampleBin(8.0);
  float a0 = sin(p.x * 3.1 + phaseShift * 0.4 + fc0.x * 2.0) +
             cos(p.y * 2.7 + phaseShift * 0.3);

  // Layer 1: low-mid — diagonal waves
  vec2 fc1 = sampleBin(40.0);
  float a1 =
      sin((p.x + p.y) * 4.5 + phaseShift * 0.7 + fc1.x * 3.0) * (0.6 + fc1.x);

  // Layer 2: high-mid — faster transverse wobble
  vec2 fc2 = sampleBin(100.0);
  float a2 =
      cos(p.y * 6.2 + phaseShift * 1.1 + fc2.x * 4.0) * (0.4 + fc2.x * 0.5);

  // Layer 3: treble — fine shimmer
  vec2 fc3 = sampleBin(200.0);
  float a3 = sin(p.x * 9.7 - p.y * 5.3 + phaseShift * 1.8 + fc3.x * 6.0) * 0.3;

  float totalAngle = a0 + a1 + a2 + a3;
  return vec2(cos(totalAngle), sin(totalAngle));
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float asp = u_resolution.x / u_resolution.y;
  vec2 p = (st - 0.5) * vec2(asp, 1.0);

  // ---------------------------------------------------------------------------
  // Pseudo-time from spatial hash + bass energy
  // ---------------------------------------------------------------------------
  vec2 fcBass = sampleBin(4.0);
  vec2 fcMid = sampleBin(80.0);
  vec2 fcHigh = sampleBin(200.0);

  // float phaseShift = sin(p.x * 7.3 + p.y * 4.1) * 6.28
  //                  + fcBass.x * 4.0
  //                  + fcMid.x  * 2.0;

  // After (real time — smooth independent motion + music reactivity on top):
  float phaseShift = u_time * 0.8 + fcBass.x * 4.0;

  // ---------------------------------------------------------------------------
  // Charge-driven cohesion: positive charge pulls field toward centre.
  // We use the average charge across low bins.
  // ---------------------------------------------------------------------------
  float avgCharge = 0.0;
  for (int b = 0; b < 8; b++) {
    avgCharge += sampleBin(float(b) * 8.0).y;
  }
  avgCharge /= 8.0; // -1..1

  // Pull vector toward origin, scaled by cohesion uniform + charge
  vec2 pullDir = -normalize(p + vec2(0.001)); // toward centre
  float pullStr = u_spread * clamp(avgCharge, 0.0, 1.0) * 0.3;

  // ---------------------------------------------------------------------------
  // Particle dot field
  // ---------------------------------------------------------------------------
  // Scale p into grid space
  vec2 grid = p * u_countPrimary;

  // Local position within a grid cell [0,1]^2
  vec2 cell = fract(grid);
  vec2 cellID = floor(grid);

  // Flow at this cell centre
  vec2 cellCentre = (cellID + 0.5) / u_countPrimary;
  vec2 cellP = (cellCentre - 0.5) * vec2(asp, 1.0);

  vec2 flow = flowField(cellP, phaseShift);
  flow += pullDir * pullStr;
  flow = normalize(flow);

  // Offset the "particle" within the cell based on flow direction.
  // The particle sits at (0.5,0.5) + flow * offset — this makes rows of dots
  // all lean in the same direction, like a flock in formation.
  float offset = 0.25;
  vec2 particleCentre = vec2(0.5) + flow * offset;

  // Distance from current sub-pixel to particle centre
  float dist = length(cell - particleCentre);

  // Particle radius is tiny — contrast sharpens/softens the edge
  float radius = 0.18;
  float particle = smoothstep(radius, radius - radius / u_emphasis, dist);

  // ---------------------------------------------------------------------------
  // Colour: spectrum mapped to flow direction angle + FFT magnitude
  // ---------------------------------------------------------------------------
  float flowAngle = atan(flow.y, flow.x);  // -pi..pi
  float hueT = (flowAngle / 6.2832 + 0.5); // 0..1

  // Local FFT sample — bin index proportional to position in the field
  float fieldBin = (cellID.x / u_countPrimary * 0.5 + 0.5) * 200.0;
  vec2 fcLocal = sampleBin(fieldBin);

  float hue = u_hueShift + hueT * 40.0 + fcLocal.y * 20.0;
  float val = clamp(fcLocal.x * 1.8 + 0.15, 0.0, 1.0);
  float sat = 0.85;

  vec3 colour = hsv2rgb(hue, sat, val);

  // Low-level background shimmer from flow field divergence
  float flowMag = length(flowField(p * 0.5, phaseShift * 0.3));
  float bgGlow = clamp(flowMag * 0.03, 0.0, 0.08);
  vec3 bgCol = hsv2rgb(u_hueShift + 40.0, 0.6, bgGlow);

  vec3 finalCol = colour * particle + bgCol * (1.0 - particle);

  fragColor = vec4(finalCol, 1.0);
}
