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
  ),
  uniformWarpStrength(
    label: 'Warp Strength',
    uniform: 'u_warpStrength',
    description:
        'How strongly the FFT bins push and pull the coordinate field. Larger values = more dramatic warping; above ~0.3 it can fold on itself.',
  ),
  uniformFoldCount(
    label: 'Fold Count',
    uniform: 'u_foldCount',
    description:
        'Must be a positive integer; non-integer values produce asymmetric tears.',
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
