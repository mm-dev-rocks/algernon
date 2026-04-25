// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/memory_slot_chooser.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_model.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:algernon/shader_tweak_slider.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class MainControlPanel extends StatefulWidget {
  const MainControlPanel({super.key, required this.currentShader});
  final ShaderModel currentShader;

  @override
  State<MainControlPanel> createState() => _MainControlPanelState();
}

class _MainControlPanelState extends State<MainControlPanel> {
  late ShaderTweakModel _fftSmoothingTweak;

  @override
  void initState() {
    /// Make sure we are using the correct smoothing tweak for the current shader.
    _fftSmoothingTweak =
        widget.currentShader.shaderTweaks[TweakType.fftDataSmoothing.name]!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    /// Most sliders are for shader parameters. They store their value as a preference and cause a rebuild of the nested
    /// [ListenableBuilder]. The FFT Smoothing slider [_fftSmoothingTweak] is different as it doesn't affect the shaders
    /// directly, but instead acts on the [SoLoud] instance to smooth its bin data before we pass it to the
    /// [AlgernonShaderPainter]. When a new shader is chosen, we need to make sure the current smoothing setting carries
    /// over.

    /// [widget.currentShader] will always be up-to-date with the latest memory slot and shader as this widget gets
    /// built on a [ListenableBuilder] listening for changes to [AlgernonPlayer.painterConfig] which includes the
    /// shader.
    if (AlgernonPlayer.soLoudIsReady) {
      /// Make sure we are using the correct smoothing tweak for the current shader.
      _fftSmoothingTweak =
          widget.currentShader.shaderTweaks[TweakType.fftDataSmoothing.name]!;
      SoLoud.instance.setFftSmoothing(_fftSmoothingTweak.storedValue);
      //debugPrint(
      //  'MainControlPanel::widget.currentShader: ${widget.currentShader}',
      //);
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,

      spacing: uiSizes.paddingMedium,
      children: [
        /// Memory slot buttons
        Padding(
          padding: EdgeInsets.only(left: uiSizes.paddingSmall),
          child: const MemorySlotChooser(),
        ),

        /// FFT smoothing
        ShaderTweakSlider(
          shaderTweak: _fftSmoothingTweak,
          onChanged: (double value) {
            if (AlgernonPlayer.soLoudIsReady) {
              setState(() {
                _fftSmoothingTweak.storedValue = value;
              });
            }
            UserInterface.keepControlsAlive();
          },
        ),

        /// Shader-specific tweaks
        ...widget.currentShader.shaderTweaks.entries
            .where(
              (MapEntry<String, ShaderTweakModel> entry) =>
                  entry.value.tweakType != TweakType.fftDataSmoothing,
            )
            .map(
              (MapEntry<String, ShaderTweakModel> entry) => ShaderTweakSlider(
                shaderTweak: entry.value,
                onChanged:
                    (entry.value.isEnergyUniform &&
                        entry.value.useEnergyDerivedCount)
                    ? null
                    : (double value) {
                        if (AlgernonPlayer.soLoudIsReady) {
                          setState(() {
                            entry.value.storedValue = value;
                          });
                        }
                        UserInterface.keepControlsAlive();
                      },
                onAutoButtonPressed: () {
                  //debugPrint(
                  //  '1. entry.value.useEnergyDerivedCount: ${entry.value.useEnergyDerivedCount}',
                  //);
                  entry.value.useEnergyDerivedCount =
                      !entry.value.useEnergyDerivedCount;
                  //debugPrint(
                  //  '2. entry.value.useEnergyDerivedCount: ${entry.value.useEnergyDerivedCount}\n',
                  //);
                  setState(() {});
                },
              ),
            ),
      ],
    );
  }
}
