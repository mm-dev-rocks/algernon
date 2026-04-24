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
    this.divisions,
    this.defaultValue = 0.75,
    this.isEnergyUniform = false,
  }) {
    /// A quirk of [AppState.getPreference] and [AppState.setPreference] is that they fail if any 'preference key'
    /// doesn't exist in [ALGERNON.defaultPreferences]. Apart from that they work well for our needs (saving tweaks to
    /// persistent storage) so we hack a little here by adding the key based on our _preferenceId if it doesn't already
    /// exist. Normally things like this would be set in the constants file but there are too many of these and
    /// shaders/tweaks are likely to increase in number over the lifetime of the app.
    /// We must do this for each memory slot.
    for (
      int slotIndex = 0;
      slotIndex < ALGERNON.totalMemorySlots;
      slotIndex++
    ) {
      String preferenceId = _preferenceIdFromMemorySlotIndex(slotIndex);
      if (!ALGERNON.defaultPreferences.containsKey(preferenceId)) {
        ALGERNON.defaultPreferences[preferenceId] = [double, defaultValue];
      }
      String useEnergyDerivedCountId =
          '${_preferenceIdFromMemorySlotIndex(slotIndex)}-useEnergyDerivedCount';
      if (!ALGERNON.defaultPreferences.containsKey(useEnergyDerivedCountId)) {
        ALGERNON.defaultPreferences[useEnergyDerivedCountId] = [bool, false];
      }
    }
  }

  final String shaderId;
  final TweakType tweakType;
  final double min;
  final double max;
  final int? divisions;
  final double defaultValue;
  final bool isEnergyUniform;

  /// [_storedValue] is stored as a preference so the app remembers settings.
  double get storedValue => AppState.getPreference(_preferenceId);
  set storedValue(double value) {
    AppState.setPreference(_preferenceId, value);
  }

  /// [_useEnergyDerivedCount] decided whether to use energy from the audio track for any special count variables in the
  /// shader.
  bool get useEnergyDerivedCount =>
      AppState.getPreference(_useEnergyDerivedCountId);
  set useEnergyDerivedCount(bool value) {
    AppState.setPreference(_useEnergyDerivedCountId, value);
  }

  String get _useEnergyDerivedCountId => '$_preferenceId-useEnergyDerivedCount';

  String get _preferenceId => _preferenceIdFromMemorySlotIndex(
    AppState.getPreference('selectedMemorySlotIndex'),
  );

  /// Canon function for deriving full name of this tweak, including current memory slot, shader id and tweak type.
  String _preferenceIdFromMemorySlotIndex(int slotIndex) =>
      "m$slotIndex-$shaderId-${tweakType.name}";
}
