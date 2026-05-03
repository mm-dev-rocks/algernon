// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/enum.dart';
import 'package:algernon/shader_model.dart';
import 'package:algernon/shader_tweak_model.dart';

final List<ShaderModel> shadersData = [
  //ShaderModel(
  //  friendlyName: 'Blocks Simple',
  //  id: 'blocks_simple',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'blocks_simple',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //  },
  //),
  //ShaderModel(
  //  friendlyName: 'Blocks Spiral',
  //  id: 'blocks_spiral',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'blocks_spiral',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //  },
  //),
  ShaderModel(
    friendlyName: 'Rose Tunnel',
    id: 'rose_tunnel_quadrant',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rose_tunnel_quadrant',
        tweakType: TweakType.fftDataSmoothing,
      ),
    },
  ),
  //ShaderModel(
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
  ShaderModel(
    friendlyName: 'Warp Kaleido',
    id: 'warp_kaleido',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformCountPrimary,
        min: 1,
        max: 7,

        /// Divisions should be difference between min and max to end up with whole integers
        divisions: 6,
        defaultValue: 3,
      ),
      TweakType.uniformWarp.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformWarp,
        min: 0.01,
        max: 0.2,
        defaultValue: 0.1,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'warp_kaleido',
        tweakType: TweakType.uniformEmphasis,
        min: 0.001,
        max: 3,
        defaultValue: 1.4,
      ),
    },
  ),
  ShaderModel(
    friendlyName: 'Organelles',
    id: 'lissajous_web',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'lissajous_web',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.99,
        max: 0.9999,
        defaultValue: 0.99,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'lissajous_web',
        tweakType: TweakType.uniformCountPrimary,
        isEnergyUniform: true,
        min: 2,
        max: 80,
        divisions: 78,
        defaultValue: 40,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'lissajous_web',
        tweakType: TweakType.uniformEmphasis,
        min: 1.0,
        max: 10.0,
        defaultValue: 4.5,
      ),
      TweakType.uniformZoom.name: ShaderTweakModel(
        shaderId: 'lissajous_web',
        tweakType: TweakType.uniformZoom,
        min: 0.1,
        max: 0.9,
        defaultValue: 0.82,
      ),
    },
  ),
  ShaderModel(
    friendlyName: 'Voronoi Cells',
    id: 'voronoi_cells',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformSpread.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformSpread,
        min: 0.05,
        max: 0.5,
        defaultValue: 0.18,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformEmphasis,
        min: 0.01,
        max: 0.06,
        defaultValue: 0.02,
      ),
      TweakType.uniformZoom.name: ShaderTweakModel(
        shaderId: 'voronoi_cells',
        tweakType: TweakType.uniformZoom,
        min: 0.001,
        max: 2,
        defaultValue: 0.30,
      ),
    },
  ),
  ShaderModel(
    friendlyName: 'Radiate',
    id: 'rings_radial_2',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.95,
        defaultValue: 0.75,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformCountPrimary,
        min: 4,
        max: 128,
        defaultValue: 16,
      ),
      TweakType.uniformHueRange.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformHueRange,
        min: 0,
        max: 360,
        defaultValue: 120,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 200,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'rings_radial_2',
        tweakType: TweakType.uniformEmphasis,
        min: 0.1,
        max: 1,
        defaultValue: 0.75,
      ),
    },
  ),
  ShaderModel(
    friendlyName: 'Moire',
    id: 'moire_grid',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.75,
        max: 0.999,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformCountPrimary,
        min: 1,
        max: 30,
        defaultValue: 14,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformEmphasis,
        min: 0.1,
        max: 2,
        defaultValue: 1.8,
      ),
      TweakType.uniformSpread.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformSpread,
        min: 0.01,
        max: 0.33,
        defaultValue: 0.22,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'moire_grid',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 180,
      ),
    },
  ),
  ShaderModel(
    friendlyName: 'Alloy',
    id: 'polar_warp',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformCountPrimary,
        min: 3,
        max: 18,
        divisions: 15,
        defaultValue: 5,
      ),
      TweakType.uniformCountSecondary.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformCountSecondary,
        isEnergyUniform: true,
        min: 1,
        max: 32,
        divisions: 31,
        defaultValue: 8,
      ),
      TweakType.uniformWarp.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformWarp,
        min: 3.14,
        max: 9.42,
        defaultValue: 5,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformEmphasis,
        min: 0,
        max: 15,
        defaultValue: 2.2,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'polar_warp',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 200,
      ),
    },
  ),
  //ShaderModel(
  //  friendlyName: 'Domain Tiles',
  //  id: 'domain_tiles',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'domain_tiles',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //    TweakType.uniformBandCount.name: ShaderTweakModel(
  //      shaderId: 'domain_tiles',
  //      tweakType: TweakType.uniformBandCount,
  //      isEnergyUniform: true,
  //      min: 1,
  //      max: 16,
  //      divisions: 15,
  //      defaultValue: 8,
  //    ),
  //  },
  //),
  //ShaderModel(
  //  friendlyName: 'Interference Waves',
  //  id: 'interference_waves',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.fftDataSmoothing,
  //    ),
  //  },
  //),
  //ShaderModel(
  //  friendlyName: 'Interference',
  //  id: 'interference_waves',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.fftDataSmoothing,
  //      min: 0.5,
  //      max: 0.97,
  //      defaultValue: 0.75,
  //    ),
  //    TweakType.uniformSpeed.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformSpeed,
  //      min: 0.1,
  //      max: 3.0,
  //      defaultValue: 1.0,
  //    ),
  //    TweakType.uniformWarp.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformWarp,
  //      min: 0.0,
  //      max: 3.0,
  //      defaultValue: 0.8,
  //    ),
  //    TweakType.uniformZoom.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformZoom,
  //      min: 5.0,
  //      max: 40.0,
  //      defaultValue: 18.0,
  //    ),
  //    TweakType.uniformSpread.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformSpread,
  //      min: 0.0,
  //      max: 0.3,
  //      defaultValue: 0.08,
  //    ),
  //    TweakType.uniformHueShift.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformHueShift,
  //      min: 0,
  //      max: 180,
  //      defaultValue: 60,
  //    ),
  //    TweakType.uniformEmphasis.name: ShaderTweakModel(
  //      shaderId: 'interference_waves',
  //      tweakType: TweakType.uniformEmphasis,
  //      min: 0.3,
  //      max: 4.0,
  //      defaultValue: 1.6,
  //    ),
  //  },
  //),
  ShaderModel(
    friendlyName: 'Orb Faeries',
    id: 'slime_trails',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.99,
        defaultValue: 0.75,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformCountPrimary,
        isEnergyUniform: true,
        min: 2,
        max: 8,
        divisions: 6,
        defaultValue: 6,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformEmphasis,
        min: 0.05,
        max: 0.5,
        defaultValue: 0.18,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 140,
      ),
      TweakType.uniformSpeed.name: ShaderTweakModel(
        shaderId: 'slime_trails',
        tweakType: TweakType.uniformSpeed,
        min: 0.2,
        max: 3.0,
        defaultValue: 1.0,
      ),
    },
  ),

  ShaderModel(
    friendlyName: 'Roots',
    id: 'root_system',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformCountPrimary,
        isEnergyUniform: true,
        min: 3,
        max: 13,
        divisions: 10,
        defaultValue: 6,
      ),
      TweakType.uniformCountSecondary.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformCountSecondary,
        min: 1,
        max: 3,
        divisions: 2,
        defaultValue: 2,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformEmphasis,
        min: 0.1,
        max: 2,
        defaultValue: 0.6,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 30,
      ),
      TweakType.uniformWarp.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformWarp,
        min: 0.1,
        max: 10,
        defaultValue: 1.2,
      ),
      TweakType.uniformZoom.name: ShaderTweakModel(
        shaderId: 'root_system',
        tweakType: TweakType.uniformZoom,
        min: 0.2,
        max: 1,
        defaultValue: 0.55,
      ),
    },
  ),

  ShaderModel(
    friendlyName: 'Murmuration',
    id: 'murmuration',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.fftDataSmoothing,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformCountPrimary,
        min: 4,
        max: 128,
        defaultValue: 28,
      ),
      TweakType.uniformSpread.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformSpread,
        min: 1,
        max: 2.0,
        defaultValue: 1.5,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 200,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'murmuration',
        tweakType: TweakType.uniformEmphasis,
        min: 0.0,
        max: 2.0,
        defaultValue: 0.8,
      ),
    },
  ),

  ShaderModel(
    friendlyName: 'Fluid',
    id: 'fluid_ink',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.99,
        defaultValue: 0.8,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformCountPrimary,
        min: 1,
        max: 16,
        divisions: 15,
        defaultValue: 3,
      ),
      TweakType.uniformWarp.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformWarp,
        min: 0.2,
        max: 15,
        defaultValue: 0.7,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 25,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'fluid_ink',
        tweakType: TweakType.uniformEmphasis,
        min: 0.1,
        max: 6.0,
        defaultValue: 1.4,
      ),
    },
  ),

  ShaderModel(
    friendlyName: 'Spectral Sphere',
    id: 'spectral_sphere',
    shaderTweaks: {
      TweakType.fftDataSmoothing.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.fftDataSmoothing,
        min: 0.5,
        max: 0.99,
        defaultValue: 0.8,
      ),
      TweakType.uniformCountPrimary.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformCountPrimary,
        min: 8,
        max: 128,
        divisions: 12,
        defaultValue: 40,
      ),
      TweakType.uniformSpeed.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformSpeed,
        min: 0.05,
        max: 5.0,
        defaultValue: 0.18,
      ),
      TweakType.uniformSpread.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformSpread,
        min: 0.1,
        max: 2,
        defaultValue: 0.33,
      ),
      TweakType.uniformHueRange.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformHueRange,
        min: 0,
        max: 360,
        defaultValue: 120,
      ),
      TweakType.uniformHueShift.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformHueShift,
        min: 0,
        max: 360,
        defaultValue: 25,
      ),
      TweakType.uniformSize.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformSize,
        min: 0.01,
        max: 0.12,
        defaultValue: 0.038,
      ),
      TweakType.uniformEmphasis.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformEmphasis,
        min: 0.02,
        max: 3.0,
        defaultValue: 1.8,
      ),
      TweakType.uniformZoom.name: ShaderTweakModel(
        shaderId: 'spectral_sphere',
        tweakType: TweakType.uniformZoom,
        min: 0.15,
        max: 1,
        defaultValue: 0.32,
      ),
    },
  ),

  //ShaderModel(
  //  friendlyName: 'Spectral Sphere 2',
  //  id: 'spectral_sphere_2',
  //  shaderTweaks: {
  //    TweakType.fftDataSmoothing.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.fftDataSmoothing,
  //      min: 0.5,
  //      max: 0.99,
  //      defaultValue: 0.8,
  //    ),
  //    TweakType.uniformHueShift.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformHueShift,
  //      min: 0,
  //      max: 360,
  //      defaultValue: 25,
  //    ),
  //    TweakType.uniformSpeed.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformSpeed,
  //      min: 0.05,
  //      max: 1.0,
  //      defaultValue: 0.18,
  //    ),
  //    TweakType.uniformHueRange.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformHueRange,
  //      min: 0,
  //      max: 360,
  //      defaultValue: 120,
  //    ),
  //    TweakType.uniformBlobSize.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformBlobSize,
  //      min: 0.01,
  //      max: 0.12,
  //      defaultValue: 0.038,
  //    ),
  //    TweakType.uniformGlowStrength.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformGlowStrength,
  //      min: 0.05,
  //      max: 4.0,
  //      defaultValue: 1.8,
  //    ),
  //    TweakType.uniformSphereRadius.name: ShaderTweakModel(
  //      shaderId: 'spectral_sphere_2',
  //      tweakType: TweakType.uniformSphereRadius,
  //      min: 0.15,
  //      max: 0.48,
  //      defaultValue: 0.32,
  //    ),
  //  },
  //),
];
