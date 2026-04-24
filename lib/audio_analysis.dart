// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioAnalysis {
  // High-resolution energy data computed once on track load.
  // All other methods derive from this.
  static List<double> _highResolutionTrackEnergyBuckets = [];
  static Duration _trackDuration = Duration.zero;

  // Coarseness-calibrated data, recomputed whenever a new shader is loaded.
  static List<double> _calibratedEnergyBuckets = [];
  static double _calibratedMinEnergy = 0;
  static double _calibratedMaxEnergy = 1;
  static int _calibratedDivisions = 3;
  static int _calibratedMin = 0;
  static int _calibratedMax = 1;

  // ─── Setup ───────────────────────────────────────────────────────────────────

  /// Call once when a track is loaded. Reads the whole track and stores a
  /// high-resolution energy profile that all subsequent queries derive from.
  static Future<void> analyseTrackOnLoad({
    required String filePath,
    required Duration trackDuration,
  }) async {
    const int numberOfRawSamplesToRead = 5000;
    const int numberOfHighResolutionBuckets = 200;

    final Stopwatch stopwatch = Stopwatch()..start();

    final Float32List rawSamples = await SoLoud.instance.readSamplesFromFile(
      filePath,
      numberOfRawSamplesToRead,
      average: true,
    );

    debugPrint('readSamplesFromFile took ${stopwatch.elapsedMilliseconds}ms');

    _trackDuration = trackDuration;
    _highResolutionTrackEnergyBuckets = _computeEnergyBuckets(
      rawSamples: rawSamples,
      numberOfBuckets: numberOfHighResolutionBuckets,
    );

    _debugPrintEnergyProfile(
      energyBuckets: _highResolutionTrackEnergyBuckets,
      trackDuration: trackDuration,
    );
  }

  /// Call when a new shader is loaded. Downsamples the high-resolution energy
  /// profile to the requested coarseness and caches the min/max so that
  /// [energyValueAtPosition] can be called cheaply on every frame.
  static void calibrateForShader({
    required int coarseness,
    required int divisions,
    required int min,
    required int max,
  }) {
    assert(
      coarseness >= 1 && coarseness <= _highResolutionTrackEnergyBuckets.length,
      'coarseness must be between 1 and ${_highResolutionTrackEnergyBuckets.length}',
    );
    _calibratedEnergyBuckets = _resampleEnergyBuckets(
      sourceEnergyBuckets: _highResolutionTrackEnergyBuckets,
      targetNumberOfBuckets: coarseness,
    );
    _calibratedMinEnergy = _calibratedEnergyBuckets.reduce(
      (a, b) => a < b ? a : b,
    );
    _calibratedMaxEnergy = _calibratedEnergyBuckets.reduce(
      (a, b) => a > b ? a : b,
    );
    _calibratedDivisions = divisions;
    _calibratedMin = min;
    _calibratedMax = max;

    debugPrint(
      '_calibratedEnergyBuckets: ${_calibratedEnergyBuckets.toString()}',
    );
  }

  static void calibrateForShaderWithZones({
    required double boundaryThreshold,
    required int divisions,
    required int min,
    required int max,
    // number of buckets either side of boundary to blend across
    int blendBuckets = 0,
  }) {
    // Find zone boundaries where energy jumps by more than the threshold
    final List<int> boundaryIndices = [0];
    for (int i = 1; i < _highResolutionTrackEnergyBuckets.length; i++) {
      final double diff =
          (_highResolutionTrackEnergyBuckets[i] -
                  _highResolutionTrackEnergyBuckets[i - 1])
              .abs();
      if (diff > boundaryThreshold) {
        boundaryIndices.add(i);
      }
    }
    boundaryIndices.add(_highResolutionTrackEnergyBuckets.length);

    // Average energy within each zone and fill a bucket list of the same length
    final List<double> zoneFlattenedEnergyBuckets = List<double>.filled(
      _highResolutionTrackEnergyBuckets.length,
      0.0,
    );

    for (int z = 0; z < boundaryIndices.length - 1; z++) {
      final int zoneStart = boundaryIndices[z];
      final int zoneEnd = boundaryIndices[z + 1];
      final List<double> zoneBuckets = _highResolutionTrackEnergyBuckets
          .sublist(zoneStart, zoneEnd);
      final double zoneAverageEnergy =
          zoneBuckets.reduce((a, b) => a + b) / zoneBuckets.length;
      for (int i = zoneStart; i < zoneEnd; i++) {
        zoneFlattenedEnergyBuckets[i] = zoneAverageEnergy;
      }
    }

    if (blendBuckets > 0) {
      for (int z = 1; z < boundaryIndices.length - 1; z++) {
        final int boundaryIndex = boundaryIndices[z];
        final int blendStart = (boundaryIndex - blendBuckets).clamp(
          0,
          zoneFlattenedEnergyBuckets.length - 1,
        );
        final int blendEnd = (boundaryIndex + blendBuckets).clamp(
          0,
          zoneFlattenedEnergyBuckets.length - 1,
        );
        final double energyBefore = zoneFlattenedEnergyBuckets[blendStart];
        final double energyAfter = zoneFlattenedEnergyBuckets[blendEnd];
        for (int i = blendStart; i <= blendEnd; i++) {
          final double t = (i - blendStart) / (blendEnd - blendStart);
          zoneFlattenedEnergyBuckets[i] =
              energyBefore + t * (energyAfter - energyBefore);
        }
      }
    }

    // Store using same calibrated vars so normalisedEnergyValueAtPosition works unchanged
    _calibratedEnergyBuckets = zoneFlattenedEnergyBuckets;
    _calibratedMinEnergy = _calibratedEnergyBuckets.reduce(
      (a, b) => a < b ? a : b,
    );
    _calibratedMaxEnergy = _calibratedEnergyBuckets.reduce(
      (a, b) => a > b ? a : b,
    );
    _calibratedDivisions = divisions;
    _calibratedMin = min;
    _calibratedMax = max;

    final double bucketDurationInSeconds =
        _trackDuration.inSeconds / _calibratedEnergyBuckets.length;
    final StringBuffer buffer = StringBuffer('Zone energy profile:\n');
    for (int b = 0; b < _calibratedEnergyBuckets.length; b++) {
      final double energy = _calibratedEnergyBuckets[b];
      final String bar = '█' * (energy * 40).round();
      final int seconds = (b * bucketDurationInSeconds).round();
      final String mm = (seconds ~/ 60).toString().padLeft(2, '0');
      final String ss = (seconds % 60).toString().padLeft(2, '0');
      buffer.writeln('$mm:$ss  $bar ${energy.toStringAsFixed(3)}');
    }
    debugPrint(buffer.toString());
  }

  // ─── Query ───────────────────────────────────────────────────────────────────

  /// Returns a single integer representing the energy at the given playback
  /// position, quantised using the currently calibrated coarseness, divisions,
  /// min and max. Cheap to call every frame after [calibrateForShader] has run.
  static int energyValueAtPosition({required Duration playbackPosition}) {
    if (_calibratedEnergyBuckets.isEmpty || _trackDuration == Duration.zero) {
      return _calibratedMin;
    }

    final double trackProgressFraction =
        (playbackPosition.inMilliseconds / _trackDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );

    final int bucketIndex =
        (trackProgressFraction * (_calibratedEnergyBuckets.length - 1)).round();

    final double bucketEnergy = _calibratedEnergyBuckets[bucketIndex];

    final double energyFraction =
        ((bucketEnergy - _calibratedMinEnergy) /
                (_calibratedMaxEnergy - _calibratedMinEnergy))
            .clamp(0.0, 1.0);

    final int discreteStep = (energyFraction * (_calibratedDivisions - 1))
        .round();
    final double stepFraction = discreteStep / (_calibratedDivisions - 1);

    return (_calibratedMin + stepFraction * (_calibratedMax - _calibratedMin))
        .round();
  }

  static double normalisedEnergyValueAtPosition({
    required Duration playbackPosition,
  }) {
    final int rawValue = energyValueAtPosition(
      playbackPosition: playbackPosition,
    );
    return (rawValue - _calibratedMin) / (_calibratedMax - _calibratedMin);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────────

  static List<double> _computeEnergyBuckets({
    required Float32List rawSamples,
    required int numberOfBuckets,
  }) {
    final int samplesPerBucket = rawSamples.length ~/ numberOfBuckets;
    return List<double>.generate(numberOfBuckets, (int bucketIndex) {
      double bucketEnergySum = 0;
      for (
        int i = bucketIndex * samplesPerBucket;
        i < (bucketIndex + 1) * samplesPerBucket;
        i++
      ) {
        bucketEnergySum += rawSamples[i].abs();
      }
      return bucketEnergySum / samplesPerBucket;
    });
  }

  static List<double> _resampleEnergyBuckets({
    required List<double> sourceEnergyBuckets,
    required int targetNumberOfBuckets,
  }) {
    final double sourceBucketsPerTargetBucket =
        sourceEnergyBuckets.length / targetNumberOfBuckets;
    return List<double>.generate(targetNumberOfBuckets, (
      int targetBucketIndex,
    ) {
      final int sourceStart = (targetBucketIndex * sourceBucketsPerTargetBucket)
          .floor();
      final int sourceEnd =
          ((targetBucketIndex + 1) * sourceBucketsPerTargetBucket)
              .floor()
              .clamp(0, sourceEnergyBuckets.length);
      final List<double> sourceBucketsInRange = sourceEnergyBuckets.sublist(
        sourceStart,
        sourceEnd,
      );
      return sourceBucketsInRange.reduce((a, b) => a + b) /
          sourceBucketsInRange.length;
    });
  }

  static void _debugPrintEnergyProfile({
    required List<double> energyBuckets,
    required Duration trackDuration,
  }) {
    final double bucketDurationInSeconds =
        trackDuration.inSeconds / energyBuckets.length;
    final StringBuffer buffer = StringBuffer('Track energy profile:\n');
    for (int b = 0; b < energyBuckets.length; b++) {
      final double energy = energyBuckets[b];
      final String bar = '█' * (energy * 40).round();
      final int seconds = (b * bucketDurationInSeconds).round();
      final String mm = (seconds ~/ 60).toString().padLeft(2, '0');
      final String ss = (seconds % 60).toString().padLeft(2, '0');
      buffer.writeln('$mm:$ss  $bar ${energy.toStringAsFixed(3)}');
    }
    debugPrint(buffer.toString());
  }

  static double suggestedBoundaryThreshold({double sensitivity = 1.0}) {
    final List<double> differences = [];
    for (int i = 1; i < _highResolutionTrackEnergyBuckets.length; i++) {
      differences.add(
        (_highResolutionTrackEnergyBuckets[i] -
                _highResolutionTrackEnergyBuckets[i - 1])
            .abs(),
      );
    }
    final double mean =
        differences.reduce((a, b) => a + b) / differences.length;
    final double variance =
        differences
            .map((d) => (d - mean) * (d - mean))
            .reduce((a, b) => a + b) /
        differences.length;
    final double standardDeviation = sqrt(variance);

    return mean + standardDeviation * sensitivity;
  }
}
