// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/shader_meta_model.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:algernon/shader_tweak_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AlgernonPlayer extends StatefulWidget {
  const AlgernonPlayer({super.key});

  @override
  State<AlgernonPlayer> createState() => _AlgernonPlayerState();
}

class _AlgernonPlayerState extends State<AlgernonPlayer>
    with SingleTickerProviderStateMixin {
  //
  /// Initialise SoLoud and tell it how we want to receive audio data
  final _soLoud = SoLoud.instance;
  late final AudioData _audioData = AudioData(GetSamplesKind.linear);

  bool get _soLoudIsReady =>
      _soLoud.isInitialized && _soLoud.getVisualizationEnabled();

  /// [PainterConfigModel] holds all the info used to draw/update the [AlgernonShaderPainter], including the
  /// constantly-updating FFT data. It is a [ChangeNotifier] and changing its properties will cause
  /// [AlgernonShaderPainter] to rebuild.
  final PainterConfigModel _painterConfig = PainterConfigModel();

  /// _zeroImage is a placeholder for when we don't have any audio data (eg on first start).
  late ui.Image? _zeroImage;
  bool _zeroImageExists = false;

  bool _isProcessing = false;

  late final Ticker _ticker;
  // Frame rate we aim for
  final Duration _fpsAimDuration = const Duration(
    microseconds: 1000000 ~/ ALGERNON.finalAimFps,
  );
  Duration _lastTimestamp = Duration.zero;

  @override
  void initState() {
    _ticker = createTicker(_onTick);
    _ticker.start();

    /// [initState] can't be async, so we send image creation off as a microtask which will be carried out after the
    /// current flow of execution.
    Future<void>.microtask(() async {
      _zeroImage = await _getZeroImage();
      _zeroImageExists = true;
    });

    super.initState();
  }

  @override
  dispose() {
    _ticker.stop();
    _audioData.dispose();
    _painterConfig.dispose();
    _soLoud.deinit();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShaderTweakModel fftSmoothingTweak = _painterConfig
        .currentShaderMeta
        .shaderTweaks[TweakType.fftDataSmoothing.name]!;

    return Stack(
      children: [
        /// Main visuals
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: ListenableBuilder(
              listenable: _painterConfig,
              builder: (BuildContext context, Widget? child) {
                return _zeroImageExists
                    ? AlgernonShaderPainter(
                        fftDataTexture:
                            _painterConfig.fftDataImage ?? _zeroImage!,
                        shaderMeta: _painterConfig.currentShaderMeta,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),

        /// Shader select/dropdown
        Positioned.directional(
          textDirection: TextDirection.ltr,
          bottom: 0,
          start: 0,
          end: 0,
          child: Row(
            children: [
              DropdownButton<ShaderMetaModel>(
                dropdownColor: Colors.transparent,
                style: const TextStyle(color: Colors.white),
                value: _painterConfig.currentShaderMeta,
                onChanged: (ShaderMetaModel? value) {
                  setState(() {
                    _painterConfig.currentShaderMeta = value!;
                  });
                },
                items: ALGERNON.shadersMetadata
                    .map<DropdownMenuItem<ShaderMetaModel>>((
                      ShaderMetaModel shaderMeta,
                    ) {
                      return DropdownMenuItem<ShaderMetaModel>(
                        value: shaderMeta,
                        child: Text(shaderMeta.friendlyName),
                      );
                    })
                    .toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _initialiseSoundAndPlay,
                child: const Text('PLAY'),
              ),
            ],
          ),
        ),

        /// Shader-specific sliders
        Positioned.directional(
          textDirection: TextDirection.ltr,

          /// TODO magic number
          top: 100,
          start: 0,
          child: Column(
            /// TODO magic number
            spacing: 30,
            children: [
              ..._painterConfig.currentShaderMeta.shaderTweaks.entries
                  .where(
                    (MapEntry<String, ShaderTweakModel> entry) =>
                        entry.value.tweakType != TweakType.fftDataSmoothing,
                  )
                  .map(
                    (MapEntry<String, ShaderTweakModel> entry) =>
                        ShaderTweakSlider(
                          shaderTweak: entry.value,
                          name: entry.value.tweakType.label,
                          onChanged: (double value) {
                            if (_soLoudIsReady) {
                              setState(() {
                                entry.value.currentVal = value;
                              });
                            }
                          },
                        ),
                  ),
            ],
          ),
        ),
        Positioned.directional(
          textDirection: TextDirection.ltr,
          top: 0,
          start: 0,
          end: 0,
          child: Row(
            children: [
              Expanded(
                child: ShaderTweakSlider(
                  shaderTweak: fftSmoothingTweak,
                  name: TweakType.fftDataSmoothing.label,
                  onChanged: (double value) {
                    if (_soLoudIsReady) {
                      setState(() {
                        fftSmoothingTweak.currentVal = value;
                        _soLoud.setFftSmoothing(fftSmoothingTweak.currentVal);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _initialiseSoundAndPlay() async {
    await _soLoud.init(bufferSize: 256);
    _soLoud.setVisualizationEnabled(true);

    await _soLoud.playSource(
      asset: 'assets/Public Image Limited - Rise.mp3',
      //asset: 'assets/South Street Player - Who Keeps Changing Your Mind.mp3',
      //asset: 'assets/Bob Dylan - Eternal Circle.mp3',
      //asset: 'assets/Pointer Sisters - Automatic.mp3',
      //volume: 0.1,
      looping: true,
    );
    //await _soLoud.playSource(asset: 'assets/Eternal Circle.mp3', looping: true);
  }

  /// Runs on every tick of [_ticker] as a callback (which works because this widget uses the
  /// [SingleTickerProviderStateMixin]).
  /// Checks if it's time to take the next sample, if so convert the sample to FFT data and change
  /// [_fftDataImageNotifier] which will cause the [AlgernonFragment] widget to rebuild.
  void _onTick(Duration elapsed) async {
    if (!_isProcessing &&
        elapsed - _lastTimestamp >= _fpsAimDuration &&
        context.mounted &&
        _soLoudIsReady) {
      {
        _lastTimestamp = elapsed;
        _isProcessing = true;
        try {
          _audioData.updateSamples();
          final oldImage = _painterConfig.fftDataImage;
          _painterConfig.fftDataImage = await _imageFromFftData(
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
    // already in that format). For now we just pass it in via the red channel, other colours are unused and alpha is
    // full/1.
    final pixels = Float32List(256 * 4);
    for (int i = 0; i < 256; i++) {
      pixels[i * 4 + 0] = fftData[i];
      pixels[i * 4 + 1] = 0.0;
      pixels[i * 4 + 2] = 0.0;
      pixels[i * 4 + 3] = 1.0;
    }

    return await _shaderImageFromPixels(pixels);
  }

  /// Make an image full of zeroes as a placeholder.
  Future<ui.Image> _getZeroImage() async {
    final pixels = Float32List(256 * 4);
    pixels.fillRange(0, pixels.length, 0.0);
    return await _shaderImageFromPixels(pixels);
  }
}
