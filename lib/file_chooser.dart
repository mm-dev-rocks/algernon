// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
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

  static String get selectedFilePath {
    /// Protect against scenario:
    /// Last item in playlist was deleted from list while still playing. Then app was closed, leaving
    /// [selectedFilePathIndex] pointing to a non-existing item.
    int lastFilePathIndex = currentPlaylist.length - 1;
    if (selectedFilePathIndex > lastFilePathIndex) {
      debugPrint("FileChooser::selectedFilePath");
      debugPrint(
        "\tItem [$selectedFilePathIndex] chosen but last item in list is [$lastFilePathIndex] --- fixing!",
      );
      selectedFilePathIndex = lastFilePathIndex;
    }
    return currentPlaylist[selectedFilePathIndex];
  }

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

  static void removeTrackByIndex(int index) {
    List<String> tracks = List.of(currentPlaylist);
    tracks.removeAt(index);
    currentPlaylist = tracks;
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
      menuHeight: Screen.height(context) * 0.66,
      onSelected: (int? value) async {
        debugPrint('FileChooser::onSelected($value)');
        if (value != null) {
          FileChooser.selectedFilePathIndex = value;
          await AlgernonPlayer.playSelectedSound(
            reason: 'FileChooser::onSelected($value)',
          );
        }
        UserInterface.keepControlsAlive();
        setState(() {
          /// Update selection colours etc
        });
      },
      dropdownMenuEntries: FileChooser.currentPlaylist
          .asMap()
          .entries
          .map<DropdownMenuEntry<int>>(
            (MapEntry entry) => DropdownMenuEntry<int>(
              value: entry.key,
              label: FileChooser.currentPlaylist[entry.key].split('/').last,
              style: MenuItemButton.styleFrom(
                foregroundColor: entry.key == FileChooser.selectedFilePathIndex
                    ? Colors.white
                    : ALGERNON.uiDefaultForegroundColor,
              ),
              trailingIcon: IconButton(
                icon: Icon(Icons.playlist_remove),
                onPressed: () {
                  FileChooser.removeTrackByIndex(entry.key);
                  setState(() {
                    /// Update list to make removal visible
                  });
                },
              ),
            ),
          )
          .toList(),
    );
  }
}
