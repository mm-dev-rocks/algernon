// The order of everything in this file is crucial as their positions are
// hardcoded for now to sidestep an annoying bug where [getUniform]/[setUniform]
// aren't working properly. Should be fixed in a soon/future Flutter version.
uniform sampler2D u_fftData;
//
uniform vec2 u_resolution;
uniform float u_time;
//
uniform float u_energyMin;
uniform float u_energyMax;
//
uniform float u_countPrimary;
uniform float u_countSecondary;
uniform float u_hueRange;
uniform float u_hueShift;
uniform float u_emphasis;
uniform float u_speed;
uniform float u_warp;
uniform float u_zoom;
uniform float u_spread;
uniform float u_size;
