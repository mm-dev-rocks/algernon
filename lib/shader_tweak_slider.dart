// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';

class ShaderTweakSlider extends StatelessWidget {
  const ShaderTweakSlider({
    super.key,
    required this.shaderTweak,
    required this.onChanged,
  });

  final ShaderTweakModel shaderTweak;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    Slider slider = Slider(
      min: shaderTweak.min,
      max: shaderTweak.max,
      value: shaderTweak.currentVal,
      divisions: shaderTweak.divisions,
      onChanged: onChanged,
    );
    Text label = Text(
      shaderTweak.tweakType.label,
      style: const TextStyle(color: Colors.white),
    );
    Text description = Text(
      shaderTweak.tweakType.description,
      style: const TextStyle(color: Colors.white),
    );

    return Column(children: [slider, label, description]);
  }
}
