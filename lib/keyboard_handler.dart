// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/algernon_window.dart';
import 'package:algernon/algernon_audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardHandler {
  static void init() {
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  static void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      debugPrint(event.logicalKey.toString());
      switch (event.logicalKey.keyLabel) {
        /// Space toggle pause
        case " ":
        case "Media Play Pause":
          AlgernonAudioHandler.instance.togglePause();

        /// Media skip
        case "Media Track Next":
          AlgernonAudioHandler.instance.skipToNext();
        case "Media Track Previous":
          AlgernonAudioHandler.instance.skipToPrevious();

        /// Fullscreen
        case "F11":

          /// TODO Does this fail gracefully on non-mobile OSes?
          AlgernonWindow.toggleFullscreen();

        /// Number keys for memory slots
        case "1":
          AlgernonPlayer.painterConfig.currentMemorySlot = 0;
        case "2":
          AlgernonPlayer.painterConfig.currentMemorySlot = 1;
        case "3":
          AlgernonPlayer.painterConfig.currentMemorySlot = 2;
        case "4":
          AlgernonPlayer.painterConfig.currentMemorySlot = 3;
        case "5":
          AlgernonPlayer.painterConfig.currentMemorySlot = 4;
      }
    }
    // don't consume — let focus/text fields still work normally
    return false;
  }
}
