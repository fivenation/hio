import 'dart:math';
import 'package:flame/components.dart';
import '../world/map.dart';

class PlayerCamera {
  Vector2 position = Vector2(3.0, 3.0);
  double angle = 0; // 0 радиан = восток (вдоль оси X)

  // Вертикальный угол обзора (фиксированный)
  static const double verticalFovDegrees =
      45.0; // ← фиксированный вертикальный FOV
  late double verticalFov; // в радианах

  double playerHeight = 1.5;
  double wallHeight = 3.0;

  // Динамические размеры экрана
  double screenWidth = 0;
  double screenHeight = 0;

  // Параметры коллизий
  static const double playerRadius = 0.35;
  static const double wallMargin = 0.2;

  PlayerCamera() {
    verticalFov = verticalFovDegrees * pi / 180;
  }

  // Горизонтальный FOV вычисляется из вертикального с учётом соотношения сторон
  double get horizontalFov {
    if (screenHeight == 0) return 60 * pi / 180; // запасной вариант
    double aspectRatio = screenWidth / screenHeight;
    return 2 * atan(tan(verticalFov / 2) * aspectRatio);
  }

  // Метод для обновления размеров экрана
  void updateScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  void rotate(double delta) {
    angle = (angle - delta) % (2 * pi);
    if (angle < 0) angle += 2 * pi;
  }

  void moveForward(double distance) {
    Vector2 newPos = Vector2(
      position.x + cos(angle) * distance,
      position.y + sin(angle) * distance,
    );
    if (_isWalkable(newPos)) position = newPos;
  }

  void moveBackward(double distance) {
    Vector2 newPos = Vector2(
      position.x - cos(angle) * distance,
      position.y - sin(angle) * distance,
    );
    if (_isWalkable(newPos)) position = newPos;
  }

  void strafeLeft(double distance) {
    Vector2 newPos = Vector2(
      position.x + cos(angle - pi / 2) * distance,
      position.y + sin(angle - pi / 2) * distance,
    );
    if (_isWalkable(newPos)) position = newPos;
  }

  void strafeRight(double distance) {
    Vector2 newPos = Vector2(
      position.x + cos(angle + pi / 2) * distance,
      position.y + sin(angle + pi / 2) * distance,
    );
    if (_isWalkable(newPos)) position = newPos;
  }

  bool _isWalkable(Vector2 pos) {
    for (double dx = -playerRadius; dx <= playerRadius; dx += playerRadius) {
      for (double dy = -playerRadius; dy <= playerRadius; dy += playerRadius) {
        double checkX = pos.x + dx;
        double checkY = pos.y + dy;

        int x = checkX.floor();
        int y = checkY.floor();

        if (x < 0 || x >= 10 || y < 0 || y >= 10) return false;

        if (gameMap[x][y] == 1) {
          double distToWall = _distanceToWall(checkX, checkY, x, y);
          if (distToWall < wallMargin) return false;
        }
      }
    }
    return true;
  }

  double _distanceToWall(double x, double y, int wallX, int wallY) {
    double distToLeft = (x - wallX).abs();
    double distToRight = (x - (wallX + 1)).abs();
    double distToTop = (y - wallY).abs();
    double distToBottom = (y - (wallY + 1)).abs();

    return min(min(distToLeft, distToRight), min(distToTop, distToBottom));
  }
}
