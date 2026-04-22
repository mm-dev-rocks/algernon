// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/enum/enum.dart';
import 'package:algernon/shader_meta_model.dart';
import 'package:algernon/shader_tweak_model.dart';

final List<ShaderMetaModel> shadersMetadata = [
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
    friendlyName: 'Rose Tunnel',
    id: 'rose_tunnel_quadrant',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rose_tunnel_quadrant',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  //ShaderMetaModel(
  //  friendlyName: 'Oscilloscope Columns',
  //  id: 'oscilloscope_columns',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'oscilloscope_columns',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //  },
  //),
  //ShaderMetaModel(
  //  friendlyName: 'Rings Radial',
  //  id: 'rings_radial',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'rings_radial',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //  },
  //),
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
      TweakType.uniformArmCount.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformArmCount,
        min: 3,
        max: 13,
        divisions: 10,
        defaultVal: 5,
      ),
      TweakType.uniformMaxTwist.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformMaxTwist,
        min: 3.14,
        max: 6.28,
        defaultVal: 5,
      ),
      TweakType.uniformBandCount.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformBandCount,
        min: 16,
        max: 256,
        divisions: 16,
        defaultVal: 32,
      ),
      TweakType.uniformArmContrast.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformArmContrast,
        min: 0,
        max: 5,
        defaultVal: 2.2,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 200,
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
    friendlyName: 'Slime Trails',
    id: 'slime_trails',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.95,
        defaultVal: 0.75,
      ),
      TweakType.uniformBlobCount.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformBlobCount,
        min: 2,
        max: 8,
        divisions: 6,
        defaultVal: 6,
      ),
      TweakType.uniformBlobSize.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformBlobSize,
        min: 0.05,
        max: 0.5,
        defaultVal: 0.18,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 140,
      ),
      TweakType.uniformSpeed.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformSpeed,
        min: 0.2,
        max: 3.0,
        defaultVal: 1.0,
      ),
    },
  ),

  ShaderMetaModel(
    friendlyName: 'Root System',
    id: 'root_system',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformArmCount.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformArmCount,
        min: 3,
        max: 12,
        divisions: 9,
        defaultVal: 6,
      ),
      TweakType.uniformBranchDepth.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformBranchDepth,
        min: 1,
        max: 4,
        divisions: 3,
        defaultVal: 2,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 30,
      ),
      TweakType.uniformMaxTwist.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformMaxTwist,
        min: 0.1,
        max: 2.5,
        defaultVal: 1.2,
      ),
    },
  ),

  ShaderMetaModel(
    friendlyName: 'Murmuration',
    id: 'murmuration',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformRingDensity.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformRingDensity,
        min: 4,
        max: 64,
        defaultVal: 28,
      ),
      TweakType.uniformRingContrast.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformRingContrast,
        min: 0.5,
        max: 4.0,
        defaultVal: 2.0,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 200,
      ),
      TweakType.uniformAttenuation.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformAttenuation,
        min: 0.0,
        max: 2.0,
        defaultVal: 0.8,
      ),
    },
  ),

  ShaderMetaModel(
    friendlyName: 'Fluid Ink',
    id: 'fluid_ink',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.95,
        defaultVal: 0.8,
      ),
      TweakType.uniformWarpStrength.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformWarpStrength,
        min: 0.1,
        max: 1.5,
        defaultVal: 0.7,
      ),
      TweakType.uniformBandCount.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformBandCount,
        min: 1,
        max: 4,
        divisions: 3,
        defaultVal: 3,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultVal: 25,
      ),
      TweakType.uniformRingContrast.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformRingContrast,
        min: 0.3,
        max: 3.0,
        defaultVal: 1.4,
      ),
    },
  ),
];
