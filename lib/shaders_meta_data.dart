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
        id: 'rose_tunnel_quadrant_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Blocks Spiral',
    id: 'blocks_spiral',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'blocks_spiral_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Blocks Simple',
    id: 'blocks_simple',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'blocks_simple_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Oscilloscope Columns',
    id: 'oscilloscope_columns',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'oscilloscope_columns_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Rings Radial',
    id: 'rings_radial',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'rings_radial_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Warp Kaleido',
    id: 'warp_kaleido',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'warp_kaleido_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformWarpStrength.name: ShaderTweakModel(
        id: 'warp_kaleido_${TweakType.uniformWarpStrength.name}',
        tweakType: TweakType.uniformWarpStrength,
        min: 0.01,
        max: 0.2,
        defaultVal: 0.1,
      ),
      TweakType.uniformFoldCount.name: ShaderTweakModel(
        id: 'warp_kaleido_${TweakType.uniformFoldCount.name}',
        tweakType: TweakType.uniformFoldCount,
        min: 1,
        max: 64,
        divisions: 63,
        defaultVal: 6,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Lissajous Web',
    id: 'lissajous_web',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'lissajous_web_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Interference Waves',
    id: 'interference_waves',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'interference_waves_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Voronoi Cells',
    id: 'voronoi_cells',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformPushRange.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.uniformPushRange.name}',
        tweakType: TweakType.uniformPushRange,
        min: 0.05,
        max: 0.5,
        defaultVal: 0.18,
      ),
      TweakType.uniformBorderWidth.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.uniformBorderWidth.name}',
        tweakType: TweakType.uniformBorderWidth,
        min: 0.01,
        max: 0.06,
        defaultVal: 0.02,
      ),
      TweakType.uniformBaseRadius.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.uniformBaseRadius.name}',
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
        id: 'moire_grid_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformRingDensity.name: ShaderTweakModel(
        id: 'moire_grid_${TweakType.uniformRingDensity.name}',
        tweakType: TweakType.uniformRingDensity,
        min: 1,
        max: 30,
        defaultVal: 14,
      ),
      TweakType.uniformRingContrast.name: ShaderTweakModel(
        id: 'moire_grid_${TweakType.uniformRingContrast.name}',
        tweakType: TweakType.uniformRingContrast,
        min: 0.1,
        max: 2,
        defaultVal: 1.8,
      ),
      TweakType.uniformMaxOffset.name: ShaderTweakModel(
        id: 'moire_grid_${TweakType.uniformMaxOffset.name}',
        tweakType: TweakType.uniformMaxOffset,
        min: 0.01,
        max: 0.33,
        defaultVal: 0.22,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        id: 'moire_grid_${TweakType.uniformHueShift.name}',
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
        id: 'polar_warp_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Domain Tiles',
    id: 'domain_tiles',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'domain_tiles_${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  ShaderMetaModel(
    friendlyName: 'Rings Radial 2',
    id: 'rings_radial_2',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        id: 'rings_radial_2${TweakType.fftDataSmoothing.name}',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        id: 'rings_radial_2${TweakType.uniformHueShift.name}',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 200,
      ),
      TweakType.uniformHueRange.name: ShaderTweakModel(
        id: 'rings_radial_2${TweakType.uniformHueRange.name}',
        tweakType: TweakType.uniformHueRange,
        min: 0,
        max: 360,
        defaultVal: 120,
      ),
      TweakType.uniformRingDensity.name: ShaderTweakModel(
        id: 'rings_radial_2${TweakType.uniformRingDensity.name}',
        tweakType: TweakType.uniformRingDensity,
        min: 4,
        max: 128,
        defaultVal: 16,
      ),
      TweakType.uniformRingFill.name: ShaderTweakModel(
        id: 'rings_radial_2${TweakType.uniformRingFill.name}',
        tweakType: TweakType.uniformRingFill,
        min: 0.05,
        max: 1.1,
        defaultVal: 0.75,
      ),
    },
  ),
];
