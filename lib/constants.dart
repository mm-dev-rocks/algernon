// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/shader_model.dart';
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
    'selectedMemorySlotIndex': [int, 0],
    'selectedAudioFilePathIndex': [int, 0],
  };

  static const int totalMemorySlots = 5;

  static const double disabledControlOpacity = 0.3;

  static const int finalAimFps = 30;
  static const Duration hideControlsDelay = Duration(seconds: 8);

  /// Shader meta info is in another file to keep this file maintainable.
  static final List<ShaderModel> shadersData = meta.shadersData;

  static const Duration defaultDebounceDuration = Duration(milliseconds: 200);
  static const Duration showControlsDebounceDuration = Duration(
    milliseconds: 150,
  );

  ///
  ///
  ///////////////////////
  ///
  /// UI / Layout
  /// Responsive
  ///
  ///////////////////////

  /*
    From:
    https://developer.android.com/guide/topics/large-screens/support-different-screen-sizes

    Compact width 	width < 600dp 	99.96% of phones in portrait
    Medium width 	600dp ≤ width < 840dp 	93.73% of tablets in portrait,

    Large unfolded inner displays in portrait
    Expanded width 	width ≥ 840dp 	97.22% of tablets in landscape,
  */
  static const double breakpointTiny = 400;
  static const double breakpointCompact = 600;

  static const List<String> audioTrackFilePaths = [
    "assets/BEATPELLA HOUSE - Candy Thief.mp3",
    'assets/Public Image Limited - Rise.mp3',
    'assets/South Street Player - Who Keeps Changing Your Mind.mp3',
    'assets/Bob Dylan - Eternal Circle.mp3',
    'assets/Sister Sledge - Thinking Of You.mp3',
    'assets/Pointer Sisters - Automatic.mp3',
  ];
}
