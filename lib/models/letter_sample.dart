import 'package:flutter/material.dart';

class LetterSample {
  final String letter;
  final List<Offset> points;

  LetterSample({
    required this.letter,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'points': points.map((p) {
        return {
          'x': p.dx,
          'y': p.dy,
        };
      }).toList(),
    };
  }

  factory LetterSample.fromJson(Map<String, dynamic> json) {
    return LetterSample(
      letter: json['letter'],
      points: (json['points'] as List).map<Offset>((item) {
        return Offset(
          (item['x'] as num).toDouble(),
          (item['y'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}