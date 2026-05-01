// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/file_chooser_notifier.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatefulWidget {
  const FileChooser({super.key});

  static FileChooserNotifier notifier = FileChooserNotifier();

  static void selectPrev() {
    debugPrint('FileChooser::selectPrev()');
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.notifier.selectedFilePathIndex}',
    );
    int nextTrackIndex = FileChooser.notifier.selectedFilePathIndex - 1;
    if (nextTrackIndex == -1) {
      nextTrackIndex = FileChooser.notifier.currentPlaylist.length - 1;
    }
    FileChooser.notifier.selectedFilePathIndex = nextTrackIndex;
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.notifier.selectedFilePathIndex}',
    );
  }

  static void selectNext() {
    debugPrint('FileChooser::selectNext()');
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.notifier.selectedFilePathIndex}',
    );
    int nextTrackIndex = FileChooser.notifier.selectedFilePathIndex + 1;
    if (nextTrackIndex == FileChooser.notifier.currentPlaylist.length) {
      nextTrackIndex = 0;
    }
    FileChooser.notifier.selectedFilePathIndex = nextTrackIndex;
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.notifier.selectedFilePathIndex}',
    );
  }

  static void removeTrackByIndex(int index) {
    List<String> tracks = List.of(FileChooser.notifier.currentPlaylist);
    tracks.removeAt(index);
    FileChooser.notifier.currentPlaylist = tracks;
  }

  @override
  State<FileChooser> createState() => _FileChooserState();
}

class _FileChooserState extends State<FileChooser> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FileChooser.notifier,
      builder: (context, child) {
        return DropdownMenu<int>(
          width: double.infinity,
          requestFocusOnTap: false,
          initialSelection: FileChooser.notifier.selectedFilePathIndex,
          menuHeight: Screen.height(context) * 0.66,
          onSelected: (int? value) async {
            debugPrint('FileChooser::onSelected($value)');
            if (value != null) {
              FileChooser.notifier.selectedFilePathIndex = value;
              await AlgernonPlayer.playSelectedSound(
                reason: 'FileChooser::onSelected($value)',
              );
            }
            UserInterface.keepControlsAlive();
          },
          dropdownMenuEntries: FileChooser.notifier.currentPlaylist
              .asMap()
              .entries
              .map<DropdownMenuEntry<int>>(
                (MapEntry entry) => DropdownMenuEntry<int>(
                  value: entry.key,
                  label: FileChooser.notifier.currentPlaylist[entry.key]
                      .split('/')
                      .last,
                  style: MenuItemButton.styleFrom(
                    foregroundColor:
                        entry.key == FileChooser.notifier.selectedFilePathIndex
                        ? Colors.white
                        : ALGERNON.uiDefaultForegroundColor,
                  ),
                  trailingIcon: IconButton(
                    icon: Icon(Icons.playlist_remove),
                    onPressed: () {
                      FileChooser.removeTrackByIndex(entry.key);
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
