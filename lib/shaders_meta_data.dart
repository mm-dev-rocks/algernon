// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/enum/enum.dart';
import 'package:algernon/shader_meta_model.dart';
import 'package:algernon/shader_tweak_model.dart';

final List<ShaderMetaModel> shadersMetadata = [
  ShaderMetaModel(
    friendlyName: 'Rose Tunnel',
    id: 'rose_tunnel_quadrant',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rose_tunnel_quadrant',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Blocks Spiral',
    id: 'blocks_spiral',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'blocks_spiral',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Blocks Simple',
    id: 'blocks_simple',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'blocks_simple',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Oscilloscope Columns',
    id: 'oscilloscope_columns',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'oscilloscope_columns',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Rings Radial',
    id: 'rings_radial',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rings_radial',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Warp Kaleido',
    id: 'warp_kaleido',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformWarpStrength.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformWarpStrength,
        min: 0.01,
        max: 0.2,
        defaultVal: 0.1,
      ),
      TweakType.uniformFoldCount.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformFoldCount,
        min: 1,
        max: 7,

        /// Divisions should be difference between min and max to end up with whole integers
        divisions: 6,
        defaultVal: 3,
      ),
      TweakType.uniformAttenuation.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformAttenuation,
        min: 0.1,
        max: 3,
        defaultVal: 1.4,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Lissajous Web',
    id: 'lissajous_web',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'lissajous_web',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.97,
        max: 0.999,
        defaultVal: 0.98,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Interference Waves',
    id: 'interference_waves',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'interference_waves',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Voronoi Cells',
    id: 'voronoi_cells',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformPushRange.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformPushRange,
        min: 0.05,
        max: 0.5,
        defaultVal: 0.18,
      ),
      TweakType.uniformBorderWidth.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformBorderWidth,
        min: 0.01,
        max: 0.06,
        defaultVal: 0.02,
      ),
      TweakType.uniformBaseRadius.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformBaseRadius,
        min: 0.03,
        max: 0.85,
        defaultVal: 0.30,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Moire Grid',
    id: 'moire_grid',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformRingDensity.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformRingDensity,
        min: 1,
        max: 30,
        defaultVal: 14,
      ),
      TweakType.uniformRingContrast.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformRingContrast,
        min: 0.1,
        max: 2,
        defaultVal: 1.8,
      ),
      TweakType.uniformMaxOffset.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformMaxOffset,
        min: 0.01,
        max: 0.33,
        defaultVal: 0.22,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 180,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Polar Warp',
    id: 'polar_warp',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Domain Tiles',
    id: 'domain_tiles',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'domain_tiles',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Rings Radial 2',
    id: 'rings_radial_2',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.95,
        defaultVal: 0.75,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 200,
      ),
      TweakType.uniformHueRange.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformHueRange,
        min: 0,
        max: 360,
        defaultVal: 120,
      ),
      TweakType.uniformRingDensity.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformRingDensity,
        min: 4,
        max: 128,
        defaultVal: 16,
      ),
      TweakType.uniformRingFill.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformRingFill,
        min: 0.05,
        max: 1.1,
        defaultVal: 0.75,
      ),
    },
  ),
];
