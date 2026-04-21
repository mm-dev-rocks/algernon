// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';

/// Each shader in the app should have a respective [ShaderMetaModel].
/// Sets up some config defaults and provides a place to store user settings.
class ShaderTweakModel {
  ShaderTweakModel({
    required this.shaderId,
    required this.tweakType,
    this.min = 0,
    this.max = 1,
    this.defaultVal = 0.75,
    this.divisions,
  }) {
    /// A quirk of [AppState.getPreference] and [AppState.setPreference] is that they fail if any 'preference key'
    /// doesn't exist in [ALGERNON.defaultPreferences]. Apart from that they work well for our needs (saving tweaks to
    /// persistent storage) so we hack a little here by adding the key based on our _preferenceId if it doesn't already
    /// exist. Normally things like this would be set in the constants file but there are too many of these and
    /// shaders/tweaks are likely to increase in number over the lifetime of the app.
    /// We must do this for each memory slot.
    for (int i = 0; i < ALGERNON.totalMemorySlots; i++) {
      String preferenceId = _preferenceIdFromMemorySlotIndex(i);
      if (!ALGERNON.defaultPreferences.containsKey(preferenceId)) {
        ALGERNON.defaultPreferences[preferenceId] = [double, defaultVal];
      }
    }
  }

  final String shaderId;
  final TweakType tweakType;
  final double min;
  final double max;
  final int? divisions;
  final double defaultVal;

  /// [_currentVal] is stored as a preference so the app remembers settings.
  double get currentVal => AppState.getPreference(_preferenceId);
  set currentVal(double value) {
    AppState.setPreference(_preferenceId, value);
  }

  String get _preferenceId => _preferenceIdFromMemorySlotIndex(
    AppState.getPreference('selectedMemorySlotIndex'),
  );

  /// Canon function for deriving full name of this tweak, including current memory slot, shader id and tweak type.
  String _preferenceIdFromMemorySlotIndex(int index) =>
      "m${index}-$shaderId-${tweakType.name}";
}
