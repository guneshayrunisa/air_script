import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_drawing.dart';
import 'signature_auth_service.dart';

class DrawingStorageService {
  static const String _baseKey = 'saved_drawings';
  final SignatureAuthService _authService = SignatureAuthService();

  Future<String> _getUserKey() async {
    final userId = await _authService.getCurrentUserId();

    if (userId == null) {
      return _baseKey;
    }

    return '${_baseKey}_$userId';
  }

  Future<List<SavedDrawing>> getDrawings() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey();

    final rawList = prefs.getStringList(key) ?? [];

    return rawList
        .map((item) => SavedDrawing.fromJson(jsonDecode(item)))
        .toList();
  }

  Future<void> saveDrawing(SavedDrawing drawing) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey();

    final drawings = await getDrawings();
    drawings.insert(0, drawing);

    final rawList = drawings
        .map((drawing) => jsonEncode(drawing.toJson()))
        .toList();

    await prefs.setStringList(key, rawList);
  }

  Future<void> deleteDrawing(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey();

    final drawings = await getDrawings();
    drawings.removeWhere((drawing) => drawing.id == id);

    final rawList = drawings
        .map((drawing) => jsonEncode(drawing.toJson()))
        .toList();

    await prefs.setStringList(key, rawList);
  }
}
