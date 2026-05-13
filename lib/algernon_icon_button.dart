// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/constants.dart';
import 'package:flutter/material.dart';

class AlgernonIconButton extends StatelessWidget {
  const AlgernonIconButton({
    super.key,
    required this.iconData,
    this.tooltip,
    this.color,
    this.onPressed,
  });

  final String? tooltip;
  final Color? color;
  final IconData iconData;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      icon: Icon(iconData),
      tooltip: tooltip,
      onPressed: onPressed,
      color: color ?? ALGERNON.uiDefaultForegroundColor,
      disabledColor: ALGERNON.uiInactiveForegroundColor,
      //disabledColor: Colors.red,
    );
  }
}
