import 'package:algernon/algernon_audio_handler.dart';
import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/playlist_item_model.dart';
import 'package:algernon/sequences.dart';
import 'package:flutter/material.dart';

class PlaylistNotifier extends ChangeNotifier {
  /// Preference stores items as JSON so convert them back to [PlaylistItemModel]s.
  List<PlaylistItemModel> get currentPlaylist =>
      AppState.getPreference('playlist')
          .map<PlaylistItemModel>(
            (String prefString) => PlaylistItemModel.fromPrefString(prefString),
          )
          .toList() ??
      <PlaylistItemModel>[];

  /// Convert items to JSON for storage in preferences as a [List<String>] which is the closest available type.
  set currentPlaylist(List<PlaylistItemModel> newPlaylist) {
    AppState.setPreference(
      'playlist',
      newPlaylist.map((PlaylistItemModel item) => item.toPrefString()).toList(),
    );
    selectedFilePathIndex = 0;
    AlgernonPlayer.playSelectedSound(
      reason: 'FileChooserNotifier: New playlist',
    );
    notifyListeners();
  }

  int get playableItemCount => currentPlaylist
      .where((PlaylistItemModel item) => !item.isMissing && !item.isUnplayable)
      .length;

  int get nextPlayableIndex {
    int index = -1;
    if (playableItemCount > 0) {
      index = selectedFilePathIndex + 1;
      if (index == currentPlaylist.length) {
        index = 0;
      }
    }
    return index;
  }

  int get prevPlayableIndex {
    int index = -1;
    if (playableItemCount > 0) {
      index = selectedFilePathIndex - 1;
      if (index == -1) {
        index = currentPlaylist.length - 1;
      }
    }
    return index;
  }

  int get selectedFilePathIndex =>
      AppState.getPreference('selectedPlaylistFilePathIndex');
  set selectedFilePathIndex(int index) {
    AppState.setPreference('selectedPlaylistFilePathIndex', index);
    AlgernonAudioHandler.instance.updateNotification();
    notifyListeners();
  }

  /// Protect against non-existent index eg when tracks have been deleted.
  PlaylistItemModel get selectedItem =>
      currentPlaylist[selectedFilePathIndex.clamp(
        0,
        currentPlaylist.length - 1,
      )];

  /// Protect against non-existent index eg when tracks have been deleted.
  String get selectedFilePath => selectedItem.filepath;

  void setCurrentItemIsMissing() {
    debugPrint('FileChooserNotifier::setCurrentItemIsMissing()');
    List<PlaylistItemModel> list = currentPlaylist;
    PlaylistItemModel updatedItem = selectedItem;
    updatedItem.isMissing = true;
    list[selectedFilePathIndex] = updatedItem;
    currentPlaylist = List<PlaylistItemModel>.of(list);
    notifyListeners();
  }

  void setCurrentItemIsUnplayable() {
    debugPrint('FileChooserNotifier::setCurrentItemIsUnplayable()');
    List<PlaylistItemModel> list = currentPlaylist;
    PlaylistItemModel updatedItem = selectedItem;
    updatedItem.isUnplayable = true;
    list[selectedFilePathIndex] = updatedItem;
    currentPlaylist = List<PlaylistItemModel>.of(list);
    notifyListeners();
  }

  String get currentSequencingId => selectedItem.basename;

  bool get currentTrackHasSequencing =>
      playableItemCount > 0 && SEQUENCES.list.containsKey(currentSequencingId);
}
