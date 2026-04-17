import 'dart:ui' as ui;

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/shader_meta_model.dart';
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
  ShaderMetaModel _currentShaderMeta =
      ALGERNON.shadersMetadata[AppState.getPreference('selectedShaderIndex')];
  ShaderMetaModel get currentShaderMeta => _currentShaderMeta;
  set currentShaderMeta(ShaderMetaModel shaderMeta) {
    _currentShaderMeta = shaderMeta;
    for (int i = 0; i < ALGERNON.shadersMetadata.length; i++) {
      if (ALGERNON.shadersMetadata[i].id == shaderMeta.id) {
        AppState.setPreference('selectedShaderIndex', i);
        break;
      }
    }
    notifyListeners();
  }

  @override
  dispose() {
    _fftDataImage?.dispose();

    super.dispose();
  }
}
