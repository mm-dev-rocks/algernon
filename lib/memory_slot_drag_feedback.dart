// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
import 'package:flutter/material.dart';

class MemorySlotDragFeedback extends StatelessWidget {
  const MemorySlotDragFeedback({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    return Padding(
      padding: EdgeInsets.only(
        left: uiSizes.paddingMedium,
        bottom: uiSizes.paddingMedium,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: ALGERNON.buttonBorderThickness,
          ),
          color: Colors.black.withValues(
            alpha: ALGERNON.fadeDarkBackgroundOpacity,
          ),
        ),
        child: Text('Drag to another slot to \ncopy slot [${index + 1}] to it'),
      ),
    );
  }
}
