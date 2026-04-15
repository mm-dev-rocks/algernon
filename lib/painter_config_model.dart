import 'dart:ui' as ui;

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
  ShaderMetaModel _currentShaderMeta = ALGERNON.shaderMetaModels.first;
  ShaderMetaModel get currentShaderMeta => _currentShaderMeta;
  set currentShaderMeta(ShaderMetaModel shaderMeta) {
    _currentShaderMeta = shaderMeta;
    notifyListeners();
  }

  /// [_currentShaderFilterQuality] affects something like visual smoothing/interpolation.
  FilterQuality _currentShaderFilterQuality =
      ALGERNON.shaderFilterQualities.values.first;
  FilterQuality get currentShaderFilterQuality => _currentShaderFilterQuality;
  set currentShaderFilterQuality(FilterQuality filterQuality) {
    _currentShaderFilterQuality = filterQuality;
    notifyListeners();
  }

  @override
  dispose() {
    _fftDataImage?.dispose();

    super.dispose();
  }
}
