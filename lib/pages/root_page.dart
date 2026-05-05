// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/file_chooser.dart';
import 'package:flutter/material.dart';

import '../algernon_player.dart';

/// First route/page for the app.
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    //return ListenableBuilder(
    //  listenable: FileChooser.notifier,
    //  builder: (BuildContext context, Widget? child) {
    //    bool playlistIsEmpty = FileChooser.notifier.currentPlaylist.isEmpty;
    //    debugPrint(
    //      'RootPage::ListenableBuilder: playlistIsEmpty: $playlistIsEmpty',
    //    );

    //    Widget contents = playlistIsEmpty
    //        ? const Text('Add some tracks')
    //        : const AlgernonPlayer();

    //    return contents;
    //  },
    //);
    return const AlgernonPlayer();
  }
}
