// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //const Tooltip(message: 'Volume', child: Icon(Icons.campaign_outlined)),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: AlgernonPlayer.currentSoundHandle != null
                  ? SoLoud.instance.getGlobalVolume()
                  : 1,
              onChanged: (double value) {
                if (AlgernonPlayer.soLoudIsReady &&
                    AlgernonPlayer.currentSoundHandle != null) {
                  setState(() {
                    SoLoud.instance.setGlobalVolume(value);
                  });
                }
                UserInterface.keepControlsAlive();
              },
            ),
          ),
        ),
        Tooltip(
          message: 'Volume',
          child: Icon(
            Icons.headphones_outlined,
            color: ALGERNON.uiDefaultForegroundColor,
          ),
        ),
      ],
    );
  }
}
