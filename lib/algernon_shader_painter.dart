// SPDX-License-Identifier: GPL-3.0-only
import 'dart:ui' as ui;

import 'package:algernon/painter_config_model.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Get a fragment shader and use it to paint a widget.
class AlgernonShaderPainter extends StatelessWidget {
  const AlgernonShaderPainter({
    super.key,
    required this.painterConfig,
    required this.elapsedSeconds,
  });
  final PainterConfigModel painterConfig;
  final double elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: painterConfig.currentShader.assetKey,
      (context, shader, child) => CustomPaint(
        isComplex: true,
        willChange: true,

        /// Scale/magnitude is irrelevant as the shader uses screen resolution, but **this [Size] does create an aspect
        /// ratio**.
        size: const Size(600, 600),
        painter: ShaderPainter(
          shader: shader,
          painterConfig: painterConfig,
          elapsedSeconds: elapsedSeconds,
          shaderTweaks: Map.fromEntries(
            /// Non uniform tweaks such as FFT Smoothing and Overall Effect are handled elsewhere.
            painterConfig.currentShader.shaderTweaks.entries.where(
              (MapEntry<String, ShaderTweakModel> entry) =>
                  !entry.value.tweakType.isNonUniformTweak,
            ),
          ),
        ),
      ),

      /// We just need an empty generic child widget
      child: const SizedBox.shrink(),
    );
  }
}

/// Pass our FTT data in to the shader and paint a canvas with it.
//class ShaderPainter extends CustomPainter {
//  ShaderPainter({
//    required this.painterConfig,
//    required this.shader,
//    required this.shaderTweaks,
//    required this.elapsedSeconds,
//  });
//  final PainterConfigModel painterConfig;
//  final ui.FragmentShader shader;
//  final Map<String, ShaderTweakModel> shaderTweaks;
//  final double elapsedSeconds;
//
//  @override
//  void paint(Canvas canvas, Size size) {
//    //size /= 10;
//    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
//
//    /// Clip to ensure no off-screen pixels are painted. This may or may not measurably help performance but it's 1 line
//    /// and can't hurt.
//    canvas.clipRect(rect);
//
//    if (painterConfig.fftDataImage != null) {
//      // There's only one sampler, we can access that easily by its index (0) as it will always be the first and only
//      // sampler.
//      shader.setImageSampler(
//        0,
//        painterConfig.fftDataImage!,
//        filterQuality: FilterQuality.low,
//      );
//
//      // Floats in a shader are set sequentially. This includes floats which are part of other variables, so if there is a
//      // vec2 (which contains 2 floats), the way to set it is to [setFloat()] twice.
//      int floatIndex = 0;
//      shader
//        // u_resolution (vec2)
//        ..setFloat(floatIndex++, size.width)
//        ..setFloat(floatIndex++, size.height)
//        // u_time
//        ..setFloat(floatIndex++, elapsedSeconds);
//
//      /// At this point we have set 3 floats, so our next couple (4th/5th) of floats will be at indices [3]/[4]
//      /// (zero-indexed).
//      int tweakTypeIndexEnergyMin = floatIndex++;
//      int tweakTypeIndexEnergyMax = floatIndex;
//
//      /// The rest of the floats are from [5] onwards
//      /// In our [TweakType] enum they come after 'special' tweaks (fft smoothing and energy max/min), so start at [3].
//      /// So here we set an offset which enables us to use [tweak.tweakType.index + tweakTypeIndexOffset] to set their
//      /// matching uniforms in the shader (tweak[3] becomes float[5], [4] becomes [6] and so on).
//      int tweakTypeIndexOffset = 2;
//
//      shaderTweaks.forEach((String uniformName, ShaderTweakModel tweak) {
//        try {
//          if (tweak.isEnergyUniform && tweak.useEnergyDerivedCount) {
//            /// Special case: Ignore slider/storedValue as the track energy will be used for this. The shader needs to
//            /// know the min/max values for some internal calculations.
//            shader.setFloat(tweakTypeIndexEnergyMin, tweak.min);
//            shader.setFloat(tweakTypeIndexEnergyMax, tweak.max);
//            //shader.getUniformFloat('u_energyMin').set(tweak.min);
//            //shader.getUniformFloat('u_energyMax').set(tweak.max);
//
//            /// Set the uniform to -1 as a signal to the shader that it should use the energy data to derive this count
//            /// (the [isEnergyUniform] tweak will never have a value of -1 in normal usage).
//            shader.setFloat(tweak.tweakType.index + tweakTypeIndexOffset, -1);
//            //shader.getUniformFloat(tweak.tweakType.uniform!).set(-1);
//          } else {
//            shader.setFloat(
//              tweak.tweakType.index + tweakTypeIndexOffset,
//              tweak.storedValue,
//            );
//            //shader
//            //    .getUniformFloat(tweak.tweakType.uniform!)
//            //    .set(tweak.storedValue);
//          }
//        } on ArgumentError catch (_) {
//          // Shader switch in progress (ie user has changed selection in dropdown)... skip an update
//          debugPrint('AlgernonShaderPainter::!!!!!');
//        }
//      });
//
//      final paint = Paint()..shader = shader;
//      canvas.drawRect(rect, paint);
//    }
//  }
//
//  @override
//  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
//    //return true;
//    return oldDelegate.elapsedSeconds != elapsedSeconds;
//  }
//}

class ShaderPainter extends CustomPainter {
  ShaderPainter({
    required this.painterConfig,
    required this.shader,
    required this.shaderTweaks,
    required this.elapsedSeconds,
  });
  final PainterConfigModel painterConfig;
  final ui.FragmentShader shader;
  final Map<String, ShaderTweakModel> shaderTweaks;
  final double elapsedSeconds;

  ui.Image? _lowResImage;
  Size? _lastSize;
  static const double _scale = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);
    if (painterConfig.fftDataImage == null) return;

    final scaledWidth = size.width * _scale;
    final scaledHeight = size.height * _scale;

    shader.setImageSampler(
      0,
      painterConfig.fftDataImage!,
      filterQuality: FilterQuality.low,
    );

    int floatIndex = 0;
    shader
      ..setFloat(floatIndex++, scaledWidth)
      ..setFloat(floatIndex++, scaledHeight)
      ..setFloat(floatIndex++, elapsedSeconds);

    int tweakTypeIndexEnergyMin = floatIndex++;
    int tweakTypeIndexEnergyMax = floatIndex;
    int tweakTypeIndexOffset = 2;

    shaderTweaks.forEach((String uniformName, ShaderTweakModel tweak) {
      try {
        if (tweak.isEnergyUniform && tweak.useEnergyDerivedCount) {
          shader.setFloat(tweakTypeIndexEnergyMin, tweak.min);
          shader.setFloat(tweakTypeIndexEnergyMax, tweak.max);
          shader.setFloat(tweak.tweakType.index + tweakTypeIndexOffset, -1);
        } else {
          shader.setFloat(
            tweak.tweakType.index + tweakTypeIndexOffset,
            tweak.storedValue,
          );
        }
      } on ArgumentError catch (_) {
        debugPrint('AlgernonShaderPainter::!!!!!');
      }
    });

    // Render shader at reduced resolution
    final recorder = ui.PictureRecorder();
    final offscreenCanvas = Canvas(recorder);
    offscreenCanvas.drawRect(
      Rect.fromLTWH(0, 0, scaledWidth, scaledHeight),
      Paint()..shader = shader,
    );
    final picture = recorder.endRecording();
    final lowResImage = picture.toImageSync(
      scaledWidth.toInt(),
      scaledHeight.toInt(),
    );

    // Draw scaled up to full size
    canvas.drawImageRect(
      lowResImage,
      Rect.fromLTWH(0, 0, scaledWidth, scaledHeight),
      rect,
      Paint()..filterQuality = FilterQuality.low,
    );

    lowResImage.dispose();
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds;
  }
}
