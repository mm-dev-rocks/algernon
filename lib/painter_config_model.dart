import 'dart:ui' as ui;

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/shader_model.dart';
import 'package:flutter/material.dart';

class PainterConfigModel with ChangeNotifier {
  /// [_fftDataImage] stores the latest data from the FFT, in an image format for efficient passthrough to the shader later.
  ui.Image? _fftDataImage;
  ui.Image? get fftDataImage => _fftDataImage;
  set fftDataImage(ui.Image image) {
    _fftDataImage = image;
    notifyListeners();
  }

  /// [_currentShader] tracks which shader is currently in use.
  ShaderModel _currentShader =
      ALGERNON.shadersData[AppState.getPreference('selectedShaderIndex')];
  ShaderModel get currentShader => _currentShader;
  set currentShader(ShaderModel shaderMeta) {
    _currentShader = shaderMeta;
    for (int i = 0; i < ALGERNON.shadersData.length; i++) {
      if (ALGERNON.shadersData[i].id == shaderMeta.id) {
        AppState.setPreference('selectedShaderIndex', i);
        break;
      }
    }
    _currentShader.calibrateAudioEnergy();

    notifyListeners();
  }

  @override
  dispose() {
    _fftDataImage?.dispose();

    super.dispose();
  }
}
