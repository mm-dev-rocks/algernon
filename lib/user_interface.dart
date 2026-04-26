// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/main_control_panel.dart';
import 'package:algernon/pause_toggle.dart';
import 'package:algernon/playback_bar.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/track_chooser.dart';
import 'package:algernon/volume_slider.dart';
import 'package:flutter/material.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({super.key});

  static Timer _hideControlsTimer = Timer(
    ALGERNON.hideControlsDelay,
    _hideControls,
  );

  static ValueNotifier<bool> controlsAreVisibleNotifier = ValueNotifier(false);

  @override
  State<UserInterface> createState() => _UserInterfaceState();

  static void keepControlsAlive() {
    AppState.debounceVoidFunction(
      callerKey: 'UserInterface.keepControlsAlive',
      debounceDuration: ALGERNON.showControlsDebounceDuration,
      voidFunction: () {
        _hideControlsTimer.cancel();
        _hideControlsTimer = Timer(ALGERNON.hideControlsDelay, _hideControls);

        UserInterface.controlsAreVisibleNotifier.value = true;
      },
    );
  }

  static void _hideControls() {
    //AppState.log("_hideControls()");
    _hideControlsTimer.cancel();
    UserInterface.controlsAreVisibleNotifier.value = false;
  }
}

class _UserInterfaceState extends State<UserInterface> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = Screen.size(context);

    /// Fade controls in or out
    return ValueListenableBuilder(
      valueListenable: UserInterface.controlsAreVisibleNotifier,
      builder: (context, controlsAreVisible, child) {
        return IgnorePointer(
          ignoring: !controlsAreVisible,
          child: AnimatedOpacity(
            opacity: controlsAreVisible ? 1.0 : 0.0,
            duration: controlsAreVisible
                ? ALGERNON.showControlsFadeDuration
                : ALGERNON.hideControlsFadeDuration,
            child: Stack(
              children: [
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: AlgernonPlayer.soLoudIsReady
                            ? const PlaybackBar()
                            : const SizedBox.shrink(),
                      ),

                      const PauseToggle(),
                      const Flexible(child: TrackChooser()),
                    ],
                  ),
                ),

                /// Shader-specific controls block
                PositionedDirectional(
                  top: 0,
                  //bottom: 0,
                  start: 0,
                  width: (screenSize.width * 0.333).clamp(
                    ALGERNON.controlPanelWidthMin,
                    ALGERNON.controlPanelWidthMax,
                  ),
                  child: FocusTraversalGroup(
                    child: ListenableBuilder(
                      listenable: AlgernonPlayer.painterConfig,
                      builder: (context, child) {
                        return MainControlPanel(
                          currentShader:
                              AlgernonPlayer.painterConfig.currentShader,
                        );
                      },
                    ),
                  ),
                ),

                /// Volume slider
                PositionedDirectional(
                  top: screenSize.height * 0.5,
                  bottom:
                      kToolbarHeight +
                      Screen.uiSizesFromContext(context).paddingSmall,
                  end: 0,
                  child: const VolumeSlider(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
