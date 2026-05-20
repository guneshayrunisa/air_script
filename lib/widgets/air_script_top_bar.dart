import 'package:flutter/material.dart';

class AirScriptTopBar extends StatelessWidget {
  final Color panelColor;
  final Color softAccent;
  final String recognizedLetter;
  final int learnedSampleCount;
  final String confidence;

  final VoidCallback onMenuTap;
  final VoidCallback onBrushTap;
  final VoidCallback onSensitivityTap;
  final VoidCallback onRecognizeTap;
  final VoidCallback onSaveTap;
  final VoidCallback onClearTap;

  const AirScriptTopBar({
    super.key,
    required this.panelColor,
    required this.softAccent,
    required this.recognizedLetter,
    required this.learnedSampleCount,
    required this.confidence,
    required this.onMenuTap,
    required this.onBrushTap,
    required this.onSensitivityTap,
    required this.onRecognizeTap,
    required this.onSaveTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 12),
          child: Text(
            "AirScript",
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
        ),

        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _BarIcon(icon: Icons.menu_rounded, onTap: onMenuTap),
              const Spacer(),
              _BarIcon(icon: Icons.brush_rounded, onTap: onBrushTap),
              _BarIcon(icon: Icons.tune_rounded, onTap: onSensitivityTap),
              _BarIcon(icon: Icons.auto_awesome_rounded, onTap: onRecognizeTap),
              _BarIcon(icon: Icons.save_alt_rounded, onTap: onSaveTap),
              _BarIcon(icon: Icons.close_rounded, onTap: onClearTap),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "AI Guess: $recognizedLetter   |   Learned: $learnedSampleCount",
            style: TextStyle(
              color: softAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: const Color(0xFF64748B), size: 24),
    );
  }
}
