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

      /// Prevent bad values
      value: shaderTweak.storedValue.clamp(shaderTweak.min, shaderTweak.max),
      divisions: shaderTweak.divisions,
      onChanged: onChanged,
      label:
          '${shaderTweak.tweakType.label.toUpperCase()}: ${shaderTweak.storedValue.toStringAsFixed(3)}',
      showValueIndicator: ShowValueIndicator.onDrag,
    );
    Widget infoIcon = Tooltip(
      message:
          '${shaderTweak.tweakType.label.toUpperCase()}: ${shaderTweak.tweakType.description}',
      child: Icon(
        //Icons.info_outlined,
        shaderTweak.tweakType.iconData,
        color: ALGERNON.uiDefaultForegroundColor,
      ),
    );
    Widget autoCountButton = SizedBox(
      width: ALGERNON.autoCountButtonSize.width,
      height: ALGERNON.autoCountButtonSize.height,
      child: shaderTweak.isEnergyUniform
          ? InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: onAutoButtonPressed,
              child: Tooltip(
                message: 'Auto: Ignore slider and adjust based on audio energy',
                child: Icon(
                  Icons.auto_awesome,
                  color: shaderTweak.useEnergyDerivedCount
                      ? Colors.white
                      : Colors.white.withValues(
                          alpha: ALGERNON.disabledControlOpacity,
                        ),
                ),
              ),
            )
          : null,
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
      ],
    );
  }
}
