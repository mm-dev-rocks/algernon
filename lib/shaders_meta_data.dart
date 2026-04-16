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
        min: 0.05,
        max: 0.5,
        defaultVal: 0.18,
      ),
      TweakType.uniformFoldCount.name: ShaderTweakModel(
        id: 'warp_kaleido_${TweakType.uniformFoldCount.name}',
        tweakType: TweakType.uniformFoldCount,
        min: 3,
        max: 12,
        divisions: 9,
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
        max: 0.25,
        defaultVal: 0.18,
      ),
      TweakType.uniformBorderWidth.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.uniformBorderWidth.name}',
        tweakType: TweakType.uniformBorderWidth,
        min: 0.01,
        max: 0.04,
        defaultVal: 0.02,
      ),
      TweakType.uniformBaseRadius.name: ShaderTweakModel(
        id: 'voronoi_cells_${TweakType.uniformBaseRadius.name}',
        tweakType: TweakType.uniformBaseRadius,
        min: 0.05,
        max: 0.75,
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
];
