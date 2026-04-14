import 'dart:ui' as ui;

import 'package:algernon/constants.dart';
import 'package:flutter/material.dart';

class PainterConfigModel with ChangeNotifier {
  /// [_fftDataImage] stores the latest data from the FFT, in an image format for efficient passthrough to the shader later.
  ui.Image? _fftDataImage;
  ui.Image? get fftDataImage => _fftDataImage;
  set fftDataImage(ui.Image image) {
    _fftDataImage = image;
    notifyListeners();
  }

  /// [_currentShaderAssetKey] tracks which shader is currently in use.
  String _currentShaderAssetKey = ALGERNON.shaderAssetKeys.values.first;
  String get currentShaderAssetKey => _currentShaderAssetKey;
  set currentShaderAssetKey(String key) {
    _currentShaderAssetKey = key;
    notifyListeners();
  }

  @override
  dispose() {
    _fftDataImage?.dispose();

    super.dispose();
  }
}
