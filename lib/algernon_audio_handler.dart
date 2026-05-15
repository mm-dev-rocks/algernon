// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/file_chooser.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// This class (via its [Player] instance) handles everything to do with actually playing/pausing
/// audio and similar functionality. Other classes must use methods from this class to do these
/// things (so eg a 'play' button must call [play] in this class). These methods will ensure that
/// integration with the system happens correctly (eg icons and controls being shown in the
/// notification panel), and due to the use of [AudioService], will automatically be called by
/// system actions outside the app. So for instance if a user clicks a 'skip next' button on a
/// headset, [skipToNext] in this class will get called.
class AlgernonAudioHandler extends BaseAudioHandler with SeekHandler {
  ///

  /// [_internal] is the real constructor and will be called only once, here, and assigned to
  /// [instance].
  AlgernonAudioHandler._internal() {
    _initAudioSession();
  }
  static final AlgernonAudioHandler instance = AlgernonAudioHandler._internal();

  // Other classes will get the singleton when they call [AlgernonAudioHandler()].
  factory AlgernonAudioHandler() => instance;

  Future<void> dispose() async {
    await pause();
    await stop();
  }

  final List<MediaControl> controlsPaused = [
    MediaControl.skipToPrevious,
    MediaControl.play,
    MediaControl.skipToNext,
  ];
  final List<MediaControl> controlsPlaying = [
    MediaControl.skipToPrevious,
    MediaControl.pause,
    MediaControl.skipToNext,
  ];

  /// Open a file ready for playing. If [startPlaying] is true then play it straight away, otherwise
  /// wait for [play()] to be called manually.
  //Future<void> open({
  //  required String filepath,
  //  required bool startPlaying,
  //}) async {
  //  if (!_firstTimeInitIsDone) _firstTimeInit();

  //  //_updateProcessingState(AudioProcessingState.loading);

  //  try {
  //    //_webdavHeaders ??= await WebDav.getDefaultHeaders();
  //    //await audioPlayer.open(
  //    //  Media(
  //    //    ServerFunctions.decodedFilepath(filepath),
  //    //    httpHeaders: _webdavHeaders,
  //    //  ),
  //    //  play: startPlaying,
  //    //);
  //    //_updateProcessingState(AudioProcessingState.ready);

  //    /// Ensure state matches
  //    playbackState.add(playbackState.value.copyWith(playing: startPlaying));
  //  } catch (e) {
  //    debugPrint('•☽────✧˖°˖☆˖°˖✧────☾•');
  //    debugPrint('[_audioHandler.open()] ERROR: $e\n\n');
  //  }
  //}

  /// On Android when the user kills the app in the task switcher, ensure that audio stops
  /// (otherwise they get stuck with audio playing and the only way to stop it is to 'force stop').
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  /// THE SINGLE RESPONSIBLE PARTY FOR AUDIO LOGIC
  /// The following overridden playback control methods are called by the system when buttons in the
  /// notification panel or lockscreen are tapped. So we treat these as a centralised place for
  /// these things to happen, meaning actions originating in the app UI do their jobs via these
  /// methods too.

  Future<void> unpause() async {
    debugPrint("AlgernonAudioHandler::unpause()");

    if (AlgernonPlayer.currentSoundHandle != null) {
      playbackState.add(
        playbackState.value.copyWith(playing: true, controls: controlsPlaying),
      );
      //_updateProcessingState(AudioProcessingState.completed);
      SoLoud.instance.setPause(AlgernonPlayer.currentSoundHandle!, false);
    } else {
      debugPrint("- IGNORING (AlgernonPlayer.currentSoundHandle == null)");
    }
  }

  @override
  Future<void> pause() async {
    debugPrint("AlgernonAudioHandler::pause()");

    //await AudavAudioObserver.stopPlaybackListeners();

    //await audioPlayer.pause();
    if (AlgernonPlayer.currentSoundHandle != null) {
      playbackState.add(
        playbackState.value.copyWith(playing: false, controls: controlsPaused),
      );
      //_updateProcessingState(AudioProcessingState.ready);
      SoLoud.instance.setPause(AlgernonPlayer.currentSoundHandle!, true);
    } else {
      debugPrint("- IGNORING (AlgernonPlayer.currentSoundHandle == null)");
    }
  }

  @override
  Future<SoundHandle?> play() async {
    debugPrint("AlgernonAudioHandler::play()");
    debugPrint(
      'AlgernonAudioHandler::play() SoLoud.instance.getActiveVoiceCount(): ${SoLoud.instance.getActiveVoiceCount().toString()}',
    );

    if (AlgernonPlayer.currentSoundNotifier.source == null) {
      debugPrint("- IGNORING (AlgernonPlayer.currentSoundHandle == null)");
      return null;
    } else {
      playbackState.add(
        playbackState.value.copyWith(playing: true, controls: controlsPlaying),
      );
      return SoLoud.instance.play(AlgernonPlayer.currentSoundNotifier.source!);
    }
  }

  Future<void> togglePause() async {
    debugPrint("AlgernonAudioHandler::togglePause()");
    if (playbackState.value.playing) {
      await pause();
    } else {
      await unpause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    SoLoud.instance.seek(AlgernonPlayer.currentSoundHandle!, position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint("AlgernonAudioHandler::skipToNext()");
    FileChooser.selectNext();
    await AlgernonPlayer.playSelectedSound(
      reason: 'AlgernonAudioHandler::skipToNext()',
    );
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint("AlgernonAudioHandler::skipToPrevious()");
    FileChooser.selectPrev();
    await AlgernonPlayer.playSelectedSound(
      reason: 'AlgernonAudioHandler::skipToPrevious()',
    );
  }

  @override
  Future<void> stop() async {
    debugPrint("AlgernonAudioHandler::stop()");
    //if (AlgernonPlayer.currentSoundHandle != null) {
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      await SoLoud.instance.disposeSource(
        AlgernonPlayer.currentSoundNotifier.source!,
      );
    } else {
      debugPrint(
        "- IGNORING (AlgernonPlayer.currentSoundNotifier.source == null)",
      );
    }

    //while (SoLoud.instance.activeSounds.isNotEmpty) {
    //for (AudioSource source in SoLoud.instance.activeSounds) {
    //  debugPrint(
    //    '- SoLoud.instance.activeSounds.length: ${SoLoud.instance.activeSounds.length}',
    //  );
    //  debugPrint(
    //    '- SoLoud.instance.countAudioSource(source): ${SoLoud.instance.countAudioSource(source)}',
    //  );
    //  debugPrint("- source.soundHash: ${source.soundHash}");
    //  if (SoLoud.instance.countAudioSource(source) > 0) {
    //    //for (SoundHandle handle in source.handles) {
    //    //  debugPrint("  - handle.id: ${handle.id}");
    //    //  await SoLoud.instance.stop(handle);
    //    //}
    //    await SoLoud.instance.disposeSource(source);
    //  }
    //}

    //[0] as AudioSource).handles
    //}
    //await SoLoud.instance.stop(AlgernonPlayer.currentSoundHandle!);

    AlgernonPlayer.currentSoundHandle = null;

    // Set the audio_service state to `idle` to deactivate the notification.
    //_updateProcessingState(AudioProcessingState.idle);
    //}
  }

  AudioProcessingState get audioState => playbackState.value.processingState;

  void updateNotification() {
    _updateNotification();
  }

  Future<void> _initAudioSession() async {
    debugPrint("AlgernonAudioHandler::_initAudioSession()");
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    //await AudioService.init(
    //  builder: () => AlgernonAudioHandler(),
    //  //config: ThirdPartyPackageOptions.audioServiceConfiguration,
    //);
    await AudioService.init(
      builder: () => AlgernonAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'rocks.mm_dev.algernon.audio',
        androidNotificationChannelName: 'Audio Playback',
        // Keep the foreground service alive
        androidNotificationOngoing: true,
        // Keep notification on pause
        //androidStopForegroundOnPause: false,
        notificationColor: Color(0xFF2196F3),
      ),
    );
  }

  /// Start/end of seek is a significant event that we handle in this class.
  //void _startObserverForPlaybackOrSeeking() {
  //  //if (audioPlayer.platform is NativePlayer) {
  //  //  (audioPlayer.platform as NativePlayer).observeProperty(
  //  //    'seeking',
  //  //    _onSeekingStateChange,
  //  //  );
  //  //}
  //}

  //void _cancelObserverForPlaybackOrSeeking() {
  //  //if (audioPlayer.platform is NativePlayer) {
  //  //  (audioPlayer.platform as NativePlayer).unobserveProperty('seeking');
  //  //}
  //}

  /// Update the sytem notification panel (if there is one).
  void _updateNotification() async {
    //if (PlaylistManager.playingBookId.value.isEmpty) {
    //  debugPrint("No book playing - notification not updated");
    //} else {
    //  mediaItem.add(
    //    MediaItem(
    //      id:
    //          PlaylistManager.playingBookId.value +
    //          AudavAudioPlayer.progressNotifier.curChapterIndex.toString(),
    //      album: PlaylistManager.curBookCleanedTitle,
    //      title: PlaylistManager.curChapterTitle,
    //      duration: Duration(
    //        milliseconds: AudavAudioPlayer.progressNotifier.curChapterDuration,
    //      ),
    //      artUri: await _curArtUri,
    //    ),
    //  );
    //}
  }

  /// This is the state the OS will use for info about the audio service, it affects things like the
  /// play/pause buttons in the notification panel. It is also referred to by [PlaybackButton] to
  /// show an appropriate state.
  void _updateProcessingState(AudioProcessingState state) {
    playbackState.add(playbackState.value.copyWith(processingState: state));
  }
}
