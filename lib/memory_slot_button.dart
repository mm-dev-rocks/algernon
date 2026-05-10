// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/constants.dart';
import 'package:flutter/material.dart';

class MemorySlotButton extends StatelessWidget {
  MemorySlotButton({
    super.key,
    required this.index,
    required this.onPressed,
    required this.selected,
    this.highlighted = false,
  });

  final int index;
  final VoidCallback? onPressed;
  final bool highlighted;
  final bool selected;

  final BoxBorder border = Border.all(
    color: Colors.white,
    width: ALGERNON.buttonBorderThickness,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onPressed,
      //customBorder: const RoundedRectangleBorder(),
      child: Tooltip(
        message: 'Memory slot ${index + 1}',
        child: Container(
          //width: double.infinity,
          width: ALGERNON.memorySlotButtonSize.width,
          height: ALGERNON.memorySlotButtonSize.height,
          //padding: EdgeInsets.all(
          //  Screen.uiSizesFromContext(context).paddingSmall,
          //),
          decoration: highlighted
              ? BoxDecoration(
                  //border: border,
                  color: ALGERNON.uiAttractColor,
                )
              : selected
              ? BoxDecoration(
                  //border: border
                )
              : null,
          child: Icon(
            IconData(
              /// Icons actually use a font so we can step through the sequential 'numbers in a box' (filter_n)
              /// characters.
              Icons.filter_1.codePoint + index,
              fontFamily: 'MaterialIcons',
            ),
            color: selected ? Colors.white : ALGERNON.uiDefaultForegroundColor,
          ),
        ),
      ),
    );
  }
}
