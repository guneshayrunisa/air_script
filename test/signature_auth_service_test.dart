import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_script/services/signature_auth_service.dart';

void main() {
  late SignatureAuthService authService;

  setUp(() {
    authService = SignatureAuthService();
  });

  group('SignatureAuthService Testleri', () {
    test('Normalize edilen imza noktaları boş olmamalı', () {
      final points = <Offset>[
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
      ];

      final normalized = authService.normalizePointsForTest(points);

      expect(normalized, isNotEmpty);
    });

    test('Boş nokta listesi normalize edilince boş dönmeli', () {
      final normalized = authService.normalizePointsForTest([]);

      expect(normalized, isEmpty);
    });

    test('Resample sonrası hedef nokta sayısı 64 olmalı', () {
      final points = List.generate(
        10,
        (i) => Offset(i.toDouble(), i.toDouble()),
      );

      final result = authService.resamplePointsForTest(
        points,
        targetCount: 64,
      );

      expect(result.length, 64);
    });

    test('Tek noktalı liste resample edilirse aynı liste dönmeli', () {
      final points = <Offset>[
        const Offset(5, 5),
      ];

      final result = authService.resamplePointsForTest(
        points,
        targetCount: 64,
      );

      expect(result.length, 1);
      expect(result.first, const Offset(5, 5));
    });
  });
}