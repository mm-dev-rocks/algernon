// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/main_control_panel.dart';
import 'package:algernon/pause_toggle.dart';
import 'package:algernon/playback_bar.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_chooser.dart';
import 'package:algernon/track_chooser.dart';
import 'package:algernon/volume_slider.dart';
import 'package:flutter/material.dart';

class UserInterface extends StatelessWidget {
  const UserInterface({super.key});

  @override
  Widget build(BuildContext context) {
    Size screenSize = Screen.size(context);

    return Stack(
      children: [
        /// Shader select/dropdown
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AlgernonPlayer.soLoudIsReady
                        ? const PlaybackBar()
                        : const SizedBox.shrink(),
                  ),

                  const PauseToggle(),
                ],
              ),
              const Row(
                children: [
                  Flexible(child: ShaderChooser()),
                  Flexible(child: TrackChooser()),
                ],
              ),
            ],
          ),
        ),

        /// Shader-specific controls block
        PositionedDirectional(
          top: 0,
          bottom: 0,
          start: 0,
          width: screenSize.width * 0.333,
          child: Center(
            child: FocusTraversalGroup(child: const MainControlPanel()),
          ),
        ),

        /// Volume slider
        PositionedDirectional(
          top: screenSize.height * 0.25,
          bottom: screenSize.height * 0.25,
          end: 0,
          child: const VolumeSlider(),
        ),
      ],
    );
  }
}
