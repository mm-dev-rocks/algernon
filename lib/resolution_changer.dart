import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ResolutionChanger {
  static Timer? _lockoutTimer;
  static bool _enabled = true;
  static int _lockoutSecs = ALGERNON.resLoweredLockoutSecs;
  static DirectionOfChange _lastResolutionChange = DirectionOfChange.none;
  // Frame rate we aim for
  static final Duration _fpsAimDuration = const Duration(
    microseconds: ALGERNON.oneMillion ~/ ALGERNON.finalAimFps,
  );
  static final List<bool> _lateFrameMeasurement = List<bool>.generate(
    ALGERNON.droppedFrameMeasurementLength,
    (index) => false,
  );

  static void resetResChangeLockout() {
    //debugPrint('AlgernonPlayer::_resetResChangeLockout()');
    _lastResolutionChange = DirectionOfChange.none;
    _lockoutSecs = ALGERNON.resLoweredLockoutSecs;
    _lockoutTimer?.cancel();
    _enabled = true;
  }

  static void onFrameTimings(List<FrameTiming> timings) {
    if (_enabled) {
      for (final t in timings) {
        final bool isLate = t.rasterDuration > _fpsAimDuration;
        _checkFrameRate(isLate);
      }
    }
  }

  static void _checkFrameRate(bool isLate) {
    /// Roll along
    _lateFrameMeasurement.removeAt(0);
    _lateFrameMeasurement.add(isLate);

    double droppedFrameRatio =
        _lateFrameMeasurement
            .where((bool frameWasLate) => frameWasLate == true)
            .length /
        _lateFrameMeasurement.length;

    if (droppedFrameRatio > 0.95) {
      //debugPrint(droppedFrameRatio.toString());
      _changeResolution(DirectionOfChange.decrease);
    } else if (droppedFrameRatio < 0.005) {
      //debugPrint(droppedFrameRatio.toString());
      _changeResolution(DirectionOfChange.increase);
    }
  }

  static void _changeResolution(DirectionOfChange direction) {
    int lockoutSecs = 0;
    //if (direction != _lastResolutionChange) {
    if (direction == DirectionOfChange.increase) {
      lockoutSecs = ALGERNON.resRaisedLockoutSecs;
      AlgernonPlayer.painterConfig.increaseResolution();
    } else if (direction == DirectionOfChange.decrease) {
      lockoutSecs = _lockoutSecs;

      /// Res has already gone up and then down again, so lockout for longer next time.
      if (_lastResolutionChange == DirectionOfChange.increase) {
        _lockoutSecs *= 2;
      }
      AlgernonPlayer.painterConfig.decreaseResolution();
    }
    //debugPrint(
    //  'SCALE CHANGE: ${AlgernonPlayer.painterConfig.scale.toString()}',
    //);

    for (var i = 0; i < ALGERNON.droppedFrameMeasurementLength; i++) {
      //_lateFrameMeasurement[i] = false;
      // Set alternating true/false to put ratio in the middle
      _lateFrameMeasurement[i] = i.isEven;
    }
    _lastResolutionChange = direction;

    _lockoutResChange(lockoutSecs);
  }

  static void _lockoutResChange(int seconds) {
    //debugPrint('AlgernonPlayer::_lockoutResChange($seconds)');
    _enabled = false;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(Duration(seconds: seconds), () {
      _enabled = true;
    });
  }

  static void dispose() {
    _lockoutTimer?.cancel();
  }
}
