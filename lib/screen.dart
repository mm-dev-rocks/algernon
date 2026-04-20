// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

import 'constants.dart';

/// Helper class for getting display size.
class Screen {
  static Size size(BuildContext context) => MediaQuery.of(context).size;

  /// Usable width and height can be reduced by a device cutout, in which case [SafeArea] will
  /// let us work out the difference via [View.of(context).padding].
  /// NB Although cutouts will usually be at the top of the screen (eg affecting height in portrait
  /// mode), the 'top' can become left or right when the device is rotated. So we need to consider
  /// width as well as height.
  static double width(BuildContext context) =>
      size(context).width -
      View.of(context).padding.left -
      View.of(context).padding.right;

  static double height(BuildContext context) =>
      size(context).height -
      View.of(context).padding.top -
      View.of(context).padding.bottom;

  /// Return whether this is a portrait display or not, otherwise must be landscape.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).size.width <
        MediaQuery.of(context).size.height;
  }

  /// Return whether this is a small/compact display or not.
  static bool isTiny(BuildContext context) {
    return MediaQuery.of(context).size.width < ALGERNON.breakpointTiny;
  }

  /// Return whether this is a small/compact display or not.
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < ALGERNON.breakpointCompact;
  }

  /// Measurements etc for the UI based on whether the layout is compact or standard.
  static uiSizesFromContext(BuildContext context) {
    return isCompact(context) ? uiSizesCompact : uiSizesStandard;
  }

  static UiSizes uiSizesCompact = UiSizes(
    smallDurationLetterSpacing: 2.8,
    progressBarSpacing: 3,
    //
    paddingExtraSmall: 4,
    paddingSmall: 6,
    paddingMedium: 7,
    paddingLarge: 13,
    paddingExtraLarge: 40,
    //
    customIconSize: 26,
    //
    quickChooserControlTopRowHeight: 69,
    quickChooserControlBottomRowHeight: 41,
    buttonStyle: ElevatedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(1),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    elevatedButtonSize: const Size(64, 36),
    floatingActionButtonSize: const Size(40, 48),
    floatingActionButtonBarOverflow: 2,
    paddingInputText: const EdgeInsets.only(
      top: 6,
      right: 8,
      bottom: 8,
      left: 8,
    ),
    dialogInsets: const EdgeInsets.all(50),
    chapterProgressTextStyle: const TextStyle(
      fontFamily: 'FixedWidthNumbers',
      fontSize: 13,
    ),
    chapterDurationTextStyle: const TextStyle(
      fontFamily: 'FixedWidthNumbers',
      fontSize: 13,
    ),
    preferenceItem: const {
      'between': 19.0,
      'sectionGap': 38.0,
      'outerPadding': EdgeInsets.only(),
      'titlePadding': EdgeInsets.only(),
      'descriptionPadding': EdgeInsets.only(top: 6),
    },
    deleteIconButtonIconSize: 18,
    brightnessChooserIconSize: 12,
    themeColorChipSize: const Size(25, 25),
    bookItemDetailedThumbWidth: 100,
    fontSizeChapterNumber: 12,
    fontHeightChapterNumber: 1.3,
  );

  static UiSizes uiSizesStandard = UiSizes(
    smallDurationLetterSpacing: 1.5,
    progressBarSpacing: 5,
    //
    paddingExtraSmall: 8,
    paddingSmall: 10,
    paddingMedium: 24,
    paddingLarge: 36,
    paddingExtraLarge: 108,
    //
    customIconSize: 38,
    //
    quickChooserControlTopRowHeight: 85,
    quickChooserControlBottomRowHeight: 50,
    buttonStyle: ElevatedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    floatingActionButtonSize: const Size(56, 56),
    elevatedButtonSize: const Size(64, 40),
    floatingActionButtonBarOverflow: 3,
    paddingInputText: const EdgeInsets.only(
      top: 8,
      right: 10,
      bottom: 10,
      left: 10,
    ),
    dialogInsets: const EdgeInsets.all(100),
    chapterProgressTextStyle: const TextStyle(
      fontFamily: 'FixedWidthNumbers',
      fontSize: 13,
    ),
    chapterDurationTextStyle: const TextStyle(
      fontFamily: 'FixedWidthNumbers',
      fontSize: 13,
    ),
    preferenceItem: const {
      'between': 50.0,
      'sectionGap': 100.0,
      'outerPadding': EdgeInsets.only(),
      'titlePadding': EdgeInsets.only(),
      'descriptionPadding': EdgeInsets.only(top: 10),
    },
    deleteIconButtonIconSize: 18,
    brightnessChooserIconSize: 18,
    themeColorChipSize: const Size(30, 30),
    bookItemDetailedThumbWidth: 150,
    fontSizeChapterNumber: 13,
    fontHeightChapterNumber: 1.25,
  );
}

/// Instances of this class are created by [Screen], with different properties
/// based on eg whether we want a compact or standard layout.
class UiSizes {
  UiSizes({
    required this.smallDurationLetterSpacing,
    required this.paddingExtraSmall,
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.paddingExtraLarge,
    required this.paddingInputText,
    required this.progressBarSpacing,
    required this.customIconSize,
    required this.quickChooserControlTopRowHeight,
    required this.quickChooserControlBottomRowHeight,
    required this.buttonStyle,
    required this.chapterProgressTextStyle,
    required this.dialogInsets,
    required this.chapterDurationTextStyle,
    required this.preferenceItem,
    required this.deleteIconButtonIconSize,
    required this.brightnessChooserIconSize,
    required this.themeColorChipSize,
    required this.bookItemDetailedThumbWidth,
    required this.floatingActionButtonSize,
    required this.floatingActionButtonBarOverflow,
    required this.elevatedButtonSize,
    required this.fontSizeChapterNumber,
    required this.fontHeightChapterNumber,
  });

  final double fontSizeChapterNumber;
  final double fontHeightChapterNumber;
  final double smallDurationLetterSpacing;

  final double progressBarSpacing;
  final double paddingExtraSmall;
  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;
  final double paddingExtraLarge;

  final Size elevatedButtonSize;

  final Size floatingActionButtonSize;
  final double floatingActionButtonBarOverflow;

  final EdgeInsets dialogInsets;
  final EdgeInsets paddingInputText;

  final double customIconSize;

  final double quickChooserControlTopRowHeight;
  final double quickChooserControlBottomRowHeight;
  final ButtonStyle buttonStyle;
  final TextStyle chapterProgressTextStyle;
  final TextStyle chapterDurationTextStyle;
  final Map preferenceItem;

  final double deleteIconButtonIconSize;
  final double brightnessChooserIconSize;
  final Size themeColorChipSize;
  final double bookItemDetailedThumbWidth;
}
