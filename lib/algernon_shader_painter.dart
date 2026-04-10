// SPDX-License-Identifier: GPL-3.0-only
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Get a fragment shader and use it to paint a widget.
class AlgernonShaderPainter extends StatelessWidget {
  const AlgernonShaderPainter({super.key, required this.audioImage});
  final ui.Image audioImage;

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: 'shaders/algernon1.frag',
      (context, shader, child) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: ShaderPainter(shader: shader, audioImage: audioImage),
      ),

      /// We just need an empty generic child widget
      child: const SizedBox.shrink(),
    );
  }
}

/// Pass our FTT data in to the shader and paint a canvas with it.
class ShaderPainter extends CustomPainter {
  ShaderPainter({required this.shader, required this.audioImage});
  ui.FragmentShader shader;
  ui.Image audioImage;

  @override
  void paint(Canvas canvas, Size size) {
    // Floats in a shader are set sequentially. This includes floats which are part of other variables, so if there is a
    // vec2 (which contains 2 floats), the way to set it is to [setFloat()] twice.

    // The first uniform in the shader is [u_resolution], which is a vec2
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      // There's only one sampler
      ..setImageSampler(0, audioImage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    return oldDelegate.audioImage != audioImage;
  }
}
