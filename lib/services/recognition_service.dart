import 'package:flutter/material.dart';
import '../models/letter_sample.dart';

class RecognitionService {
  String recognizeLetter(
    List<Offset> rawPoints, {
    List<LetterSample> samples = const [],
  }) {
    if (rawPoints.length < 8) return "?";

    if (samples.isNotEmpty) {
      final learnedGuess = _recognizeFromSamples(rawPoints, samples);

      if (learnedGuess != "?") {
        return learnedGuess;
      }
    }

    return _ruleBasedGuess(rawPoints);
  }

  String _recognizeFromSamples(
    List<Offset> rawPoints,
    List<LetterSample> samples,
  ) {
    final input = _resamplePoints(
      _normalizePoints(rawPoints),
      targetCount: 48,
    );

    if (input.length < 8) return "?";

    String bestLetter = "?";
    double bestScore = double.infinity;

    for (final sample in samples) {
      final samplePoints = _resamplePoints(
        _normalizePoints(sample.points),
        targetCount: 48,
      );

      if (samplePoints.length != input.length) continue;

      double distance = 0;

      for (int i = 0; i < input.length; i++) {
        distance += (input[i] - samplePoints[i]).distance;
      }

      final score = distance / input.length;

      if (score < bestScore) {
        bestScore = score;
        bestLetter = sample.letter;
      }
    }

    if (bestScore < 38) {
      return bestLetter;
    }

    return "?";
  }

  String _ruleBasedGuess(List<Offset> rawPoints) {
    final points = _normalizePoints(rawPoints);

    if (points.length < 8) return "?";

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    final start = points.first;
    final end = points.last;
    final closed = (end - start).distance < 28;

    if (closed) return "O";
    if (height > width * 2.3) return "I";
    if (width > height * 2.0) return "-";

    return "?";
  }

  List<Offset> _normalizePoints(
    List<Offset> rawPoints, {
    double targetSize = 100,
  }) {
    if (rawPoints.isEmpty) return [];

    double minX = rawPoints.first.dx;
    double maxX = rawPoints.first.dx;
    double minY = rawPoints.first.dy;
    double maxY = rawPoints.first.dy;

    for (final p in rawPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    if (width == 0 || height == 0) return rawPoints;

    final scale = targetSize / (width > height ? width : height);

    return rawPoints.map((p) {
      return Offset(
        (p.dx - minX) * scale,
        (p.dy - minY) * scale,
      );
    }).toList();
  }

  List<Offset> _resamplePoints(
    List<Offset> points, {
    int targetCount = 48,
  }) {
    if (points.length <= 1) return points;

    final result = <Offset>[];

    for (int i = 0; i < targetCount; i++) {
      final index = (i / (targetCount - 1)) * (points.length - 1);
      final lower = index.floor();
      final upper = index.ceil();

      if (lower == upper) {
        result.add(points[lower]);
      } else {
        final t = index - lower;
        final interpolated = Offset.lerp(points[lower], points[upper], t);

        if (interpolated != null) {
          result.add(interpolated);
        }
      }
    }

    return result;
  }
}