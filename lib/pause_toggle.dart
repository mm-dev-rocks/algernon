// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class PauseToggle extends StatefulWidget {
  const PauseToggle({super.key});

  @override
  State<PauseToggle> createState() => _PauseToggleState();
}

class _PauseToggleState extends State<PauseToggle> {
  StreamSubscription? _soundSubscription;
  //StreamSubscription? _soundSubscription = AlgernonPlayer
  //    .currentSound
  //    .soundEvents
  //    .listen((event) {
  //      switch (event.event) {
  //        case SoundEventType.handleIsNoMoreValid:
  //          // Playback finished for this handle
  //          // event.handle — the specific SoundHandle that ended
  //          // event.sound  — the AudioSource it belongs to
  //          debugPrint('Playback ended for handle ${event.handle}');
  //          break;
  //        case SoundEventType.soundDisposed:
  //          // The AudioSource itself was disposed
  //          break;
  //      }
  //    });

  @override
  void dispose() {
    //_soundSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AlgernonPlayer.currentSoundNotifier,
      builder: (context, child) {
        if (AlgernonPlayer.currentSoundNotifier.source != null) {
          _soundSubscription ??= AlgernonPlayer
              .currentSoundNotifier
              .source!
              .soundEvents
              .listen((event) {
                switch (event.event) {
                  case SoundEventType.handleIsNoMoreValid:
                    // Playback finished for this handle
                    // event.handle — the specific SoundHandle that ended
                    // event.sound  — the AudioSource it belongs to
                    debugPrint('Playback ended for handle ${event.handle}');
                    break;
                  case SoundEventType.soundDisposed:
                    // The AudioSource itself was disposed
                    break;
                }
              });
        }
        debugPrint('PauseToggle::build()');
        return IconButton(
          onPressed: _togglePause,
          icon: Icon(
            (AlgernonPlayer.currentSoundHandle != null &&
                    SoLoud.instance.getPause(
                      AlgernonPlayer.currentSoundHandle!,
                    ))
                ? Icons.play_arrow
                : Icons.pause,
          ),
        );
      },
    );
  }

  void _togglePause() {
    if (AlgernonPlayer.currentSoundHandle != null) {
      SoLoud.instance.pauseSwitch(AlgernonPlayer.currentSoundHandle!);
      setState(() {
        /// Rebuild to update state of the toggle button
      });
    }
  }
}
