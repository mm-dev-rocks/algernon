// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/constants.dart';
import 'package:algernon/screen.dart';
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
    color: ALGERNON.uiStrongForegroundColor,
    width: ALGERNON.buttonBorderThickness,
  );

  final BoxBorder borderSoft = Border.all(
    color: ALGERNON.uiSoftForegroundColor,
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
          //width: ALGERNON.memorySlotButtonSize.width,
          ////height: ALGERNON.memorySlotButtonSize.height,
          decoration: highlighted
              ? BoxDecoration(border: border, color: ALGERNON.uiAttractColor)
              : selected
              ? BoxDecoration(border: border)
              : BoxDecoration(border: borderSoft),
          child: Padding(
            padding: EdgeInsets.all(
              Screen.uiSizesFromContext(context).paddingSmall,
            ),
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? ALGERNON.uiStrongForegroundColor
                    : ALGERNON.uiDefaultForegroundColor,
              ),
            ),
          ),

          //Icon(
          //    IconData(
          //      /// Icons actually use a font so we can step through the sequential 'numbers in a box' (filter_n)
          //      /// characters.
          //      Icons.filter_1.codePoint + index,
          //      fontFamily: 'MaterialIcons',
          //    ),
          //    color: selected ? ALGERNON.uiStrongForegroundColor : ALGERNON.uiDefaultForegroundColor,
          //  ),
        ),
      ),
    );
  }
}
