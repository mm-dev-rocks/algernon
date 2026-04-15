// SPDX-License-Identifier: GPL-3.0-only

enum TweakType {
  fftDataSmoothing(
    label: 'FFT Smoothing',
    description: 'Smoothing/interpolation between FFT bins.',
  ),
  uniformPushRange(
    label: 'Push Range',
    uniform: 'u_pushRange',
    description: 'Size range of the cell size swings',
  ),
  uniformBorderWidth(
    label: 'Border Width',
    uniform: 'u_borderWidth',
    description: 'Width of black borders',
  ),
  uniformBaseRadius(
    label: 'Base Radius',
    uniform: 'u_baseRadius',
    description: 'Radius of base',
  );

  final String label;
  final String description;
  final String? uniform;
  const TweakType({
    required this.label,
    required this.description,
    this.uniform,
  });
}

enum TweakId {
  fftDataSmoothing,
  uniformPushRange,
  uniformBorderWidth,
  uniformBaseRadius,
}
