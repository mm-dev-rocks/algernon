// SPDX-License-Identifier: GPL-3.0-only

enum TweakType {
  fftDataSmoothing(
    name: 'FFT Smoothing',
    description: 'Smoothing/interpolation between FFT bins.',
  );

  final String name;
  final String description;
  const TweakType({required this.name, required this.description});
}

enum TweakId { fftDataSmoothing }
