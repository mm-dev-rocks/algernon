import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/audio_analysis.dart';
import 'package:algernon/audio_source_notifier.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:algernon/file_chooser.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AlgernonPlayer extends StatefulWidget {
  const AlgernonPlayer({super.key});

  static SoundHandle? currentSoundHandle;

  static bool get soLoudIsReady =>
      SoLoud.instance.isInitialized &&
      SoLoud.instance.getVisualizationEnabled();

  static AudioSourceNotifier currentSoundNotifier = AudioSourceNotifier();

  static StreamSubscription? _trackFinishedSubscription;

  /// [PainterConfigModel] holds all the info used to draw/update the [AlgernonShaderPainter], including the
  /// constantly-updating FFT data. It is a [ChangeNotifier] and changing its properties will cause
  /// [AlgernonShaderPainter] to rebuild.
  static final PainterConfigModel painterConfig = PainterConfigModel();

  static Timer? _resChangeLockoutTimer;
  static bool _resChangeEnabled = true;
  static int _resRaisedLockoutSecs = ALGERNON.resRaisedLockoutSecs;
  static DirectionOfChange _lastResolutionChange = DirectionOfChange.none;
  static void resetResChangeLockout() {
    debugPrint('AlgernonPlayer::_resetResChangeLockout()');
    AlgernonPlayer._lastResolutionChange = DirectionOfChange.none;
    AlgernonPlayer._resRaisedLockoutSecs = ALGERNON.resRaisedLockoutSecs;
    AlgernonPlayer._resChangeLockoutTimer?.cancel();
    AlgernonPlayer._resChangeEnabled = true;
  }

  static Future<void> playSelectedSound({required String reason}) async {
    debugPrint('AlgernonPlayer::playSelectedSound(): $reason');
    await _ensureSoLoudIsInitialised();

    try {
      await AlgernonPlayer.stopAllSounds();

      AlgernonPlayer.currentSoundNotifier.source = await SoLoud.instance
          .loadFile(FileChooser.playlistNotifier.selectedFilePath);

      if (AlgernonPlayer.currentSoundNotifier.source != null) {
        await AudioAnalysis.analyseTrackOnLoad(
          filePath: FileChooser.playlistNotifier.selectedFilePath,
          trackDuration: SoLoud.instance.getLength(
            AlgernonPlayer.currentSoundNotifier.source!,
          ),
        );

        AlgernonPlayer.painterConfig.currentShader.calibrateAudioEnergy();

        AlgernonPlayer.currentSoundHandle = SoLoud.instance.play(
          AlgernonPlayer.currentSoundNotifier.source!,
        );
        await _startListeningForTrackFinished();
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
    AlgernonPlayer.currentSoundNotifier.togglePause(forcedState: false);
  }

  static Future<void> stopAllSounds() async {
    debugPrint('AlgernonPlayer::stopAllSounds()');
    await SoLoud.instance.disposeAllSources();
  }

  static Future<void> _startListeningForTrackFinished() async {
    debugPrint('AlgernonPlayer::_startListeningForTrackFinished()');
    await _trackFinishedSubscription?.cancel();
    _trackFinishedSubscription = AlgernonPlayer
        .currentSoundNotifier
        .source!
        .allInstancesFinished
        .listen(_onAllInstancesFinished);
  }

  static Future<void> _onAllInstancesFinished(_) async {
    debugPrint('AlgernonPlayer::_onAllInstancesFinished()');
    debugPrint('\t${FileChooser.playlistNotifier.selectedFilePathIndex}');
    AlgernonPlayer.currentSoundNotifier.togglePause(forcedState: true);
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
    debugPrint('\t${FileChooser.playlistNotifier.selectedFilePathIndex}');
  }

  static Future<void> _ensureSoLoudIsInitialised() async {
    if (!AlgernonPlayer.soLoudIsReady) {
      await SoLoud.instance.init(bufferSize: ALGERNON.soLoudBufferSize);
      SoLoud.instance.setVisualizationEnabled(true);
    }
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

  // Frame rate we aim for
  final Duration _fpsAimDuration = const Duration(
    microseconds: ALGERNON.oneMillion ~/ ALGERNON.finalAimFps,
  );
  final List<bool> _lateFrameMeasurement = List<bool>.generate(
    ALGERNON.droppedFrameMeasurementLength,
    (index) => false,
  );

  @override
  void initState() {
    _tickTimer = Timer.periodic(
      Duration(
        microseconds: (ALGERNON.oneMillion / ALGERNON.finalAimFps).toInt(),
      ),
      _onTick,
    );

    AlgernonPlayer.playSelectedSound(reason: 'initState');

    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    super.initState();
  }

  @override
  dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _tickTimer.cancel();
    AlgernonPlayer._resChangeLockoutTimer?.cancel();
    _audioData.dispose();
    AlgernonPlayer.painterConfig.dispose();
    SoLoud.instance.deinit();

    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (AlgernonPlayer._resChangeEnabled) {
      for (final t in timings) {
        final bool isLate = t.rasterDuration > _fpsAimDuration;
        _checkFrameRate(isLate);
      }
    }
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
              valueListenable: UserInterface.controlsAreVisibleNotifier,
              builder: (context, value, child) {
                return GestureDetector(
                  onTap: UserInterface.controlsAreVisibleNotifier.value
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
    if (!_isProcessing && context.mounted && AlgernonPlayer.soLoudIsReady) {
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

  void _checkFrameRate(bool isLate) {
    /// Roll along
    _lateFrameMeasurement.removeAt(0);
    _lateFrameMeasurement.add(isLate);

    double droppedFrameRatio =
        _lateFrameMeasurement
            .where((bool frameWasLate) => frameWasLate == true)
            .length /
        _lateFrameMeasurement.length;

    if (droppedFrameRatio > 0.95) {
      debugPrint(droppedFrameRatio.toString());
      _changeResolution(DirectionOfChange.decrease);
    } else if (droppedFrameRatio < 0.005) {
      debugPrint(droppedFrameRatio.toString());
      _changeResolution(DirectionOfChange.increase);
    }
  }

  void _changeResolution(DirectionOfChange direction) {
    int lockoutSeconds = 0;
    //if (direction != _lastResolutionChange) {
    if (direction == DirectionOfChange.increase) {
      lockoutSeconds = AlgernonPlayer._resRaisedLockoutSecs;
      AlgernonPlayer.painterConfig.increaseResolution();
    } else if (direction == DirectionOfChange.decrease) {
      lockoutSeconds = ALGERNON.resLoweredLockoutSecs;

      /// Res has already gone up and then down again, so lockout for longer next time.
      if (AlgernonPlayer._lastResolutionChange == DirectionOfChange.increase) {
        AlgernonPlayer._resRaisedLockoutSecs *= 2;
      }
      AlgernonPlayer.painterConfig.decreaseResolution();
    }
    debugPrint(
      'SCALE CHANGE: ${AlgernonPlayer.painterConfig.scale.toString()}',
    );

    for (var i = 0; i < ALGERNON.droppedFrameMeasurementLength; i++) {
      //_lateFrameMeasurement[i] = false;

      /// Set alternating true/false to put ratio in the middle
      _lateFrameMeasurement[i] = i.isEven;
    }
    AlgernonPlayer._lastResolutionChange = direction;

    _lockoutResChange(lockoutSeconds);
  }

  void _lockoutResChange(int seconds) {
    debugPrint('AlgernonPlayer::_lockoutResChange($seconds)');
    AlgernonPlayer._resChangeEnabled = false;
    AlgernonPlayer._resChangeLockoutTimer?.cancel();
    AlgernonPlayer._resChangeLockoutTimer = Timer(
      Duration(seconds: seconds),
      () {
        AlgernonPlayer._resChangeEnabled = true;
      },
    );
  }

  /// We pass data into the shader as an image format, but it isn't an image as such, just an efficient way of passing
  /// our data.
  Future<ui.Image> _shaderImageFromPixels(Float32List pixels) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),

      /// We just pass all data in a single row.
      256,
      1,
      ui.PixelFormat.rgbaFloat32,
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
