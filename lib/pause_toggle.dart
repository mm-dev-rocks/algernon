// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:flutter/material.dart';

class PauseToggle extends StatefulWidget {
  const PauseToggle({super.key});

  @override
  State<PauseToggle> createState() => _PauseToggleState();
}

class _PauseToggleState extends State<PauseToggle> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AlgernonPlayer.currentSoundNotifier,
      builder: (context, child) {
        return IconButton(
          onPressed: AlgernonPlayer.currentSoundNotifier.togglePause,
          icon: Icon(
            AlgernonPlayer.currentSoundNotifier.isPaused
                ? Icons.play_arrow
                : Icons.pause,
          ),
        );
      },
    );
  }
}
