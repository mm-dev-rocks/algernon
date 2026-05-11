// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io';

import 'package:algernon/shader_model.dart';
import 'package:flutter/material.dart';

import 'package:algernon/shaders_meta_data.dart' as meta;
import 'package:algernon/shader_defaults.dart' as shader_defaults;

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
    //'disableAnimations': [
    //  bool,
    //  WidgetsBinding
    //      .instance
    //      .platformDispatcher
    //      .accessibilityFeatures
    //      .disableAnimations,
    //],

    //'themeBrightnessModeIndex': [int, 0],
    //'colorScheme': [String, 'Choc Lime'],
    'selectedShaderIndex': [int, 0],
    'selectedMemorySlotIndex': [int, 0],
    'selectedAudioFilePathIndex': [int, 0],

    /// Default to 'no looping'
    'loopTypeIndex': [int, 0],
    //
    'playlist': [List<String>, <String>[]],
    'selectedPlaylistFilePathIndex': [int, 0],
  }..addAll(shader_defaults.shaderDefaults);

  static const int soLoudBufferSize = 2048;
  static const double binEmaSmoothing = 0.95;
  static const double binChargeSmoothing = 0.5;
  static const int energyZoneBlendBuckets = 3;

  static const int totalMemorySlots = 5;

  static const double fadeDarkBackgroundOpacity = 0.7;

  static const double disabledControlOpacity = 0.5;
  static const double buttonBorderThickness = 1;

  static const int droppedFrameMeasurementLength = 45;
  static const int finalAimFps = 33;
  static const int oneMillion = 1000000;
  static const int resLoweredLockoutSecs = 15;
  static const int resRaisedLockoutSecs = 5;

  static const String autoCountPrefSuffix = 'auto';
  static const String memorySlotPrefPrefix = 'memslot';

  /// Shader meta info is in another file to keep this file maintainable.
  static final List<ShaderModel> shadersData = meta.shadersData;

  static const Duration defaultDebounceDuration = Duration(milliseconds: 200);

  static const Duration hideControlsDelay = Duration(seconds: 5);
  static const Duration showControlsDebounceDuration = Duration(
    milliseconds: 150,
  );
  static const Duration hideControlsFadeDuration = Duration(milliseconds: 800);
  static const Duration showControlsFadeDuration = Duration(milliseconds: 300);

  static final Color uiDefaultForegroundColor = Colors.white.withValues(
    alpha: 0.5,
  );
  static final Color uiSoftForegroundColor = Colors.white.withValues(
    alpha: 0.3,
  );
  //static final Color uiDefaultForegroundColor = Color.alphaBlend(
  //  Colors.white.withValues(alpha: 0.5),
  //  Colors.black,
  //);
  //static final Color uiSoftForegroundColor = Color.alphaBlend(
  //  Colors.white.withValues(alpha: 0.3),
  //  Colors.black,
  //);
  static final Color uiAttractColor = Colors.pink.withValues(
    alpha: ALGERNON.fadeDarkBackgroundOpacity,
  );
  //Colors.green;

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

  static const double controlPanelWidthMin = 300;
  static const double controlPanelWidthMax = 400;

  static const double scrollbarThickness = 2;

  static const Size autoCountButtonSize = Size(42, 42);
  static const Size memorySlotButtonSize = Size(42, 42);

  ///
  ///
  ///////////////////////
  ///
  /// Paths to show in the file picker
  ///
  ///////////////////////

  static final List<String> filepathsLinux = [
    Platform.environment['HOME'] ?? '/',
  ];

  static final List<String> filepathsWindows = [
    Platform.environment['USERPROFILE'] ?? '/',
  ];

  static const List<String> filepathsAndroid = [
    '/sdcard/',
    '/sdcard/Download',
    '/storage/emulated/0/',
    '/storage/emulated/0/Download',
  ];
}
