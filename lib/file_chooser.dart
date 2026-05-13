// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_icon_button.dart';
import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/playlist_item_model.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/user_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatefulWidget {
  const FileChooser({super.key});

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
      list.addAll(AlgernonPlayer.playlistNotifier.currentPlaylist);
      AlgernonPlayer.playlistNotifier.currentPlaylist =
          List<PlaylistItemModel>.of(list);
    }
  }

  static void selectNext() {
    debugPrint('FileChooser::selectNext()');
    debugPrint(
      '\tselectedFilePathIndex: ${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}',
    );
    int nextTrackIndex = AlgernonPlayer.playlistNotifier.nextPlayableIndex;
    if (nextTrackIndex != -1) {
      AlgernonPlayer.playlistNotifier.selectedFilePathIndex = nextTrackIndex;
      debugPrint(
        '\tselectedFilePathIndex: ${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}',
      );
    }
  }

  static void selectPrev() {
    debugPrint('FileChooser::selectPrev()');
    debugPrint(
      '\tselectedFilePathIndex: ${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}',
    );
    int prevTrackIndex = AlgernonPlayer.playlistNotifier.prevPlayableIndex;
    if (prevTrackIndex != -1) {
      AlgernonPlayer.playlistNotifier.selectedFilePathIndex = prevTrackIndex;
      debugPrint(
        '\tselectedFilePathIndex: ${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}',
      );
    }
  }

  static void removeTrackByIndex(int index) {
    List<PlaylistItemModel> tracks = List.of(
      AlgernonPlayer.playlistNotifier.currentPlaylist,
    );
    tracks.removeAt(index);
    AlgernonPlayer.playlistNotifier.currentPlaylist = tracks;
  }

  static void setCurrentItemIsMissing() {
    debugPrint('FileChooser::setCurrentItemIsMissing()');
    AlgernonPlayer.playlistNotifier.setCurrentItemIsMissing();
  }

  static void setCurrentItemIsUnplayable() {
    debugPrint('FileChooser::setCurrentItemIsUnplayable()');
    AlgernonPlayer.playlistNotifier.setCurrentItemIsUnplayable();
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
      AlgernonPlayer.playlistNotifier.selectedFilePathIndex ==
      AlgernonPlayer.playlistNotifier.currentPlaylist.length - 1;

  @override
  State<FileChooser> createState() => _FileChooserState();
}

class _FileChooserState extends State<FileChooser> {
  final int _emptyPlaylistSpecialIndex = -1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AlgernonPlayer.playlistNotifier,
      builder: (context, child) {
        dynamic uiSizes = Screen.uiSizesFromContext(context);
        List<PlaylistItemModel> playlist =
            AlgernonPlayer.playlistNotifier.currentPlaylist;

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
                      : AlgernonPlayer.playlistNotifier.selectedFilePathIndex,
                  menuHeight: Screen.height(context) * 0.66,
                  onSelected: playlist.isEmpty
                      ? (value) async {
                          await FileChooser.chooseFiles();
                        }
                      : (int? value) async {
                          debugPrint('FileChooser::onSelected($value)');
                          if (value != null &&
                              value != _emptyPlaylistSpecialIndex) {
                            AlgernonPlayer
                                    .playlistNotifier
                                    .selectedFilePathIndex =
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
                          PlaylistItemModel item = AlgernonPlayer
                              .playlistNotifier
                              .currentPlaylist[index];
                          return DropdownMenuEntry<int>(
                            enabled: !item.isMissing && !item.isUnplayable,
                            value: index,
                            label: item.filepath.split('/').last,
                            style: MenuItemButton.styleFrom(
                              foregroundColor:
                                  index ==
                                      AlgernonPlayer
                                          .playlistNotifier
                                          .selectedFilePathIndex
                                  ? ALGERNON.uiStrongForegroundColor
                                  : ALGERNON.uiDefaultForegroundColor,
                              disabledForegroundColor:
                                  item.isMissing || item.isUnplayable
                                  ? ALGERNON.uiSoftForegroundColor
                                  : ALGERNON.uiDefaultForegroundColor,
                            ),
                            trailingIcon: AlgernonIconButton(
                              tooltip: item.isMissing
                                  ? 'Remove MISSING file from playlist'
                                  : item.isUnplayable
                                  ? 'Remove UNPLAYABLE file from playlist'
                                  : 'Remove file from playlist',
                              iconData: item.isMissing
                                  ? Icons.error_outline
                                  : item.isUnplayable
                                  ? Icons.question_mark
                                  : Icons.playlist_remove,
                              color: item.isMissing || item.isUnplayable
                                  ? ALGERNON.uiAttractColor
                                  : null,
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
              child: AlgernonIconButton(
                tooltip: 'Add files to playlist',
                onPressed: () async {
                  await FileChooser.chooseFiles();
                },
                iconData: Icons.playlist_add,
              ),
            ),
          ],
        );
      },
    );
  }
}
