import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_audio_handler.dart';
import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/audio_analysis.dart';
import 'package:algernon/audio_source_notifier.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:algernon/file_chooser.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/playlist_notifier.dart';
import 'package:algernon/resolution_changer.dart';
import 'package:algernon/sequencing.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AlgernonPlayer extends StatefulWidget {
  const AlgernonPlayer({super.key});

  static PlaylistNotifier playlistNotifier = PlaylistNotifier();

  static SoundHandle? currentSoundHandle;
  static AudioSource? _preloadedSource;
  static String? _preloadedFilepath;

  static AudioSourceNotifier currentSoundNotifier = AudioSourceNotifier();

  static ValueNotifier<bool> playbackControlsEnabledNotifier = ValueNotifier(
    true,
  );

  static StreamSubscription? _trackFinishedSubscription;

  /// [PainterConfigModel] holds all the info used to draw/update the [AlgernonShaderPainter], including the
  /// constantly-updating FFT data. It is a [ChangeNotifier] and changing its properties will cause
  /// [AlgernonShaderPainter] to rebuild.
  static final PainterConfigModel painterConfig = PainterConfigModel();

  static Future<void> playSelectedSound({required String reason}) async {
    AlgernonPlayer.playbackControlsEnabledNotifier.value = false;
    debugPrint('AlgernonPlayer::playSelectedSound(): $reason');

    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      try {
        await AlgernonPlayer.stopCurrentSound();
      } catch (e) {
        exit(1);
      }

      debugPrint(
        '0. AlgernonPlayer._preloadedSource:\n\t${AlgernonPlayer._preloadedSource}',
      );
      debugPrint(
        '1. AlgernonPlayer.currentSoundNotifier.source:\n\t${AlgernonPlayer.currentSoundNotifier.source}',
      );
      if (AlgernonPlayer._preloadedSource != null &&
          AlgernonPlayer._preloadedFilepath ==
              AlgernonPlayer.playlistNotifier.selectedFilePath) {
        AlgernonPlayer.currentSoundNotifier.source =
            AlgernonPlayer._preloadedSource;
      } else {
        AlgernonPlayer.currentSoundNotifier.source =
            await AlgernonPlayer._loadFile(
              AlgernonPlayer.playlistNotifier.selectedFilePath,
            );
      }
      debugPrint(
        '2. AlgernonPlayer.currentSoundNotifier.source:\n\t${AlgernonPlayer.currentSoundNotifier.source}',
      );
      AlgernonPlayer._preloadedSource = null;

      if (AlgernonPlayer.currentSoundNotifier.source != null) {
        stopwatch.reset();
        stopwatch.start();
        AlgernonPlayer.currentSoundHandle = await AlgernonAudioHandler.instance
            .play();
        debugPrint(
          'AlgernonAudioHandler.instance.play took ${stopwatch.elapsedMilliseconds}ms',
        );

        stopwatch.reset();
        stopwatch.start();
        await _startListeningForTrackFinished();
        debugPrint(
          'AlgernonPlayer._startListeningForTrackFinished() took ${stopwatch.elapsedMilliseconds}ms',
        );
        Sequencing.startListening(
        );

        await _calibrateCurrentTrack();
        await _preloadNextTrack();
      }
    } on SoLoudNotInitializedException catch (e) {
      debugPrint(
        'AlgernonPlayer::loadFile error: SoLoud Engine is not yet initialised\n$e',
      );
    } on SoLoudFileNotFoundException catch (e) {
      debugPrint('AlgernonPlayer::loadFile error: File not found\n$e');
      FileChooser.setCurrentItemIsMissing();
      FileChooser.selectNext();
    } on SoLoudFileLoadFailedException catch (e) {
      debugPrint('AlgernonPlayer::loadFile error: Problem loading file\n$e');
      FileChooser.setCurrentItemIsUnplayable();
      FileChooser.selectNext();
    } catch (e) {
      debugPrint('AlgernonPlayer::loadFile error:\n$e');
    }

    /// Start unpaused
    await AlgernonPlayer.currentSoundNotifier.togglePause(forcedState: false);
    AlgernonPlayer.playbackControlsEnabledNotifier.value = true;
  }

  static Future<AudioSource?> _loadFile(String filepath) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    AudioSource source = await SoLoud.instance.loadFile(filepath);
    debugPrint(
      'AlgernonPlayer._loadFile() took ${stopwatch.elapsedMilliseconds}ms',
    );
    return source;
  }

  static Future<void> stopCurrentSound() async {
    debugPrint('AlgernonPlayer::stopCurrentSound()');

    await _trackFinishedSubscription?.cancel();

    await AlgernonAudioHandler.instance.stop();

    await _disposeSourceIfNotNull(AlgernonPlayer.currentSoundNotifier.source);

    if (SoLoud.instance.getActiveVoiceCount() > 0) {
      throw (Exception('STILL PLAYING SOUNDS!!!!'));
    }
  }

  static Future<void> _disposeSourceIfNotNull(AudioSource? source) async {
    if (source != null) {
      await SoLoud.instance.disposeSource(source);
    }
  }

  static Future<void> _calibrateCurrentTrack() async {
    debugPrint('AlgernonPlayer::_calibrateCurrentTrack()');
    final Stopwatch stopwatch = Stopwatch()..start();
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      await AudioAnalysis.analyseTrackOnLoad(
        filePath: AlgernonPlayer.playlistNotifier.selectedFilePath,
        trackDuration: SoLoud.instance.getLength(
          AlgernonPlayer.currentSoundNotifier.source!,
        ),
      );
      AlgernonPlayer.painterConfig.currentShader.calibrateAudioEnergy();
    }
    debugPrint(
      'AlgernonPlayer._calibrateCurrentTrack() took ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  static Future<void> _preloadNextTrack() async {
    debugPrint('AlgernonPlayer::_preloadNextTrack()');
    await _disposeSourceIfNotNull(AlgernonPlayer._preloadedSource);
    AlgernonPlayer._preloadedFilepath = null;
    AlgernonPlayer._preloadedSource = null;

    int nextPlayableIndex = AlgernonPlayer.playlistNotifier.nextPlayableIndex;
    if (nextPlayableIndex != -1) {
      final Stopwatch stopwatch = Stopwatch()..start();
      debugPrint('- Preloading [$nextPlayableIndex]');
      AlgernonPlayer._preloadedFilepath = AlgernonPlayer
          .playlistNotifier
          .currentPlaylist[nextPlayableIndex]
          .filepath;
      if (AlgernonPlayer._preloadedFilepath != null) {
        AlgernonPlayer._preloadedSource = await AlgernonPlayer._loadFile(
          AlgernonPlayer._preloadedFilepath!,
        );
      }
      debugPrint(
        '- SoLoud.instance.loadFile took ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  static Future<void> _startListeningForTrackFinished() async {
    debugPrint('AlgernonPlayer::_startListeningForTrackFinished()');
    await _trackFinishedSubscription?.cancel();
    if (AlgernonPlayer.currentSoundNotifier.source != null) {
      _trackFinishedSubscription = AlgernonPlayer
          .currentSoundNotifier
          .source!
          .allInstancesFinished
          .listen(_onAllInstancesFinished);
    }
  }

  static Future<void> _onAllInstancesFinished(_) async {
    debugPrint('AlgernonPlayer::_onAllInstancesFinished()');
    debugPrint('\t${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}');
    Sequencing.stopListening();
    await AlgernonPlayer.currentSoundNotifier.togglePause(forcedState: true);
    _trackFinishedSubscription?.cancel();
    switch (AlgernonPlayer.currentSoundNotifier.loopType) {
      case LoopType.all:
        FileChooser.selectNext();
        await AlgernonPlayer.playSelectedSound(
          reason: '_onAllInstancesFinished',
        );
      case LoopType.one:
        // No change in file, so will loop current track
        await AlgernonPlayer.playSelectedSound(
          reason: '_onAllInstancesFinished',
        );
      case LoopType.none:
        debugPrint(
          '\tFileChooser.currentTrackIsLast: ${FileChooser.currentTrackIsLast}',
        );
        if (!FileChooser.currentTrackIsLast) {
          FileChooser.selectNext();
          await AlgernonPlayer.playSelectedSound(
            reason: '_onAllInstancesFinished',
          );
        }
        break;
    }
    debugPrint('\t${AlgernonPlayer.playlistNotifier.selectedFilePathIndex}');
  }

  @override
  State<AlgernonPlayer> createState() => _AlgernonPlayerState();
}

class _AlgernonPlayerState extends State<AlgernonPlayer> {
  //
  /// Tell [SoLoud] how we want to receive audio data
  late final AudioData _audioData = AudioData(GetSamplesKind.linear);

  /// Keep an average of bins to be used for physics 'charges'.
  /// It's an exponential decay average — every past sample is still technically included, but older ones are weighted
  /// exponentially less. With binEmaSmoothing as α, a value from k frames ago has weight α^k * (1 - α).
  /// There's no fixed window; the "memory" decays toward zero but never fully forgets.
  final Float32List _binExponentialMovingAverages = Float32List(256);
  final Float32List _binChargeSmoothed = Float32List(256);

  bool _isProcessing = false;

  late final Timer _tickTimer;

  @override
  void initState() {
    _tickTimer = Timer.periodic(
      Duration(
        microseconds: (ALGERNON.oneMillion / ALGERNON.finalAimFps).toInt(),
      ),
      _onTick,
    );

    //AlgernonPlayer.playSelectedSound(reason: 'initState');

    SchedulerBinding.instance.addTimingsCallback(
      ResolutionChanger.onFrameTimings,
    );

    super.initState();
  }

  @override
  dispose() {
    SchedulerBinding.instance.removeTimingsCallback(
      ResolutionChanger.onFrameTimings,
    );
    _tickTimer.cancel();
    ResolutionChanger.dispose();
    _audioData.dispose();
    AlgernonPlayer.painterConfig.dispose();
    SoLoud.instance.deinit();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AlgernonPlayer::build()');

    return MouseRegion(
      onHover: (_) {
        UserInterface.keepControlsAlive();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: UserInterface.isVisibleNotifier,
              builder: (context, value, child) {
                return GestureDetector(
                  onTap: UserInterface.isVisibleNotifier.value
                      ? UserInterface.hideControls
                      : UserInterface.keepControlsAlive,
                  child: FittedBox(
                    fit: BoxFit.cover,

                    /// Main visuals
                    /// This [ListenableBuilder] rebuilds whenever any [ShaderTweakModel] changes.
                    child: ListenableBuilder(
                      listenable: AlgernonPlayer.painterConfig,
                      builder: (BuildContext context, Widget? child) {
                        return AlgernonShaderPainter(
                          elapsedSeconds:
                              (AlgernonPlayer.currentSoundHandle != null
                                      ? SoLoud.instance
                                                .getPosition(
                                                  AlgernonPlayer
                                                      .currentSoundHandle!,
                                                )
                                                .inMicroseconds /
                                            ALGERNON.oneMillion
                                      : 0)
                                  .toDouble(),

                          painterConfig: AlgernonPlayer.painterConfig,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const UserInterface(),
        ],
      ),
    );
  }

  /// The beating heart of the audio animation
  void _onTick(Timer timer) async {
    if (!_isProcessing && context.mounted && SoLoud.instance.isInitialized) {
      {
        _isProcessing = true;
        try {
          await _updatePainterDataImage();
        } on Exception catch (e) {
          debugPrint('$e');
        } finally {
          _isProcessing = false;
        }
      }
    }
  }

  /// That's a real lead. PixelFormat.rgbaFloat32 with decodeImageFromPixels — there's a known Flutter issue: decodeImageFromPixels float32 does not work correctly in Impeller. GitHubThat's a real lead. PixelFormat.rgbaFloat32 with decodeImageFromPixels — there's a known Flutter issue: decodeImageFromPixels float32 does not work correctly in Impeller. GitHub
  /// You lose some precision (8-bit vs 32-bit per channel), but for FFT visualisation that's unlikely to matter perceptually.
  Future<ui.Image> _shaderImageFromPixels(Float32List pixels) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();

    // Convert float32 [0,1] to uint8 [0,255]
    final bytes = Uint8List(256 * 4);
    for (int i = 0; i < pixels.length; i++) {
      bytes[i] = (pixels[i] * 255).clamp(0, 255).toInt();
    }

    ui.decodeImageFromPixels(
      bytes,
      256,
      1,
      ui.PixelFormat.rgba8888,
      (ui.Image image) => completer.complete(image),
    );
    return completer.future;
  }

  /// We have 256 bytes of data to pass, each representing a bin we got back from the FFT.
  Future<void> _updatePainterDataImage() async {
    /// Get FFT data bins.
    ///
    /// We use `AudioData(GetSamplesKind.linear)`:
    /// `Get data in a linear manner: the first 256 floats are audio FFI values, the other 256 are audio wave samples.`
    ///
    /// FFI (Foreign Function Interface) is how Dart talks to SoLoud's native C++ code. FFI here (from the
    /// soLoud docs) is either sloppy wording or a typo, but basically the first 256 floats are our FFT bins.
    _audioData.updateSamples();
    Float32List fftData = Float32List.sublistView(
      _audioData.getAudioData(),
      0,
      256,
    );

    /// Store data for the shader in pixels.
    ///
    // 256 pixels, each pixel needs R,G,B,A as floats, each of which is normalised between 0 and 1 (the FFT data is
    // already in that format). We pass FFT bins in via the red channel.
    final pixels = Float32List(256 * 4);

    for (int i = 0; i < 256; i++) {
      final double binMagnitude = fftData[i];

      // Update rolling average
      _binExponentialMovingAverages[i] =
          _binExponentialMovingAverages[i] * ALGERNON.binEmaSmoothing +
          binMagnitude * (1.0 - ALGERNON.binEmaSmoothing);

      // Raw charge
      final double rawCharge = (binMagnitude - _binExponentialMovingAverages[i])
          .clamp(-1.0, 1.0);

      // Smooth the charge itself
      _binChargeSmoothed[i] =
          _binChargeSmoothed[i] * ALGERNON.binChargeSmoothing +
          rawCharge * (1.0 - ALGERNON.binChargeSmoothing);

      final double chargeNormalised = (_binChargeSmoothed[i] + 1.0) * 0.5;
      final double energy = AlgernonPlayer.currentSoundHandle == null
          ? 0
          : AudioAnalysis.normalisedEnergyValueAtPosition(
              playbackPosition: SoLoud.instance.getPosition(
                AlgernonPlayer.currentSoundHandle!,
              ),
            );

      // R: raw bin FFT bin magnitude
      pixels[i * 4 + 0] = binMagnitude;
      // G: signed charge
      pixels[i * 4 + 1] = chargeNormalised;
      // B: energy from quantised buckets
      pixels[i * 4 + 2] = energy;
      // Alpha full
      pixels[i * 4 + 3] = 1.0;
    }

    AlgernonPlayer.painterConfig.fftDataImage = await _shaderImageFromPixels(
      pixels,
    );
  }
}
