// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_icon_button.dart';
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
        return AlgernonIconButton(
          onPressed: AlgernonPlayer.currentSoundNotifier.cycleLoopType,
          tooltip: switch (AlgernonPlayer.currentSoundNotifier.loopType) {
            LoopType.none => 'Loop NONE',
            LoopType.all => 'Loop ALL',
            LoopType.one => 'Loop ONE',
          },
          iconData: switch (AlgernonPlayer.currentSoundNotifier.loopType) {
            LoopType.none => Icons.repeat,
            LoopType.all => Icons.repeat,
            LoopType.one => Icons.repeat_one,
          },
          color: switch (AlgernonPlayer.currentSoundNotifier.loopType) {
            LoopType.none => ALGERNON.uiDefaultForegroundColor,
            LoopType.all => ALGERNON.uiStrongForegroundColor,
            LoopType.one => ALGERNON.uiStrongForegroundColor,
          },
        );
      },
    );
  }
}
