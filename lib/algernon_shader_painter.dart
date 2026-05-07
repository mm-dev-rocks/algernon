// SPDX-License-Identifier: GPL-3.0-only
import 'dart:ui' as ui;

import 'package:algernon/enum.dart';
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

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);
    if (painterConfig.fftDataImage == null) return;

    final scaledWidth = size.width * painterConfig.scale.value;
    final scaledHeight = size.height * painterConfig.scale.value;

    shader.setImageSampler(
      0,
      painterConfig.fftDataImage!,
      filterQuality: FilterQuality.low,
    );

    /// TODO Comments to explain this properly!
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
      } on ArgumentError catch (e) {
        debugPrint('AlgernonShaderPainter::!!!!!');
        debugPrint(e.toString());
      }
    });

    // Render shader at whichever resolution scale dictates
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
