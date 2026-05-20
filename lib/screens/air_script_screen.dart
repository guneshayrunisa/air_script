import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/saved_drawing.dart';
import '../models/letter_sample.dart';
import '../painters/canvas_painter.dart';
import '../services/drawing_storage_service.dart';
import '../services/recognition_service.dart';
import '../services/letter_training_storage_service.dart';
import '../widgets/brush_settings_sheet.dart';
import '../widgets/sensitivity_slider.dart';
import '../widgets/air_script_top_bar.dart';
import '../widgets/write_button.dart';
import '../widgets/prediction_dialog.dart';
import '../services/firebase_drawing_service.dart';
import '../services/sqlite_drawing_service.dart';
import 'signature_login_screen.dart';
import '../services/signature_auth_service.dart';

class AirScriptScreen extends StatefulWidget {
  const AirScriptScreen({super.key});

  @override
  State<AirScriptScreen> createState() => _AirScriptScreenState();
}

class _AirScriptScreenState extends State<AirScriptScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final DrawingStorageService _storageService = DrawingStorageService();
  final FirebaseDrawingService _firebaseDrawingService =
      FirebaseDrawingService();

  final RecognitionService _recognitionService = RecognitionService();
  final LetterTrainingStorageService _letterTrainingStorage =
      LetterTrainingStorageService();
  final SQLiteDrawingService _sqliteDrawingService =
      SQLiteDrawingService.instance;

  final List<Offset?> points = [];
  List<SavedDrawing> _savedDrawings = [];
  List<LetterSample> _letterSamples = [];

  final SignatureAuthService _authService = SignatureAuthService();

  Offset _currentPos = const Offset(200, 400);
  bool _isWriting = false;

  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _sensitivity = 850.0;
  double _filteredDx = 0;
  double _filteredDy = 0;
  final double _deadZone = 0.35;
  final double _maxStep = 18.0;
  final double _alpha = 0.18;

  DateTime? _lastTime;

  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _panelColor = Colors.white;
  final Color _softAccent = const Color(0xFF5F6F82);
  final Color _buttonColor = const Color(0xFF1F2937);
  final Color _dangerColor = const Color(0xFFD96C6C);
  final Color _textColor = const Color(0xFF111827);
  final Color _mutedTextColor = const Color(0xFF64748B);
  Color _selectedColor = const Color(0xFF1F2937);
  double _strokeWidth = 4.0;
  PenType _penType = PenType.normal;

  String _recognizedLetter = "-";
  String _aiConfidence = "-";

  final double _topLimit = 120;
  final double _bottomLimit = 120;

  @override
  void initState() {
    super.initState();

    _loadSavedDrawings();
    _loadLetterSamples();

    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!_isWriting) return;

      final now = DateTime.now();
      double dt = 0.016;

      if (_lastTime != null) {
        dt = now.difference(_lastTime!).inMilliseconds / 1000.0;
      }

      _lastTime = now;

      double rawDx = event.y * _sensitivity * dt;
      double rawDy = event.x * _sensitivity * dt;

      if (rawDx.abs() < _deadZone) rawDx = 0;
      if (rawDy.abs() < _deadZone) rawDy = 0;

      rawDx = rawDx.clamp(-_maxStep, _maxStep);
      rawDy = rawDy.clamp(-_maxStep, _maxStep);

      _filteredDx = _alpha * rawDx + (1 - _alpha) * _filteredDx;
      _filteredDy = _alpha * rawDy + (1 - _alpha) * _filteredDy;

      if (_filteredDx.abs() < 0.08) _filteredDx = 0;
      if (_filteredDy.abs() < 0.08) _filteredDy = 0;

      setState(() {
        final size = MediaQuery.of(context).size;

        final newX = (_currentPos.dx + _filteredDx).clamp(0.0, size.width);
        final newY = (_currentPos.dy + _filteredDy).clamp(0.0, size.height);

        _currentPos = _clampToDrawingArea(Offset(newX, newY));
        points.add(_currentPos);
      });
    });
  }

  Offset _clampToDrawingArea(Offset position) {
    final size = MediaQuery.of(context).size;

    return Offset(
      position.dx.clamp(12.0, size.width - 12),
      position.dy.clamp(_topLimit, size.height - _bottomLimit),
    );
  }

  Future<void> _loadSavedDrawings() async {
    final drawings = await _sqliteDrawingService.getDrawings();

    setState(() {
      _savedDrawings = drawings;
    });
  }

  Future<void> _loadLetterSamples() async {
    final samples = await _letterTrainingStorage.getSamples();

    setState(() {
      _letterSamples = samples;
    });
  }

  void _startWriting() {
    setState(() {
      _isWriting = true;
      _lastTime = DateTime.now();
      _filteredDx = 0;
      _filteredDy = 0;
      points.add(null);
      points.add(_currentPos);
    });
  }

  void _stopWriting() {
    setState(() {
      _isWriting = false;
      _lastTime = null;
    });
  }

  void _clearCanvas() {
    setState(() {
      points.clear();
      _filteredDx = 0;
      _filteredDy = 0;
      _recognizedLetter = "-";
      _aiConfidence = "-";
    });
  }

  Future<void> _recognizeLetter() async {
    final validPoints = points.whereType<Offset>().toList();

    if (validPoints.length < 8) {
      setState(() {
        _recognizedLetter = "-";
        _aiConfidence = "-";
      });

      _showInfoDialog(
        title: "Yetersiz Çizim",
        message:
            "Harf tahmini yapabilmem için önce biraz daha çizim yapmalısın.",
      );
      return;
    }

    String guess = _recognitionService.recognizeLetter(
      validPoints,
      samples: _letterSamples,
    );

    if (guess == "?") {
      guess = _basicShapeGuess(validPoints);
    }

    setState(() {
      _recognizedLetter = guess;
      _aiConfidence = _letterSamples.isEmpty ? "Basic" : "Learning";
    });

    await _showPredictionDialog(guess);
  }

  String _basicShapeGuess(List<Offset> validPoints) {
    if (validPoints.length < 8) {
      return "?";
    }

    double minX = validPoints.first.dx;
    double maxX = validPoints.first.dx;
    double minY = validPoints.first.dy;
    double maxY = validPoints.first.dy;

    for (final p in validPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    final ratio = width / (height == 0 ? 1 : height);

    final start = validPoints.first;
    final end = validPoints.last;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    // Dikey çizim → I
    if (ratio < 0.35) {
      return "I";
    }

    // Yatay çizim → -
    if (ratio > 2.2) {
      return "-";
    }

    // Yuvarlak çizim → O
    if (validPoints.length > 90 && ratio > 0.65 && ratio < 1.4) {
      return "O";
    }

    // Aşağı yönlü çizim → L
    if (dy.abs() > dx.abs() && end.dy > start.dy) {
      return "L";
    }

    // Karemsi yapı → A
    if (ratio > 0.6 && ratio < 1.5) {
      return "A";
    }

    // Default
    return "S";
  }

  void _showInfoDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
          ),
          content: Text(
            message,
            style: TextStyle(color: _mutedTextColor, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Tamam",
                style: TextStyle(
                  color: _softAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPredictionDialog(String guess) async {
    final correctedLetter = await showPredictionDialog(
      context: context,
      guess: guess,
      panelColor: _panelColor,
      softAccent: _softAccent,
      buttonColor: _buttonColor,
    );

    if (correctedLetter != null && correctedLetter.isNotEmpty) {
      final validPoints = points.whereType<Offset>().toList();

      await _letterTrainingStorage.saveSample(
        LetterSample(letter: correctedLetter, points: validPoints),
      );

      await _loadLetterSamples();

      setState(() {
        _recognizedLetter = correctedLetter;
        _aiConfidence = "Improved";
      });

      _showInfoDialog(
        title: "Harf Öğrenildi",
        message: "Çizimin '$correctedLetter' harfi olarak kaydedildi.",
      );
      ;
    }
  }

  Future<void> _resetAiLearning() async {
    await _letterTrainingStorage.clearSamples();
    await _loadLetterSamples();

    setState(() {
      _recognizedLetter = "-";
      _aiConfidence = "-";
    });

    _showInfoDialog(
      title: "AI Sıfırlandı",
      message: "Öğrenilen harf örnekleri başarıyla temizlendi.",
    );
  }

  Future<void> _saveCurrentDrawing() async {
    if (points.whereType<Offset>().isEmpty) {
      _showInfoDialog(
        title: "Boş Çizim",
        message: "Kaydetmeden önce ekranda bir çizim oluşturmalısın.",
      );
      return;
    }

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Çizimi Kaydet",
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: "Çizim adı",
              hintStyle: TextStyle(
                color: _mutedTextColor.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _softAccent, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "İptal",
                style: TextStyle(
                  color: _mutedTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: Text(
                "Kaydet",
                style: TextStyle(
                  color: _buttonColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (name == null) return;

    final drawing = SavedDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      points: List.from(points),
    );

    await _sqliteDrawingService.saveDrawing(drawing);
    await _loadSavedDrawings();
  }

  void _openDrawing(SavedDrawing drawing) {
    setState(() {
      points
        ..clear()
        ..addAll(drawing.points);

      final lastPoint = drawing.points.whereType<Offset>().lastOrNull;
      if (lastPoint != null) {
        _currentPos = lastPoint;
      }
    });
  }

  Future<void> _deleteDrawing(SavedDrawing drawing) async {
    await _sqliteDrawingService.deleteDrawing(drawing.id);
    await _loadSavedDrawings();
  }

  void _showBrushSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return BrushSettingsSheet(
          bgColor: _bgColor,
          panelColor: _panelColor,
          softAccent: _softAccent,
          buttonColor: _buttonColor,
          selectedColor: _selectedColor,
          strokeWidth: _strokeWidth,
          penType: _penType,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
          onStrokeWidthChanged: (value) {
            setState(() {
              _strokeWidth = value;
            });
          },
          onPenTypeChanged: (type) {
            setState(() {
              _penType = type;
            });
          },
        );
      },
    );
  }

  void _showSensitivitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SensitivitySliderSheet(
          bgColor: _bgColor,
          softAccent: _softAccent,
          sensitivity: _sensitivity,
          onChanged: (value) {
            setState(() {
              _sensitivity = value;
            });
          },
        );
      },
    );
  }

  void _showSavedDrawingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Text(
                      "Saved Drawings",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${_savedDrawings.length} item",
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: _savedDrawings.isEmpty
                      ? const Center(
                          child: Text(
                            "Henüz kayıtlı çizim yok",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _savedDrawings.length,
                          itemBuilder: (context, index) {
                            final drawing = _savedDrawings[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _openDrawing(drawing);
                                },
                                title: Text(
                                  drawing.name,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  "${drawing.createdAt.day}.${drawing.createdAt.month}.${drawing.createdAt.year}",
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: _dangerColor,
                                  ),
                                  onPressed: () async {
                                    await _deleteDrawing(drawing);
                                    Navigator.pop(context);
                                    _showSavedDrawingsSheet();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            CustomPaint(
              painter: CanvasPainter(
                points,
                color: _selectedColor,
                strokeWidth: _strokeWidth,
                penType: _penType,
              ),
              child: Container(),
            ),
            Positioned(top: 18, left: 18, right: 18, child: _buildTopBar()),
            Positioned(
              left: _currentPos.dx - 11,
              top: _currentPos.dy - 11,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (_isWriting) return;

                  setState(() {
                    final size = MediaQuery.of(context).size;

                    final newX = (_currentPos.dx + details.delta.dx).clamp(
                      0.0,
                      size.width,
                    );

                    final newY = (_currentPos.dy + details.delta.dy).clamp(
                      0.0,
                      size.height,
                    );

                    _currentPos = _clampToDrawingArea(Offset(newX, newY));
                  });
                },
                child: _buildCursor(),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(child: _buildWriteButton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AirScriptTopBar(
      panelColor: _panelColor,
      softAccent: _softAccent,
      recognizedLetter: _recognizedLetter,
      learnedSampleCount: _letterSamples.length,
      confidence: _aiConfidence,
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      onBrushTap: _showBrushSettingsSheet,
      onSensitivityTap: _showSensitivitySheet,
      onRecognizeTap: _recognizeLetter,
      onSaveTap: _saveCurrentDrawing,
      onClearTap: _clearCanvas,
    );
  }

  Widget _buildCursor() {
    final cursorColor = _isWriting ? _dangerColor : _buttonColor;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: cursorColor,
        shape: BoxShape.circle,
        border: Border.all(color: _bgColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteButton() {
    return WriteButton(
      isWriting: _isWriting,
      buttonColor: _buttonColor,
      dangerColor: _dangerColor,
      onStart: _startWriting,
      onStop: _stopWriting,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _bgColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AirScript",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Motion drawing workspace",
                    style: TextStyle(color: _mutedTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),

            _drawerItem(
              icon: Icons.folder_open,
              title: "Saved Drawings",
              subtitle: "View your saved scripts",
              onTap: () {
                Navigator.pop(context);
                _showSavedDrawingsSheet();
              },
            ),

            _drawerItem(
              icon: Icons.psychology_alt,
              title: "Reset AI Learning",
              subtitle: "Clear trained letter samples",
              onTap: () {
                Navigator.pop(context);
                _resetAiLearning();
              },
            ),

            _drawerItem(
              icon: Icons.delete_outline,
              title: "Clear Canvas",
              subtitle: "Remove current drawing",
              onTap: () {
                Navigator.pop(context);
                _clearCanvas();
              },
            ),

            _drawerItem(
              icon: Icons.logout,
              title: "Log out",
              subtitle: "Return to login screen",
              onTap: () async {
                Navigator.pop(context);

                await _authService.logout();

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignatureLoginScreen(),
                  ),
                );
              },
            ),

            _drawerItem(
              icon: Icons.info_outline,
              title: "About",
              subtitle: "Project information",
              onTap: () {
                Navigator.pop(context);

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: _panelColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: Text(
                        "AirScript",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      content: Text(
                        "AirScript, telefonun jiroskop sensörünü kullanarak "
                        "havada yapılan hareketleri dijital çizimlere dönüştüren "
                        "ve yapay zeka destekli harf tahmini yapabilen deneysel "
                        "bir çizim uygulamasıdır.",
                        style: TextStyle(color: _mutedTextColor, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Kapat",
                            style: TextStyle(color: _softAccent),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                "Gyro Mode Active • ${_letterSamples.length} AI samples",
                style: TextStyle(color: _mutedTextColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _softAccent),
      title: Text(
        title,
        style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: _mutedTextColor)),
      onTap: onTap,
    );
  }
}
