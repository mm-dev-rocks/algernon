// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/app_state.dart';
import 'package:algernon/constants.dart';
import 'package:algernon/memory_slot_copy_model.dart';
import 'package:algernon/memory_slot_button.dart';
import 'package:algernon/memory_slot_drag_feedback.dart';
import 'package:algernon/screen.dart';
import 'package:algernon/shader_model.dart';
import 'package:algernon/shader_defaults.dart' as shader_defaults;
import 'package:algernon/user_interface.dart';
import 'package:flutter/material.dart';
import 'package:algernon/shaders_meta_data.dart' as meta;

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
                delay: Duration(milliseconds: ALGERNON.longPressMillisecs),
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: MemorySlotDragFeedback(index: index),
                data: MemorySlotCopyModel(
                  slotIndex: index,
                  //preferenceKeys: _getPrefKeysFromIndex(index),
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

  //Set<String> _getPrefKeysFromIndex(int index) {
  //  return AppState.allPreferenceKeys
  //      .where(
  //        (String prefKey) =>
  //            prefKey.startsWith('${ALGERNON.memorySlotPrefPrefix}$index'),
  //      )
  //      .toSet();
  //}

  void _copySlotFromDetails(DragTargetDetails details, int toIndex) {
    /// Get relevant info about the currently in-use shader.
    int fromIndex = details.data.slotIndex;
    String currentShaderId = AlgernonPlayer.painterConfig.currentShader.id;
    ShaderModel currentShader = meta.shadersData.firstWhere(
      (shader) => shader.id == currentShaderId,
    );

    /// For all properties in the slot we're copying **TO**, we need to either:
    /// - Copy the **FROM** property, or
    /// - Copy any matching property from [shaderDefaults] (some shaders have multiple defaults for different mem slots
    ///   so to make sure the exact shader details are copied we might need to copy those across)
    /// - Delete the existing property. This is necessary because non-existant properties use default values, so if we
    /// don't delete them they will persist (if **FROM** uses a default, we have to ensure that **TO** goes back to
    /// using that default)
    for (String tweakId in currentShader.shaderTweaks.keys) {
      String fromKey =
          "${ALGERNON.memorySlotPrefPrefix}$fromIndex-$currentShaderId-$tweakId";
      String toKey =
          "${ALGERNON.memorySlotPrefPrefix}$toIndex-$currentShaderId-$tweakId";

      /// Delete all for a clean start
      AppState.deletePreference(toKey);

      debugPrint('*** copying slot [$fromKey] -> [$toKey]');

      /// Copy settings for this tweak from one of:
      /// - A saved preference for the slot we're copying from
      /// - A default for the slot we're copying from (remember different slots may have different defaults)

      dynamic prefToCopy = AppState.getPreference(fromKey);
      //dynamic prefToCopy = AppState.getPreference(fromKey, useDefaults: false);

      if (prefToCopy == null) {
        if (shader_defaults.shaderDefaults[fromKey] != null) {
          debugPrint('- FOUND DEFAULT SETTING');
          prefToCopy = shader_defaults.shaderDefaults[fromKey][1];
        } else {
          debugPrint('- FOUND NOTHING');
        }
      } else {
        debugPrint('- FOUND USER SETTING');
      }

      //dynamic prefToCopy =
      //    AppState.getPreference(fromKey, useDefaults: false) ??
      //        shader_defaults.shaderDefaults[fromKey] == null
      //    ? null
      //    /// Default prefs are a [List] of [`runtimeType`, `value`]
      //    : shader_defaults.shaderDefaults[fromKey][1];
      debugPrint('- prefToCopy: $prefToCopy');

      if (prefToCopy == null) {
        /// Already deleted earlier
        //debugPrint('- DELETING');
        //AppState.deletePreference(toKey);
      } else {
        debugPrint('- COPYING');
        AppState.setPreference(toKey, prefToCopy);
      }
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
