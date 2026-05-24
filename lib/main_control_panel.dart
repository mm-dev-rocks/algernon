// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/auto_sequence_toggle.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:algernon/memory_slot_chooser.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_chooser.dart';
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
    _updateNonUniformTweaks();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    /// Most sliders are for shader parameters. They store their value as a preference and cause a rebuild of the nested
    /// [ListenableBuilder]. The FFT Smoothing slider [_fftSmoothingTweak] is different as it doesn't affect the shaders
    /// directly, but instead acts on the [SoLoud] instance to smooth its bin data before we pass it to the
    /// [AlgernonShaderPainter]. When a new shader is chosen, we need to make sure the current smoothing setting carries
    /// over (unlike the normal shader parameters, this dosen't happen automatically).

    /// [widget.currentShader] will always be up-to-date with the latest memory slot and shader as this widget gets
    /// built on a [ListenableBuilder] listening for changes to [AlgernonPlayer.painterConfig] which includes the
    /// shader.
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.setFftSmoothing(_fftSmoothingTweak.storedValue);
    }

    return Row(
      crossAxisAlignment: .start,
      children: [
        AutoSequenceToggle(),
        Expanded(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,

            spacing: uiSizes.paddingSmall,
            children: [
              /// 'Choose shader' dropdown
              const Flexible(fit: FlexFit.loose, child: ShaderChooser()),

              /// Memory slot buttons
              ListenableBuilder(
                listenable: AlgernonPlayer.painterConfig,
                builder: (context, child) {
                  _updateNonUniformTweaks();
                  return MemorySlotChooser(
                    selectedIndex:
                        AlgernonPlayer.painterConfig.currentMemorySlot,
                  );
                },
              ),

              /// FFT smoothing
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      Screen.height(context) -
                      (kToolbarHeight * 2 +
                          ALGERNON.memorySlotButtonSize.height +
                          uiSizes.paddingLarge),
                ),
                // [kToolbarHeight] matches [DropdownMenu] height.
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      ShaderTweakSlider(
                        shaderTweak: _fftSmoothingTweak,
                        onChanged: (double value) {
                          if (SoLoud.instance.isInitialized) {
                            _fftSmoothingTweak.storedValue = value;

                            /// Rebuild to account for new slider value
                            setState(() {});
                          }
                          UserInterface.keepControlsAlive();
                        },
                      ),

                      SizedBox(height: uiSizes.paddingMedium),

                      /// Shader-specific tweaks
                      ...widget.currentShader.shaderTweaks.entries
                          /// Non uniform tweaks such as FFT Smoothing and Overall Effect are treated differently to the others
                          /// and have bespoke sliders.
                          .where(
                            (MapEntry<String, ShaderTweakModel> entry) =>
                                !entry.value.tweakType.isNonUniformTweak,
                          )
                          .map(
                            (
                              MapEntry<String, ShaderTweakModel> entry,
                            ) => ShaderTweakSlider(
                              shaderTweak: entry.value,
                              onChanged:
                                  /// If this is an energy uniform and the user has selected 'auto', disable its slider.
                                  (entry.value.isEnergyUniform &&
                                      entry.value.useEnergyDerivedCount)
                                  ? null
                                  : (double value) {
                                      if (SoLoud.instance.isInitialized) {
                                        entry.value.storedValue = value;

                                        /// Rebuild to account for new slider value
                                        setState(() {});
                                      }
                                      UserInterface.keepControlsAlive();
                                    },
                              onAutoButtonPressed: () {
                                entry.value.useEnergyDerivedCount =
                                    !entry.value.useEnergyDerivedCount;

                                /// Rebuild to account for new useEnergyDerivedCount toggle
                                setState(() {});
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ensure we are pointing to the current tweaks
  void _updateNonUniformTweaks() {
    //debugPrint('MainControlPanel::_updateNonUniformTweaks()');
    //debugPrint('\t${widget.currentShader.shaderTweaks.toString()}');

    /// We know these tweaks will always exist because [ShaderModel] asserts it in its constructor.
    _fftSmoothingTweak =
        widget.currentShader.shaderTweaks[TweakType.fftDataSmoothing.name]!;
  }
}
