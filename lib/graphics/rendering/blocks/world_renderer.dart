// lib/graphics/rendering/blocks/world_renderer.dart
import 'dart:math';
import 'dart:ui';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/world/game_world.dart';
import 'package:hio/graphics/world/models/world_map.dart';
import 'face_renderer.dart';

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

class WorldRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final BlockRegistry _blockRegistry;
  final WorldMap _map;
  final List<_RenderFace> _allFaces = [];

  WorldRenderer({
    required ProjectionCamera camera,
    required WorldMap map,
  })  : _camera = camera,
        _faceRenderer = FaceRenderer(),
        _blockRegistry = BlockRegistry.instance,
        _map = map;

  void render(Canvas canvas, GameWorld world) {
    final player = world.player;

    _allFaces.clear();

    final startX = max(0, (player.x - GraphicsConsts.defaultRenderDistance).floor());
    final endX = min(_map.width - 1, (player.x + GraphicsConsts.defaultRenderDistance).ceil());
    final startY = max(0, (player.y - GraphicsConsts.defaultRenderDistance).floor());
    final endY = min(_map.height - 1, (player.y + GraphicsConsts.defaultRenderDistance).ceil());

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final dx = x + 0.5 - player.x;
        final dy = y + 0.5 - player.y;
        final distance2D = sqrt(dx * dx + dy * dy);

        if (distance2D > GraphicsConsts.defaultRenderDistance) continue;

        final light = _calculateLight(distance2D);

        for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
          final blockId = _map.getBlockId(x, y, z);
          if (blockId == 0) continue;

          final blockDef = _blockRegistry.get(blockId);
          if (blockDef == null) continue;

          _collectBlockFaces(x, y, z, blockDef, player, light);
        }
      }
    }

    _allFaces.sort((a, b) => b.depth.compareTo(a.depth));

    for (final face in _allFaces) {
      final screenPoints = _camera.projectPoints(face.corners, player);
      if (screenPoints.length == 4) {
        _faceRenderer.render(canvas, screenPoints, face.color, 1.0);
      }
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
      (block.color.red * light).toInt().clamp(0, 255),
      (block.color.green * light).toInt().clamp(0, 255),
      (block.color.blue * light).toInt().clamp(0, 255),
    );

    // NORTH (+Y)
    if (_isFaceVisible(x, y + 1, z)) {
      _addFace(
        [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
      );
    }

    // SOUTH (-Y)
    if (_isFaceVisible(x, y - 1, z)) {
      _addFace(
        [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
        colorWithLight,
        player,
      );
    }

    // EAST (+X)
    if (_isFaceVisible(x + 1, y, z)) {
      _addFace(
        [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
        colorWithLight,
        player,
      );
    }

    // WEST (-X)
    if (_isFaceVisible(x - 1, y, z)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
        colorWithLight,
        player,
      );
    }

    // TOP (+Z)
    if (_isFaceVisible(x, y, z + 1)) {
      _addFace(
        [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
        colorWithLight,
        player,
      );
    }

    // BOTTOM (-Z)
    if (_isFaceVisible(x, y, z - 1)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
        colorWithLight,
        player,
      );
    }
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

    for (final (x, y, z) in corners) {
      final dx = x - player.x;
      final dy = y - player.y;
      final dz = z - GraphicsConsts.playerHeight;

      final cosA = cos(player.angle);
      final sinA = sin(player.angle);

      final depth = dx * cosA + dy * sinA;

      totalDepth += depth;
      validPoints++;
    }

    if (validPoints > 0) {
      _allFaces.add(_RenderFace(
        corners: corners,
        color: color,
        depth: totalDepth / validPoints,
      ));
    }
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
}
