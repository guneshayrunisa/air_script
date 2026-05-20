import 'package:flutter/material.dart';

enum PenType { normal, soft, marker, dashed }

class CanvasPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;
  final PenType penType;

  CanvasPainter(
    this.points, {
    required this.color,
    required this.strokeWidth,
    required this.penType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (penType == PenType.soft) {
      paint
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    }

    if (penType == PenType.marker) {
      paint
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = strokeWidth * 1.8;
    }

    if (penType == PenType.dashed) {
      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          _drawDashedLine(canvas, points[i]!, points[i + 1]!, paint);
        }
      }
      return;
    }

    final List<Offset> segment = [];

    for (final point in points) {
      if (point == null) {
        _drawSmoothSegment(canvas, segment, paint);
        segment.clear();
      } else {
        segment.add(point);
      }
    }

    _drawSmoothSegment(canvas, segment, paint);
  }

  void _drawSmoothSegment(Canvas canvas, List<Offset> segment, Paint paint) {
    if (segment.length < 2) return;

    final path = Path();
    path.moveTo(segment.first.dx, segment.first.dy);

    for (int i = 1; i < segment.length - 1; i++) {
      final current = segment[i];
      final next = segment[i + 1];

      final midPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );

      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midPoint.dx,
        midPoint.dy,
      );
    }

    path.lineTo(segment.last.dx, segment.last.dy);
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 7.0;

    final distance = (end - start).distance;
    if (distance == 0) return;

    final direction = (end - start) / distance;
    double currentDistance = 0;

    while (currentDistance < distance) {
      final from = start + direction * currentDistance;
      final to =
          start + direction * (currentDistance + dashWidth).clamp(0, distance);

      canvas.drawLine(from, to, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}