import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioSourceNotifier extends ChangeNotifier {
  AudioSource? _source;

  AudioSource? get source => _source;
  set source(AudioSource? source) {
    _source = source;
    debugPrint('AudioSourceNotifier::source : notifying listeners');
    notifyListeners();
  }

  /// Paused state
  bool get isPaused =>
      source == null ||
          AlgernonPlayer.currentSoundHandle == null ||
          (AlgernonPlayer.currentSoundHandle != null &&
              SoLoud.instance.getPause(AlgernonPlayer.currentSoundHandle!))
      ? true
      : false;

  /// Toggle pause, unless [forceState] is non-null, in which case [true] pauses, [false] unpauses.
  void togglePause({bool? forcedState}) {
    if (AlgernonPlayer.currentSoundHandle != null) {
      if (forcedState != null) {
        SoLoud.instance.setPause(
          AlgernonPlayer.currentSoundHandle!,
          forcedState,
        );
      } else {
        SoLoud.instance.pauseSwitch(AlgernonPlayer.currentSoundHandle!);
      }
    }
    debugPrint('AudioSourceNotifier::togglePause: notifying listeners');
    notifyListeners();
  }

  /// Type of looping playback
  LoopType get loopType =>
      LoopType.values[AppState.getPreference('loopTypeIndex')];
  void cycleLoopType() {
    int index = AppState.getPreference('loopTypeIndex');
    index++;
    if (index == LoopType.values.length) {
      index = 0;
    }
    AppState.setPreference('loopTypeIndex', index);

    debugPrint('AudioSourceNotifier::cycleLoopType: notifying listeners');
    notifyListeners();
  }
}
