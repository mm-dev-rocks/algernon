// SPDX-License-Identifier: GPL-3.0-only
import 'dart:ui' as ui;

import 'package:algernon/enum/enum.dart';
import 'package:algernon/shader_model.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Get a fragment shader and use it to paint a widget.
class AlgernonShaderPainter extends StatelessWidget {
  const AlgernonShaderPainter({
    super.key,
    required this.fftDataTexture,
    required this.shaderMeta,
    required this.elapsedSeconds,
  });
  final ui.Image fftDataTexture;
  final ShaderModel shaderMeta;
  final double elapsedSeconds;

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
          elapsedSeconds: elapsedSeconds,
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
    required this.elapsedSeconds,
  });
  final ui.FragmentShader shader;
  final ui.Image fftDataTexture;
  final Map<String, ShaderTweakModel> shaderTweaks;
  final double elapsedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    // Floats in a shader are set sequentially. This includes floats which are part of other variables, so if there is a
    // vec2 (which contains 2 floats), the way to set it is to [setFloat()] twice.
    shader
      ..getUniformFloat('u_resolution', 0).set(size.width)
      ..getUniformFloat('u_resolution', 1).set(size.height)
      ..getUniformFloat('u_time').set(elapsedSeconds)
      // There's only one sampler so we can access that easily by its index (0)
      ..setImageSampler(0, fftDataTexture, filterQuality: FilterQuality.low);

    shaderTweaks.forEach((String uniformName, ShaderTweakModel tweak) {
      try {
        if (tweak.isEnergyUniform && tweak.useEnergyDerivedCount) {
          /// Special case: Ignore slider/storedValue as the track energy will be used for this. The shader needs to
          /// know the min/max values for some internal calculations.
          shader.getUniformFloat('u_energyMin').set(tweak.min);
          shader.getUniformFloat('u_energyMax').set(tweak.max);
        } else {
          shader
              .getUniformFloat(tweak.tweakType.uniform!)
              .set(tweak.storedValue);
        }
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
