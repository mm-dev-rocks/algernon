// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_model.dart';
import 'package:flutter/material.dart';

class ShaderChooser extends StatelessWidget {
  const ShaderChooser({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<ShaderModel>(
      width: Screen.mainControlPanelWidth(context),
      selectOnly: true,
      initialSelection: AlgernonPlayer.painterConfig.currentShader,
      onSelected: (ShaderModel? value) {
        if (value != null) {
          AlgernonPlayer.painterConfig.currentShader = value;
        }
      },
      dropdownMenuEntries: ALGERNON.shadersData
          .map<DropdownMenuEntry<ShaderModel>>(
            (ShaderModel shaderMeta) => DropdownMenuEntry<ShaderModel>(
              value: shaderMeta,
              label: shaderMeta.friendlyName,
              //label: shaderMeta.friendlyName.toUpperCase(),
              style: MenuItemButton.styleFrom(foregroundColor: ALGERNON.uiStrongForegroundColor),
            ),
          )
          .toList(),
    );
  }
}
