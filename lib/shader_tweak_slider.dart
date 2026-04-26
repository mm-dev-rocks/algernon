// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:flutter/material.dart';

class ShaderTweakSlider extends StatelessWidget {
  const ShaderTweakSlider({
    super.key,
    required this.shaderTweak,
    required this.onChanged,
    this.onAutoButtonPressed,
  });

  final ShaderTweakModel shaderTweak;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onAutoButtonPressed;

  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    Slider slider = Slider(
      min: shaderTweak.min,
      max: shaderTweak.max,
      value: shaderTweak.storedValue,
      divisions: shaderTweak.divisions,
      onChanged: onChanged,
      label: shaderTweak.storedValue.toString(),
      showValueIndicator: ShowValueIndicator.onDrag,
    );
    Widget label = IgnorePointer(
      child: Text(
        shaderTweak.tweakType.label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
    Widget infoIcon = Tooltip(
      message: shaderTweak.tweakType.description,
      child: const Icon(Icons.info_outlined),
    );
    Widget autoCountButton = SizedBox(
      /// TODO magic numbers
      width: 42,
      height: 42,
      child: shaderTweak.isEnergyUniform
          ? Container(
              decoration: shaderTweak.useEnergyDerivedCount
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: ALGERNON.buttonBorderThickness,
                      ),
                    )
                  : BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: ALGERNON.disabledControlOpacity,
                      ),
                    ),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Auto: Ignore slider and adjust based on audio energy',
                onPressed: onAutoButtonPressed,
              ),
            )
          : const SizedBox.shrink(),
    );

    return Stack(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: uiSizes.paddingSmall),
              child: infoIcon,
            ),
            Expanded(child: slider),
            autoCountButton,
          ],
        ),
        PositionedDirectional(bottom: 0, start: 0, end: 0, child: label),
      ],
    );
  }
}
