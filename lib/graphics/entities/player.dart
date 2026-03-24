import 'dart:math';
import 'package:hio/graphics/core/constants.dart';

class Player {
  double x;
  double y;
  double angle;
  double pitch;

  bool _moveForward = false;
  bool _moveBackward = false;
  bool _strafeLeft = false;
  bool _strafeRight = false;
  double _rotateDelta = 0.0;
  double _pitchDelta = 0.0;

  Player({
    required this.x,
    required this.y,
    this.angle = 0.0,
    this.pitch = 0.0,
    double speed = 3.0,
    double rotationSpeed = 2.0,
    double pitchSpeed = 1.5,
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
    if (pitch > 45 * pi / 180) pitch = 45 * pi / 180;
    if (pitch < -45 * pi / 180) pitch = -45 * pi / 180;

    _rotateDelta = 0.0;
    _pitchDelta = 0.0;
  }

  void clearMovementCommands() {
    _moveForward = false;
    _moveBackward = false;
    _strafeLeft = false;
    _strafeRight = false;
  }
}
