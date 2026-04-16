// SPDX-License-Identifier: GPL-3.0-only
import 'dart:ui' as ui;

import 'package:algernon/enum/enum.dart';
import 'package:algernon/shader_meta_model.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Get a fragment shader and use it to paint a widget.
class AlgernonShaderPainter extends StatelessWidget {
  const AlgernonShaderPainter({
    super.key,
    required this.fftDataTexture,
    required this.shaderMeta,
  });
  final ui.Image fftDataTexture;
  final ShaderMetaModel shaderMeta;

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: shaderMeta.assetKey,
      (context, shader, child) => CustomPaint(
        /// Scale/magnitude is irrelevant as the shader uses screen resolution, but **this [Size] does create an aspect
        /// ratio**.
        size: const Size(1, 1),
        painter: ShaderPainter(
          shader: shader,
          fftDataTexture: fftDataTexture,
          shaderTweaks: Map.fromEntries(
            shaderMeta.shaderTweaks.entries.where(
              (e) => e.value.tweakType != TweakType.fftDataSmoothing,
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
class ShaderPainter extends CustomPainter {
  ShaderPainter({
    required this.shader,
    required this.fftDataTexture,
    required this.shaderTweaks,
  });
  final ui.FragmentShader shader;
  final ui.Image fftDataTexture;
  final Map<String, ShaderTweakModel> shaderTweaks;

  @override
  void paint(Canvas canvas, Size size) {
    // Floats in a shader are set sequentially. This includes floats which are part of other variables, so if there is a
    // vec2 (which contains 2 floats), the way to set it is to [setFloat()] twice.

    // The first uniform in the shader is [u_resolution], which is a vec2
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      // There's only one sampler
      ..setImageSampler(0, fftDataTexture, filterQuality: FilterQuality.low);

    shaderTweaks.forEach((String uniformName, ShaderTweakModel tweak) {
      try {
        shader.getUniformFloat(tweak.tweakType.uniform!).set(tweak.currentVal);
      } on ArgumentError catch (_) {
        // Shader switch in progress (ie user has changed selection in dropdown)... skip an update
      }
    });

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    return oldDelegate.fftDataTexture != fftDataTexture;
  }
}
