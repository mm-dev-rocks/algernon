// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/screen.dart';
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

  /// Keep a rolling average of bins to be used for physics 'charges'
  final Float32List _binAverages = Float32List(256); // rolling avg per bin

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

  AudioSource? _currentSound;
  SoundHandle? _currentSoundHandle;

  late Timer _hideControlsTimer;
  bool _controlsAreVisible = true;

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

    _initialiseSoundAndPlay();

    /// [initState] can't be async, so we send image creation off as a microtask which will be carried out after the
    /// current flow of execution.
    Future<void>.microtask(() async {
      _zeroImage = await _getZeroImage();
      _zeroImageExists = true;
    });
    _hideControlsTimer = Timer(ALGERNON.hideControlsDelay, _hideControls);

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
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    final ShaderTweakModel fftSmoothingTweak = _painterConfig
        .currentShaderMeta
        .shaderTweaks[TweakType.fftDataSmoothing.name]!;

    return Stack(
      children: [
        /// Main visuals
        Positioned.fill(
          child: GestureDetector(
            onTap: _showControlsDebounced,
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
        ),

        /// Shader select/dropdown
        if (_controlsAreVisible)
          Positioned.directional(
            textDirection: TextDirection.ltr,
            bottom: 0,
            start: 0,
            end: 0,
            child: Row(
              children: [
                DropdownMenu<ShaderMetaModel>(
                  requestFocusOnTap: false,
                  initialSelection: _painterConfig.currentShaderMeta,
                  onSelected: (ShaderMetaModel? value) {
                    if (value != null) {
                      setState(() {
                        _painterConfig.currentShaderMeta = value;
                      });
                    }
                  },
                  dropdownMenuEntries: ALGERNON.shadersMetadata
                      .map<DropdownMenuEntry<ShaderMetaModel>>(
                        (ShaderMetaModel shaderMeta) =>
                            DropdownMenuEntry<ShaderMetaModel>(
                              value: shaderMeta,
                              label: shaderMeta.friendlyName,
                              style: MenuItemButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                            ),
                      )
                      .toList(),
                ),
                const Spacer(),
                if (_currentSoundHandle != null)
                  IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      _soLoud.getPause(_currentSoundHandle!)
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                  ),
              ],
            ),
          ),

        /// Shader-specific sliders
        if (_controlsAreVisible)
          Positioned.directional(
            textDirection: TextDirection.ltr,

            top: 0,
            bottom: 0,
            start: 0,

            end: Screen.width(context) * 0.66,
            child: Center(
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,

                  spacing: uiSizes.paddingMedium,
                  children: [
                    ..._painterConfig.currentShaderMeta.shaderTweaks.entries
                        .where(
                          (MapEntry<String, ShaderTweakModel> entry) =>
                              entry.value.tweakType !=
                              TweakType.fftDataSmoothing,
                        )
                        .map(
                          (MapEntry<String, ShaderTweakModel> entry) =>
                              ShaderTweakSlider(
                                shaderTweak: entry.value,
                                onChanged: (double value) {
                                  if (_soLoudIsReady) {
                                    setState(() {
                                      entry.value.currentVal = value;
                                    });
                                  }
                                  _showControlsDebounced();
                                },
                              ),
                        ),
                  ],
                ),
              ),
            ),
          ),

        /// Volume slider
        if (_controlsAreVisible)
          Positioned.directional(
            textDirection: TextDirection.ltr,

            /// TODO magic number
            top: 100,
            bottom: 100,
            end: 0,
            child: Row(
              children: [
                const Tooltip(
                  message: 'Volume',
                  child: Icon(Icons.speaker_outlined),
                ),
                RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    //shaderTweak: fftSmoothingTweak,
                    value: _currentSoundHandle != null
                        ? _soLoud.getVolume(_currentSoundHandle!)
                        : 1,
                    onChanged: (double value) {
                      if (_soLoudIsReady && _currentSoundHandle != null) {
                        setState(() {
                          _soLoud.setVolume(_currentSoundHandle!, value);
                          //fftSmoothingTweak.currentVal = value;
                          //_soLoud.setFftSmoothing(fftSmoothingTweak.currentVal);
                        });
                      }
                      _showControlsDebounced();
                    },
                  ),
                ),
              ],
            ),
          ),

        /// FFT smoothing slider
        if (_controlsAreVisible)
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
                    onChanged: (double value) {
                      if (_soLoudIsReady) {
                        setState(() {
                          fftSmoothingTweak.currentVal = value;
                          _soLoud.setFftSmoothing(fftSmoothingTweak.currentVal);
                        });
                      }
                      _showControlsDebounced();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _togglePause() {
    //if (_soLoud.getPause()) {}
    if (_currentSoundHandle != null) {
      _soLoud.pauseSwitch(_currentSoundHandle!);
      setState(() {});
    }
  }

  void _initialiseSoundAndPlay() async {
    await _soLoud.init(bufferSize: 256);
    _soLoud.setVisualizationEnabled(true);

    _currentSound = await _soLoud.loadAsset(
      //"assets/BEATPELLA HOUSE - Candy Thief.mp3",
      //'assets/Public Image Limited - Rise.mp3',
      // 'assets/South Street Player - Who Keeps Changing Your Mind.mp3',
      'assets/Bob Dylan - Eternal Circle.mp3',
      // 'assets/Sister Sledge - Thinking Of You.mp3',
      // 'assets/Pointer Sisters - Automatic.mp3',
    );
    if (_currentSound != null) {
      // After SoLoud 4, [play()] is sync
      //_currentSoundHandle = await _soLoud.play(
      _currentSoundHandle = _soLoud.play(
        _currentSound!,
        //volume: 0.1,
        looping: true,
      );
      setState(() {});
    }
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
    // In SoLoud, FFT data is processed late in the pipeline after the mixing stage, meaning the volume slider affects
    // the intensity of the visuals. This is not what we want, so here we scale it to compensate for the current volume.
    if (_currentSoundHandle != null) {
      for (var i = 0; i < fftData.length; i++) {
        fftData[i] /= _soLoud.getVolume(_currentSoundHandle!);
      }
    }

    // 256 pixels, each pixel needs R,G,B,A as floats, each of which is normalised between 0 and 1 (the FFT data is
    // already in that format). For now we just pass it in via the red channel, other colours are unused and alpha is
    // full/1.
    final pixels = Float32List(256 * 4);

    // how slowly the average moves
    const double binSmoothing = 0.8;
    //const double binSmoothing = 0.92;

    for (int i = 0; i < 256; i++) {
      final double magnitude = fftData[i];

      // Update rolling average
      _binAverages[i] =
          _binAverages[i] * binSmoothing + magnitude * (1.0 - binSmoothing);

      // Signed charge: positive when louder than average, negative when quieter
      // clamp to [-1, 1] then remap to [0, 1] for the texture
      final double charge = (magnitude - _binAverages[i]).clamp(-1.0, 1.0);
      final double chargeNormalised = (charge + 1.0) * 0.5;

      pixels[i * 4 + 0] = magnitude; // R: raw magnitude (existing)
      pixels[i * 4 + 1] = chargeNormalised; // G: signed charge
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

  void _showControlsDebounced() {
    AppState.debounceVoidFunction(
      callerKey: 'AlgernonPlayer._showControlsDebounced',
      debounceDuration: ALGERNON.showControlsDebounceDuration,
      voidFunction: _showControls,
    );
  }

  void _showControls() {
    AppState.log("_showControls()");
    _hideControlsTimer.cancel();
    _hideControlsTimer = Timer(ALGERNON.hideControlsDelay, _hideControls);
    setState(() {
      _controlsAreVisible = true;
    });
  }

  void _hideControls() {
    AppState.log("_hideControls()");
    _hideControlsTimer.cancel();
    setState(() {
      _controlsAreVisible = false;
    });
  }
}
