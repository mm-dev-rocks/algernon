// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/audio_analysis.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/shader_tweak_model.dart';

/// Each shader in the app should have a respective [ShaderModel].
/// Sets up some config defaults and provides a place to store user settings.
class ShaderModel {
  ShaderModel({
    required this.friendlyName,
    required this.id,
    this.shaderTweaks = const {},
  }) : assert(
         shaderTweaks.values.where((t) => t.isEnergyUniform).length <= 1,
         'Only one [ShaderTweakModel] in a [ShaderModel] may have `isEnergyUniform` set to `true`',
       );

  final String friendlyName;
  final String id;
  final Map<String, ShaderTweakModel> shaderTweaks;

  String get assetKey => 'shaders/$id.frag';

  /// If an 'energy uniform' tweak exists, calibrate the audio track to it.
  void calibrateAudioEnergy() {
    ShaderTweakModel? energyUniformTweak = shaderTweaks.values
        .where((tweak) => tweak.isEnergyUniform)
        .firstOrNull;

    if (energyUniformTweak != null) {
      int min = energyUniformTweak.min.toInt();
      int max = energyUniformTweak.max.toInt();
      AudioAnalysis.calibrateForShaderWithZones(
        boundaryThreshold: AudioAnalysis.suggestedBoundaryThreshold(),
        blendBuckets: ALGERNON.energyZoneBlendBuckets,
        divisions: energyUniformTweak.divisions ?? max - min,
        min: min,
        max: max,
      );
    }
  }

  @override
  String toString() {
    return '''
$id
  $friendlyName
  $assetKey
  ${shaderTweaks.entries.map((entry) => '${entry.value.toString()}\n')}
''';
  }
}
