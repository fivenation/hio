import 'dart:ui';

import 'package:flutter/material.dart';

class FaceRenderer {
  void render(
    Canvas canvas,
    List<Offset> screenPoints,
    double light,
    Color color,
  ) {
    if (screenPoints.length != 4) return;

    final path = Path()
      ..moveTo(screenPoints[0].dx, screenPoints[0].dy)
      ..lineTo(screenPoints[1].dx, screenPoints[1].dy)
      ..lineTo(screenPoints[2].dx, screenPoints[2].dy)
      ..lineTo(screenPoints[3].dx, screenPoints[3].dy)
      ..close();

    // Заливка
    final fillPaint = Paint()
      ..color = Color.fromARGB(
        255,
        (color.red * light).toInt().clamp(0, 255),
        (color.green * light).toInt().clamp(0, 255),
        (color.blue * light).toInt().clamp(0, 255),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Обводка (чтобы видеть грани)
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, strokePaint);
  }
}
