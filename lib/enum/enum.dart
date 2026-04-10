// SPDX-License-Identifier: GPL-3.0-only

enum BookType {
  directoryBook(
    description: 'Folder of files, each file is a chapter',
  ),
  fileLooseInLibraryBaseDir(
    description: 'Single file, loose in the library with no parent folder',
  ),
  fileWithCuesheetBook(
    description: 'Single file with an associated cue sheet (`*.cue file`)',
  ),
  fileWithMetadataChapterListBook(
    description: 'Single file with a list of chapters in its metadata',
  ),
  fileWithCuesheetAndMetadataChapterListBook(
    description:
        'Single file with BOTH an associated cue sheet (`*.cue file`) AND a list of chapters in its metadata',
  ),
  nullBook(
    description: 'Null book',
  );

  final String description;
  const BookType({
    required this.description,
  });
}

enum FavouriteIconState {
  favourited,
  notFavourited,
  busy,
}

enum SearchbarVisibility {
  visible,
  hidden,
  hideOnce,
}

enum Corner {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
}

enum DurationType {
  playerControls,
  currentChapter,
  nonplayingChapter;
}

enum DurationTriState {
  total(description: 'chapter length', symbol: '╍'),
  position(description: 'current position', symbol: '↑'),
  remaining(description: 'time remaining', symbol: '↓'),
  ;

  final String description;
  final String symbol;
  const DurationTriState({
    required this.description,
    required this.symbol,
  });
}

enum AppBarExtra {
  none,
  quickChoosers;
}

enum PlayerControlsExtra {
  none,
  playbackSpeed,
  longSeekInfoBox,
  maximumRetriesFailedInfoBox,
  metadataChapterListInfoBox;
}

/// The state of audio playback/processing can be nuanced and complex, with idle, buffering,
/// playing, paused, stopped, seeking etc. For some situations we just want a simple binary 'is
/// sound currently being sent to the speakers or not'. That's what [BinaryPlayingState] is for.
enum BinaryPlayingState {
  isPlaying,
  isNotPlaying,
}

enum PlaybackSpeed {
  level1(
    speed: 0.8,
    compensatedPitch: 1.02,
    label: '0.8x',
    semanticLabel: 'slow 0.8',
  ),
  level2(
    speed: 1,
    compensatedPitch: 1,
    label: '1x',
    semanticLabel: 'normal',
  ),
  level3(
    speed: 1.3,
    compensatedPitch: 0.97,
    label: '1.3x',
    semanticLabel: 'fast 1.3',
  ),
  level4(
    speed: 1.6,
    compensatedPitch: 0.965,
    label: '1.6x',
    semanticLabel: 'fast 1.6',
  ),
  level5(
    speed: 1.9,
    compensatedPitch: 0.96,
    label: '1.9x',
    semanticLabel: 'fast 1.9',
  ),
  level6(
    speed: 2.1,
    compensatedPitch: 0.955,
    label: '2.1x',
    semanticLabel: 'fast 2.1',
  );

  final double speed;
  final double compensatedPitch;
  final String label;
  final String semanticLabel;
  const PlaybackSpeed({
    required this.speed,
    required this.compensatedPitch,
    required this.label,
    required this.semanticLabel,
  });
}

enum BookListPageMode {
  fullLibrary,
  favourites,
}

enum SearchMatchType {
  bookTitle(description: 'book:'),
  chapterTitle(description: 'chapter:'),
  bookmarkNote(description: 'bookmark note:');

  final String description;
  const SearchMatchType({
    required this.description,
  });
}

enum PlaylistType {
  files,
  metadata,
  empty,
}

enum MetadataPlaylistType {
  cuesheetFile,
  chaptersJson,
  none,
}

enum WebDavConnectionStatus {
  notYetInitialised(description: 'Starting...'),
  firstTimeSetup(description: 'No server settings'),
  attempting(description: 'Connecting...'),
  verified(description: 'Connected'),
  verifiedWithBadAudiobookDirectory(description: 'Check audiobook directory setting'),
  savingProgress(description: 'Saving listening progress'),
  error(description: 'Connection Error: Check settings');

  final String description;
  const WebDavConnectionStatus({
    required this.description,
  });
}

enum ScanStatus {
  checkForExisting,
  starting,
  scanning,
  completed,
  error,
  cancelled,
}

enum ServerPathId {
  libraryJsonFileAbsolute,
  bookmarksJsonFileAbsolute,
  historyJsonFileAbsolute,
  readmeFileAbsolute,
  libraryBaseDir,
  appDataDirAbsolute,
  booksProgressDirAbsolute,
}
