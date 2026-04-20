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
    Widget infoIcon = Tooltip(
      message: shaderTweak.tweakType.description,
      child: const Icon(Icons.info_outlined),
    );

    return Column(
      //crossAxisAlignment: .start,
      children: [
        Row(mainAxisSize: .min, children: [slider, infoIcon]),
        label,
      ],
    );
  }
}
