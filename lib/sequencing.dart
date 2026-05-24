// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/sequenced_shader_model.dart';
import 'package:algernon/sequences.dart';
import 'package:algernon/shader_model.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'constants.dart';

class Sequencing {
  static Timer? _timer;

  static const _updatePeriodMs = 200;

  static void startListening() {
    debugPrint("Sequencing::startListening()");
    if (AlgernonPlayer.playlistNotifier.currentTrackHasSequencing) {
      debugPrint("- Track has sequencing");
      _currentList.clear();
      _currentList.addAll(
        SEQUENCES.list[AlgernonPlayer.playlistNotifier.currentSequencingId]!,
      );
      _timer = Timer.periodic(
        Duration(milliseconds: _updatePeriodMs),
        Sequencing._ensureCorrectShader,
      );
      UserInterface.hideControls();
    } else {
      debugPrint("- Track has no sequencing");
    }
  }

  static void stopListening() {
    _timer?.cancel();
  }

  static final List<SequencedShaderModel> _currentList =
      <SequencedShaderModel>[];

  static void _ensureCorrectShader(Timer _) {
    if (AppState.getPreference('useShaderSequenceWhereAvailable')) {
      Duration position = Duration(
        milliseconds: AlgernonPlayer.currentSoundHandle != null
            ? SoLoud.instance
                  .getPosition(AlgernonPlayer.currentSoundHandle!)
                  .inMilliseconds
            : 0,
      );

      SequencedShaderModel sequencedShader = _currentList.lastWhere(
        (SequencedShaderModel shader) => position >= shader.timestamp,
      );

      if (AlgernonPlayer.painterConfig.currentShader.id !=
          sequencedShader.shaderModelId) {
        debugPrint(
          "Sequencing:: Starting intended shader: ${sequencedShader.shaderModelId}",
        );
        AlgernonPlayer.painterConfig.currentShader = ALGERNON.shadersData
            .firstWhere(
              (ShaderModel shader) =>
                  shader.id == sequencedShader.shaderModelId,
            );
      }

      if (AlgernonPlayer.painterConfig.currentMemorySlot !=
          sequencedShader.memorySlotIndex) {
        debugPrint(
          "Sequencing:: Selecting intended memory slot: ${sequencedShader.memorySlotIndex}",
        );
        AlgernonPlayer.painterConfig.currentMemorySlot =
            sequencedShader.memorySlotIndex;
      }
    }
  }
}
