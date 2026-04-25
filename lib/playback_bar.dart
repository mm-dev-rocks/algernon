// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, _) {
        return Slider(
          value: _positionInTrackNormalised,
          onChanged: (double value) {
            AppState.debounceVoidFunction(
              callerKey: 'AlgernonPlayer::playheadSeek',
              voidFunction: () {
                _setPlaybackPosFromNormalised(value);
              },
            );
          },
        );
      },
    );
  }

  void _setPlaybackPosFromNormalised(double norm) {
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      int milliseconds =
          (SoLoud.instance
                      .getLength(AlgernonPlayer.currentSoundNotifier.source!)
                      .inMilliseconds *
                  norm)
              .toInt();
      SoLoud.instance.seek(
        AlgernonPlayer.currentSoundHandle!,
        Duration(milliseconds: milliseconds),
      );
    }
  }

  double get _positionInTrackNormalised =>
      (AlgernonPlayer.currentSoundNotifier.source != null &&
          AlgernonPlayer.currentSoundHandle != null)
      ? SoLoud.instance
                .getPosition(AlgernonPlayer.currentSoundHandle!)
                .inMilliseconds /
            SoLoud.instance
                .getLength(AlgernonPlayer.currentSoundNotifier.source!)
                .inMilliseconds
      : 0;
}
