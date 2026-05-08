#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

vec2 sampleBinRange(float binStart, float binEnd) {
  vec2 acc = vec2(0.0);
  float count = 0.0;
  for (int i = 0; i < 256; i++) {
    float fi = binStart + float(i);
    if (fi >= binEnd) break;
    float u = (fi + 0.5) / 256.0;
    vec4 s = texture(u_fftData, vec2(u, 0.5));
    acc += vec2(s.r, (s.g - 0.5) * 2.0);
    count += 1.0;
  }
  return acc / count;
}

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

float hash1(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p.yx + 19.19);
  return fract(p.x * p.y);
}

vec2 bezier(vec2 a, vec2 b, vec2 c, float t) {
  float s = 1.0 - t;
  return s*s*a + 2.0*s*t*b + t*t*c;
}

float bezierSDF(vec2 p, vec2 a, vec2 b, vec2 c) {
  float minDist = 1e9;
  vec2 prev = a;
  for (int i = 1; i <= 12; i++) {
    float t = float(i) / 12.0;
    vec2 curr = bezier(a, b, c, t);
    vec2 ab = curr - prev;
    vec2 ap = p - prev;
    float tt = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    float d = length(ap - ab * tt);
    minDist = min(minDist, d);
    prev = curr;
  }
  return minDist;
}

const int FIBRES_PER_CELL = 12;

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 res = u_resolution.xy;
  float asp = res.x / res.y;

  // World space: x in [0, asp], y in [0, 1].
  // Flip y so y=0 is the bottom of the screen — fibres grow upward from floor.
  vec2 world = vec2(fragCoord.x / res.x * asp,
                    1.0 - fragCoord.y / res.y);

  vec2 fcBass = sampleBinRange(1.0,  6.0);
  vec2 fcMid  = sampleBinRange(20.0, 60.0);
  vec2 fcHigh = sampleBinRange(120.0, 180.0);

  float bassCharge = fcBass.y;
  float bassMag    = fcBass.x;
  float midMag     = fcMid.x;

  float wind = sin(u_time * u_speed * 0.8) * u_warp
               + max(0.0, bassCharge) * u_warp * 2.5;

  // Fibre length 3x longer than before; u_zoom is now the length directly
  float fibreLen = u_zoom * 3.0;
  // Smaller cell relative to fibre length = denser packing
  float cellSize = fibreLen * 0.35;

  vec2 cellCoord = world / cellSize;
  vec2 cellIdx   = floor(cellCoord);

  float bestDist = 1e9;
  float bestT    = 0.0;
  float bestHash = 0.0;
  float bestSway = 0.0;

  for (int cx = -1; cx <= 1; cx++) {
    for (int cy = -1; cy <= 1; cy++) {
      vec2 neighbourCell = cellIdx + vec2(float(cx), float(cy));

      for (int fi = 0; fi < FIBRES_PER_CELL; fi++) {
        float h1 = hash1(neighbourCell * 7.3  + float(fi) * 13.7);
        float h2 = hash1(neighbourCell * 3.1  + float(fi) * 5.9  + 1.0);
        float h3 = hash1(neighbourCell * 11.1 + float(fi) * 2.3  + 2.0);
        float h4 = hash1(neighbourCell * 17.3 + float(fi) * 8.1  + 3.0);

        // Root scattered within cell, always on y=0 (floor)
        vec2 root = vec2((neighbourCell.x + h1) * cellSize, 0.0);

        float thisLen  = fibreLen * (0.6 + h2 * 0.4);
        float restLean = (h3 - 0.5) * 0.3;
        float fibreWind = wind * (0.7 + h4 * 0.6) + restLean;

        vec2 ctrl = root + vec2(sin(fibreWind * 0.5) * thisLen * 0.4,
                                thisLen * 0.55);
        vec2 tip  = root + vec2(sin(fibreWind) * thisLen * 0.7,
                                thisLen);

        float d = bezierSDF(world, root, ctrl, tip);

        if (d < bestDist) {
          bestDist = d;
          bestHash = h1;
          bestSway = abs(fibreWind);
          bestT    = clamp((world.y - root.y) / thisLen, 0.0, 1.0);
        }
      }
    }
  }

  float width  = u_size * (1.0 - bestT * 0.75);
  float strand = 1.0 - smoothstep(0.0, width, bestDist);

  if (strand < 0.01) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  float hue = u_hueShift + bestHash * u_hueRange + midMag * 20.0;
  float sat = 0.7 + bassMag * 0.3;
  float val = (0.2 + bestT * 0.6 + bassMag * 0.2) * strand;

  vec3 col = hsv2rgb(hue, sat, val);
  col = pow(col, vec3(u_emphasis));

  fragColor = vec4(col, 1.0);
}
