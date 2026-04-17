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
  ),
  uniformRingDensity(
    label: 'Ring Density',
    uniform: 'u_ringDensity',
    description:
        'Baseline ring density: how many full ring cycles fit across the screen at silence. Higher = finer rings, more detail in the moiré pattern.',
  ),
  uniformRingContrast(
    label: 'Ring Contrast',
    uniform: 'u_ringContrast',
    description:
        'Controls how sharply the ring edges are defined. 1.0 = smooth sine gradient, higher values → harder, brighter ring edges.',
  ),
  uniformMaxOffset(
    label: 'Max Offset',
    uniform: 'u_maxOffset',
    description:
        'Maximum offset of each field centre from screen centre, in normalised units (0..1 space). At full bass energy both centres reach this distance from the middle, so the total spread is 2 × MAX_OFFSET.',
  ),
  uniformHueShift(
    label: 'Hue Shift',
    uniform: 'u_hueShift',
    description: 'Shift. The. Hue.',
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
