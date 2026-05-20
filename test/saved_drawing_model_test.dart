import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_script/models/saved_drawing.dart';

void main() {
  test('SavedDrawing JSON dönüşümü doğru çalışır', () {
    final drawing = SavedDrawing(
      id: '1',
      name: 'Test Drawing',
      createdAt: DateTime.parse('2026-05-20T10:00:00'),
      points: [const Offset(10, 20), null, const Offset(30, 40)],
    );

    final json = drawing.toJson();
    final restored = SavedDrawing.fromJson(json);

    expect(restored.id, drawing.id);
    expect(restored.name, drawing.name);
    expect(restored.points.length, drawing.points.length);
    expect(restored.points[0], const Offset(10, 20));
    expect(restored.points[1], null);
    expect(restored.points[2], const Offset(30, 40));
  });
}
