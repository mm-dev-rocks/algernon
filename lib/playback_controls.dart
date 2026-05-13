// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_audio_handler.dart';
import 'package:algernon/algernon_icon_button.dart';
import 'package:algernon/algernon_player.dart';
import 'package:algernon/loop_cycle_button.dart';
import 'package:algernon/pause_toggle.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AlgernonPlayer.playbackControlsEnabledNotifier,
      builder: (context, value, child) {
        bool isEnabled = value;
        return Row(
          children: [
            PauseToggle(isEnabled: isEnabled),
            AlgernonIconButton(
              tooltip: 'Skip PREVIOUS',
              iconData: Icons.skip_previous,
              onPressed: isEnabled
                  ? () async {
                      await AlgernonAudioHandler.instance.skipToPrevious();
                      UserInterface.keepControlsAlive();
                    }
                  : null,
            ),
            AlgernonIconButton(
              tooltip: 'Skip NEXT',
              iconData: Icons.skip_next,
              onPressed: isEnabled
                  ? () async {
                      await AlgernonAudioHandler.instance.skipToNext();
                      UserInterface.keepControlsAlive();
                    }
                  : null,
            ),
            const LoopCycleButton(),
          ],
        );
      },
    );
  }
}
