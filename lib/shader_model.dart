// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/shader_tweak_model.dart';

/// Each shader in the app should have a respective [ShaderModel].
/// Sets up some config defaults and provides a place to store user settings.
class ShaderModel {
  const ShaderModel({
    required this.friendlyName,
    required this.id,
    this.shaderTweaks = const {},
  });

  final String friendlyName;
  final String id;
  final Map<String, ShaderTweakModel> shaderTweaks;

  String get assetKey => 'shaders/$id.frag';
}
