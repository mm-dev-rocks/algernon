// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

/// The order of this enum matters! Don't move stuff around without checking how the uniforms are passed into the
/// shaders!
enum TweakType {
  /// Special slider outside normal tweaks
  fftDataSmoothing(
    label: 'Stability',
    iconData: Icons.video_stable_outlined,
    description: 'Smoothing/interpolation between FFT bins.',
    isNonUniformTweak: true,
  ),

  /// Uniforms set via audio analysis --- no tweak slider
  uniformEnergyMin(
    label: '',
    uniform: 'u_energyMin',
    iconData: Icons.hide_image,
    description: '',
  ),
  uniformEnergyMax(
    label: '',
    uniform: 'u_energyMax',
    iconData: Icons.hide_image,
    description: '',
  ),

  /// Normal tweak sliders below
  uniformCountPrimary(
    label: 'Main Count',
    uniform: 'u_countPrimary',
    iconData: Icons.scatter_plot,
    description: '???',
  ),
  uniformCountSecondary(
    label: 'Secondary Count',
    uniform: 'u_countSecondary',
    iconData: Icons.scatter_plot_outlined,
    description: '???',
  ),
  uniformHueRange(
    label: 'Hue Range',
    uniform: 'u_hueRange',
    iconData: Icons.format_paint,
    description: '???',
  ),
  uniformHueShift(
    label: 'Hue Shift',
    uniform: 'u_hueShift',
    iconData: Icons.color_lens_rounded,
    description: '???',
  ),
  uniformEmphasis(
    label: 'Emphasis',
    uniform: 'u_emphasis',
    iconData: Icons.tonality_outlined,
    description: '???',
  ),
  uniformSpeed(
    label: 'Speed',
    uniform: 'u_speed',
    iconData: Icons.speed,
    description: '???',
  ),
  uniformWarp(
    label: 'Warp',
    uniform: 'u_warp',
    iconData: Icons.storm,
    description: '???',
  ),
  uniformZoom(
    label: 'Zoom',
    uniform: 'u_zoom',
    iconData: Icons.crop_free,
    description: '???',
  ),
  uniformSpread(
    label: 'Spread',
    uniform: 'u_spread',
    iconData: Icons.expand_outlined,
    description: '???',
  ),
  uniformSize(
    label: 'Size',
    uniform: 'u_size',
    iconData: Icons.bubble_chart_rounded,
    description: '???',
  );

  ///
  ///

  final String label;
  final String description;
  final String? uniform;
  final bool isNonUniformTweak;
  final IconData iconData;
  const TweakType({
    required this.label,
    required this.description,
    required this.iconData,
    this.isNonUniformTweak = false,
    this.uniform,
  });
}

enum RenderScale {
  //eighth(0.125),
  quarter(0.25),
  half(0.5),
  full(1.0);

  const RenderScale(this.value);
  final double value;
}

enum DirectionOfChange { increase, decrease, none }
