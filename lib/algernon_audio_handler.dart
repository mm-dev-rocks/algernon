// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/file_chooser.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../app_state.dart';

/// This class (via its [Player] instance) handles everything to do with actually playing/pausing
/// audio and similar functionality. Other classes must use methods from this class to do these
/// things (so eg a 'play' button must call [play] in this class). These methods will ensure that
/// integration with the system happens correctly (eg icons and controls being shown in the
/// notification panel), and due to the use of [AudioService], will automatically be called by
/// system actions outside the app. So for instance if a user clicks a 'skip next' button on a
/// headset, [skipToNext] in this class will get called.

/// The other main classes which related to audio playback are [AlgernonAudioHandler], which manages
/// other things such as farming out events and processes related to the app UI (buffer bars,
/// button state etc), and [AudavAudioSeeker], which does similar things but specifically related to
/// the 'seek within a track' process.
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

  ///

  bool _firstTimeInitIsDone = false;
  void _firstTimeInit() {
    _firstTimeInitIsDone = true;
  }

  Future<void> dispose() async {
    await pause();
    await stop();
    //await AudavAudioObserver.stopPlaybackListeners();
    //await AudavAudioObserver.stopPermanentListeners();
    //_cancelObserverForPlaybackOrSeeking();
  }

  /// Open a file ready for playing. If [startPlaying] is true then play it straight away, otherwise
  /// wait for [play()] to be called manually.
  Future<void> open({
    required String filepath,
    required bool startPlaying,
  }) async {
    if (!_firstTimeInitIsDone) _firstTimeInit();

    //_updateProcessingState(AudioProcessingState.loading);

    try {
      //_webdavHeaders ??= await WebDav.getDefaultHeaders();
      //await audioPlayer.open(
      //  Media(
      //    ServerFunctions.decodedFilepath(filepath),
      //    httpHeaders: _webdavHeaders,
      //  ),
      //  play: startPlaying,
      //);
      //_updateProcessingState(AudioProcessingState.ready);

      /// Ensure state matches
      playbackState.add(playbackState.value.copyWith(playing: startPlaying));
    } catch (e) {
      AppState.log('•☽────✧˖°˖☆˖°˖✧────☾•');
      AppState.log('[_audioHandler.open()] ERROR: $e\n\n');
    }
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

  @override
  Future<void> pause() async {
    AppState.log("AlgernonAudioHandler::pause()");

    //await AudavAudioObserver.stopPlaybackListeners();

    //await audioPlayer.pause();
    if (AlgernonPlayer.currentSoundHandle != null) {
      SoLoud.instance.setPause(AlgernonPlayer.currentSoundHandle!, true);
    }

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
      ),
    );

    //_updateProcessingState(AudioProcessingState.ready);
  }

  @override
  Future<void> play() async {
    AppState.log("AlgernonAudioHandler::play()");

    /// Start the listeners here **if we are not in the middle of a seek**. If we are seeking, trust
    /// the _onSeekingStateChange handler to start them when the seek is complete.
    //if (!AudavAudioSeeker.isSeeking) {
    //  AudavAudioObserver.startPlaybackListeners(
    //    AudavAudioPlayer.currentPlaybackToken,
    //  );
    //}

    //await audioPlayer.play();
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      AlgernonPlayer.currentSoundHandle = SoLoud.instance.play(AlgernonPlayer.currentSoundNotifier.source!);
    }

    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
      ),
    );

    //_updateProcessingState(AudioProcessingState.ready);
    //AudavAudioObserver.startPlaybackListeners();
  }

  Future<void> togglePause() async {
    AppState.log("AlgernonAudioHandler::playOrPause()");
    if (instance.playbackState.value.playing) {
      await instance.pause();
    } else {
      await instance.play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    //_updateProcessingState(AudioProcessingState.buffering);
    SoLoud.instance.seek(AlgernonPlayer.currentSoundHandle!, position);
  }

  @override
  Future<void> skipToNext() async {
    FileChooser.selectNext();
    await AlgernonPlayer.playSelectedSound(
      reason: 'UserInterface::skipNext button',
    );
  }

  @override
  Future<void> skipToPrevious() async {
    FileChooser.selectPrev();
    await AlgernonPlayer.playSelectedSound(
      reason: 'UserInterface::skipPrevious button',
    );
  }

  @override
  Future<void> stop() async {
    AppState.log("AlgernonAudioHandler::stop()");
    if (AlgernonPlayer.currentSoundHandle != null) {
      await SoLoud.instance.stop(AlgernonPlayer.currentSoundHandle!);
      AlgernonPlayer.currentSoundHandle = null;
    }
    //AudavAudioPlayer.stopHousekeepingTimers();
    //await audioPlayer.stop();

    // Set the audio_service state to `idle` to deactivate the notification.
    //_updateProcessingState(AudioProcessingState.idle);
  }

  //static AudioProcessingState get audioState =>
  //    instance.playbackState.value.processingState;

  static void updateNotification() {
    instance._updateNotification();
  }

  Future<void> _initAudioSession() async {
    AppState.log("AlgernonAudioHandler::_initAudioSession()");
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await AudioService.init(
      builder: () => AlgernonAudioHandler(),
      //config: ThirdPartyPackageOptions.audioServiceConfiguration,
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
    //  AppState.log("No book playing - notification not updated");
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
  //static _updateProcessingState(AudioProcessingState state) {
  //  instance.playbackState.add(
  //    instance.playbackState.value.copyWith(processingState: state),
  //  );
  //}
}
