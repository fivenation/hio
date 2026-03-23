import 'dart:math';
import 'dart:ui';
import '../entities/player.dart';

class ProjectionCamera {
  double screenWidth;
  double screenHeight;
  final double verticalFovDegrees;
  late final double verticalFovRad;

  double get aspectRatio => screenWidth / screenHeight;

  double get horizontalFovRad =>
      2 * atan(tan(verticalFovRad / 2) * aspectRatio);

  double get horizonY => screenHeight * 0.5; // Горизонт по центру

  static const double playerHeight = 1.5;

  ProjectionCamera({
    required this.screenWidth,
    required this.screenHeight,
    this.verticalFovDegrees = 60.0,
  }) {
    verticalFovRad = verticalFovDegrees * pi / 180;
  }

  void resize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  Offset? worldToScreen(double x, double y, double z, Player player) {
    // Вектор от игрока до точки
    double dx = x - player.x;
    double dy = y - player.y;
    double dz = z - playerHeight;

    // Поворачиваем координаты в систему камеры
    double cosA = cos(player.angle);
    double sinA = sin(player.angle);

    // Глубина (вперед от камеры) - это projection на направление взгляда
    double forward = dx * cosA + dy * sinA;

    // Горизонтальное смещение (вправо от камеры) - перпендикуляр
    double right = -dx * sinA + dy * cosA;

    // Вертикальное смещение
    double vertical = dz;

    // Точки сзади камеры не рисуем
    if (forward <= 0.1) {
      return null;
    }

    // Перспективная проекция
    double scale = screenWidth / 2 / tan(horizontalFovRad / 2);

    // Экранируем с учетом pitch камеры
    double screenX = screenWidth / 2 + (right / forward) * scale;
    double screenY =
        horizonY - (vertical / forward) * scale + tan(player.pitch) * scale;

    return Offset(screenX, screenY);
  }

  List<Offset> projectPoints(
      List<(double, double, double)> points, Player player) {
    final result = <Offset>[];
    for (final (x, y, z) in points) {
      final offset = worldToScreen(x, y, z, player);
      if (offset != null) {
        result.add(offset);
      }
    }
    return result;
  }
}
