// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:algernon/algernon_shader_painter.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/memory_slot_button.dart';
import 'package:algernon/painter_config_model.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_model.dart';
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

  /// Unused for now but might be useful later
  // ignore: unused_field
  double _trackJumpiness = 0;
  // ignore: unused_field
  double _trackAmplitude = 0;

  bool get _soLoudIsReady =>
      _soLoud.isInitialized && _soLoud.getVisualizationEnabled();

  String _filePath =
      ALGERNON.audioTrackFilePaths[AppState.getPreference(
        'selectedAudioFilePathIndex',
      )];

  /// [PainterConfigModel] holds all the info used to draw/update the [AlgernonShaderPainter], including the
  /// constantly-updating FFT data. It is a [ChangeNotifier] and changing its properties will cause
  /// [AlgernonShaderPainter] to rebuild.
  final PainterConfigModel _painterConfig = PainterConfigModel();
  late ShaderTweakModel _fftSmoothingTweak;

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
  double _elapsedSeconds = 0;

  @override
  void initState() {
    _ticker = createTicker(_onTick);
    _ticker.start();

    _initialiseSoundAndPlay();

    _updateFftSmoothingTweak();

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

    /// Most sliders are for shader parameters. They store their value as a preference and cause a rebuild of the nested
    /// [ListenableBuilder]. The FFT Smoothing slider is different as it doesn't affect the shaders directly, but
    /// instead acts on the [SoLoud] instance to smooth its bin data before we pass it to the [AlgernonShaderPainter].
    /// When a new shader is chosen, we need to make sure the current smoothing setting carries over. So we call
    /// [SetState()], which causes this (re)build to happen.
    /// [_painterConfig.currentShader] is guaranteed to always be up-to-date with the latest memory slot and shader.
    if (_soLoudIsReady) {
      _updateFftSmoothingTweak();
      _soLoud.setFftSmoothing(_fftSmoothingTweak.storedValue);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: MouseRegion(
            onHover: (_) {
              _showControlsThenHideDebounced();
            },
            child: GestureDetector(
              onTap: _showControlsThenHideDebounced,
              child: FittedBox(
                fit: BoxFit.cover,

                /// Main visuals
                /// This [ListenableBuilder] rebuilds whenever any [ShaderTweakModel] changes.
                child: ListenableBuilder(
                  listenable: _painterConfig,
                  builder: (BuildContext context, Widget? child) {
                    return _zeroImageExists
                        ? AlgernonShaderPainter(
                            elapsedSeconds: _elapsedSeconds,
                            fftDataTexture:
                                _painterConfig.fftDataImage ?? _zeroImage!,
                            shaderMeta: _painterConfig.currentShader,
                          )
                        : const SizedBox.shrink();
                  },
                ),
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
                DropdownMenu<ShaderModel>(
                  requestFocusOnTap: false,
                  initialSelection: _painterConfig.currentShader,
                  onSelected: (ShaderModel? value) {
                    if (value != null) {
                      setState(() {
                        _painterConfig.currentShader = value;
                      });
                    }
                    _showControlsThenHideDebounced();
                  },
                  dropdownMenuEntries: ALGERNON.shadersData
                      .map<DropdownMenuEntry<ShaderModel>>(
                        (ShaderModel shaderMeta) =>
                            DropdownMenuEntry<ShaderModel>(
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
                DropdownMenu<String>(
                  requestFocusOnTap: false,
                  initialSelection: _filePath,
                  onSelected: (String? value) async {
                    if (value != null) {
                      if (_currentSoundHandle != null) {
                        await _soLoud.stop(_currentSoundHandle!);
                      }
                      setState(() {
                        _filePath = value;
                        AppState.setPreference(
                          'selectedAudioFilePathIndex',
                          ALGERNON.audioTrackFilePaths.indexOf(_filePath),
                        );
                        Future.microtask(() {
                          _initialiseSoundAndPlay();
                        });
                      });
                    }
                    _showControlsThenHideDebounced();
                  },
                  dropdownMenuEntries: ALGERNON.audioTrackFilePaths
                      .map<DropdownMenuEntry<String>>(
                        (String filePath) => DropdownMenuEntry<String>(
                          value: filePath,
                          label: filePath,
                          style: MenuItemButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                      .toList(),
                ),
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

        /// Shader-specific controls block
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
                    /// Memory slot buttons
                    Padding(
                      padding: EdgeInsets.only(
                        left: uiSizes.paddingLarge,
                        right: uiSizes.paddingLarge,
                      ),
                      child: Row(
                        mainAxisSize: .max,
                        spacing: uiSizes.paddingLarge,
                        children: List.generate(
                          ALGERNON.totalMemorySlots,
                          (int index) => Expanded(
                            child: MemorySlotButton(
                              index: index,
                              onPressed: () {
                                AppState.setPreference(
                                  'selectedMemorySlotIndex',
                                  index,
                                );
                                _showControlsThenHideDebounced();
                                setState(() {
                                  // Rebuild to make sure the latest [selectedMemorySlotIndex] is picked up for the
                                  // smoothing slider.
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// FFT smoothing
                    ShaderTweakSlider(
                      shaderTweak: _fftSmoothingTweak,
                      onChanged: (double value) {
                        if (_soLoudIsReady) {
                          setState(() {
                            _fftSmoothingTweak.storedValue = value;
                          });
                        }
                        _showControlsThenHideDebounced();
                      },
                    ),

                    /// Shader-specific tweaks
                    ..._painterConfig.currentShader.shaderTweaks.entries
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
                                      entry.value.storedValue = value;
                                    });
                                  }
                                  _showControlsThenHideDebounced();
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
                    value: _currentSoundHandle != null
                        ? _soLoud.getVolume(_currentSoundHandle!)
                        : 1,
                    onChanged: (double value) {
                      if (_soLoudIsReady && _currentSoundHandle != null) {
                        setState(() {
                          _soLoud.setVolume(_currentSoundHandle!, value);
                        });
                      }
                      _showControlsThenHideDebounced();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Make sure we are using the correct smoothing tweak for the current shader.
  void _updateFftSmoothingTweak() {
    _fftSmoothingTweak = _painterConfig
        .currentShader
        .shaderTweaks[TweakType.fftDataSmoothing.name]!;
  }

  void _togglePause() {
    if (_currentSoundHandle != null) {
      _soLoud.pauseSwitch(_currentSoundHandle!);
      setState(() {
        /// Rebuild to update state of the toggle button
      });
    }
  }

  void _initialiseSoundAndPlay() async {
    if (!_soLoudIsReady) {
      await _soLoud.init(bufferSize: 1024);
      _soLoud.setVisualizationEnabled(true);
    }

    _currentSound = await _soLoud.loadAsset(_filePath);
    analyseFile(_filePath);
    if (_currentSound != null) {
      _currentSoundHandle = _soLoud.play(_currentSound!, looping: true);
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

          _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;

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
    // already in that format). We pass FFT bins in via the red channel.
    final pixels = Float32List(256 * 4);

    /// TODO is this working?
    // how slowly the average moves
    //const double binSmoothing = 0.8;
    const double binSmoothing = 0.1;
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

      // R: raw magnitude
      pixels[i * 4 + 0] = magnitude;
      // G: signed charge
      pixels[i * 4 + 1] = chargeNormalised;
      // Unused
      pixels[i * 4 + 2] = 0.0;
      // Alpha full
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

  void _showControlsThenHideDebounced() {
    AppState.debounceVoidFunction(
      callerKey: 'AlgernonPlayer._showControlsThenHideDebounced',
      debounceDuration: ALGERNON.showControlsDebounceDuration,
      voidFunction: _showControlsThenHide,
    );
  }

  void _showControlsThenHide() {
    //AppState.log("_showControlsThenHide()");
    _hideControlsTimer.cancel();
    _hideControlsTimer = Timer(ALGERNON.hideControlsDelay, _hideControls);
    setState(() {
      _controlsAreVisible = true;
    });
  }

  void _hideControls() {
    //AppState.log("_hideControls()");
    _hideControlsTimer.cancel();
    setState(() {
      _controlsAreVisible = false;
    });
  }

  Future<void> analyseFile(String filePath) async {
    // 1000 evenly-spaced points from seconds 10–40 (runs off the main thread internally)
    final samples = await SoLoud.instance.readSamplesFromFile(
      filePath,
      1000,
      startTime: 10.0,
      endTime: 40.0,
      // each point is an average of its surrounding region
      average: true,
    );

    _trackJumpiness = _computeJumpiness(samples);
    _trackAmplitude = _computeAmplitude(samples);
  }

  double _computeJumpiness(Float32List samples) {
    double total = 0;
    for (int i = 1; i < samples.length; i++) {
      total += (samples[i] - samples[i - 1]).abs();
    }
    return total / samples.length;
  }

  double _computeAmplitude(Float32List samples) {
    double total = 0;
    for (int i = 0; i < samples.length; i++) {
      total += samples[i].abs();
    }
    return total / samples.length;
  }
}
