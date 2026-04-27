// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

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
