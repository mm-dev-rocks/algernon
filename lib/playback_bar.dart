// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_audio_handler.dart';
import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:algernon/utils.dart';

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, _) {
        return Row(
          children: [
            Flexible(
              flex: 1,
              child: Slider(
                value: _positionInTrackNormalised,
                onChanged: (double value) {
                  AppState.debounceVoidFunction(
                    callerKey: 'AlgernonPlayer::playheadSeek',
                    voidFunction: () {
                      _setPlaybackPosFromNormalised(value);
                    },
                  );
                },
              ),
            ),
            Text(
              _positionTimeString,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
      AlgernonAudioHandler.instance.seek(Duration(milliseconds: milliseconds));
    }
  }

  String get _positionTimeString {
    String str = '00:00';
    try {
      if (AlgernonPlayer.currentSoundHandle != null) {
        str = durationToMinutesAndSeconds(
          SoLoud.instance.getPosition(AlgernonPlayer.currentSoundHandle!),
        );
      }
    } catch (e) {
      debugPrint('PlaybackBar::_positionTimeString: $e');
    }

    return str;
  }

  double get _positionInTrackNormalised {
    //debugPrint('PlaybackBar::_positionInTrackNormalised()');
    int position = AlgernonPlayer.currentSoundHandle != null
        ? SoLoud.instance
              .getPosition(AlgernonPlayer.currentSoundHandle!)
              .inMilliseconds
        : 0;
    //debugPrint('\tposition: $position');
    int length = AlgernonPlayer.currentSoundNotifier.source != null
        ? SoLoud.instance
              .getLength(AlgernonPlayer.currentSoundNotifier.source!)
              .inMilliseconds
        : 1;
    //debugPrint('\tlength: $length');
    //debugPrint('\t(position / length): ${(position / length)}');

    return (position == 0 && length == 0) ? 0 : position / length;
  }
}
