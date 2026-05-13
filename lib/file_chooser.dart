// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/playlist_notifier.dart';
import 'package:algernon/playlist_item_model.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/user_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatefulWidget {
  const FileChooser({super.key});

  static PlaylistNotifier playlistNotifier = PlaylistNotifier();

  static Future<void> chooseFiles() async {
    FilePickerResult? filePickerResult = await FileChooser.pickFile();
    if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
      /// Add to END of playlist

      //List<PlaylistItemModel> list =
      //    FileChooser.playlistNotifier.currentPlaylist;
      //list.addAll(
      //  filePickerResult.files
      //      .map(
      //        (PlatformFile file) =>
      //            PlaylistItemModel(filepath: file.path.toString()),
      //      )
      //      .toList(),
      //);
      //FileChooser.playlistNotifier.currentPlaylist = List<PlaylistItemModel>.of(
      //  list,
      //);
      //FileChooser.playlistNotifier.currentPlaylist.insertAll
      /// Add to START of playlist
      List<PlaylistItemModel> list = filePickerResult.files
          .map(
            (PlatformFile file) =>
                PlaylistItemModel(filepath: file.path.toString()),
          )
          .toList();
      list.addAll(FileChooser.playlistNotifier.currentPlaylist);
      FileChooser.playlistNotifier.currentPlaylist = List<PlaylistItemModel>.of(
        list,
      );
    }
  }

  static void selectNext() {
    debugPrint('FileChooser::selectNext()');
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.playlistNotifier.selectedFilePathIndex}',
    );
    int nextTrackIndex = FileChooser.playlistNotifier.nextPlayableIndex;
    if (nextTrackIndex != -1) {
      FileChooser.playlistNotifier.selectedFilePathIndex = nextTrackIndex;
      debugPrint(
        '\tselectedFilePathIndex: ${FileChooser.playlistNotifier.selectedFilePathIndex}',
      );
    }
  }

  static void selectPrev() {
    debugPrint('FileChooser::selectPrev()');
    debugPrint(
      '\tselectedFilePathIndex: ${FileChooser.playlistNotifier.selectedFilePathIndex}',
    );
    int prevTrackIndex = FileChooser.playlistNotifier.prevPlayableIndex;
    if (prevTrackIndex != -1) {
      FileChooser.playlistNotifier.selectedFilePathIndex = prevTrackIndex;
      debugPrint(
        '\tselectedFilePathIndex: ${FileChooser.playlistNotifier.selectedFilePathIndex}',
      );
    }
  }

  static void removeTrackByIndex(int index) {
    List<PlaylistItemModel> tracks = List.of(
      FileChooser.playlistNotifier.currentPlaylist,
    );
    tracks.removeAt(index);
    FileChooser.playlistNotifier.currentPlaylist = tracks;
  }

  static void setCurrentItemIsMissing() {
    debugPrint('FileChooser::setCurrentItemIsMissing()');
    FileChooser.playlistNotifier.setCurrentItemIsMissing();
  }

  static void setCurrentItemIsUnplayable() {
    debugPrint('FileChooser::setCurrentItemIsUnplayable()');
    FileChooser.playlistNotifier.setCurrentItemIsUnplayable();
  }

  static Future<FilePickerResult?> pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'opus'],
    );

    return result;
  }

  static bool get currentTrackIsLast =>
      FileChooser.playlistNotifier.selectedFilePathIndex ==
      FileChooser.playlistNotifier.currentPlaylist.length - 1;

  @override
  State<FileChooser> createState() => _FileChooserState();
}

class _FileChooserState extends State<FileChooser> {
  final int _emptyPlaylistSpecialIndex = -1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FileChooser.playlistNotifier,
      builder: (context, child) {
        dynamic uiSizes = Screen.uiSizesFromContext(context);
        List<PlaylistItemModel> playlist =
            FileChooser.playlistNotifier.currentPlaylist;

        return Row(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: playlist.isEmpty,
                child: DropdownMenu<int>(
                  textAlign: playlist.isEmpty ? TextAlign.end : TextAlign.start,
                  width: double.infinity,
                  trailingIcon: playlist.isEmpty
                      ? Icon(Icons.arrow_right)
                      : null,
                  requestFocusOnTap: false,
                  initialSelection: playlist.isEmpty
                      ? _emptyPlaylistSpecialIndex
                      : FileChooser.playlistNotifier.selectedFilePathIndex,
                  menuHeight: Screen.height(context) * 0.66,
                  onSelected: playlist.isEmpty
                      ? (value) async {
                          await FileChooser.chooseFiles();
                        }
                      : (int? value) async {
                          debugPrint('FileChooser::onSelected($value)');
                          if (value != null &&
                              value != _emptyPlaylistSpecialIndex) {
                            FileChooser.playlistNotifier.selectedFilePathIndex =
                                value;
                            await AlgernonPlayer.playSelectedSound(
                              reason: 'FileChooser::onSelected($value)',
                            );
                          }
                          UserInterface.keepControlsAlive();
                        },
                  dropdownMenuEntries: playlist.isEmpty
                      ? [
                          DropdownMenuEntry<int>(
                            value: _emptyPlaylistSpecialIndex,
                            label: ('Add some tracks').toUpperCase(),
                          ),
                        ]
                      : playlist.asMap().entries.map<DropdownMenuEntry<int>>((
                          MapEntry entry,
                        ) {
                          int index = entry.key;
                          PlaylistItemModel item = FileChooser
                              .playlistNotifier
                              .currentPlaylist[index];
                          return DropdownMenuEntry<int>(
                            enabled: !item.isMissing && !item.isUnplayable,
                            value: index,
                            label: item.filepath.split('/').last,
                            style: MenuItemButton.styleFrom(
                              foregroundColor:
                                  index ==
                                      FileChooser
                                          .playlistNotifier
                                          .selectedFilePathIndex
                                  ? Colors.white
                                  : ALGERNON.uiDefaultForegroundColor,
                              disabledForegroundColor:
                                  item.isMissing || item.isUnplayable
                                  ? ALGERNON.uiSoftForegroundColor
                                  : ALGERNON.uiDefaultForegroundColor,
                            ),
                            trailingIcon: IconButton(
                              mouseCursor: SystemMouseCursors.click,
                              tooltip: item.isMissing
                                  ? 'Remove MISSING file from playlist'
                                  : item.isUnplayable
                                  ? 'Remove UNPLAYABLE file from playlist'
                                  : 'Remove file from playlist',
                              icon: Icon(
                                item.isMissing
                                    ? Icons.error_outline
                                    : item.isUnplayable
                                    ? Icons.question_mark
                                    : Icons.playlist_remove,
                                color: item.isMissing || item.isUnplayable
                                    ? ALGERNON.uiAttractColor
                                    : ALGERNON.uiDefaultForegroundColor,
                              ),
                              onPressed: () {
                                FileChooser.removeTrackByIndex(index);
                              },
                            ),
                          );
                        }).toList(),
                ),
              ),
            ),

            SizedBox(width: uiSizes.paddingSmall),

            ColoredBox(
              color: playlist.isEmpty
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
