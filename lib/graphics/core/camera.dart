import 'dart:math';
import 'dart:ui';
import '../../graphics/entities/player.dart';
import '../core/constants.dart';

class ProjectionCamera {
  double _screenWidth;
  double _screenHeight;
  final double verticalFovDegrees;
  late final double verticalFovRad;

  static const double minDepth = 0.05;

  double forwardX = 0, forwardY = 0, forwardZ = 0;
  double _rightX = 0, _rightY = 0, _rightZ = 0;
  double _upX = 0, _upY = 0, _upZ = 0;

  double _scale = 0;
  bool _cacheValid = false;

  final Map<int, Offset> _projectionCache = {};
  int _currentFrameId = 0;

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
    _currentFrameId++;

    _projectionCache.clear();

    final yaw = player.angle;
    final pitch = player.pitch;

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    forwardX = cosYaw * cosPitch;
    forwardY = sinYaw * cosPitch;
    forwardZ = sinPitch;

    _rightX = -sinYaw;
    _rightY = cosYaw;
    _rightZ = 0.0;

    // Up: cross(forward, right)
    _upX = forwardY * _rightZ - forwardZ * _rightY;
    _upY = forwardZ * _rightX - forwardX * _rightZ;
    _upZ = forwardX * _rightY - forwardY * _rightX;

    // Масштаб для перспективы
    _scale = _screenWidth / 2 / tan(horizontalFovRad / 2);
    _cacheValid = true;
  }

  Offset? worldToScreen(double x, double y, double z, Player player) {
    if (!_cacheValid) {
      updateCache(player);
    }

    final cacheKey = Object.hash(
      (x * 100).round(),
      (y * 100).round(),
      (z * 100).round(),
      _currentFrameId,
    );

    if (_projectionCache.containsKey(cacheKey)) {
      return _projectionCache[cacheKey];
    }

    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - player.z;

    final forwardDepth = dx * forwardX + dy * forwardY + dz * forwardZ;

    final depth = max(forwardDepth, minDepth);

    final rightOffset = dx * _rightX + dy * _rightY + dz * _rightZ;
    final upOffset = dx * _upX + dy * _upY + dz * _upZ;

    final screenX = _screenWidth / 2 + (rightOffset / depth) * _scale;
    final screenY = _screenHeight / 2 - (upOffset / depth) * _scale;

    final result = Offset(screenX, screenY);

    // Сохраняем в кэш
    _projectionCache[cacheKey] = result;

    return result;
  }

  List<Offset> projectPoints(
      List<(double, double, double)> points, Player player) {
    final result = <Offset>[];
    for (final (x, y, z) in points) {
      final screenPoint = worldToScreen(x, y, z, player);
      if (screenPoint != null) {
        result.add(screenPoint);
      }
    }
    return result;
  }

  bool isPointInFront(double x, double y, double z, Player player) {
    if (!_cacheValid) updateCache(player);

    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - player.z;

    return dx * forwardX + dy * forwardY + dz * forwardZ > minDepth;
  }

  ClipResult? clipAndProjectQuad(
    List<(double, double, double)> corners,
    Player player,
  ) {
    final viewVerts = <ViewVertex>[];

    const uvs = [
      Offset(0.0, 1.0),
      Offset(1.0, 1.0),
      Offset(1.0, 0.0),
      Offset(0.0, 0.0),
    ];

    for (int i = 0; i < 4; i++) {
      final dx = corners[i].$1 - player.x;
      final dy = corners[i].$2 - player.y;
      final dz = corners[i].$3 - player.z;

      final vz = dx * forwardX + dy * forwardY + dz * forwardZ;
      final vx = dx * _rightX + dy * _rightY + dz * _rightZ;
      final vy = dx * _upX + dy * _upY + dz * _upZ;

      viewVerts.add(ViewVertex(vx, vy, vz, uvs[i].dx, uvs[i].dy));
    }

    final clipped = <ViewVertex>[];
    for (int i = 0; i < viewVerts.length; i++) {
      final current = viewVerts[i];
      final prev = viewVerts[(i - 1 + viewVerts.length) % viewVerts.length];

      final currentInside = current.z >= minDepth;
      final prevInside = prev.z >= minDepth;

      if (currentInside != prevInside) {
        final t = (minDepth - prev.z) / (current.z - prev.z);
        final ix = prev.x + t * (current.x - prev.x);
        final iy = prev.y + t * (current.y - prev.y);
        const iz = minDepth;
        final iu = prev.u + t * (current.u - prev.u);
        final iv = prev.v + t * (current.v - prev.v);
        clipped.add(ViewVertex(ix, iy, iz, iu, iv));
      }

      if (currentInside) {
        clipped.add(current);
      }
    }

    if (clipped.length < 3) return null;

    final screenPoints = <Offset>[];
    final uvPoints = <Offset>[];

    for (final v in clipped) {
      final screenX = _screenWidth / 2 + (v.x / v.z) * _scale;
      final screenY = _screenHeight / 2 - (v.y / v.z) * _scale;
      screenPoints.add(Offset(screenX, screenY));
      uvPoints.add(Offset(v.u, v.v));
    }

    return ClipResult(screenPoints, uvPoints);
  }

  void clearCache() {
    _projectionCache.clear();
    _currentFrameId = 0;
  }
}

class ViewVertex {
  final double x, y, z;
  final double u, v;
  ViewVertex(this.x, this.y, this.z, this.u, this.v);
}

class ClipResult {
  final List<Offset> screenPoints;
  final List<Offset> uvPoints;
  ClipResult(this.screenPoints, this.uvPoints);
}
