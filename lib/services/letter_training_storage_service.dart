import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_sample.dart';

class LetterTrainingStorageService {
  static const String _key = 'letter_training_samples';

  Future<List<LetterSample>> getSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    return rawList
        .map((item) => LetterSample.fromJson(jsonDecode(item)))
        .toList();
  }

  Future<void> saveSample(LetterSample sample) async {
    final prefs = await SharedPreferences.getInstance();
    final samples = await getSamples();

    samples.add(sample);

    final rawList = samples.map((sample) {
      return jsonEncode(sample.toJson());
    }).toList();

    await prefs.setStringList(_key, rawList);
  }

  Future<void> clearSamples() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}