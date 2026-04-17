// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/shader_meta_model.dart';
import 'package:flutter/material.dart';

import 'package:algernon/shaders_meta_data.dart' as meta;

/// Lots of constants related to the app:
/// - UI (eg colours, sizes)
/// - Defaults for user preferences
/// - Important file paths
/// - Some NewPipe-specific info relating to the database, such as table names
class ALGERNON {
  static const String appName = 'Algernon - Audio Visualiser';
  static const String androidNotificationChannelId =
      'rocks.mm_dev.algernon.channel';

  /// Route / page names
  static const String routeRoot = '/';
  static const String routePreferences = 'preferences';

  /// Default user settings [type, value]
  /// Type can be String, bool, int or double
  /// All preferences must have a default defined here
  /// Some of these (eg 'expandChapterMetadata', 'debugPanelIsOpen') don't
  /// appear on the settings page but are used to remember in-app preferences.
  static final Map<String, dynamic> defaultPreferences = {
    /// On first run, default to system preference
    'disableAnimations': [
      bool,
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations,
    ],

    'themeBrightnessModeIndex': [int, 0],
    'colorScheme': [String, 'Choc Lime'],

    /// Container for shader tweaks, which are saved as 'preferences' for persistence between sessions.
    'shaderTweakValuesMap': [],
    'selectedShaderIndex': [int, 0],
  };

  static const int finalAimFps = 30;

  /// Shader meta info is in another file to keep this file maintainable.
  static final List<ShaderMetaModel> shadersMetadata = meta.shadersMetadata;
}
