// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
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
    _initSoLoud();
  }
  static final AlgernonAudioHandler instance = AlgernonAudioHandler._internal();

  // Other classes will get the singleton when they call [AlgernonAudioHandler()].
  factory AlgernonAudioHandler() => instance;

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

  Future<void> _initAudioSession() async {
    debugPrint("AlgernonAudioHandler::_initAudioSession()");
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await AudioService.init(
      builder: () => AlgernonAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'rocks.mm_dev.algernon.audio',
        androidNotificationChannelName: 'Algernon Visualiser Audio Playback',
        // Keep the foreground service alive
        androidNotificationOngoing: true,
        // Keep notification on pause
        //androidStopForegroundOnPause: false,
        notificationColor: Colors.black,
        androidNotificationIcon: 'mipmap/algernon-icon-monochrome.png',
      ),
    );
    isIdle = true;
  }

  void _initSoLoud() async {
    await SoLoud.instance.init(bufferSize: ALGERNON.soLoudBufferSize);
    SoLoud.instance.setVisualizationEnabled(true);
  }

  Future<void> dispose() async {
    debugPrint("AlgernonAudioHandler::dispose()");
    await pause();
    await stop();
  }

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
      isPlaying = true;
      isIdle = false;
      SoLoud.instance.setPause(AlgernonPlayer.currentSoundHandle!, false);
    } else {
      debugPrint("- IGNORING (AlgernonPlayer.currentSoundHandle == null)");
    }
  }

  @override
  Future<void> pause() async {
    debugPrint("AlgernonAudioHandler::pause()");

    if (AlgernonPlayer.currentSoundHandle != null) {
      isPlaying = false;
      isIdle = false;
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
    SoundHandle? handle;

    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      isPlaying = true;
      isIdle = false;
      handle = SoLoud.instance.play(
        AlgernonPlayer.currentSoundNotifier.source!,
      );
    } else {
      debugPrint("- IGNORING (AlgernonPlayer.currentSoundHandle == null)");
    }

    return handle;
  }

  Future<void> togglePause() async {
    debugPrint("AlgernonAudioHandler::togglePause()");
    await (isPlaying
        ? pause()
        : (!isPlaying && isIdle)
        ? AlgernonPlayer.playSelectedSound(
            reason: "AlgernonAudioHandler::togglePause but no track loaded",
          )
        : unpause());
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
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      isPlaying = false;
      isIdle = true;
      await SoLoud.instance.disposeSource(
        AlgernonPlayer.currentSoundNotifier.source!,
      );
    } else {
      debugPrint(
        "- IGNORING (AlgernonPlayer.currentSoundNotifier.source == null)",
      );
    }

    AlgernonPlayer.currentSoundHandle = null;
  }

  AudioProcessingState get audioState => playbackState.value.processingState;

  /// Update the sytem notification panel (if there is one).
  void updateNotification() async {
    mediaItem.add(
      MediaItem(
        id: AlgernonPlayer.playlistNotifier.selectedItem.filepath,
        //album: PlaylistManager.curBookCleanedTitle,
        title: AlgernonPlayer.playlistNotifier.selectedItem.title,
        duration: AlgernonPlayer.currentSoundNotifier.source == null
            ? Duration.zero
            : SoLoud.instance.getLength(
                AlgernonPlayer.currentSoundNotifier.source!,
              ),
        //artUri: await _curArtUri,
      ),
    );
  }

  bool get isPlaying => playbackState.value.playing;

  set isPlaying(bool isPlaying) {
    playbackState.add(
      playbackState.value.copyWith(
        playing: isPlaying,
        controls: isPlaying ? controlsPlaying : controlsPaused,
      ),
    );
  }

  /// This is the state the OS will use for info about the audio service, it affects things like the
  /// play/pause buttons in the notification panel. It is also referred to by [PlaybackButton] to
  /// show an appropriate state.
  bool get isIdle =>
      playbackState.value.processingState == AudioProcessingState.idle;

  set isIdle(bool isIdle) {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: isIdle
            ? AudioProcessingState.idle
            : AudioProcessingState.ready,
      ),
    );
  }
}
