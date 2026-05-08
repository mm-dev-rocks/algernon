#version 460 core
#include <all_uniforms.frag>
#include <flutter/runtime_effect.glsl>

precision lowp float;

out vec4 fragColor;

// fibre_spectrum.frag
//
// Frequency-mapped fibre field. The screen is divided into vertical columns,
// each column mapped to a frequency bin range. Low frequencies on the left
// sway heavily on kick; high frequencies on the right shimmer on cymbals.
// Within each column, fibres share that column's FFT data but have per-row
// hash offsets for organic stagger.

vec2 sampleBin(float binIndex) {
  float u = clamp((binIndex + 0.5) / 256.0, 0.0, 1.0);
  vec4 s = texture(u_fftData, vec2(u, 0.5));
  return vec2(s.r, (s.g - 0.5) * 2.0);
}

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float hash2(vec2 v) { return hash(v.x + v.y * 127.1); }

float lineSDF(vec2 p, vec2 a, vec2 b, float width) {
  vec2 ab = b - a;
  vec2 ap = p - a;
  float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
  return 1.0 - smoothstep(0.0, width, length(ap - ab * t));
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

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 res = u_resolution.xy;
  float asp = res.x / res.y;

  float cellSize = u_zoom;
  vec2 uv = fragCoord / res;
  uv.x *= asp;

  vec2 cell = floor(uv / (cellSize * vec2(asp, 1.0)));
  vec2 local = fract(uv / (cellSize * vec2(asp, 1.0)));
  local = local - vec2(0.5, 0.0);

  float cellHash  = hash2(cell);
  float cellHash2 = hash(cellHash * 7.3 + 1.1);

  // Map this cell's column to a frequency bin.
  // u_countPrimary controls how many bins the full width spans (frequency range).
  // Left = low freq, right = high freq.
  float totalCols = floor(asp / cellSize);
  float colFrac   = clamp(cell.x / max(totalCols - 1.0, 1.0), 0.0, 1.0);

  // Map colFrac across bin range 1..u_countPrimary
  float maxBin  = clamp(u_countPrimary, 2.0, 200.0);
  float binIndex = 1.0 + colFrac * (maxBin - 1.0);

  // Sample that bin
  vec2 fc = sampleBin(binIndex);
  float mag    = fc.x;
  float charge = fc.y;

  // Fibre length: magnitude of this column's frequency
  float fibreLen = (0.3 + mag * 0.6) * (0.75 + cellHash * 0.25);

  // Sway: charge drives the kick, u_warp is resting wind
  float swayPhase = u_time * u_speed * (0.3 + cellHash * 0.2)
                    + cellHash2 * 6.28;
  float gentleSway = sin(swayPhase) * u_warp;
  float beatKick   = charge * (0.4 + cellHash * 0.3);
  float totalSway  = gentleSway + beatKick;

  // High-freq columns get tip flutter proportional to their own charge
  float flutter = charge * sin(u_time * u_speed * 4.0 + cellHash * 6.28) * 0.1;

  vec2 root = vec2(0.0, 0.0);
  vec2 mid  = root + vec2(sin(totalSway * 0.5) * fibreLen * 0.4,
                           fibreLen * 0.5);
  vec2 tip  = mid  + vec2(sin(totalSway + flutter) * fibreLen * 0.3,
                           fibreLen * 0.5);

  float rootW = u_size;
  float gRoot = lineSDF(local, root, mid, rootW);
  float gTip  = lineSDF(local, mid,  tip, rootW * 0.4);
  float g = max(gRoot, gTip);

  if (g < 0.001) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // Colour shifts across the frequency spectrum left→right
  float t   = clamp(local.y / (fibreLen * 0.9), 0.0, 1.0);
  float hue = u_hueShift + colFrac * u_hueRange + mag * 20.0 * t;
  float sat = 0.65 + mag * 0.35;
  float val = 0.3 + mag * 0.6 + t * 0.15;

  vec3 col = hsv2rgb(hue, sat, val);
  col = pow(col * g, vec3(u_emphasis));

  fragColor = vec4(col, 1.0);
}
