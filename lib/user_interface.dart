// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/file_chooser.dart';
import 'package:algernon/algernon_window.dart';
import 'package:algernon/loop_cycle_button.dart';
import 'package:algernon/main_control_panel.dart';
import 'package:algernon/pause_toggle.dart';
import 'package:algernon/playback_bar.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/volume_slider.dart';
import 'package:flutter/material.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({super.key});

  static Timer _hideControlsTimer = Timer(
    ALGERNON.hideControlsDelay,
    hideControls,
  );

  static ValueNotifier<bool> controlsAreVisibleNotifier = ValueNotifier(true);

  @override
  State<UserInterface> createState() => _UserInterfaceState();

  static void keepControlsAlive() {
    //AppState.log("UserInterface::keepControlsAlive()");
    AppState.debounceVoidFunction(
      callerKey: 'UserInterface.keepControlsAlive',
      debounceDuration: ALGERNON.showControlsDebounceDuration,
      voidFunction: () {
        _hideControlsTimer.cancel();
        _hideControlsTimer = Timer(ALGERNON.hideControlsDelay, hideControls);

        UserInterface.controlsAreVisibleNotifier.value = true;
      },
    );
  }

  static void hideControls() {
    /// If there are no tracks in the playlist, leave the UI visible as a hint.
    if (FileChooser.playlistNotifier.currentPlaylist.isNotEmpty) {
      //AppState.log("UserInterface::hideControls()");
      _hideControlsTimer.cancel();
      UserInterface.controlsAreVisibleNotifier.value = false;
    }
  }
}

class _UserInterfaceState extends State<UserInterface> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = Screen.size(context);
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    /// Fade controls in or out
    return ValueListenableBuilder(
      valueListenable: UserInterface.controlsAreVisibleNotifier,
      builder: (context, controlsAreVisible, child) {
        return SafeArea(
          child: IgnorePointer(
            ignoring: !controlsAreVisible,
            child: AnimatedOpacity(
              opacity: controlsAreVisible ? 1.0 : 0.0,
              curve: controlsAreVisible ? Curves.easeOut : Curves.easeOut,
              duration: controlsAreVisible
                  ? ALGERNON.showControlsFadeDuration
                  : ALGERNON.hideControlsFadeDuration,
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    child: AlgernonWindow(),
                  ),
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

                        SizedBox(width: uiSizes.paddingMedium),

                        Row(
                          children: [
                            const PauseToggle(),
                            IconButton(
                              mouseCursor: SystemMouseCursors.click,
                              icon: Icon(
                                Icons.skip_previous,
                                color: ALGERNON.uiDefaultForegroundColor,
                              ),
                              onPressed: () async {
                                FileChooser.selectPrev();
                                await AlgernonPlayer.playSelectedSound(
                                  reason: 'UserInterface::skipPrevious button',
                                );
                                UserInterface.keepControlsAlive();
                              },
                            ),
                            IconButton(
                              mouseCursor: SystemMouseCursors.click,
                              icon: Icon(
                                Icons.skip_next,
                                color: ALGERNON.uiDefaultForegroundColor,
                              ),
                              onPressed: () async {
                                FileChooser.selectNext();
                                await AlgernonPlayer.playSelectedSound(
                                  reason: 'UserInterface::skipNext button',
                                );
                                UserInterface.keepControlsAlive();
                              },
                            ),
                            const LoopCycleButton(),
                          ],
                        ),

                        SizedBox(width: uiSizes.paddingMedium),

                        const Flexible(child: FileChooser()),
                      ],
                    ),
                  ),

                  /// Shader-specific controls block
                  PositionedDirectional(
                    top: 0,
                    //bottom: 0,
                    end: 0,
                    width:
                        Screen.mainControlPanelWidth(context) +
                        ALGERNON.autoCountButtonSize.width,
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
                    // [kToolbarHeight] matches [DropdownMenu] height.
                    bottom:
                        kToolbarHeight +
                        Screen.uiSizesFromContext(context).paddingSmall,
                    start: 0,
                    child: const VolumeSlider(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
