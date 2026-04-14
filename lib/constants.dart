// SPDX-License-Identifier: GPL-3.0-only

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Lots of constants related to the app:
/// - UI (eg colours, sizes)
/// - Defaults for user preferences
/// - Important file paths
/// - Some NewPipe-specific info relating to the database, such as table names
class ALGERNON {
  static const String appName = 'Algernon - Audio Visualiser';
  static const String androidNotificationChannelId =
      'rocks.mm_dev.algernon.channel';
  //static const FlexScheme appColorScheme = FlexScheme.jungle;

  /// Route / page names
  static const String routeRoot = '/';
  static const String routePreferences = 'preferences';

  /// Default user settings [type, value]
  /// Type can be String, bool, int or double
  /// All preferences must have a default defined here
  /// Some of these (eg 'expandChapterMetadata', 'debugPanelIsOpen') don't
  /// appear on the settings page but are used to remember in-app preferences.
  static final Map<String, dynamic> defaultPreferences = {
    /// Debugging
    'enableDebugPanel': [bool, false],
    'debugPanelIsOpen': [bool, false],
    'showExtraDebugInfo': [bool, false],

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

    'playbackSpeedIndex': [int, 1],
    'usePitchCompensation': [bool, false],
  };

  static const int finalAimFps = 30;
  static final Map<String, String> shaderAssetKeys = {
    'Rose Tunnel': 'shaders/algernon_rose_tunnel_quadrant.frag',
    'Blocks Spiral': 'shaders/algernon_blocks_spiral.frag',
    'Blocks Simple': 'shaders/algernon_blocks_simple.frag',
    'Oscilloscope Columns': 'shaders/algernon_oscilloscope_columns.frag',
    'Rings Radial': 'shaders/algernon_rings_radial.frag',
    'Warp Kaleido': 'shaders/algernon_warp_kaleido.frag',
  };
  static final Map<String, FilterQuality> shaderFilterQualities = {
    'None': FilterQuality.none,
    'Low': FilterQuality.low,
    'Medium': FilterQuality.medium,
    'High': FilterQuality.high,
  };

  static const double sliderTrackHeight = 3;
  static const SliderTrackShape sliderTrackShape =
      RectangularSliderTrackShape();
  static const double scrollbarThickness = 6;
  static const double brightnessRadioButtonBorderThickness = 2;
  static const double brightnessChooserWidthCompact = 160;

  static const double playbackIndicatorDotDiameter = 2;
  static const double playbackIndicatorDotBorderWidth = 2;

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

  static const double scrollBottomBufferStandard = 150;
  static const double scrollBottomBufferCompact = 75;

  ///
  ///
  ///////////////////////
  ///
  /// UI / Layout
  ///
  ///////////////////////

  /// Important bars / rows
  static const double bufferingBarHeight = 3;
  static const double playerControlsButtonTopPadding = 2;

  static const double scrollWheelSideScrollScale = 0.2;

  ///
  ///
  ///////////////////////
  ///
  /// Webdav / Server-related
  ///
  ///////////////////////

  static String appDataDirectory = ".algernon_audiobook_listener";
  static String jsonFilename = "library.json";
  static String readmeFilename = "README.md";
  static String bookmarksFilename = "bookmarks-and-faves.json";
  static String historyFilename = "history.json";
  static String booksProgressDirectory = "progress";

  /// Local
  static String localCacheDirectoryBookCoverImages = "book-covers";
  static String localCacheDirectoryBookInfoText = "book-info-text";

  // Used to split/join lists of filenames
  // Needs to be a character which is illegal in filenames on all OSes (so it
  // won't be encountered in a filename), and short so that it doesn't add too
  // much bulk to the JSON
  static String safeJsonFilenameListSeperator = "/";
  //static Map<String, dynamic> headerCharsetUtf8 = {'accept-charset': 'utf-8'};
  static String dateFormat = 'yyyy-MM-dd HH:mm:ss';

  /// How often to auto-save book progress
  static const int bookSaveProgressTimeoutMillisecs = 15000;
  static const int playbackInfoRevertTimeoutMillisecs = 10000;
  static const int webdavAttemptLoginDelayMillisecs = 3000;

  static const double webdavTryUpdatedLoginDetailsTimeoutIncrease = 1.5;

  /// MIME types which are used for cue sheets
  //static final List<String> cueSheetMimeTypes = [
  //  'application/octet-stream',
  //];

  /// MIME types which are probably an entire book
  //static final List<String> bookMimeTypes = [
  //  //'audio/m4b',
  //];

  /// MIME types which are probably seperate chapters (or could be an entire book)
  static final List<String> bookOrChapterMimeTypes = [
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'audio/m4b',
  ];

  /// MIME types which are probably cover images
  static final List<String> coverImageMimeTypes = ['image/jpeg', 'image/png'];

  /// MIME types which are probably supplementary info files for a book
  static final List<String> addedInfoFileExtensions = ['.txt', '.nfo'];

  /// MIME types which are probably supplementary info files for a book
  static final List<String> cueSheetFileExtensions = ['.cue'];

  static const Function hhh = FlexTones.candyPop;

  //FlexScheme dd = FlexScheme.yellowM3

  /// The key is the name as presented in the UI, ['flexSchemeName'] is the name of a scheme as per
  /// the [FlexScheme] enum.
  /// ONE OF ['flexTonesFunction'] or ['flexSchemeVariant'] may be present, but not both (if both
  /// are present there will be an error).
  static const Map<String, Map<String, dynamic>> themeColorOptions = {
    /// E-Ink
    'E-ink': {'isSeparator': true, 'hidePadding': true},
    'Mono': {
      'flexSchemeName': 'rosewood',
      'flexSchemeVariant': FlexSchemeVariant.monochrome,
      'isEink': true,
    },

    /// Soft
    'Soft': {'isSeparator': true},
    'Soft pink': {
      'flexSchemeName': 'pinkM3',
      'flexTonesFunction': FlexTones.soft,
    },
    'Coffee cream': {
      'flexSchemeName': 'espresso',
      'flexTonesFunction': FlexTones.soft,
    },
    'Acorn': {'flexSchemeName': 'orangeM3'},
    'Verdun Hemlock': {'flexSchemeName': 'verdunHemlock'},
    'Money': {'flexSchemeName': 'money'},
    'Ebony Clay (soft)': {
      'flexSchemeName': 'ebonyClay',
      'flexTonesFunction': FlexTones.soft,
    },
    'Shark': {'flexSchemeName': 'shark'},
    'Outer Space (soft)': {
      'flexSchemeName': 'outerSpace',
      'flexTonesFunction': FlexTones.soft,
    },
    'Purple': {'flexSchemeName': 'purpleM3'},
    'Deep Purple': {'flexSchemeName': 'deepPurple'},

    /// Pop
    'Pop': {'isSeparator': true},
    'Pink (pop)': {
      'flexSchemeName': 'pinkM3',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Barossa (pop)': {
      'flexSchemeName': 'barossa',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Espresso (pop)': {
      'flexSchemeName': 'espresso',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Choc Lime': {
      'flexSchemeName': 'orangeM3',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Hemlock': {
      'flexSchemeName': 'verdunHemlock',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Minted': {
      'flexSchemeName': 'money',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Outer Space (pop)': {
      'flexSchemeName': 'outerSpace',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Shark (pop)': {
      'flexSchemeName': 'shark',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Deep Purple (pop)': {
      'flexSchemeName': 'deepPurple',
      'flexTonesFunction': FlexTones.candyPop,
    },
    'Purple (pop)': {
      'flexSchemeName': 'purpleM3',
      'flexTonesFunction': FlexTones.candyPop,
    },
  };
}
