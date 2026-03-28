import 'dart:math';
import 'dart:ui';
import '../../graphics/entities/player.dart';
import '../core/constants.dart';

class ProjectionCamera {
  double _screenWidth;
  double _screenHeight;
  final double verticalFovDegrees;
  late final double verticalFovRad;
  
  // Минимальная глубина для проекции
  static const double minDepth = 0.05;

  // Кэшированные векторы камеры
  double _forwardX = 0, _forwardY = 0, _forwardZ = 0;
  double _rightX = 0, _rightY = 0, _rightZ = 0;
  double _upX = 0, _upY = 0, _upZ = 0;

  double _scale = 0;
  bool _cacheValid = false;

  ProjectionCamera({
    required double screenWidth,
    required double screenHeight,
    this.verticalFovDegrees = GraphicsConsts.defaultVerticalFov,
  })  : _screenWidth = screenWidth,
        _screenHeight = screenHeight {
    verticalFovRad = verticalFovDegrees * pi / 180;
  }

  double get aspectRatio => _screenWidth / _screenHeight;
  double get horizontalFovRad =>
      2 * atan(tan(verticalFovRad / 2) * aspectRatio);
  double get horizonY => _screenHeight * 0.5;
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;

  void resize(double width, double height) {
    _screenWidth = width;
    _screenHeight = height;
    _cacheValid = false;
  }

  void updateCache(Player player) {
    final yaw = player.angle;
    final pitch = player.pitch;

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    // Forward: куда смотрит камера
    _forwardX = cosYaw * cosPitch;
    _forwardY = sinYaw * cosPitch;
    _forwardZ = sinPitch;

    // Right: перпендикулярно forward в горизонтальной плоскости
    _rightX = -sinYaw;
    _rightY = cosYaw;
    _rightZ = 0.0;

    // Up: cross(forward, right)
    _upX = _forwardY * _rightZ - _forwardZ * _rightY;
    _upY = _forwardZ * _rightX - _forwardX * _rightZ;
    _upZ = _forwardX * _rightY - _forwardY * _rightX;

    // Масштаб для перспективы
    _scale = _screenWidth / 2 / tan(horizontalFovRad / 2);
    _cacheValid = true;
  }

  Offset? worldToScreen(double x, double y, double z, Player player) {
    if (!_cacheValid) {
      updateCache(player);
    }

    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - player.z;

    final forwardDepth = dx * _forwardX + dy * _forwardY + dz * _forwardZ;

    // Используем минимальную глубину для проекции
    final depth = max(forwardDepth, minDepth);

    final rightOffset = dx * _rightX + dy * _rightY + dz * _rightZ;
    final upOffset = dx * _upX + dy * _upY + dz * _upZ;

    final screenX = _screenWidth / 2 + (rightOffset / depth) * _scale;
    final screenY = _screenHeight / 2 - (upOffset / depth) * _scale;

    return Offset(screenX, screenY);
  }

  List<Offset> projectPoints(List<(double, double, double)> points, Player player) {
    final result = <Offset>[];
    for (final (x, y, z) in points) {
      final screenPoint = worldToScreen(x, y, z, player);
      if (screenPoint != null) {
        result.add(screenPoint);
      }
    }
    return result;
  }
  
  // Проверяет, находится ли точка перед камерой
  bool isPointInFront(double x, double y, double z, Player player) {
    if (!_cacheValid) updateCache(player);
    
    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - player.z;
    
    return dx * _forwardX + dy * _forwardY + dz * _forwardZ > minDepth;
  }
}