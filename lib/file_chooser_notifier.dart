import 'package:algernon/app_state.dart';
import 'package:flutter/material.dart';

class FileChooserNotifier extends ChangeNotifier {
  List<String> get currentPlaylist => AppState.getPreference('playlist');
  set currentPlaylist(List<String> newPlaylist) {
    AppState.setPreference('playlist', newPlaylist);
    notifyListeners();
  }

  int get selectedFilePathIndex =>
      AppState.getPreference('selectedPlaylistFilePathIndex');
  set selectedFilePathIndex(int index) {
    AppState.setPreference('selectedPlaylistFilePathIndex', index);
    notifyListeners();
  }

  /// Protect against non-existent index eg when tracks have been deleted.
  String get selectedFilePath =>
      currentPlaylist[selectedFilePathIndex.clamp(
        0,
        currentPlaylist.length - 1,
      )];
}
