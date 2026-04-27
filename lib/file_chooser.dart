// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatefulWidget {
  const FileChooser({super.key});

  static List<String> get currentPlaylist => AppState.getPreference('playlist');
  static set currentPlaylist(List<String> newPlaylist) {
    AppState.setPreference('playlist', newPlaylist);
  }

  static int get selectedFilePathIndex =>
      AppState.getPreference('selectedPlaylistFilePathIndex');
  static set selectedFilePathIndex(int index) =>
      AppState.setPreference('selectedPlaylistFilePathIndex', index);

  static String get selectedFilePath => currentPlaylist[selectedFilePathIndex];

  static void selectNextTrack() {
    debugPrint('FileChooser::selectNextTrack()');
    debugPrint('\tselectedFilePathIndex: $selectedFilePathIndex');
    int nextTrackIndex = selectedFilePathIndex + 1;
    if (nextTrackIndex == currentPlaylist.length) {
      nextTrackIndex = 0;
    }
    selectedFilePathIndex = nextTrackIndex;
    debugPrint('\tselectedFilePathIndex: $selectedFilePathIndex');
  }

  @override
  State<FileChooser> createState() => _FileChooserState();
}

class _FileChooserState extends State<FileChooser> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      width: double.infinity,
      requestFocusOnTap: false,
      initialSelection: FileChooser.selectedFilePathIndex,
      onSelected: (int? value) async {
        debugPrint('FileChooser::onSelected($value)');
        if (value != null) {
          //await AlgernonPlayer.stopAllSounds();
          FileChooser.selectedFilePathIndex = value;
          await AlgernonPlayer.playSelectedSound(
            reason: 'FileChooser::onSelected($value)',
          );
        }
        UserInterface.keepControlsAlive();
      },
      dropdownMenuEntries: FileChooser.currentPlaylist
          .asMap()
          .entries
          .map<DropdownMenuEntry<int>>(
            (MapEntry entry) => DropdownMenuEntry<int>(
              value: entry.key,
              //label: entry.key.toString(),
              label: FileChooser.currentPlaylist[entry.key],
              style: MenuItemButton.styleFrom(foregroundColor: Colors.white),
            ),
          )
          .toList(),
    );
  }
}
