// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';

class ShaderTweakSlider extends StatelessWidget {
  const ShaderTweakSlider({
    super.key,
    required this.shaderTweak,
    required this.onChanged,
    this.name = "Tweak Slider",
  });

  final ShaderTweakModel shaderTweak;
  final ValueChanged<double> onChanged;
  final String name;

  @override
  Widget build(BuildContext context) {
    Slider slider = Slider(
      min: shaderTweak.min,
      max: shaderTweak.max,
      value: shaderTweak.currentVal,
      divisions: shaderTweak.divisions,
      onChanged: onChanged,
    );
    Text label = Text(name, style: const TextStyle(color: Colors.white));

    return Column(children: [slider, label]);
  }
}
