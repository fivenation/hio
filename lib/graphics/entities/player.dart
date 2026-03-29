import 'dart:math';
import 'package:hio/graphics/core/constants.dart';

class Player {
  double x;
  double y;
  double z; // Высота камеры
  double angle;
  double pitch;

  // Радиус коллизии камеры (меньше радиуса игрока для smooth движения)
  static const double cameraRadius = 0.3;

  // Вес для сглаживания выталкивания из блоков
  static const double pushForce = 0.95;

  bool _moveForward = false;
  bool _moveBackward = false;
  bool _strafeLeft = false;
  bool _strafeRight = false;
  double _rotateDelta = 0.0;
  double _pitchDelta = 0.0;
  bool _wasInsideBlock = false;

  Player({
    required this.x,
    required this.y,
    this.z = GraphicsConsts.playerHeight,
    this.angle = 0.0,
    this.pitch = 0.0,
  });

  void setMoveForward(bool active) => _moveForward = active;
  void setMoveBackward(bool active) => _moveBackward = active;
  void setStrafeLeft(bool active) => _strafeLeft = active;
  void setStrafeRight(bool active) => _strafeRight = active;
  void setRotate(double delta) => _rotateDelta = delta;
  void setPitch(double delta) => _pitchDelta = delta;

  (double dx, double dy) calculateMovement(double dt) {
    double moveX = 0.0;
    double moveY = 0.0;

    if (_moveForward) {
      moveX += cos(angle);
      moveY += sin(angle);
    }
    if (_moveBackward) {
      moveX -= cos(angle);
      moveY -= sin(angle);
    }
    if (_strafeLeft) {
      moveX += cos(angle - pi / 2);
      moveY += sin(angle - pi / 2);
    }
    if (_strafeRight) {
      moveX += cos(angle + pi / 2);
      moveY += sin(angle + pi / 2);
    }

    if (moveX != 0 || moveY != 0) {
      final len = sqrt(moveX * moveX + moveY * moveY);
      moveX /= len;
      moveY /= len;
    }

    return (
      moveX * GraphicsConsts.playerSpeed * dt,
      moveY * GraphicsConsts.playerSpeed * dt
    );
  }

  void updateRotation(double dt) {
    angle += _rotateDelta * GraphicsConsts.playerRotationSpeed * dt;
    angle %= 2 * pi;
    if (angle < 0) angle += 2 * pi;

    pitch += _pitchDelta * GraphicsConsts.playerPitchSpeed * dt;
    if (pitch > 50 * pi / 180) pitch = 50 * pi / 180;
    if (pitch < -50 * pi / 180) pitch = -50 * pi / 180;

    _rotateDelta = 0.0;
    _pitchDelta = 0.0;
  }

  void clearMovementCommands() {
    _moveForward = false;
    _moveBackward = false;
    _strafeLeft = false;
    _strafeRight = false;
  }

  void updatePosition(double dt,
      bool Function(double x, double y, double z, double radius) canMove) {
    final (dx, dy) = calculateMovement(dt);

    // Пробуем движение по X
    if (dx != 0) {
      final newX = x + dx;
      if (canMove(newX, y, z, cameraRadius)) {
        x = newX;
      } else {
        final slideX = x + dx;
        if (canMove(slideX, y, z, cameraRadius)) {
          x = slideX;
        }
      }
    }

    // Пробуем движение по Y
    if (dy != 0) {
      final newY = y + dy;
      if (canMove(x, newY, z, cameraRadius)) {
        y = newY;
      } else {
        final slideY = y + dy;
        if (canMove(x, slideY, z, cameraRadius)) {
          y = slideY;
        }
      }
    }

    _resolveCollision(canMove);

    clearMovementCommands();
  }

  void _resolveCollision(
      bool Function(double x, double y, double z, double radius) canMove) {
    if (canMove(x, y, z, cameraRadius)) {
      _wasInsideBlock = false;
      return;
    }

    _wasInsideBlock = true;

    // Поиск безопасной позиции
    for (double attempt = 0.05; attempt <= 0.5; attempt += 0.05) {
      for (double angleOffset = 0;
          angleOffset < 2 * pi;
          angleOffset += pi / 6) {
        final testX = x + cos(angleOffset) * attempt;
        final testY = y + sin(angleOffset) * attempt;

        if (canMove(testX, testY, z, cameraRadius)) {
          x = testX;
          y = testY;
          return;
        }
      }
    }

    // Откат назад
    final backX = x - cos(angle) * 0.5;
    final backY = y - sin(angle) * 0.5;
    if (canMove(backX, backY, z, cameraRadius)) {
      x = backX;
      y = backY;
    }
  }

  bool get isInsideBlock => _wasInsideBlock;
}
