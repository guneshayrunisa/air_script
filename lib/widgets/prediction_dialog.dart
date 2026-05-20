import 'package:flutter/material.dart';

Future<String?> showPredictionDialog({
  required BuildContext context,
  required String guess,
  required Color panelColor,
  required Color softAccent,
  required Color buttonColor,
}) async {
  final controller = TextEditingController(text: guess == "?" ? "" : guess);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "AI Letter Guess",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tahmin: $guess",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              maxLength: 1,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "Harf",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: softAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Vazgeç",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim().toUpperCase();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(
              "Kabul Et / Düzelt",
              style: TextStyle(color: buttonColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );
}
