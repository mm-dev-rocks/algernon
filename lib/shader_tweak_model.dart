// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';

/// Each shader in the app should have a respective [ShaderMetaModel].
/// Sets up some config defaults and provides a place to store user settings.
class ShaderTweakModel {
  ShaderTweakModel({
    required this.id,
    required this.tweakType,
    this.min = 0,
    this.max = 1,
    this.divisions = 100,
    this.defaultVal = 0.75,
  }) {
    /// A quirk of [AppState.getPreference] and [AppState.setPreference] is that they fail if any 'preference key'
    /// doesn't exist in [ALGERNON.defaultPreferences]. Apart from that they work well for our needs (saving tweaks to
    /// persistent storage) so we hack a little here by adding the key based on our id.
    if (!ALGERNON.defaultPreferences.containsKey(id)) {
      ALGERNON.defaultPreferences[id] = [double, defaultVal];
    }
  }

  final String id;
  final TweakType tweakType;
  final double min;
  final double max;
  final int divisions;
  final double defaultVal;

  /// [_currentVal] is stored as a preference so the app remembers settings.
  double get currentVal => AppState.getPreference(id);
  set currentVal(double value) {
    AppState.setPreference(id, value);
  }
}
