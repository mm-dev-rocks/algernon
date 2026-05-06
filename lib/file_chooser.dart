// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/file_chooser_notifier.dart';
import 'package:algernon/file_manager.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/user_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatefulWidget {
  const FileChooser({super.key});

  static FileChooserNotifier notifier = FileChooserNotifier();

  static Future<void> chooseFiles() async {
    FilePickerResult? filePickerResult = await FileManager.pickFile();
    if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
      FileChooser.notifier.currentPlaylist = filePickerResult.files
          .map((PlatformFile file) => file.path.toString())
          .toList();
    }
  }

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

  static bool get currentTrackIsLast =>
      FileChooser.notifier.selectedFilePathIndex ==
      FileChooser.notifier.currentPlaylist.length - 1;

  @override
  State<FileChooser> createState() => _FileChooserState();
}

class _FileChooserState extends State<FileChooser> {
  final int _emptyPlaylistSpecialIndex = -1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FileChooser.notifier,
      builder: (context, child) {
        dynamic uiSizes = Screen.uiSizesFromContext(context);
        return Row(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: FileChooser.notifier.currentPlaylist.isEmpty,
                child: DropdownMenu<int>(
                  textAlign: FileChooser.notifier.currentPlaylist.isEmpty
                      ? TextAlign.end
                      : TextAlign.start,
                  width: double.infinity,
                  trailingIcon: FileChooser.notifier.currentPlaylist.isEmpty
                      ? Icon(Icons.arrow_right)
                      : null,
                  requestFocusOnTap: false,
                  initialSelection: FileChooser.notifier.currentPlaylist.isEmpty
                      ? _emptyPlaylistSpecialIndex
                      : FileChooser.notifier.selectedFilePathIndex,
                  menuHeight: Screen.height(context) * 0.66,
                  onSelected: FileChooser.notifier.currentPlaylist.isEmpty
                      ? (value) async {
                          await FileChooser.chooseFiles();
                        }
                      : (int? value) async {
                          debugPrint('FileChooser::onSelected($value)');
                          if (value != null &&
                              value != _emptyPlaylistSpecialIndex) {
                            FileChooser.notifier.selectedFilePathIndex = value;
                            await AlgernonPlayer.playSelectedSound(
                              reason: 'FileChooser::onSelected($value)',
                            );
                          }
                          UserInterface.keepControlsAlive();
                        },
                  dropdownMenuEntries:
                      FileChooser.notifier.currentPlaylist.isEmpty
                      ? [
                          DropdownMenuEntry<int>(
                            value: _emptyPlaylistSpecialIndex,
                            label: ('Add some tracks').toUpperCase(),
                          ),
                        ]
                      : FileChooser.notifier.currentPlaylist
                            .asMap()
                            .entries
                            .map<DropdownMenuEntry<int>>(
                              (MapEntry entry) => DropdownMenuEntry<int>(
                                value: entry.key,
                                label: FileChooser
                                    .notifier
                                    .currentPlaylist[entry.key]
                                    .split('/')
                                    .last,
                                style: MenuItemButton.styleFrom(
                                  foregroundColor:
                                      entry.key ==
                                          FileChooser
                                              .notifier
                                              .selectedFilePathIndex
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
                ),
              ),
            ),

            SizedBox(width: uiSizes.paddingSmall),

            ColoredBox(
              color: FileChooser.notifier.currentPlaylist.isEmpty
                  ? ALGERNON.uiAttractColor
                  : Colors.transparent,
              child: IconButton(
                mouseCursor: SystemMouseCursors.click,
                onPressed: () async {
                  await FileChooser.chooseFiles();
                },
                icon: Icon(Icons.playlist_add),
              ),
            ),
          ],
        );
      },
    );
  }
}
