import 'package:algernon/algernon_player.dart';
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

  bool get isPaused =>
      (AlgernonPlayer.currentSoundHandle != null &&
          SoLoud.instance.getPause(AlgernonPlayer.currentSoundHandle!))
      ? true
      : false;
  void togglePause() {
    if (AlgernonPlayer.currentSoundHandle != null) {
      SoLoud.instance.pauseSwitch(AlgernonPlayer.currentSoundHandle!);
    }
    debugPrint('AudioSourceNotifier::togglePause: notifying listeners');
    notifyListeners();
  }
}
