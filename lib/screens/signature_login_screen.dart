import 'package:flutter/material.dart';

import 'air_script_screen.dart';
import 'signature_register_screen.dart';
import '../services/signature_auth_service.dart';

class SignatureLoginScreen extends StatefulWidget {
  const SignatureLoginScreen({super.key});

  @override
  State<SignatureLoginScreen> createState() => _SignatureLoginScreenState();
}

class _SignatureLoginScreenState extends State<SignatureLoginScreen> {
  final SignatureAuthService _authService = SignatureAuthService();
  final TextEditingController _usernameController = TextEditingController();

  final List<Offset> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _goToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignatureRegisterScreen()),
    );

    if (result == true) {
      _clear();
      _usernameController.clear();
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage("Eksik Bilgi", "Lütfen kullanıcı adını gir.");
      return;
    }

    final user = await _authService.findUserByName(username);

    if (user == null) {
      _showMessage(
        "Kullanıcı Bulunamadı",
        "Bu kullanıcı adına ait kayıtlı bir imza bulunamadı.",
      );
      return;
    }

    if (_points.length < 12) {
      _showMessage("İmza Eksik", "Lütfen giriş yapmak için imzanı çiz.");
      return;
    }

    final score = await _authService.compareSignature(
      username: username,
      inputPoints: _points,
    );

    if (score >= 70) {
      await _authService.setCurrentUser(user.id);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AirScriptScreen()),
      );
    } else {
      _showMessage(
        "İmza Eşleşmedi",
        "İmza doğrulaması başarısız oldu.\nBenzerlik skoru: ${score.toInt()}",
      );
    }
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                "AirScript",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Kullanıcı adını gir ve imzanı çiz.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
              const SizedBox(height: 22),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Kullanıcı adı",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToRegister,
                      child: const Text("Kayıt Ol"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                      ),
                      child: const Text("Giriş Yap"),
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
