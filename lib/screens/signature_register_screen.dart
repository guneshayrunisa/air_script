import 'package:flutter/material.dart';
import '../services/signature_auth_service.dart';

class SignatureRegisterScreen extends StatefulWidget {
  const SignatureRegisterScreen({super.key});

  @override
  State<SignatureRegisterScreen> createState() =>
      _SignatureRegisterScreenState();
}

class _SignatureRegisterScreenState extends State<SignatureRegisterScreen> {
  final SignatureAuthService _authService = SignatureAuthService();
  final TextEditingController _nameController = TextEditingController();
  final List<Offset> _points = [];

  void _clear() {
    setState(() => _points.clear());
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage("Eksik Bilgi", "Lütfen kullanıcı adını yaz.");
      return;
    }

    if (_points.length < 10) {
      _showMessage("Yetersiz İmza", "Lütfen daha belirgin bir imza çiz.");
      return;
    }

    try {
      await _authService.registerUser(
        name: name,
        signaturePoints: List.from(_points),
      );
    } catch (_) {
      _showMessage(
        "Kayıt Başarısız",
        "Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir ad seç.",
      );
      return;
    }

    if (!mounted) return;

    _showMessage(
      "Kayıt Tamamlandı",
      "İmzan kaydedildi. Şimdi giriş ekranından imzanla giriş yapabilirsin.",
      onClose: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      },
    );
  }

  void _showMessage(String title, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onClose ?? () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kayıt Ol",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Kullanıcı adını yaz ve imzanı çiz.",
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Kullanıcı adı",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _signatureBox()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      child: const Text("Temizle"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                      ),
                      child: const Text("İmzayı Kaydet"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signatureBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _points.add(details.localPosition);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _points.add(const Offset(-1, -1));
          });
        },
        child: CustomPaint(
          painter: _SignaturePainter(_points),
          child: Container(),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBrush = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx == -1 || points[i + 1].dx == -1) continue;
      canvas.drawLine(points[i], points[i + 1], paintBrush);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
