// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/memory_slot_copy_model.dart';
import 'package:algernon/memory_slot_button.dart';
import 'package:algernon/memory_slot_drag_feedback.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';

class MemorySlotChooser extends StatefulWidget {
  const MemorySlotChooser({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  State<MemorySlotChooser> createState() => _MemorySlotChooserState();
}

class _MemorySlotChooserState extends State<MemorySlotChooser> {
  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);
    //int selectedIndex = AlgernonPlayer.painterConfig.currentMemorySlot;
    return SizedBox(
      width: Screen.mainControlPanelWidth(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: uiSizes.paddingSmall,
          right: uiSizes.paddingSmall,
        ),
        child: Row(
          mainAxisSize: .max,
          //mainAxisAlignment: .spaceBetween,
          children: List.generate(
            ALGERNON.totalMemorySlots,
            (int index) => Expanded(
              child: LongPressDraggable<MemorySlotCopyModel>(
                delay: Duration(milliseconds: 150),
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: MemorySlotDragFeedback(index: index),
                data: MemorySlotCopyModel(
                  slotIndex: index,
                  preferenceKeys: _getPrefKeysFromIndex(index),
                ),

                child: DragTarget<MemorySlotCopyModel>(
                  builder: (context, candidateItems, rejectedItems) {
                    return MemorySlotButton(
                      index: index,
                      selected: (index == widget.selectedIndex),
                      highlighted: candidateItems.isNotEmpty,
                      onPressed: () {
                        _selectSlot(index);
                      },
                    );
                  },
                  onAcceptWithDetails: (details) {
                    if (details.data.slotIndex != index) {
                      _copySlotFromDetails(details, index);
                      _selectSlot(index);
                    }
                    UserInterface.keepControlsAlive();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Set<String> _getPrefKeysFromIndex(int index) {
    return AppState.allPreferenceKeys
        .where(
          (String prefKey) =>
              prefKey.startsWith('${ALGERNON.memorySlotPrefPrefix}$index'),
        )
        .toSet();
  }

  void _copySlotFromDetails(DragTargetDetails details, int toIndex) {
    for (final String fromPrefKey in details.data.preferenceKeys) {
      String toPrefKey = fromPrefKey.replaceFirst(
        '${ALGERNON.memorySlotPrefPrefix}${details.data.slotIndex}',
        '${ALGERNON.memorySlotPrefPrefix}$toIndex',
      );
      AppState.setPreference(toPrefKey, AppState.getPreference(fromPrefKey));
    }
  }

  void _selectSlot(int index) {
    AlgernonPlayer.painterConfig.currentMemorySlot = index;
    UserInterface.keepControlsAlive();
    //setState(() {
    //  /// To update selection state
    //});
  }
}
