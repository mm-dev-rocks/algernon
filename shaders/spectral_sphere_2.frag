#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision mediump float;

out vec4 fragColor;

// algernon_spectral_sphere.frag
//
// Visualisation strategy: a transparent sphere whose surface is populated by
// 128 glowing blobs distributed evenly via a pre-baked Fibonacci lattice.
// Each blob glows brighter when its bin magnitude (R channel) is high. The
// green channel (charge, remapped -1..1) pushes blobs radially in or out of
// the surface. The blue channel drives broad breathing of the whole sphere.
// Sinusoidal motion from u_time gives the sphere a slow living rotation.
//
// Performance: Fibonacci points are pre-baked (no loop trig). Blob falloff
// uses a squared linear ramp instead of exp() — much cheaper on mobile.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 200.0
//
//   u_hueRange      — TweakType.uniformHueRange (already exists)
//                     min: 0.0   max: 360.0   default: 140.0
//
//   u_sphereRadius  — TweakType.uniformSphereRadius (NEW)
//                     min: 0.15  max: 0.48   default: 0.32
//
//   u_blobSize      — TweakType.uniformBlobSize (already exists)
//                     min: 0.01  max: 0.12   default: 0.038
//
//   u_glowStrength  — TweakType.uniformGlowStrength (NEW)
//                     min: 0.5   max: 4.0    default: 1.8
//
//   u_speed         — TweakType.uniformSpeed (already exists)
//                     min: 0.05  max: 1.0    default: 0.18
//
// fftDataSmoothing — same as all other shaders.
//
//precision mediump float;
//
//uniform vec2      u_resolution;
//uniform float     u_time;
//uniform sampler2D u_fftData;
//
//uniform float u_hueShift;
//uniform float u_hueRange;
//uniform float u_sphereRadius;
//uniform float u_blobSize;
//uniform float u_glowStrength;
//uniform float u_speed;
//
//out vec4 fragColor;

// ---------------------------------------------------------------------------
// Pre-baked Fibonacci lattice — 128 unit vectors, evenly distributed on the
// sphere surface. Generated offline; zero runtime trig cost in the loop.
// ---------------------------------------------------------------------------
const vec3 FIBS[128] = vec3[128](
  vec3(0.124756, 0.000000, 0.992188),
  vec3(-0.158707, -0.145388, 0.976562),
  vec3(0.024196, 0.275706, 0.960938),
  vec3(0.198452, -0.258846, 0.945312),
  vec3(-0.362718, 0.064160, 0.929688),
  vec3(0.342205, 0.217683, 0.914062),
  vec3(-0.113993, -0.424047, 0.898438),
  vec3(-0.216500, 0.416857, 0.882812),
  vec3(0.467765, -0.170827, 0.867188),
  vec3(-0.484591, -0.200032, 0.851562),
  vec3(0.232617, 0.497089, 0.835938),
  vec3(0.171165, -0.545701, 0.820312),
  vec3(-0.513675, 0.297685, 0.804688),
  vec3(0.599985, 0.131905, 0.789062),
  vec3(-0.364559, -0.518547, 0.773438),
  vec3(-0.083850, 0.647062, 0.757812),
  vec3(0.512462, -0.431903, 0.742188),
  vec3(-0.686514, -0.028389, 0.726562),
  vec3(0.498488, 0.496062, 0.710938),
  vec3(-0.033198, -0.717940, 0.695312),
  vec3(-0.469961, 0.563171, 0.679688),
  vec3(0.741000, -0.099700, 0.664062),
  vec3(-0.624893, -0.434784, 0.648438),
  vec3(0.169946, 0.755425, 0.632812),
  vec3(0.391190, -0.682679, 0.617188),
  vec3(-0.761036, 0.242791, 0.601562),
  vec3(0.735634, 0.339882, 0.585938),
  vec3(-0.317121, -0.757745, 0.570312),
  vec3(-0.281612, 0.782954, 0.554688),
  vec3(0.745565, -0.391848, 0.539062),
  vec3(-0.823920, -0.217183, 0.523438),
  vec3(0.465914, 0.724604, 0.507812),
  vec3(0.147440, -0.857912, 0.492188),
  vec3(-0.695069, 0.538300, 0.476562),
  vec3(0.884403, 0.073271, 0.460937),
  vec3(-0.608031, -0.657263, 0.445312),
  vec3(0.004405, 0.902967, 0.429688),
  vec3(0.611582, -0.674180, 0.414063),
  vec3(-0.913282, 0.084643, 0.398438),
  vec3(0.735882, 0.558508, 0.382813),
  vec3(-0.166481, -0.915127, 0.367188),
  vec3(-0.498606, 0.792335, 0.351562),
  vec3(0.908388, -0.248952, 0.335938),
  vec3(-0.842810, -0.432516, 0.320313),
  vec3(0.331088, 0.893054, 0.304688),
  vec3(0.360947, -0.886657, 0.289062),
  vec3(-0.869217, 0.411938, 0.273437),
  vec3(0.923308, 0.284666, 0.257813),
  vec3(-0.490570, -0.837070, 0.242187),
  vec3(-0.204493, 0.952288, 0.226563),
  vec3(0.796904, -0.566083, 0.210937),
  vec3(-0.973212, -0.121290, 0.195313),
  vec3(0.637620, 0.749102, 0.179687),
  vec3(0.035949, -0.985795, 0.164062),
  vec3(-0.694138, 0.704371, 0.148437),
  vec3(0.989848, -0.050612, 0.132812),
  vec3(-0.765588, -0.632567, 0.117187),
  vec3(0.137466, 0.985286, 0.101562),
  vec3(0.565023, -0.820588, 0.085937),
  vec3(-0.972122, 0.223683, 0.070313),
  vec3(0.868760, 0.492205, 0.054687),
  vec3(-0.308343, -0.950473, 0.039062),
  vec3(-0.414875, 0.909576, 0.023437),
  vec3(0.920551, -0.390545, 0.007813),
  vec3(-0.942595, -0.333848, -0.007812),
  vec3(0.469414, 0.882667, -0.023438),
  vec3(0.249979, -0.967463, -0.039063),
  vec3(-0.837224, 0.544119, -0.054688),
  vec3(0.983925, 0.164159, -0.070312),
  vec3(-0.613873, -0.784713, -0.085938),
  vec3(-0.077301, 0.991821, -0.101562),
  vec3(0.725708, -0.677949, -0.117188),
  vec3(-0.991094, 0.009670, -0.132813),
  vec3(0.735683, 0.660861, -0.148438),
  vec3(-0.095824, -0.981785, -0.164063),
  vec3(-0.590891, 0.786486, -0.179688),
  vec3(0.964036, -0.180242, -0.195312),
  vec3(-0.829850, -0.516580, -0.210938),
  vec3(0.262019, 0.938092, -0.226562),
  vec3(0.438764, -0.865351, -0.242188),
  vec3(-0.904291, 0.340281, -0.257812),
  vec3(0.892657, 0.358323, -0.273438),
  vec3(-0.414192, -0.863069, -0.289062),
  vec3(-0.276173, 0.911534, -0.304687),
  vec3(0.814952, -0.482963, -0.320312),
  vec3(-0.921845, -0.193256, -0.335937),
  vec3(0.545862, 0.760551, -0.351563),
  vec3(0.110528, -0.923557, -0.367188),
  vec3(-0.700560, 0.602221, -0.382812),
  vec3(0.916738, 0.028954, -0.398438),
  vec3(-0.651444, -0.635745, -0.414062),
  vec3(0.050508, 0.901564, -0.429688),
  vec3(0.566941, -0.693019, -0.445312),
  vec3(-0.878311, 0.126912, -0.460938),
  vec3(0.726514, 0.495041, -0.476562),
  vec3(-0.199333, -0.847359, -0.492187),
  vec3(-0.420992, 0.751593, -0.507812),
  vec3(0.809190, -0.266880, -0.523438),
  vec3(-0.768012, -0.345789, -0.539063),
  vec3(0.328699, 0.764381, -0.554688),
  vec3(0.270460, -0.775626, -0.570312),
  vec3(-0.713606, 0.383983, -0.585938),
  vec3(0.774390, 0.196067, -0.601563),
  vec3(-0.431977, -0.657629, -0.617188),
  vec3(-0.123697, 0.764361, -0.632812),
  vec3(0.597300, -0.471977, -0.648438),
  vec3(-0.745691, -0.054459, -0.664062),
  vec3(0.503335, 0.533553, -0.679688),
  vec3(-0.010518, -0.718631, -0.695312),
  vec3(-0.467402, 0.525455, -0.710938),
  vec3(0.683517, -0.070081, -0.726562),
  vec3(-0.537776, -0.399944, -0.742188),
  vec3(0.123039, 0.640766, -0.757812),
  vec3(0.332354, -0.539755, -0.773438),
  vec3(-0.590854, 0.168143, -0.789062),
  vec3(0.530825, 0.265900, -0.804688),
  vec3(-0.204030, -0.534284, -0.820313),
  vec3(-0.201961, 0.510314, -0.835937),
  vec3(0.471531, -0.229128, -0.851563),
  vec3(-0.477287, -0.142068, -0.867187),
  vec3(0.241446, 0.402922, -0.882813),
  vec3(0.087997, -0.430194, -0.898438),
  vec3(-0.328335, 0.238088, -0.914062),
  vec3(0.365949, 0.041986, -0.929688),
  vec3(-0.213824, -0.246300, -0.945312),
  vec3(-0.007387, 0.276667, -0.960938),
  vec3(0.149573, -0.154770, -0.976562),
  vec3(-0.124525, 0.007586, -0.992188)
);

// ---------------------------------------------------------------------------
// HSV → RGB — H in [0,360], S/V in [0,1].
// ---------------------------------------------------------------------------
vec3 hsv2rgb(float h, float s, float v) {
  h = mod(h, 360.0);
  float c = v * s;
  float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
  float m = v - c;
  vec3 rgb;
  if      (h < 60.0)  rgb = vec3(c, x, 0.0);
  else if (h < 120.0) rgb = vec3(x, c, 0.0);
  else if (h < 180.0) rgb = vec3(0.0, c, x);
  else if (h < 240.0) rgb = vec3(0.0, x, c);
  else if (h < 300.0) rgb = vec3(x, 0.0, c);
  else                rgb = vec3(c, 0.0, x);
  return rgb + m;
}

// ---------------------------------------------------------------------------
// Sample a single FFT bin.
//   .x = magnitude (R channel, 0..1)
//   .y = charge    (G channel, remapped 0..1 → -1..1)
//   .z = energy    (B channel, 0..1)
// ---------------------------------------------------------------------------
vec3 sampleBin(float binIdx) {
  float u = (binIdx + 0.5) / 256.0;
  vec4  s = texture(u_fftData, vec2(u, 0.5));
  return vec3(s.r, (s.g - 0.5) * 2.0, s.b);
}

// ---------------------------------------------------------------------------
// Rotation matrices — built once per fragment, not per bin.
// ---------------------------------------------------------------------------
mat3 rotY(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c, 0.0, s,  0.0, 1.0, 0.0,  -s, 0.0, c);
}
mat3 rotX(float a) {
  float c = cos(a), s = sin(a);
  return mat3(1.0, 0.0, 0.0,  0.0, c, -s,  0.0, s, c);
}

void main() {
  vec2  st     = FlutterFragCoord().xy / u_resolution.xy;
  float aspect = u_resolution.x / u_resolution.y;
  vec2  p      = (st - 0.5) * vec2(aspect, 1.0);

  float energy  = sampleBin(0.0).z;
  float breathe = 1.0 + energy * 0.12 + sin(u_time * 0.4) * 0.03;
  float radius  = u_sphereRadius * breathe;

  float rotAngleY = u_time * u_speed + energy * 0.6;
  float rotAngleX = sin(u_time * u_speed * 0.37) * 0.4 + energy * 0.2;
  mat3  orient    = rotX(rotAngleX) * rotY(rotAngleY);

  vec3  colourAcc = vec3(0.0);
  float alphaAcc  = 0.0;

  // Ambient rim — one exp() here is fine, it's outside the loop.
  float rimDist  = abs(length(p) - radius);
  float rimGlow  = exp(-rimDist * rimDist * 800.0) * 0.07;
  vec3  rimColour = hsv2rgb(u_hueShift, 0.5, 0.4);

  for (int i = 0; i < 128; i++) {
    float fi = float(i);
    float t  = fi / 127.0;  // 0..1, bass → treble

    float texBin = fi * 2.0;  // spread 128 blobs across 256 texture bins
    vec3  fc     = sampleBin(texBin);
    float mag    = fc.x;   // 0..1
    float charge = fc.y;   // -1..1

    vec3  base = FIBS[i];  // pre-baked unit vector, no trig

    float displacement = charge * 0.22 + energy * 0.06
                       + sin(u_time * (0.3 + t * 0.7) + fi * 0.41) * 0.015;
    float r3d = radius * (1.0 + displacement);

    vec3  pos3d    = orient * (base * r3d);
    vec2  screenPos = pos3d.xy;
    float depth    = pos3d.z;

    float depthFade  = 0.35 + 0.65 * (depth / r3d + 1.0) * 0.5;
    float occlude    = (depth < 0.0) ? 0.55 : 1.0;
    float visibility = depthFade * occlude;

    float blobR  = u_blobSize * (1.0 + mag * 0.8 + max(charge, 0.0) * 0.5)
                 * (0.7 + 0.3 * depthFade);
    float blobR2 = blobR * blobR;

    vec2  diff = p - screenPos;
    float d2   = dot(diff, diff);

    // Polynomial falloff — replaces exp(). Two multiplies instead of exp().
    // Looks slightly harder-edged than a Gaussian but still soft and glowy.
    float falloff = max(0.0, 1.0 - d2 / blobR2);
    float blob    = falloff * falloff * visibility;

    float contribution = blob * mag * u_glowStrength;

    float hue = u_hueShift + t * u_hueRange + charge * 18.0;
    float sat = 0.85 + mag * 0.15;
    float val = clamp(mag * 1.5 + 0.08, 0.0, 1.0);

    colourAcc += hsv2rgb(hue, sat, val) * contribution;
    alphaAcc  += contribution;
  }

  vec3 finalColour = rimColour * rimGlow;
  if (alphaAcc > 0.001) {
    finalColour += colourAcc / alphaAcc * clamp(alphaAcc, 0.0, 1.0);
  }

  float vignette = 1.0 - smoothstep(0.38, 0.52, length(p));
  finalColour   *= vignette;

  float finalAlpha = clamp(alphaAcc + rimGlow * 0.6, 0.0, 1.0);
  fragColor = vec4(finalColour, finalAlpha);
}
