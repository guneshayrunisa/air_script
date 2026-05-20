import 'package:flutter/material.dart';
import '../painters/canvas_painter.dart';

class BrushSettingsSheet extends StatelessWidget {
  final Color bgColor;
  final Color panelColor;
  final Color softAccent;
  final Color buttonColor;

  final Color selectedColor;
  final double strokeWidth;
  final PenType penType;

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<PenType> onPenTypeChanged;

  const BrushSettingsSheet({
    super.key,
    required this.bgColor,
    required this.panelColor,
    required this.softAccent,
    required this.buttonColor,
    required this.selectedColor,
    required this.strokeWidth,
    required this.penType,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onPenTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFB9C2CC),
      const Color(0xFFA7B8A1),
      const Color(0xFFB8A38F),
      const Color(0xFFA18FAF),
      const Color(0xFFB96A6A),
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, modalSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Brush Settings",
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Color",
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: colors.map((color) {
                      final isSelected = selectedColor == color;

                      return GestureDetector(
                        onTap: () {
                          modalSetState(() {});
                          onColorChanged(color);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF111827)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: [
                      const Text(
                        "Stroke Width",
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        strokeWidth.toStringAsFixed(1),
                        style: TextStyle(
                          color: softAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  Slider(
                    value: strokeWidth,
                    min: 2,
                    max: 14,
                    activeColor: const Color(0xFF64748B),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (value) {
                      modalSetState(() {});
                      onStrokeWidthChanged(value);
                    },
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Pen Type",
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _penTypeChip("Normal", PenType.normal),
                      _penTypeChip("Soft", PenType.soft),
                      _penTypeChip("Marker", PenType.marker),
                      _penTypeChip("Dashed", PenType.dashed),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _penTypeChip(String label, PenType type) {
    final selected = penType == type;

    return GestureDetector(
      onTap: () {
        onPenTypeChanged(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? buttonColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? buttonColor
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF101217)
                : const Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}