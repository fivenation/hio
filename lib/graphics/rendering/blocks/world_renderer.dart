/*
 * Модуль отрисовки игрового мира.
 * 
 * ОСНОВНАЯ ЗАДАЧА:
 * Рендеринг всех видимых блоков в пределах радиуса обзора.
 * 
 * АЛГОРИТМ ОПРЕДЕЛЕНИЯ ВИДИМОСТИ ГРАНИ:
 * 
 * 1. Статическая проверка: соседний блок должен быть Air (или за границей карты)
 * 2. Back-face culling: грань должна быть повёрнута к камере
 *    - Вычисляем нормаль грани (вектор, указывающий наружу из блока)
 *    - Вычисляем вектор от камеры к центру грани
 *    - Если скалярное произведение > 0, грань смотрит на камеру
 * 3. Проверка попадания в поле зрения:
 *    - Горизонтальный угол не должен превышать половину FOV
 *    - Вертикальный угол (с учётом pitch) не должен превышать половину FOV
 */

import 'dart:math';
import 'dart:ui';
import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';
import 'package:hio/graphics/world/game_world.dart';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/world/models/world_map.dart';

enum FaceDirection { north, south, east, west, top, bottom }

class WorldRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final BlockRegistry _blockRegistry;
  final WorldMap _map;

  int renderDistance;
  final double fogStartDistance = GraphicsConsts.fogStartDistance;
  final double fogEndDistance = GraphicsConsts.fogEndDistance;

  final List<_RenderFace> _allFaces = [];
  final Map<int, _CachedColumnData> _columnCache = {};
  final Map<int, _CachedFaceVisibility> _faceVisibilityCache = {};

  static const int _bucketCount = 50;
  final List<List<_RenderFace>> _buckets =
      List.generate(_bucketCount, (_) => []);
  double _maxDepth = 0;

  WorldRenderer({
    required ProjectionCamera camera,
    required WorldMap map,
  })  : _camera = camera,
        _faceRenderer = FaceRenderer(),
        _blockRegistry = BlockRegistry.instance,
        renderDistance = GraphicsConsts.defaultRenderDistance.toInt(),
        _map = map;

  void render(Canvas canvas, GameWorld world) {
    final player = world.player;

    _camera.updateCache(player);
    _columnCache.clear();
    _faceVisibilityCache.clear();
    _allFaces.clear();

    final startX = max(0, (player.x - renderDistance).floor());
    final endX = min(_map.width - 1, (player.x + renderDistance).ceil());
    final startY = max(0, (player.y - renderDistance).floor());
    final endY = min(_map.height - 1, (player.y + renderDistance).ceil());

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final columnData = _getCachedColumnData(x, y, player);
        if (!columnData.isVisible) continue;

        final light = columnData.light;

        for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
          final blockId = _map.getBlockId(x, y, z);
          if (blockId == 0) continue;

          final blockDef = _blockRegistry.get(blockId);
          if (blockDef == null) continue;

          _collectBlockFaces(x, y, z, blockDef, player, light);
        }
      }
    }

    _maxDepth = 0;
    for (final face in _allFaces) {
      if (face.depth > _maxDepth) _maxDepth = face.depth;
    }
    if (_maxDepth == 0) _maxDepth = 1;

    for (final face in _allFaces) {
      final normalizedDepth = (face.depth / _maxDepth).clamp(0.0, 0.999);
      final bucketIndex = (normalizedDepth * _bucketCount).floor();
      _buckets[bucketIndex].add(face);
    }

    for (int i = _bucketCount - 1; i >= 0; i--) {
      for (final face in _buckets[i]) {
        final screenPoints = _camera.projectPoints(face.corners, player);
        if (screenPoints.length == 4) {
          _faceRenderer.render(canvas, screenPoints, face.color, 1.0);
        }
      }
      _buckets[i].clear();
    }
  }

  _CachedColumnData _getCachedColumnData(int x, int y, Player player) {
    final key = x * 10000 + y;

    if (_columnCache.containsKey(key)) {
      return _columnCache[key]!;
    }

    final dx = x + 0.5 - player.x;
    final dy = y + 0.5 - player.y;
    final distance2D = dx * dx + dy * dy;
    final distance = sqrt(distance2D);

    final light = _calculateLight(distance);
    final isVisible = _isColumnVisible(x, y, player, distance);

    final data = _CachedColumnData(
      distance2D: distance2D,
      distance: distance,
      light: light,
      isVisible: isVisible,
    );

    _columnCache[key] = data;
    return data;
  }

  bool _isColumnVisible(int x, int y, Player player, double distance) {
    if (distance > renderDistance) return false;

    final dx = x + 0.5 - player.x;
    final dy = y + 0.5 - player.y;
    final angleToBlock = atan2(dy, dx);
    var angleDiff = (angleToBlock - player.angle).abs();
    if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;

    return angleDiff < pi / 2;
  }

  double _calculateLight(double distance) {
    if (distance < fogStartDistance) {
      return 1.0;
    } else if (distance >= fogEndDistance) {
      return 0.2;
    } else {
      final t =
          (distance - fogStartDistance) / (fogEndDistance - fogStartDistance);
      return 1.0 - t * 0.8;
    }
  }

  void _collectBlockFaces(
    int x,
    int y,
    int z,
    BlockDefinition block,
    Player player,
    double light,
  ) {
    final x1 = x.toDouble();
    final y1 = y.toDouble();
    final z1 = z.toDouble();
    final x2 = x + 1.0;
    final y2 = y + 1.0;
    final z2 = z + 1.0;

    final colorWithLight = Color.fromARGB(
      255,
      ((block.color.r * 255.0) * light).round().clamp(0, 255),
      ((block.color.g * 255.0) * light).round().clamp(0, 255),
      ((block.color.b * 255.0) * light).round().clamp(0, 255),
    );

    final northAir = _isFaceVisible(x, y + 1, z);
    final southAir = _isFaceVisible(x, y - 1, z);
    final eastAir = _isFaceVisible(x + 1, y, z);
    final westAir = _isFaceVisible(x - 1, y, z);
    final topAir = _isFaceVisible(x, y, z + 1);
    final bottomAir = _isFaceVisible(x, y, z - 1);

    if (northAir &&
        _isFaceVisibleToCamera(x, y, z, FaceDirection.north, player)) {
      _addFace(
        [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
      );
    }

    if (southAir &&
        _isFaceVisibleToCamera(x, y, z, FaceDirection.south, player)) {
      _addFace(
        [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
        colorWithLight,
        player,
      );
    }

    if (eastAir &&
        _isFaceVisibleToCamera(x, y, z, FaceDirection.east, player)) {
      _addFace(
        [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
        colorWithLight,
        player,
      );
    }

    if (westAir &&
        _isFaceVisibleToCamera(x, y, z, FaceDirection.west, player)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
        colorWithLight,
        player,
      );
    }

    if (topAir && _isFaceVisibleToCamera(x, y, z, FaceDirection.top, player)) {
      _addFace(
        [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
      );
    }

    if (bottomAir &&
        _isFaceVisibleToCamera(x, y, z, FaceDirection.bottom, player)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
        colorWithLight,
        player,
      );
    }
  }

  bool _isFaceVisibleToCamera(
    int x,
    int y,
    int z,
    FaceDirection direction,
    Player player,
  ) {
    final (cx, cy, cz) = _getFaceCenter(x, y, z, direction);
    final (nx, ny, nz) = _getFaceNormal(direction);

    final viewX = cx - player.x;
    final viewY = cy - player.y;
    final viewZ = cz - GraphicsConsts.playerHeight;

    final dot = nx * viewX + ny * viewY + nz * viewZ;

    // Исправлено: грань видима, если нормаль направлена ОТ камеры
    // то есть угол между нормалью и вектором на камеру > 90°
    if (dot >= 0) return false;

    final forward = viewX * cos(player.angle) + viewY * sin(player.angle);
    if (forward <= 0.1) return false;

    final right = -viewX * sin(player.angle) + viewY * cos(player.angle);
    final vertical = viewZ;

    final horizontalAngle = atan2(right, forward).abs();
    const maxHorizontalAngle = pi / 2.2;
    if (horizontalAngle > maxHorizontalAngle) return false;

    final verticalAngle = atan2(vertical, forward) - player.pitch;
    const maxVerticalAngle = GraphicsConsts.defaultVerticalFov * pi / 180 / 2;
    if (verticalAngle.abs() > maxVerticalAngle + 0.2) return false;

    return true;
  }

  (num, num, num) _getFaceCenter(int x, int y, int z, FaceDirection direction) {
    switch (direction) {
      case FaceDirection.north:
        return (x + 0.5, y + 1.0, z + 0.5);
      case FaceDirection.south:
        return (x + 0.5, y, z + 0.5);
      case FaceDirection.east:
        return (x + 1.0, y + 0.5, z + 0.5);
      case FaceDirection.west:
        return (x, y + 0.5, z + 0.5);
      case FaceDirection.top:
        return (x + 0.5, y + 0.5, z + 1.0);
      case FaceDirection.bottom:
        return (x + 0.5, y + 0.5, z);
    }
  }

  (double, double, double) _getFaceNormal(FaceDirection direction) {
    switch (direction) {
      case FaceDirection.north:
        return (0.0, 1.0, 0.0);
      case FaceDirection.south:
        return (0.0, -1.0, 0.0);
      case FaceDirection.east:
        return (1.0, 0.0, 0.0);
      case FaceDirection.west:
        return (-1.0, 0.0, 0.0);
      case FaceDirection.top:
        return (0.0, 0.0, 1.0);
      case FaceDirection.bottom:
        return (0.0, 0.0, -1.0);
    }
  }

  _CachedFaceVisibility _getFaceVisibility(int x, int y, int z) {
    final key = ((x * 10000 + y) * 100) + z;

    if (_faceVisibilityCache.containsKey(key)) {
      return _faceVisibilityCache[key]!;
    }

    final visibility = _CachedFaceVisibility(
      north: _isFaceVisible(x, y + 1, z),
      south: _isFaceVisible(x, y - 1, z),
      east: _isFaceVisible(x + 1, y, z),
      west: _isFaceVisible(x - 1, y, z),
      top: _isFaceVisible(x, y, z + 1),
      bottom: _isFaceVisible(x, y, z - 1),
    );

    _faceVisibilityCache[key] = visibility;
    return visibility;
  }

  bool _isFaceVisible(int nx, int ny, int nz) {
    if (nx < 0 || nx >= _map.width || ny < 0 || ny >= _map.height) {
      return true;
    }
    final neighborId = _map.getBlockId(nx, ny, nz);
    return neighborId == 0;
  }

  void _addFace(
    List<(double, double, double)> corners,
    Color color,
    Player player,
  ) {
    double totalDepth = 0.0;
    int validPoints = 0;
    bool hasPointInFront = false;

    final cosA = cos(player.angle);
    final sinA = sin(player.angle);

    for (final (x, y, z) in corners) {
      final dx = x - player.x;
      final dy = y - player.y;
      final dz = z - GraphicsConsts.playerHeight;

      final depth = dx * cosA + dy * sinA;

      if (depth > 0.1) {
        hasPointInFront = true;
      }

      totalDepth += depth;
      validPoints++;
    }

    if (!hasPointInFront) return;

    if (validPoints > 0) {
      _allFaces.add(_RenderFace(
        corners: corners,
        color: color,
        depth: totalDepth / validPoints,
      ));
    }
  }
}

class _RenderFace {
  final List<(double, double, double)> corners;
  final Color color;
  final double depth;

  _RenderFace({
    required this.corners,
    required this.color,
    required this.depth,
  });
}

class _CachedColumnData {
  final double distance2D;
  final double distance;
  final double light;
  final bool isVisible;

  _CachedColumnData({
    required this.distance2D,
    required this.distance,
    required this.light,
    required this.isVisible,
  });
}

class _CachedFaceVisibility {
  final bool north;
  final bool south;
  final bool east;
  final bool west;
  final bool top;
  final bool bottom;

  _CachedFaceVisibility({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.top,
    required this.bottom,
  });
}
