#version 300 es

struct FrameInfo {
  mat4 mvp;
};
uniform FrameInfo frame_info;

in vec2 position;    // ← was: attribute vec2 position
out vec2 _fragCoord; // ← was: varying vec2 _fragCoord

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  _fragCoord = position;
  gl_Position.z = 2.0 * gl_Position.z - gl_Position.w;
}
