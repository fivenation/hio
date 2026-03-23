import 'dart:math';
import 'dart:ui';
import 'block_renderer.dart';
import 'camera.dart';
import '../entities/player.dart';
import '../world/game_world.dart';
import '../world/world_map.dart';

class WorldRenderer {
  final ProjectionCamera _camera;
  final BlockRenderer _blockRenderer;
  int renderDistance;

  WorldRenderer({
    required ProjectionCamera camera,
    required WorldMap map,
    this.renderDistance = 64,
  })  : _camera = camera,
        _blockRenderer = BlockRenderer(camera: camera, map: map);

  void render(Canvas canvas, GameWorld world) {
    final player = world.player;
    final map = world.map;

    // Рендерим пол (Z = -1, верхняя грань)
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        final dx = x + 0.5 - player.x;
        final dy = y + 0.5 - player.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > renderDistance) continue;

        final blockId = map.getBlockId(x, y, -1);
        if (blockId != 0) {
          final light = _calculateLight(distance);
          // Рендерим только верхнюю грань пола
          _blockRenderer.renderBlock(canvas, x, y, -1, blockId, player, light);
        }
      }
    }

    // Рендерим стены (Z = 1,2,3)
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        final dx = x + 0.5 - player.x;
        final dy = y + 0.5 - player.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > renderDistance) continue;

        for (int z = 1; z <= 3; z++) {
          final blockId = map.getBlockId(x, y, z);
          if (blockId == 0) continue;

          final light = _calculateLight(distance);
          _blockRenderer.renderBlock(canvas, x, y, z, blockId, player, light);
        }
      }
    }
  }

  double _distanceToPlayer(int x, int y, int z, Player player) {
    final dx = x + 0.5 - player.x;
    final dy = y + 0.5 - player.y;
    final dz = z.toDouble();
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  double _calculateLight(double distance) {
    // Базовое освещение с затуханием по расстоянию
    double light = 1.0;
    if (distance > 40) {
      light = 1.0 - (distance - 40) / 40;
    }
    return light.clamp(0.2, 1.0);
  }
}
