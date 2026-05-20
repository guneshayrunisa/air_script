import 'package:flutter/material.dart';

class SavedDrawing {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Offset?> points;

  SavedDrawing({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'points': points.map((point) {
        if (point == null) return null;
        return {
          'x': point.dx,
          'y': point.dy,
        };
      }).toList(),
    };
  }

  factory SavedDrawing.fromJson(Map<String, dynamic> json) {
    return SavedDrawing(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      points: (json['points'] as List).map<Offset?>((item) {
        if (item == null) return null;
        return Offset(
          (item['x'] as num).toDouble(),
          (item['y'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}