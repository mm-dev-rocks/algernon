// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/lib/memory_slot_copy_model.dart';
import 'package:algernon/memory_slot_button.dart';
import 'package:algernon/screen.dart';
import 'package:flutter/material.dart';

class MemorySlotChooser extends StatefulWidget {
  const MemorySlotChooser({super.key});

  @override
  State<MemorySlotChooser> createState() => _MemorySlotChooserState();
}

class _MemorySlotChooserState extends State<MemorySlotChooser> {
  @override
  Widget build(BuildContext context) {
    dynamic uiSizes = Screen.uiSizesFromContext(context);

    return Row(
      mainAxisSize: .max,
      mainAxisAlignment: .spaceBetween,
      children: List.generate(
        ALGERNON.totalMemorySlots,
        (int index) => Expanded(
          child: LongPressDraggable<MemorySlotCopyModel>(
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Padding(
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
                child: Text(
                  'Drag to another slot to \ncopy slot [$index] to it',
                ),
              ),
            ),
            data: MemorySlotCopyModel(
              slotIndex: index,
              preferenceKeys: AppState.allPreferenceKeys
                  .where(
                    (String key) => key.startsWith(
                      '${ALGERNON.memorySlotPrefPrefix}$index',
                    ),
                  )
                  .toSet(),
            ),

            child: DragTarget<MemorySlotCopyModel>(
              builder: (context, candidateItems, rejectedItems) {
                return MemorySlotButton(
                  index: index,
                  highlighted: candidateItems.isNotEmpty,
                  onPressed: () {
                    AlgernonPlayer.painterConfig.currentMemorySlot = index;
                    //_showControlsThenHideDebounced();
                    setState(() {
                      /// To update selection state
                    });
                  },
                );
              },
              onAcceptWithDetails: (details) {
                if (details.data.slotIndex != index) {
                  for (final String prefKeyFrom
                      in details.data.preferenceKeys) {
                    String prefKeyTo = prefKeyFrom.replaceFirst(
                      '${ALGERNON.memorySlotPrefPrefix}${details.data.slotIndex}',
                      '${ALGERNON.memorySlotPrefPrefix}$index',
                    );
                    AppState.setPreference(
                      prefKeyTo,
                      AppState.getPreference(prefKeyFrom),
                    );
                    //debugPrint('from: $prefKeyFrom');
                    //debugPrint('to: $prefKeyTo');
                  }
                } else {}
              },
            ),
          ),
        ),
      ),
    );
  }
}
