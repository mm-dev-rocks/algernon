// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/enum.dart';
import 'package:algernon/screen.dart';
import 'package:flutter/material.dart';

class ScaleMeterWidget extends StatelessWidget {
  const ScaleMeterWidget({super.key});

  final double dotSize = 6;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Rendering scale: ${AlgernonPlayer.painterConfig.scale.name.toUpperCase()}',
      child: Column(
        verticalDirection: .up,
        spacing: dotSize,
        children: [
          ...RenderScale.values.asMap().entries.map(
            (MapEntry<int, RenderScale> entry) => Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  width: 1,
                  color: ALGERNON.uiSoftForegroundColor,
                  //color: entry.key <= AlgernonPlayer.painterConfig.scale.index
                  //    ? ALGERNON.uiSoftForegroundColor
                  //    : ALGERNON.uiInactiveForegroundColor,
                ),
                color: entry.key <= AlgernonPlayer.painterConfig.scale.index
                    ? ALGERNON.uiSoftForegroundColor
                    : null,
              ),
              width: dotSize,
              height: dotSize,
            ),
          ),
        ],
      ),
    );
  }
}
