import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_script/services/recognition_service.dart';

void main() {
  test('Yetersiz nokta varsa ? döndürür', () {
    final service = RecognitionService();

    final result = service.recognizeLetter([
      const Offset(0, 0),
      const Offset(1, 1),
    ]);

    expect(result, "?");
  });

  test('Dikey çizim I olarak tahmin edilir', () {
    final service = RecognitionService();

    final points = List.generate(
      20,
      (i) => Offset(10, i * 5),
    );

    final result = service.recognizeLetter(points);

    expect(result, "I");
  });

  test('Kapalı şekil O olarak tahmin edilir', () {
    final service = RecognitionService();

    final points = <Offset>[
      const Offset(0, 0),
      const Offset(10, 0),
      const Offset(20, 10),
      const Offset(20, 20),
      const Offset(10, 30),
      const Offset(0, 20),
      const Offset(0, 10),
      const Offset(0, 0),
    ];

    final result = service.recognizeLetter(points);

    expect(result, "O");
  });
}