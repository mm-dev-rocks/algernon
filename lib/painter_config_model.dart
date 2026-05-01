import 'dart:ui' as ui;

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:algernon/shader_model.dart';
import 'package:flutter/material.dart';

class PainterConfigModel with ChangeNotifier {
  /// [_fftDataImage] stores the latest data from the FFT, in an image format for efficient passthrough to the shader later.
  ui.Image? _fftDataImage;
  //
  ui.Image? get fftDataImage => _fftDataImage;
  set fftDataImage(ui.Image image) {
    _fftDataImage = image;
    //debugPrint('PainterConfigModel::fftDataImage NOTIFY LISTENERS');
    notifyListeners();
  }

  /// [currentMemorySlot] keeps track of which memory slot is currently selected. It reads/writes directly to
  /// [SharedPreferencesWithCache] via [AppState].
  int get currentMemorySlot =>
      AppState.getPreference('selectedMemorySlotIndex');
  set currentMemorySlot(int index) {
    AppState.setPreference('selectedMemorySlotIndex', index);
    debugPrint('PainterConfigModel::currentMemorySlot NOTIFY LISTENERS');
    notifyListeners();
  }

  /// [_currentShader] tracks which shader is currently in use.
  /// Protect against non-existent index eg when shaders have been deleted.
  ShaderModel _currentShader =
      ALGERNON.shadersData[AppState.getPreference(
        'selectedShaderIndex',
      ).clamp(0, ALGERNON.shadersData.length - 1)];
  //
  ShaderModel get currentShader => _currentShader;
  set currentShader(ShaderModel shaderMeta) {
    _currentShader = shaderMeta;

    /// Try full scale rendering for a new shader, it will drop down via [AlgernonPlayer] if the device can't handle it.
    scale = RenderScale.full;

    for (int i = 0; i < ALGERNON.shadersData.length; i++) {
      if (ALGERNON.shadersData[i].id == shaderMeta.id) {
        AppState.setPreference('selectedShaderIndex', i);
        break;
      }
    }
    _currentShader.calibrateAudioEnergy();
    debugPrint('PainterConfigModel::currentShader NOTIFY LISTENERS');
    notifyListeners();
  }

  RenderScale scale = RenderScale.full;
  void decreaseResolution() {
    if (scale.index > 0) {
      scale = RenderScale.values[scale.index - 1];
    }
    debugPrint('Resolution change to: ${scale.name}');
  }

  void increaseResolution() {
    if (scale.index < RenderScale.values.length - 1) {
      scale = RenderScale.values[scale.index + 1];
    }
    debugPrint('Resolution change to: ${scale.name}');
  }

  @override
  dispose() {
    _fftDataImage?.dispose();
    super.dispose();
  }
}
