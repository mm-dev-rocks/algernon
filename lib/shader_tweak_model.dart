// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';

/// Each shader in the app should have a respective [ShaderModel].
/// Sets up some config defaults and provides a place to store user settings.
class ShaderTweakModel {
  ShaderTweakModel({
    required this.shaderId,
    required this.tweakType,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.defaultValue = 0.75,

    /// [isEnergyUniform] denotes that this is a special tweak that can be overriden by an 'auto' button next to the
    /// slider which will set the value based on the 'energy' of the current point in the audio track.
    this.isEnergyUniform = false,
  }) {
    /// A quirk of [AppState.getPreference] and [AppState.setPreference] is that they fail if any 'preference key'
    /// doesn't exist in [ALGERNON.defaultPreferences]. Apart from that they work well for our needs (saving tweaks to
    /// persistent storage) so we hack a little here by adding the key based on our _prefId if it doesn't already
    /// exist. Normally things like this would be set in the constants file but there are too many of these and
    /// shaders/tweaks are likely to increase in number over the lifetime of the app.
    /// We must do this for each memory slot.
    for (
      int slotIndex = 0;
      slotIndex < ALGERNON.totalMemorySlots;
      slotIndex++
    ) {
      String preferenceId = _prefIdFromMemSlotIndex(slotIndex);
      if (!ALGERNON.defaultPreferences.containsKey(preferenceId)) {
        ALGERNON.defaultPreferences[preferenceId] = [double, defaultValue];
      }
      String useEnergyDerivedCountId =
          '${_prefIdFromMemSlotIndex(slotIndex)}-${ALGERNON.autoCountPrefSuffix}';
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
  double get storedValue => AppState.getPreference(_prefId);
  set storedValue(double value) {
    // Clamp to cover cases where min/max for this tweak changes eg during dev and stored value might be outside limits.
    AppState.setPreference(_prefId, value.clamp(min, max));
  }

  /// [_useEnergyDerivedCount] decided whether to use energy from the audio track for any special count variables in the
  /// shader.
  bool get useEnergyDerivedCount =>
      AppState.getPreference(_useEnergyDerivedCountId);
  set useEnergyDerivedCount(bool value) {
    AppState.setPreference(_useEnergyDerivedCountId, value);
  }

  String get _useEnergyDerivedCountId =>
      '$_prefId-${ALGERNON.autoCountPrefSuffix}';

  String get _prefId => _prefIdFromMemSlotIndex(
    AppState.getPreference('selectedMemorySlotIndex'),
  );

  /// Canon function for deriving full name of this tweak, including current memory slot, shader id and tweak type.
  String _prefIdFromMemSlotIndex(int slotIndex) =>
      "${ALGERNON.memorySlotPrefPrefix}$slotIndex-$shaderId-${tweakType.name}";

  @override
  String toString() {
    return 'shaderId:  $shaderId, tweakType:  $tweakType, min:  $min, max:  $max, divisions:  $divisions, defaultValue:  $defaultValue, isEnergyUniform:  $isEnergyUniform';
  }
}
