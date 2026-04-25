// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/enum/enum.dart';
import 'package:algernon/memory_slot_chooser.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_tweak_model.dart';
import 'package:algernon/shader_tweak_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class MainControlPanel extends StatefulWidget {
  const MainControlPanel({super.key});

  @override
  State<MainControlPanel> createState() => _MainControlPanelState();
}

class _MainControlPanelState extends State<MainControlPanel> {
  late ShaderTweakModel _fftSmoothingTweak;

  @override
  void initState() {
    _updateFftSmoothingTweak();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    /// Most sliders are for shader parameters. They store their value as a preference and cause a rebuild of the nested
    /// [ListenableBuilder]. The FFT Smoothing slider is different as it doesn't affect the shaders directly, but
    /// instead acts on the [SoLoud] instance to smooth its bin data before we pass it to the [AlgernonShaderPainter].
    /// When a new shader is chosen, we need to make sure the current smoothing setting carries over. So we call
    /// [SetState()], which causes this (re)build to happen.
    /// [AlgernonPlayer.painterConfig.currentShader] is guaranteed to always be up-to-date with the latest memory slot and shader.
    if (AlgernonPlayer.soLoudIsReady) {
      _updateFftSmoothingTweak();
      SoLoud.instance.setFftSmoothing(_fftSmoothingTweak.storedValue);
      debugPrint(
        'AlgernonPlayer.painterConfig.currentShader: ${AlgernonPlayer.painterConfig.currentShader}',
      );
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
            //_showControlsThenHideDebounced();
          },
        ),

        /// Shader-specific tweaks
        ...AlgernonPlayer.painterConfig.currentShader.shaderTweaks.entries
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
                        //_showControlsThenHideDebounced();
                      },
                onAutoButtonPressed: () {
                  debugPrint(
                    '1. entry.value.useEnergyDerivedCount: ${entry.value.useEnergyDerivedCount}',
                  );
                  entry.value.useEnergyDerivedCount =
                      !entry.value.useEnergyDerivedCount;
                  debugPrint(
                    '2. entry.value.useEnergyDerivedCount: ${entry.value.useEnergyDerivedCount}\n',
                  );
                  setState(() {});
                },
              ),
            ),
      ],
    );
  }

  /// Make sure we are using the correct smoothing tweak for the current shader.
  void _updateFftSmoothingTweak() {
    _fftSmoothingTweak = AlgernonPlayer
        .painterConfig
        .currentShader
        .shaderTweaks[TweakType.fftDataSmoothing.name]!;
  }
}
