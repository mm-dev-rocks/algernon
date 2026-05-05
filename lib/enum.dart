// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

/// The order of this enum matters! Don't move stuff around without checking how the uniforms are passed into the
/// shaders!
enum TweakType {
  /// Special slider outside normal tweaks
  fftDataSmoothing(
    label: 'Stability',
    iconData: Icons.video_stable_outlined,
    description:
        'Reponsiveness to the audio. Less responsive means smoother visuals.',
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
    description: 'Number of primary objects',
  ),
  uniformCountSecondary(
    label: 'Secondary Count',
    uniform: 'u_countSecondary',
    iconData: Icons.scatter_plot_outlined,
    description: 'Number of secondary objects',
  ),
  uniformHueRange(
    label: 'Hue Range',
    uniform: 'u_hueRange',
    iconData: Icons.color_lens_rounded,
    description: 'How much total colour',
  ),
  uniformHueShift(
    label: 'Hue Shift',
    uniform: 'u_hueShift',
    iconData: Icons.colorize,
    description: 'Spin color wheel',
  ),
  uniformEmphasis(
    label: 'Emphasis',
    uniform: 'u_emphasis',
    iconData: Icons.tonality_outlined,
    description: 'Contrast / attenuation',
  ),
  uniformSpeed(
    label: 'Speed',
    uniform: 'u_speed',
    iconData: Icons.speed,
    description: 'Speed of motion',
  ),
  uniformWarp(
    label: 'Warp',
    uniform: 'u_warp',
    iconData: Icons.storm,
    description: 'Twistedness',
  ),
  uniformZoom(
    label: 'Zoom',
    uniform: 'u_zoom',
    iconData: Icons.all_out_outlined,
    description: 'Scale or move in/out',
  ),
  uniformSpread(
    label: 'Spread',
    uniform: 'u_spread',
    iconData: Icons.code,
    description: 'Distance between things',
  ),
  uniformSize(
    label: 'Size',
    uniform: 'u_size',
    iconData: Icons.bubble_chart_rounded,
    description: 'Size of things',
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

enum LoopType { none, all, one }
