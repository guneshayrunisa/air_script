import 'package:flutter/material.dart';

class WriteButton extends StatelessWidget {
  final bool isWriting;
  final Color buttonColor;
  final Color dangerColor;

  final VoidCallback onStart;
  final VoidCallback onStop;

  const WriteButton({
    super.key,
    required this.isWriting,
    required this.buttonColor,
    required this.dangerColor,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onStart(),
      onTapUp: (_) => onStop(),
      onTapCancel: onStop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: isWriting ? 150 : 128,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isWriting ? dangerColor : buttonColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isWriting ? Icons.edit : Icons.touch_app,
          color: const Color(0xFF101217),
          size: 27,
        ),
      ),
    );
  }
}
