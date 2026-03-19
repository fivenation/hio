import 'dart:ui';
import 'package:flame/components.dart';
import '../camera/player_camera.dart';

class Crosshair extends Component {
  final PlayerCamera camera;

  static const double size = 20.0;
  static const double thickness = 2.0;
  static const Color color = Color(0xFFFFFFFF);
  static const Color outlineColor = Color(0xFF000000);

  Crosshair({required this.camera});

  @override
  void render(Canvas canvas) {
    final screenWidth = camera.screenWidth;
    final screenHeight = camera.screenHeight;

    if (screenWidth == 0 || screenHeight == 0) return;

    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;

    Paint outlinePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = thickness + 1
      ..style = PaintingStyle.stroke;

    Paint crosshairPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    // Горизонтальная линия
    canvas.drawLine(
      Offset(centerX - size, centerY),
      Offset(centerX + size, centerY),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(centerX - size, centerY),
      Offset(centerX + size, centerY),
      crosshairPaint,
    );

    // Вертикальная линия
    canvas.drawLine(
      Offset(centerX, centerY - size),
      Offset(centerX, centerY + size),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - size),
      Offset(centerX, centerY + size),
      crosshairPaint,
    );

    // Центральная точка
    Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      3,
      dotPaint,
    );
  }
}
