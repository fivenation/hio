import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/world/models/lighting.dart';

import 'models/world_map.dart';
import '../entities/player.dart';

class GameWorld {
  final WorldMap map;
  final Player player;
  double ambientLight;
  final LightingSystem lighting;

  GameWorld({
    required this.map,
    required this.player,
    this.ambientLight = 1.0,
    List<LightSource>? lightSources,
  }) : lighting = LightingSystem(
          ambientLight: ambientLight,
          sources: lightSources ?? [],
        );

  void update(double dt) {
    player.updateRotation(dt);
    final (dx, dy) = player.calculateMovement(dt);

    if (dx != 0) {
      final newX = player.x + dx;
      if (canMoveTo(newX, player.y, GraphicsConsts.playerRadius)) {
        player.x = newX;
      }
    }

    if (dy != 0) {
      final newY = player.y + dy;
      if (canMoveTo(player.x, newY, GraphicsConsts.playerRadius)) {
        player.y = newY;
      }
    }

    player.clearMovementCommands();
  }

  bool canMoveTo(double x, double y, double radius) {
    final minX = (x - radius).floor();
    final maxX = (x + radius).floor();
    final minY = (y - radius).floor();
    final maxY = (y + radius).floor();

    for (int ix = minX; ix <= maxX; ix++) {
      for (int iy = minY; iy <= maxY; iy++) {
        if (ix < 0 || ix >= map.width || iy < 0 || iy >= map.height) {
          return false;
        }

        final blockId = map.getBlockId(ix, iy, GraphicsConsts.collisionCheckZ);
        if (blockId != 0) {
          return false;
        }
      }
    }

    return true;
  }

  bool isWithinBounds() {
    return player.x >= 0 &&
        player.x < map.width &&
        player.y >= 0 &&
        player.y < map.height;
  }
}
