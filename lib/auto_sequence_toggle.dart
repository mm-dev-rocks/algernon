// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
import 'package:flutter/material.dart';

class AutoSequenceToggle extends StatefulWidget {
  const AutoSequenceToggle({super.key});

  @override
  State<AutoSequenceToggle> createState() => _AutoSequenceToggleState();
}

class _AutoSequenceToggleState extends State<AutoSequenceToggle> {
  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    return InkWell(
      onTap: AlgernonPlayer.playlistNotifier.currentTrackHasSequencing
          ? () {
              AppState.setPreference(
                'useShaderSequenceWhereAvailable',
                !AppState.getPreference('useShaderSequenceWhereAvailable'),
              );
              setState(() {});
            }
          : null,
      child: Padding(
        padding: EdgeInsets.only(top: 5, right: uiSizes.paddingMedium),
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(
              'Auto sequence',
              style: TextStyle(
                color: AlgernonPlayer.playlistNotifier.currentTrackHasSequencing
                    ? ALGERNON.uiStrongForegroundColor
                    : ALGERNON.uiDefaultForegroundColor,
              ),
            ),
            Checkbox(
              value: AppState.getPreference('useShaderSequenceWhereAvailable'),
              onChanged:
                  AlgernonPlayer.playlistNotifier.currentTrackHasSequencing
                  ? (bool? value) {
                      AppState.setPreference(
                        'useShaderSequenceWhereAvailable',
                        value,
                      );
                      setState(() {});
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
