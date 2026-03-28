import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/core/rect_uv.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';
import 'package:hio/graphics/rendering/textures/texture_lod.dart';
import 'package:hio/graphics/world/game_world.dart';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/world/models/world_map.dart';

class WorldRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final BlockRegistry _blockRegistry;
  final WorldMap _map;
  final TextureLODManager _lodManager = TextureLODManager.instance;

  int renderDistance;

  final List<_RenderFace> _allFaces = [];
  final Map<int, _CachedColumnData> _columnCache = {};

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
    _allFaces.clear();

    final cameraBlockX = player.x.floor();
    final cameraBlockY = player.y.floor();
    final cameraBlockZ = player.z.floor();
    final isCameraInsideBlock =
        _map.getBlockId(cameraBlockX, cameraBlockY, cameraBlockZ) != 0;

    final startX = max(0, (player.x - renderDistance).floor());
    final endX = min(_map.width - 1, (player.x + renderDistance).ceil());
    final startY = max(0, (player.y - renderDistance).floor());
    final endY = min(_map.height - 1, (player.y + renderDistance).ceil());

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final columnData = _getCachedColumnData(x, y, player);
        if (!columnData.isVisible) continue;

        final light = columnData.light;
        final distance3D = columnData.distance3D;

        for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
          final blockId = _map.getBlockId(x, y, z);
          if (blockId == 0) continue;

          final blockDef = _blockRegistry.get(blockId);
          if (blockDef == null) continue;

          _collectBlockFaces(
            x,
            y,
            z,
            blockDef,
            player,
            light,
            distance3D,
            isCameraInsideBlock &&
                x == cameraBlockX &&
                y == cameraBlockY &&
                z == cameraBlockZ,
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
            uv: face.uv,
            distance: face.distance,
            isInsideBlock: face.isInsideBlock,
          );
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
    final dz = 0.5 - player.z;
    final distance2D = dx * dx + dy * dy;
    final distance = sqrt(distance2D);
    final distance3D = sqrt(distance2D + dz * dz);

    final light = _calculateLight(distance);
    final isVisible = _isColumnVisible(x, y, player, distance);

    final data = _CachedColumnData(
      distance2D: distance2D,
      distance: distance,
      distance3D: distance3D,
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
    if (distance < GraphicsConsts.fogStartDistance) {
      return 1.0;
    } else if (distance >= GraphicsConsts.fogEndDistance) {
      return 0.2;
    } else {
      final t = (distance - GraphicsConsts.fogStartDistance) /
          (GraphicsConsts.fogEndDistance - GraphicsConsts.fogStartDistance);
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
    double distance3D,
    bool isCameraBlock,
  ) {
    final x1 = x.toDouble();
    final y1 = y.toDouble();
    final z1 = z.toDouble();
    final x2 = x + 1.0;
    final y2 = y + 1.0;
    final z2 = z + 1.0;

    final Color faceColor;
    if (block.hasTextures) {
      faceColor = Colors.white;
    } else {
      faceColor = block.color;
    }

    final northAir = _isFaceVisible(x, y + 1, z);
    final southAir = _isFaceVisible(x, y - 1, z);
    final eastAir = _isFaceVisible(x + 1, y, z);
    final westAir = _isFaceVisible(x - 1, y, z);
    final topAir = _isFaceVisible(x, y, z + 1);
    final bottomAir = _isFaceVisible(x, y, z - 1);

    final isVeryClose = distance3D < 0.5;

    // Север
    if (isCameraBlock ||
        (northAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(
                    x, y, z, FaceDirection.north, player)))) {
      _addFace(
        [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
        faceColor,
        player,
        block.textures?.north,
        distance3D,
        isCameraBlock,
      );
    }

    // Юг
    if (isCameraBlock ||
        (southAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(
                    x, y, z, FaceDirection.south, player)))) {
      _addFace(
        [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
        faceColor,
        player,
        block.textures?.south,
        distance3D,
        isCameraBlock,
      );
    }

    // Восток
    if (isCameraBlock ||
        (eastAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(x, y, z, FaceDirection.east, player)))) {
      _addFace(
        [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
        faceColor,
        player,
        block.textures?.east,
        distance3D,
        isCameraBlock,
      );
    }

    // Запад
    if (isCameraBlock ||
        (westAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(x, y, z, FaceDirection.west, player)))) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
        faceColor,
        player,
        block.textures?.west,
        distance3D,
        isCameraBlock,
      );
    }

    // Верх
    if (isCameraBlock ||
        (topAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(x, y, z, FaceDirection.top, player)))) {
      _addFace(
        [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
        faceColor,
        player,
        block.textures?.top,
        distance3D,
        isCameraBlock,
      );
    }

    // Низ
    if (isCameraBlock ||
        (bottomAir &&
            (isVeryClose ||
                _isFaceVisibleToCamera(
                    x, y, z, FaceDirection.bottom, player)))) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
        faceColor,
        player,
        block.textures?.bottom,
        distance3D,
        isCameraBlock,
      );
    }
  }

  void _addFace(
    List<(double, double, double)> corners,
    Color color,
    Player player,
    RectUV? uv,
    double distance,
    bool isInsideBlock,
  ) {
    final lod = _lodManager.getLOD(distance);
    if (lod == TextureLOD.none) return;

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
      final distanceToPoint = sqrt(dx * dx + dy * dy + dz * dz);
      final threshold = distanceToPoint < 0.3 ? 0.01 : 0.1;

      if (depth > threshold) {
        hasPointInFront = true;
      }

      totalDepth += depth;
      validPoints++;
    }

    if (!hasPointInFront) {
      final isInsideAnyBlock = corners.any((p) {
        final (cx, cy, cz) = p;
        return (cx.floor() == player.x.floor() &&
            cy.floor() == player.y.floor() &&
            cz.floor() == player.z.floor());
      });
      if (!isInsideAnyBlock) return;
    }

    if (validPoints > 0) {
      _allFaces.add(_RenderFace(
        corners: corners,
        color: color,
        depth: totalDepth / validPoints,
        uv: uv,
        distance: distance,
        isInsideBlock: isInsideBlock,
      ));
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

  bool _isFaceVisible(int nx, int ny, int nz) {
    if (nx < 0 || nx >= _map.width || ny < 0 || ny >= _map.height) {
      return true;
    }
    return _map.getBlockId(nx, ny, nz) == 0;
  }

  void clearCache() {
    _lodManager.clearCache();
    _faceRenderer.clearCache();
  }
}

class _RenderFace {
  final List<(double, double, double)> corners;
  final Color color;
  final double depth;
  final RectUV? uv;
  final double distance;
  final bool isInsideBlock;

  _RenderFace({
    required this.corners,
    required this.color,
    required this.depth,
    this.uv,
    required this.distance,
    this.isInsideBlock = false,
  });
}

class _CachedColumnData {
  final double distance2D;
  final double distance;
  final double distance3D;
  final double light;
  final bool isVisible;

  _CachedColumnData({
    required this.distance2D,
    required this.distance,
    required this.distance3D,
    required this.light,
    required this.isVisible,
  });
}
