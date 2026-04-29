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

  static double mainControlPanelWidth(BuildContext context) =>
      (size(context).width * 0.333).clamp(
        ALGERNON.controlPanelWidthMin,
        ALGERNON.controlPanelWidthMax,
      );

  /// Measurements etc for the UI based on whether the layout is compact or standard.
  static dynamic uiSizesFromContext(BuildContext context) {
    return isCompact(context) ? uiSizesCompact : uiSizesStandard;
  }

  static UiSizes uiSizesCompact = UiSizes(
    //
    paddingExtraSmall: 4,
    paddingSmall: 6,
    paddingMedium: 7,
    paddingLarge: 13,
    paddingExtraLarge: 40,
    //
    customIconSize: 26,
    //
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
  );

  static UiSizes uiSizesStandard = UiSizes(
    //
    paddingExtraSmall: 8,
    paddingSmall: 10,
    paddingMedium: 24,
    paddingLarge: 36,
    paddingExtraLarge: 108,
    //
    customIconSize: 38,
    //
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
  );
}

/// Instances of this class are created by [Screen], with different properties
/// based on eg whether we want a compact or standard layout.
class UiSizes {
  UiSizes({
    required this.paddingExtraSmall,
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.paddingExtraLarge,
    required this.paddingInputText,
    required this.customIconSize,
    required this.buttonStyle,
    required this.floatingActionButtonSize,
    required this.floatingActionButtonBarOverflow,
    required this.elevatedButtonSize,
  });

  final double paddingExtraSmall;
  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;
  final double paddingExtraLarge;

  final Size elevatedButtonSize;

  final Size floatingActionButtonSize;
  final double floatingActionButtonBarOverflow;

  final EdgeInsets paddingInputText;

  final double customIconSize;

  final ButtonStyle buttonStyle;
}
