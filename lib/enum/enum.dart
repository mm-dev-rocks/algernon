// SPDX-License-Identifier: GPL-3.0-only

enum TweakType {
  fftDataSmoothing(
    label: 'Stability',
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
  uniformAttenuation(
    label: 'Attenuation',
    uniform: 'u_attenuation',
    description: 'Used to affect eg fading distance',
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
  uniformRingFill(
    label: 'Ring Fill',
    uniform: 'u_ringFill',
    description: '???',
  ),
  uniformHueRange(
    label: 'Hue Range',
    uniform: 'u_hueRange',
    description: '???',
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
  ),
  uniformArmCount(
    label: 'Arm Count',
    uniform: 'u_armCount',
    description:
        'Number of spiral arms. Even numbers give point-symmetric patterns; odd numbers give more organic asymmetric spirals.',
  ),
  uniformArmContrast(
    label: 'Arm Contrast',
    uniform: 'u_armContrast',
    description:
        'Controls the sharpness of the spiral arm edges. 1.0 = smooth cosine gradient, higher values → sharper arm boundaries.',
  ),
  uniformMaxTwist(
    label: 'Maximum Twist',
    uniform: 'u_maxTwist',
    description:
        'Maximum twist in radians that a bin at full amplitude can apply to its ring. pi (3.14) = half a full rotation; 2*pi = one full rotation per ring.',
  ),
  uniformBandCount(
    label: 'Band Count',
    uniform: 'u_bandCount',
    description:
        'How many radial bands to map across the 256 FFT bins. 32 gives smooth transitions between adjacent rings while still showing fine per-ring variation. Must divide evenly into 256.',
  ),
  uniformBlobCount(
    label: 'Blob Count',
    uniform: 'u_blobCount',
    description: '???',
  ),
  uniformBlobSize(
    label: 'Blob Size',
    uniform: 'u_blobSize',
    description: '???',
  ),
  uniformSpeed(label: 'Speed', uniform: 'u_speed', description: '???'),
  uniformSphereRadius(
    label: 'Sphere Radius',
    uniform: 'u_sphereRadius',
    description: '???',
  ),
  uniformGlowStrength(
    label: 'Glow Strength',
    uniform: 'u_glowStrength',
    description: '???',
  ),
  uniformBranchDepth(
    label: 'Branch Depth',
    uniform: 'u_branchDepth',
    description: '???',
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
