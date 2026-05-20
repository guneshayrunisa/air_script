import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignatureUser {
  final String id;
  final String name;
  final List<Offset> signaturePoints;

  SignatureUser({
    required this.id,
    required this.name,
    required this.signaturePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'signaturePoints': signaturePoints.map((p) {
        return {'x': p.dx, 'y': p.dy};
      }).toList(),
    };
  }

  factory SignatureUser.fromJson(Map<String, dynamic> json) {
    return SignatureUser(
      id: json['id'],
      name: json['name'],
      signaturePoints: (json['signaturePoints'] as List).map<Offset>((item) {
        return Offset(
          (item['x'] as num).toDouble(),
          (item['y'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}

class SignatureAuthService {
  static const String _usersKey = 'signature_users';
  static const String _currentUserKey = 'current_signature_user_id';

  Future<List<SignatureUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_usersKey) ?? [];

    return rawList
        .map((item) => SignatureUser.fromJson(jsonDecode(item)))
        .toList();
  }

  Future<void> registerUser({
    required String name,
    required List<Offset> signaturePoints,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getUsers();

    final existingUser = users.any(
      (u) => u.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );

    if (existingUser) {
      throw Exception("Bu kullanıcı adı zaten kayıtlı.");
    }

    final user = SignatureUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      signaturePoints: signaturePoints,
    );

    users.add(user);

    await prefs.setStringList(
      _usersKey,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }

  Future<void> setCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<SignatureUser?> findUserByName(String username) async {
    final users = await getUsers();
    final normalizedUsername = username.trim().toLowerCase();

    try {
      return users.firstWhere(
        (u) => u.name.trim().toLowerCase() == normalizedUsername,
      );
    } catch (_) {
      return null;
    }
  }

  Future<double> compareSignature({
    required String username,
    required List<Offset> inputPoints,
  }) async {
    final user = await findUserByName(username);

    if (user == null) return 0;

    if (user.signaturePoints.length < 12 || inputPoints.length < 12) {
      return 0;
    }

    final saved = _resamplePoints(
      _normalizePoints(user.signaturePoints),
      targetCount: 96,
    );

    final input = _resamplePoints(
      _normalizePoints(inputPoints),
      targetCount: 96,
    );

    if (saved.length != input.length) return 0;

    double totalDistance = 0;
    double startEndPenalty = 0;

    for (int i = 0; i < saved.length; i++) {
      totalDistance += (saved[i] - input[i]).distance;
    }

    startEndPenalty += (saved.first - input.first).distance;
    startEndPenalty += (saved.last - input.last).distance;

    final avgDistance = totalDistance / saved.length;
    final finalDistance = avgDistance + (startEndPenalty * 0.25);

    final score = (100 - (finalDistance * 1.8)).clamp(0, 100);

    return score.toDouble();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  List<Offset> _normalizePoints(
    List<Offset> points, {
    double targetSize = 100,
  }) {
    if (points.isEmpty) return [];

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

    if (width == 0 || height == 0) return points;

    final scale = targetSize / (width > height ? width : height);

    return points.map((p) {
      return Offset((p.dx - minX) * scale, (p.dy - minY) * scale);
    }).toList();
  }

  List<Offset> _resamplePoints(List<Offset> points, {int targetCount = 64}) {
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

  List<Offset> normalizePointsForTest(List<Offset> points) {
    return _normalizePoints(points);
  }

  List<Offset> resamplePointsForTest(
    List<Offset> points, {
    int targetCount = 64,
  }) {
    return _resamplePoints(points, targetCount: targetCount);
  }
}
