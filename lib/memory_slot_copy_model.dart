// SPDX-License-Identifier: GPL-3.0-only

/// Used during copy operations between memory slots (eg drag/drop to copy).
class MemorySlotCopyModel {
  MemorySlotCopyModel({required this.slotIndex, required this.preferenceKeys});

  final int slotIndex;
  final Set<String> preferenceKeys;

  @override
  String toString() {
    return '''slotIndex: $slotIndex
    preferenceKeys: ${preferenceKeys.toString()}''';
  }
}
