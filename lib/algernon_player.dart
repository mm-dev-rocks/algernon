import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/audio_analysis.dart';
import 'package:algernon/audio_source_notifier.dart';
import 'package:algernon/constants.dart';
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

  static Future<void> playSelectedSound({required String reason}) async {
    debugPrint('AlgernonPlayer::playSelectedSound(): $reason');
    await _ensureSoLoudIsInitialised();

    try {
      await AlgernonPlayer.stopAllSounds();

      AlgernonPlayer.currentSoundNotifier.source = await SoLoud.instance
          .loadFile(FileChooser.selectedFilePath);

      await AudioAnalysis.analyseTrackOnLoad(
        filePath: FileChooser.selectedFilePath,
        trackDuration: SoLoud.instance.getLength(
          AlgernonPlayer.currentSoundNotifier.source!,
        ),
      );

      AlgernonPlayer.painterConfig.currentShader.calibrateAudioEnergy();

      if (AlgernonPlayer.currentSoundNotifier.source != null) {
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
    } on SoLoudFileLoadFailedException catch (e) {
      debugPrint('AlgernonPlayer::loadFile error: Problem loading file\n$e');
    } catch (e) {
      debugPrint('AlgernonPlayer::loadFile error:\n$e');
    }
  }

  static Future<void> stopAllSounds() async {
    debugPrint('AlgernonPlayer::stopAllSounds()');
    //if (AlgernonPlayer.currentSoundHandle != null) {
    //  await SoLoud.instance.stop(AlgernonPlayer.currentSoundHandle!);
    //}
    await SoLoud.instance.disposeAllSources();
  }

  //static void setOverallEffectMagnitude(double magnitude) {
  //  debugPrint('AlgernonPlayer::setOverallEffectMagnitude($magnitude)');
  //}

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
    debugPrint('\t${FileChooser.selectedFilePathIndex}');
    //await AlgernonPlayer.stopAllSounds();
    //SoLoud.instance.disposeSource(
    //  AlgernonPlayer.currentSoundNotifier.source!,
    //);
    _trackFinishedSubscription?.cancel();
    FileChooser.selectNextTrack();
    debugPrint('\t${FileChooser.selectedFilePathIndex}');
    await AlgernonPlayer.playSelectedSound(reason: '_onAllInstancesFinished');
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

class _AlgernonPlayerState extends State<AlgernonPlayer>
    with SingleTickerProviderStateMixin {
  //
  /// Tell [SoLoud] how we want to receive audio data
  late final AudioData _audioData = AudioData(GetSamplesKind.linear);

  /// Keep an average of bins to be used for physics 'charges'.
  /// It's an exponential decay average — every past sample is still technically included, but older ones are weighted
  /// exponentially less. With magnitudeChargeSmoothing as α, a value from k frames ago has weight α^k * (1 - α).
  /// There's no fixed window; the "memory" decays toward zero but never fully forgets.
  final Float32List _binExponentialMovingAverages = Float32List(256);

  bool _isProcessing = false;

  late final Ticker _ticker;
  // Frame rate we aim for
  final Duration _fpsAimDuration = const Duration(
    microseconds: 1000000 ~/ ALGERNON.finalAimFps,
  );
  Duration _lastTimestamp = Duration.zero;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    _ticker = createTicker(_onTick);
    _ticker.start();

    AlgernonPlayer.playSelectedSound(reason: 'initState');

    super.initState();
  }

  @override
  dispose() {
    _ticker.stop();
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
            child: GestureDetector(
              onTap: UserInterface.keepControlsAlive,
              child: FittedBox(
                fit: BoxFit.cover,

                /// Main visuals
                /// This [ListenableBuilder] rebuilds whenever any [ShaderTweakModel] changes.
                child: ListenableBuilder(
                  listenable: AlgernonPlayer.painterConfig,
                  builder: (BuildContext context, Widget? child) {
                    return AlgernonShaderPainter(
                      elapsedSeconds: _elapsedSeconds,
                      painterConfig: AlgernonPlayer.painterConfig,
                    );
                  },
                ),
              ),
            ),
          ),
          const UserInterface(),
        ],
      ),
    );
  }

  /// Runs on every tick of [_ticker] as a callback (which works because this widget uses the
  /// [SingleTickerProviderStateMixin]).
  /// Checks if it's time to take the next sample, if so convert the sample to FFT data and change
  /// [_fftDataImageNotifier] which will cause the [AlgernonFragment] widget to rebuild.
  void _onTick(Duration elapsed) async {
    if (!_isProcessing &&
        elapsed - _lastTimestamp >= _fpsAimDuration &&
        context.mounted &&
        AlgernonPlayer.soLoudIsReady) {
      {
        _lastTimestamp = elapsed;
        _isProcessing = true;
        try {
          _audioData.updateSamples();

          _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;

          final oldImage = AlgernonPlayer.painterConfig.fftDataImage;
          AlgernonPlayer.painterConfig.fftDataImage = await _imageFromFftData(
            /// We use `AudioData(GetSamplesKind.linear)`:
            /// `Get data in a linear manner: the first 256 floats are audio FFI values, the other 256 are audio wave samples.`
            ///
            /// FFI (Foreign Function Interface) is how Dart talks to SoLoud's native C++ code. FFI here (from the
            /// asoLoud docs) is either sloppy wording or a typo, but basically the first 256 floats are our FFT bins.
            Float32List.sublistView(_audioData.getAudioData(), 0, 256),
          );
          oldImage?.dispose();
        } on Exception catch (e) {
          debugPrint('$e');
        } finally {
          _isProcessing = false;
        }
      }
    }
  }

  /// We pass data into the shader as an image format, but it isn't an image as such, just an efficient way of passing
  /// our data.
  Future<ui.Image> _shaderImageFromPixels(Float32List pixels) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),

      /// We just pass all data in a single row.
      256,
      1,
      ui.PixelFormat.rgbaFloat32,
      completer.complete,
    );
    return completer.future;
  }

  /// We have 256 bytes of data to pass, each representing a bin we got back from the FFT.
  Future<ui.Image> _imageFromFftData(Float32List fftData) async {
    // 256 pixels, each pixel needs R,G,B,A as floats, each of which is normalised between 0 and 1 (the FFT data is
    // already in that format). We pass FFT bins in via the red channel.
    final pixels = Float32List(256 * 4);

    for (int i = 0; i < 256; i++) {
      final double binMagnitude = fftData[i];

      // Update rolling average
      _binExponentialMovingAverages[i] =
          _binExponentialMovingAverages[i] * ALGERNON.magnitudeChargeSmoothing +
          binMagnitude * (1.0 - ALGERNON.magnitudeChargeSmoothing);

      // Signed charge: positive when louder than average, negative when quieter
      // clamp to [-1, 1] then remap to [0, 1] for the texture
      final double charge = (binMagnitude - _binExponentialMovingAverages[i])
          .clamp(-1.0, 1.0);
      final double chargeNormalised = (charge + 1.0) * 0.5;
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

    return await _shaderImageFromPixels(pixels);
  }
}
