// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:flutter/material.dart';

class MemorySlotButton extends StatelessWidget {
  const MemorySlotButton({
    super.key,
    required this.index,
    required this.onPressed,
  });

  final int index;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    bool isSelected =
        (index == AppState.getPreference('selectedMemorySlotIndex'));

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onPressed,
      customBorder: const RoundedRectangleBorder(),
      child: Tooltip(
        message: 'Memory slot $index',
        child: Container(
          width: double.infinity,
          decoration: isSelected
              ? BoxDecoration(border: Border.all(color: Colors.white, width: 2))
              : BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: ALGERNON.disabledControlOpacity,
                  ),
                ),
          child: Text(
            index.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}
