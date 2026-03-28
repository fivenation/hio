/*
 * Модуль отрисовки игрового мира.
 * Полная версия с поддержкой текстур и внутренних граней
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
import 'package:hio/graphics/core/rect_uv.dart';

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

    // Определяем блок, в котором находится камера
    final cameraBlockX = player.x.floor();
    final cameraBlockY = player.y.floor();
    final cameraBlockZ = player.z.floor();
    final isCameraInsideBlock = _map.getBlockId(cameraBlockX, cameraBlockY, cameraBlockZ) != 0;
    
    // Если камера внутри блока, добавляем туман для плавного выхода
    if (isCameraInsideBlock) {
      _addFogEffect(canvas);
    }

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

          _collectBlockFaces(
            x, y, z, blockDef, player, light,
            isCameraInsideBlock && x == cameraBlockX && y == cameraBlockY && z == cameraBlockZ,
          );
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
        if (screenPoints.length >= 3) {
          _faceRenderer.render(
            canvas,
            screenPoints,
            face.color,
            opacity: 1.0,
            uv: face.uv,
            isInsideBlock: face.isInsideBlock,
          );
        }
      }
      _buckets[i].clear();
    }
  }
  
  void _addFogEffect(Canvas canvas) {
    final fogPaint = Paint()
      ..color = const Color(0x44000000)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _camera.screenWidth, _camera.screenHeight),
      fogPaint,
    );
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

    final dx = x - player.x;
    final dy = y - player.y;
    final angleToBlock = atan2(dy, dx);
    var angleDiff = (angleToBlock - player.angle).abs();
    if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;

    final fovMultiplier = distance < 2.0 ? 1.5 : 1.0;
    return angleDiff < pi * fovMultiplier;
  }

  double _calculateLight(double distance) {
    if (distance < fogStartDistance) {
      return 1.0;
    } else if (distance >= fogEndDistance) {
      return 0.2;
    } else {
      final t = (distance - fogStartDistance) / (fogEndDistance - fogStartDistance);
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
    bool isCameraBlock,
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

    // Для блока с камерой - рисуем ВСЕ грани с флагом isInsideBlock = true
    if (isCameraBlock) {
      _addAllFacesWithTextures(x1, y1, z1, x2, y2, z2, colorWithLight, player, block, true);
      return;
    }

    // Проверка статической видимости
    final northAir = _isFaceVisible(x, y + 1, z);
    final southAir = _isFaceVisible(x, y - 1, z);
    final eastAir = _isFaceVisible(x + 1, y, z);
    final westAir = _isFaceVisible(x - 1, y, z);
    final topAir = _isFaceVisible(x, y, z + 1);
    final bottomAir = _isFaceVisible(x, y, z - 1);

    final blockCenterX = x + 0.5;
    final blockCenterY = y + 0.5;
    final blockCenterZ = z + 0.5;

    final dxToPlayer = blockCenterX - player.x;
    final dyToPlayer = blockCenterY - player.y;
    final dzToPlayer = blockCenterZ - player.z;

    final distance3D = sqrt(dxToPlayer * dxToPlayer +
        dyToPlayer * dyToPlayer +
        dzToPlayer * dzToPlayer);

    final isVeryClose = distance3D < 0.5;

    // Получаем UV координаты для каждой грани
    final textures = block.textures;
    
    // Северная грань (NORTH) - Y+
    if (northAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.north, player))) {
      _addFaceWithTexture(
        [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
        textures?.north,
        false,
      );
    }

    // Южная грань (SOUTH) - Y-
    if (southAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.south, player))) {
      _addFaceWithTexture(
        [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
        colorWithLight,
        player,
        textures?.south,
        false,
      );
    }

    // Восточная грань (EAST) - X+
    if (eastAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.east, player))) {
      _addFaceWithTexture(
        [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
        colorWithLight,
        player,
        textures?.east,
        false,
      );
    }

    // Западная грань (WEST) - X-
    if (westAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.west, player))) {
      _addFaceWithTexture(
        [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
        colorWithLight,
        player,
        textures?.west,
        false,
      );
    }

    // Верхняя грань (TOP)
    if (topAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.top, player))) {
      _addFaceWithTexture(
        [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
        textures?.top,
        false,
      );
    }

    // Нижняя грань (BOTTOM)
    if (bottomAir && (isVeryClose || _isFaceVisibleToCamera(x, y, z, FaceDirection.bottom, player))) {
      _addFaceWithTexture(
        [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
        colorWithLight,
        player,
        textures?.bottom,
        false,
      );
    }
  }
  
  void _addAllFacesWithTextures(
    double x1, double y1, double z1,
    double x2, double y2, double z2,
    Color color,
    Player player,
    BlockDefinition block,
    bool isInsideBlock,
  ) {
    final textures = block.textures;
    
    // Рисуем все 6 граней с соответствующими текстурами
    _addFaceWithTexture([(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)], color, player, textures?.north, isInsideBlock);
    _addFaceWithTexture([(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)], color, player, textures?.south, isInsideBlock);
    _addFaceWithTexture([(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)], color, player, textures?.east, isInsideBlock);
    _addFaceWithTexture([(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)], color, player, textures?.west, isInsideBlock);
    _addFaceWithTexture([(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)], color, player, textures?.top, isInsideBlock);
    _addFaceWithTexture([(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)], color, player, textures?.bottom, isInsideBlock);
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

    final viewX = player.x - cx;
    final viewY = player.y - cy;
    final viewZ = player.z - cz;

    final dot = nx * viewX + ny * viewY + nz * viewZ;
    final distance = sqrt(viewX * viewX + viewY * viewY + viewZ * viewZ);
    final threshold = distance < 0.5 ? -0.3 : 0.0;
    
    return dot > threshold;
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
    _addFaceWithTexture(corners, color, player, null, false);
  }

  void _addFaceWithTexture(
    List<(double, double, double)> corners,
    Color color,
    Player player,
    RectUV? uv,
    bool isInsideBlock,
  ) {
    double totalDepth = 0.0;
    int validPoints = 0;
    bool hasPointInFront = false;

    final cosA = cos(player.angle);
    final sinA = sin(player.angle);

    for (final (x, y, z) in corners) {
      final dx = x - player.x;
      final dy = y - player.y;
      final dz = z - player.z;

      final depth = dx * cosA + dy * sinA;
      
      final threshold = sqrt(dx*dx + dy*dy + dz*dz) < 0.3 ? 0.01 : 0.1;

      if (depth > threshold) {
        hasPointInFront = true;
      }

      totalDepth += depth;
      validPoints++;
    }

    if (!hasPointInFront) {
      final isInsideAnyBlock = corners.any((p) {
        final (cx, cy, cz) = p;
        final blockX = cx.floor();
        final blockY = cy.floor();
        final blockZ = cz.floor();
        return (blockX == player.x.floor() && 
                blockY == player.y.floor() && 
                blockZ == player.z.floor());
      });
      
      if (!isInsideAnyBlock) return;
    }

    if (validPoints > 0) {
      _allFaces.add(_RenderFace(
        corners: corners,
        color: color,
        depth: totalDepth / validPoints,
        uv: uv,
        isInsideBlock: isInsideBlock,
      ));
    }
  }
}

class _RenderFace {
  final List<(double, double, double)> corners;
  final Color color;
  final double depth;
  final RectUV? uv;
  final bool isInsideBlock;

  _RenderFace({
    required this.corners,
    required this.color,
    required this.depth,
    this.uv,
    this.isInsideBlock = false,
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