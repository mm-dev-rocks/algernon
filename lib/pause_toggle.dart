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
    return StreamBuilder(
      stream: AlgernonAudioHandler.instance.playbackState,
      builder: (context, child) {
        bool isPlaying =
            AlgernonAudioHandler.instance.playbackState.value.playing;

        return AlgernonIconButton(
          tooltip: isPlaying ? 'Pause' : 'Play',
          iconData: isPlaying ? Icons.pause : Icons.play_arrow,
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
