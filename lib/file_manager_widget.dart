// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

import 'app_state.dart';

/// Show a filechooser for opening/adding/saving NewPipe zips containing database files.
class FileManagerWidget extends StatefulWidget {
  const FileManagerWidget({super.key});

  @override
  State<FileManagerWidget> createState() => _FileManagerWidgetState();
}

class _FileManagerWidgetState extends State<FileManagerWidget> {
  final bool _wereUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    bool fileLoadOrSaveIsInProgress = AppState.get(
      'fileLoadOrSaveIsInProgress',
    );

    return Container(
      //color: dbBackgroundColor,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.add_to_photos_rounded),
            onPressed: null,
            //iconData: Icons.add_to_photos_rounded,
            //hoverText: 'Add Zip',
            //label: showFloatingIconButtonLabels ? 'Add Zip' : null,
            //onPressed: fileLoadOrSaveIsInProgress
            //    ? null
            //    : FileManager.pickZipDbFile,
            //backgroundColor: dbBackgroundColor,
            //foregroundColor: dbForegroundColor,
            //borderRadius: const BorderRadius.only(
            //  topRight: Radius.circular(BS.cornerButtonRadius),
            //),
          ),
        ],
      ),
    );
  }
}
