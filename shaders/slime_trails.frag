#version 460 core
#include <flutter/runtime_effect.glsl>
// algernon_slime_trails.frag
//
// Visualisation strategy: 8 soft metaball "creatures" wander the screen on
// Lissajous-style paths. Each blob is bound to a slice of the FFT spectrum so
// bass blobs move slowly with large arcs, treble blobs twitch quickly in small
// circles. Charge swells each blob and blooms its colour. Blobs merge where
// they overlap, giving an amoebic, bioluminescent feel.
//
// Uniforms to wire up in shaders_meta_data.dart:
//
//   u_blobCount     — TweakType.uniformBlobCount (NEW enum value needed)
//                     min: 2.0   max: 8.0   default: 6.0   divisions: 6
//
//   u_blobSize      — TweakType.uniformBlobSize (NEW enum value needed)
//                     min: 0.05   max: 0.5   default: 0.18
//
//   u_hueShift      — TweakType.uniformHueShift (already exists)
//                     min: 0.0   max: 360.0   default: 140.0
//
//   u_speed         — TweakType.uniformSpeed (NEW enum value needed)
//                     min: 0.2   max: 3.0   default: 1.0
//
// fftDataSmoothing — same as all other shaders.

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_fftData;

uniform float u_energyMin;
uniform float u_energyMax;

uniform float u_blobCount;
uniform float u_blobSize;
uniform float u_hueShift;
uniform float u_speed;

out vec4 fragColor;

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

vec2 sampleBin(float binIndex) {
  float u = (binIndex + 0.5) / 256.0;
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

int energyDerivedCount() {
  float countRange = float(u_energyMax - u_energyMin);
  float count = float(u_energyMin) +
                texture(u_fftData, vec2(0.5 / 256.0, 0.5)).b * countRange;
  return int(round(count));
}

void main() {
  vec2 st = FlutterFragCoord().xy / u_resolution.xy;
  float aspect = u_resolution.x / u_resolution.y;
  vec2 p = st;
  p.x *= aspect;

  float field = 0.0;
  vec3 colourAcc = vec3(0.0);
  float weightAcc = 0.0;

  int nBlobs = u_blobCount == 0.0 ? energyDerivedCount() : int(u_blobCount);

  for (int i = 0; i < 8; i++) {
    if (i >= nBlobs)
      break;

    float fi = float(i);

    float binIndex = fi * (256.0 / float(nBlobs));
    vec2 fc = sampleBin(binIndex);
    float mag = fc.x;
    float charge = fc.y;

    // Each blob moves on its own Lissajous path driven by u_time.
    // Prime-ratio frequencies ensure blobs never move in lockstep.
    float freqX = (0.37 + fi * 0.19) * u_speed;
    float freqY = (0.29 + fi * 0.23) * u_speed;
    float ampX = max(0.38 - fi * 0.02, 0.10);
    float ampY = max(0.38 - fi * 0.02, 0.10);

    float bx = (0.5 + ampX * sin(u_time * freqX + fi * 1.3)) * aspect;
    float by = 0.5 + ampY * cos(u_time * freqY + fi * 2.1);

    float radius = u_blobSize * (1.0 + charge * 0.4 + mag * 0.3);

    float dx = p.x - bx;
    float dy = p.y - by;
    float d2 = dx * dx + dy * dy;
    float influence = min((radius * radius) / max(d2, 0.0001), 12.0);

    field += influence;

    float hue = u_hueShift + (fi / float(nBlobs)) * 180.0 + charge * 30.0;
    float val = clamp(mag * 1.5 + 0.2, 0.0, 1.0);

    colourAcc += hsv2rgb(hue, 0.85, val) * influence;
    weightAcc += influence;
  }

  float skin = smoothstep(0.7, 1.3, field);
  float glow = clamp((field - 1.0) / 3.0, 0.0, 1.0);
  vec3 colour = (weightAcc > 0.001) ? colourAcc / weightAcc : vec3(0.0);
  vec3 ambient =
      hsv2rgb(u_hueShift + 60.0, 0.5, clamp(field * 0.04, 0.0, 0.15));

  fragColor = vec4(colour * skin + colour * glow * 0.5 + ambient, 1.0);
}
