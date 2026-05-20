import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/saved_drawing.dart';
import 'signature_auth_service.dart';

class FirebaseDrawingService {
  final SignatureAuthService _authService = SignatureAuthService();
  static const String projectId = 'airscript-gunes-2026';

  Future<void> saveDrawing(SavedDrawing drawing) async {
    final userId = await _authService.getCurrentUserId();

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/saved_drawings/${drawing.id}',
    );

    final body = {
      'fields': {
        'userId': {'stringValue': userId ?? 'unknown'},
        'id': {'stringValue': drawing.id},
        'name': {'stringValue': drawing.name},
        'createdAt': {'stringValue': drawing.createdAt.toIso8601String()},
        'pointsCount': {'integerValue': drawing.points.length.toString()},
      },
    };

    debugPrint("Firebase REST gönderiliyor: ${drawing.name}");

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("Firebase REST status: ${response.statusCode}");
    debugPrint("Firebase REST body: ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Firestore REST hata: ${response.statusCode}");
    }
  }

  Future<void> deleteDrawing(String id) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/saved_drawings/$id',
    );

    await http.delete(url);
  }
}
