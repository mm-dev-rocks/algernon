// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_player.dart';
import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/audio_analysis.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/memory_slot_chooser.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/pause_toggle.dart';
import 'package:algernon/playback_bar.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_chooser.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:algernon/shader_tweak_slider.dart';
import 'package:algernon/volume_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class TrackChooser extends StatefulWidget {
  const TrackChooser({super.key});

  @override
  State<TrackChooser> createState() => _TrackChooserState();

  static String selectedFilePath =
      ALGERNON.audioTrackFilePaths[AppState.getPreference(
        'selectedAudioFilePathIndex',
      )];
}

class _TrackChooserState extends State<TrackChooser> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      width: double.infinity,
      requestFocusOnTap: false,
      initialSelection: TrackChooser.selectedFilePath,
      onSelected: (String? value) async {
        if (value != null) {
          if (AlgernonPlayer.currentSoundHandle != null) {
            await SoLoud.instance.stop(AlgernonPlayer.currentSoundHandle!);
          }
          TrackChooser.selectedFilePath = value;
          AppState.setPreference(
            'selectedAudioFilePathIndex',
            ALGERNON.audioTrackFilePaths.indexOf(TrackChooser.selectedFilePath),
          );
          AlgernonPlayer.initialiseSoundAndPlay();
        }
        //_showControlsThenHideDebounced();
      },
      dropdownMenuEntries: ALGERNON.audioTrackFilePaths
          .map<DropdownMenuEntry<String>>(
            (String filePath) => DropdownMenuEntry<String>(
              value: filePath,
              label: filePath,
              style: MenuItemButton.styleFrom(foregroundColor: Colors.white),
            ),
          )
          .toList(),
    );
  }
}
