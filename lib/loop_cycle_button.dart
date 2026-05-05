// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:flutter/material.dart';

class LoopCycleButton extends StatefulWidget {
  const LoopCycleButton({super.key});

  @override
  State<LoopCycleButton> createState() => _LoopCycleButtonState();
}

class _LoopCycleButtonState extends State<LoopCycleButton> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AlgernonPlayer.currentSoundNotifier,
      builder: (context, child) {
        return IconButton(
          onPressed: AlgernonPlayer.currentSoundNotifier.cycleLoopType,
          icon: switch (AlgernonPlayer.currentSoundNotifier.loopType) {
            LoopType.none => Icon(
              Icons.repeat,
              color: ALGERNON.uiDefaultForegroundColor,
            ),

            /// Default colour is white (brighter than [uiDefaultForegroundColor]) so states below indicate 'on'.
            LoopType.all => Icon(Icons.repeat),
            LoopType.one => Icon(Icons.repeat_one),
          },
        );
      },
    );
  }
}
