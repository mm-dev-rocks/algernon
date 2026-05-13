// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_audio_handler.dart';
import 'package:algernon/algernon_icon_button.dart';
import 'package:algernon/algernon_player.dart';
import 'package:flutter/material.dart';

class PauseToggle extends StatefulWidget {
  const PauseToggle({super.key, this.isEnabled = false});

  final bool isEnabled;
  @override
  State<PauseToggle> createState() => _PauseToggleState();
}

class _PauseToggleState extends State<PauseToggle> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AlgernonPlayer.currentSoundNotifier,
      builder: (context, child) {
        return AlgernonIconButton(
          tooltip: AlgernonPlayer.currentSoundNotifier.isPaused
              ? 'Play'
              : 'Pause',
          iconData: AlgernonPlayer.currentSoundNotifier.isPaused
              ? Icons.play_arrow
              : Icons.pause,
          onPressed: widget.isEnabled
              ? () async {
                  await AlgernonAudioHandler.instance.togglePause();
                }
              : null,
        );
      },
    );
  }
}
