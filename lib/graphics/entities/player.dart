import 'dart:math';

/// Игрок. Хранит позицию, угол обзора и состояние движения.
class Player {
  /// Позиция по X (метры)
  double x;

  /// Позиция по Y (метры)
  double y;

  /// Угол поворота (радианы). 0 = восток, π/2 = север.
  double angle;

  /// Вертикальный угол (радианы). 0 = прямо, >0 = вверх, <0 = вниз.
  double pitch;

  /// Скорость движения (м/с)
  final double _speed;

  /// Скорость поворота (рад/с)
  final double _rotationSpeed;

  /// Скорость наклона камеры (рад/с)
  final double _pitchSpeed;

  // Команды (накапливаются из ввода)
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
  })  : _pitchSpeed = pitchSpeed,
        _rotationSpeed = rotationSpeed,
        _speed = speed;

  void setMoveForward(bool active) => _moveForward = active;
  void setMoveBackward(bool active) => _moveBackward = active;
  void setStrafeLeft(bool active) => _strafeLeft = active;
  void setStrafeRight(bool active) => _strafeRight = active;
  void setRotate(double delta) => _rotateDelta = delta;
  void setPitch(double delta) => _pitchDelta = delta;

  void debugAngle() {
    print(
        'Player angle: ${(angle * 180 / pi).toStringAsFixed(1)}° (${angle.toStringAsFixed(3)} rad)');
    print(
        '  Direction: dx=${cos(angle).toStringAsFixed(2)}, dy=${sin(angle).toStringAsFixed(2)}');
  }

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

    return (moveX * _speed * dt, moveY * _speed * dt);
  }

  void updateRotation(double dt) {
    angle += _rotateDelta * _rotationSpeed * dt;
    angle %= 2 * pi;
    if (angle < 0) angle += 2 * pi;

    pitch += _pitchDelta * _pitchSpeed * dt;
    if (pitch > pi / 2) pitch = pi / 2;
    if (pitch < -pi / 2) pitch = -pi / 2;

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
