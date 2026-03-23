import 'package:flutter/material.dart';

class FaceRenderer {
  void render(
    Canvas canvas,
    List<Offset> screenPoints,
    Color color,
    double light,
  ) {
    if (screenPoints.length != 4) return;

    final path = Path()
      ..moveTo(screenPoints[0].dx, screenPoints[0].dy)
      ..lineTo(screenPoints[1].dx, screenPoints[1].dy)
      ..lineTo(screenPoints[2].dx, screenPoints[2].dy)
      ..lineTo(screenPoints[3].dx, screenPoints[3].dy)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Опционально: обводка для отладки
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, strokePaint);
  }
}
