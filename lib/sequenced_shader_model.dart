// SPDX-License-Identifier: GPL-3.0-only

/// Used during copy operations between memory slots (eg drag/drop to copy).
class SequencedShaderModel {
  SequencedShaderModel({
    required this.timestamp,
    required this.shaderModelId,
    required this.memorySlotIndex,
  });

  final Duration timestamp;
  final String shaderModelId;
  final int memorySlotIndex;
}
