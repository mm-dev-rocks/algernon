// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_state.dart';
import 'constants.dart';

/// Methods related to opening/closing files
class FileManager {
  /// TODO Use [join] instead of [_osSlash].
  // Slash to be used in file paths depending on which OS is in use
  //static final String _osSlash = Platform.isWindows ? '\\' : '/';

  // Depending on `rememberLastOpenedDirectory` preference,
  // save either the recently-used path or an empty string in [SharedPreferences]
  static void updateLatestPickedPath(String? path) {
    if (path != null) {
      String parentDirPath = File(path).parent.path;

      AppState.setPreference(
        'lastOpenedDirectory',
        AppState.getPreference('rememberLastOpenedDirectory')
            ? parentDirPath
            : '',
      );
    }
  }

  //static void pickJsonPlaylistFile() async {
  //  AppState.update('fileLoadOrSaveIsInProgress', true);

  //  String? pickedPath = await _pickFile('Open a JSON playlist file', [
  //    '.json',
  //  ]);

  //  if (pickedPath != null) {
  //    File(pickedPath).readAsString().then((String jsonString) {
  //      JsonImporter.playlistFromString(
  //        jsonString,
  //        AppState.get('currentSelectedDbPath'),
  //      );
  //    });
  //  }

  //  AppState.update('fileLoadOrSaveIsInProgress', false);
  //}

  /// For one (current) database: Bundle up its extracted files from the original zip (including the
  /// updated database) from the temp directory. Write the updated zip back to the same directory as
  /// the original.
  //  static void saveFile() {
  //    /// Get the full path for currently selected database/tab
  //    String currentSelectedDbPath = AppState.get('currentSelectedDbPath');
  //
  //    /// If the user wants to save the search playlist with the zip, we need to rename it for the
  //    /// save, then name it back (the search playlist has a special name internally). Save some vars
  //    /// here to help with that.
  //    int? originalSearchPlaylistUid;
  //    String? originalSearchPlaylistName;
  //    String? friendlySearchPlaylistName;
  //    bool shouldRenameBack = false;
  //
  //    if (!AppState.getPreference('saveSearchTableToZip')) {
  //      AppState.debug('DELETING search table');
  //      DbManager.deleteSearchPlaylist(currentSelectedDbPath);
  //    } else {
  //      AppState.debug('RETAINING search table in zip');
  //
  //      originalSearchPlaylistUid = DbManager.getSearchPlaylistUid(currentSelectedDbPath);
  //
  //      // Only proceed with renaming if a search playlist actually exists
  //      if (originalSearchPlaylistUid != null) {
  //        originalSearchPlaylistName = DbManager.getSearchPlaylistName(currentSelectedDbPath);
  //        friendlySearchPlaylistName = DbManager.getSearchPlaylistCopyName(currentSelectedDbPath);
  //
  //        // Renaming the search playlist to its friendly name before saving.
  //        // This is a temporary state change for the save operation.
  //        DbManager.renameLocalPlaylist(
  //          currentSelectedDbPath,
  //          originalSearchPlaylistUid,
  //          friendlySearchPlaylistName,
  //        );
  //
  //        shouldRenameBack = true;
  //        AppState.debug('Temporarily renamed search playlist to: $friendlySearchPlaylistName');
  //      }
  //    }
  //
  //    AppState.update('fileLoadOrSaveIsInProgress', true);
  //
  //    /// Do the file-saving in a [try] block as something could go wrong externally (eg no space left
  //    /// on drive) and if it does we can use [finally] to make sure we rename the special search
  //    /// playlist if we need to.
  //    try {
  //      String directoryToZip = Directory(currentSelectedDbPath).parent.path;
  //      AppState.debug('directoryToZip: $directoryToZip');
  //
  //      String outputZipPath = DbManager.databases
  //          .getByKey(currentSelectedDbPath)!
  //          .originalZipPath
  //          .replaceAll('.zip', '${ALGERNON.savedFileSuffix}.zip');
  //      AppState.debug('outputZipPath: $outputZipPath');
  //
  //      var encoder = ZipFileEncoder();
  //      encoder.zipDirectory(Directory(directoryToZip), filename: outputZipPath);
  //
  //      DbManager.setDbDirtyState(AppState.get('currentSelectedDbPath'), false);
  //
  //      AppState.showAppDialog(
  //        title: 'File saved:',
  //        message:
  //            '''
  //A new file has been saved to:
  //$outputZipPath
  //
  //
  //You can import it into NewPipe now.
  //
  //Don't delete your old file until you're sure everything is ok with the new one!
  //      ''',
  //      );
  //    } finally {
  //      if (shouldRenameBack &&
  //          originalSearchPlaylistUid != null &&
  //          originalSearchPlaylistName != null) {
  //        DbManager.renameLocalPlaylist(
  //          currentSelectedDbPath,
  //          originalSearchPlaylistUid,
  //          originalSearchPlaylistName,
  //        );
  //        AppState.debug('Renamed search playlist back to original: $originalSearchPlaylistName');
  //      }
  //      AppState.update('fileLoadOrSaveIsInProgress', false);
  //    }
  //  }

  static Future<String?> _pickFile(
    String title,
    List<String> allowedExtensions,
  ) async {
    List<String> systemPaths = Platform.isLinux
        ? List<String>.from(ALGERNON.filepathsLinux)
        : Platform.isWindows
        ? List<String>.from(ALGERNON.filepathsWindows)
        : List<String>.from(ALGERNON.filepathsAndroid);

    _addLastOpenedDirectoryToList(systemPaths);

    String? pickedPath = await FilesystemPicker.open(
      title: title,
      context: AppState.globalContext,
      shortcuts: systemPaths
          .map<FilesystemPickerShortcut>(
            (path) => FilesystemPickerShortcut(
              name: path,
              path: Directory(path),
              icon: Icons.snippet_folder,
            ),
          )
          .toList(),
      fsType: FilesystemType.file,
      requestPermission: _checkStoragePermission,
      allowedExtensions: allowedExtensions,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
    );

    if (pickedPath == null) {
      debugPrint('No file selected');
      AppState.update('fileLoadOrSaveIsInProgress', false);
    }

    return pickedPath;
  }

  /// [tempTestDirectory] is just for the test environment. The app usually uses [path_provider] to
  /// get a directory. This will work differently on different OSes. Tests are usually run on Linux
  /// and the app is usually run on Android, so there's no point getting hung up on testing
  /// [path_provider] as it complicates tests and wouldn't test the end-user environment anyway. So
  /// we allow tests to just pass in a directory.
  //static Future<bool> importZipDbFile(
  //  String pickedPath, {
  //  Directory? tempTestDirectory,
  //}) async {
  //  bool dbWasAdded = false;

  //  String? pickedPathSafe = pickedPath;

  //  /// Windows ends up with additional drive letters eg 'C:' in the temporary path, so replace the
  //  /// colons with a string which is valid in Windows, but hopefully won't occur in any filepaths
  //  /// we encounter.
  //  if (Platform.isWindows) {
  //    pickedPathSafe = pickedPath.replaceAll(':', '()_-,');
  //  }

  //  /// Remember this path for next time the user wants to choose a zip
  //  FileManager.updateLatestPickedPath(pickedPathSafe);

  //  /// NewPipe works with (exports/imports) zip files.
  //  ///
  //  /// We have to extract the zip so `sqlite3` can access the `*.db` file.
  //  ///
  //  /// Get a temp directory from the OS, add a directory for BendyStraw, then recreate the entire
  //  /// path for the original file inside the directory, so eg: - original file is
  //  /// `/home/user1/NewPipeData.zip` - extraction directory is:
  //  /// `/tmp/bendy-straw-unzipped/home/user1/NewPipeData.zip/`
  //  ///
  //  /// **The long recreated path is necessary in case multiple zips are opened with the same
  //  /// filename in different filesystem locations**
  //  Directory tmpDir = tempTestDirectory ?? await getTemporaryDirectory();
  //  String tmpDirPath =
  //      '${tmpDir.path}${_osSlash}${ALGERNON.baseWorkingDirectory}${_osSlash}${pickedPathSafe}';
  //  AppState.debug('tmpDirPath: $tmpDirPath');

  //  /// Extract zip to [tmpDirPath].
  //  final inputStream = InputFileStream(pickedPath);
  //  final archive = ZipDecoder().decodeBuffer(inputStream);
  //  await extractArchiveToDisk(archive, tmpDirPath);

  //  /// Path to the extracted database file.
  //  String extractedDbPath = '${tmpDirPath}${_osSlash}newpipe.db';
  //  AppState.debug('extractedDbPath: $extractedDbPath');

  //  /// Add the extracted database to the app.
  //  /// The full filepath is used as a key in a [Map].
  //  /// Sometimes no db will be added (eg if the same file is added twice).
  //  if (DbManager.addDbByPathKey(extractedDbPath, pickedPath)) {
  //    dbWasAdded = true;
  //    AppState.update('databases', DbManager.databases, forceRebuild: true);
  //  }

  //  return dbWasAdded;
  //}

  //static Future<void> pickZipDbFile({Directory? tempTestDirectory}) async {
  //  AppState.update('fileLoadOrSaveIsInProgress', true);

  //  String? pickedPath = await _pickFile('Open a NewPipe zip file', ['.zip']);
  //  if (pickedPath != null) {
  //    final bool dbWasAdded = await importZipDbFile(pickedPath);
  //    if (dbWasAdded) {
  //      _ensureTabsPageOpen();
  //    }
  //  }
  //  AppState.update('fileLoadOrSaveIsInProgress', false);
  //}

  //static void _ensureTabsPageOpen() {
  //  AppState.debug('FileManagerWidget::_ensureTabsPageOpen()');
  //  if (AppState.globalContext.mounted) {
  //    String currentSelectedDbPath = AppState.get('currentSelectedDbPath');
  //    AppState.debug('\tcurrentSelectedDbPath: ${currentSelectedDbPath}');
  //    if (currentSelectedDbPath.isEmpty) {
  //      AppState.get(
  //        'nestedNavigatorKey',
  //      ).currentState?.pushNamed(ALGERNON.routeInnerTabsPage);
  //    } else {
  //      AppState.debug('TABS PAGE ALREADY OPENED, NO NAVIGATION NEEDED');
  //    }
  //  }
  //}

  // Depending on `rememberLastOpenedDirectory` preference,
  // and whether a `lastOpenedDirectory` is stored in preferences,
  // add the directory to the List passed in via the [paths] parameter.
  static void _addLastOpenedDirectoryToList(List<String> paths) async {
    String? lastOpenedDirectory = AppState.getPreference('lastOpenedDirectory');
    if (AppState.getPreference('rememberLastOpenedDirectory') &&
        lastOpenedDirectory != null &&
        lastOpenedDirectory.isNotEmpty) {
      if (!paths.contains(lastOpenedDirectory)) {
        paths.add(lastOpenedDirectory);
      }
    }
  }

  /// Passed into [FilesystemPicker.open()] via its [requestPermission]
  /// parameter, to be used when it wants to check that we have permission to
  /// read files on this system.
  static Future<bool> _checkStoragePermission() async {
    bool isPermitted = true;
    PermissionStatus status;
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
      if ((info.version.sdkInt) >= 30) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }
      if (status != PermissionStatus.granted) {
        isPermitted = false;
        debugPrint('''
BendyStraw needs storage permissions to work.

status: $status
''');
      }
      debugPrint('status: $status');
    }
    debugPrint('isPermitted: $isPermitted');

    return isPermitted;
  }
}
