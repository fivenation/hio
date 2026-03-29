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
    player.updatePosition(dt, canMove);
  }

  bool canMove(double x, double y, double z, double radius) {
    final minX = (x - radius).floor();
    final maxX = (x + radius).ceil();
    final minY = (y - radius).floor();
    final maxY = (y + radius).ceil();
    final minZ = (z - radius).floor();
    final maxZ = (z + radius).ceil();

    for (int ix = minX; ix <= maxX; ix++) {
      for (int iy = minY; iy <= maxY; iy++) {
        for (int iz = minZ; iz <= maxZ; iz++) {
          if (ix < 0 || ix >= map.width || iy < 0 || iy >= map.height) {
            continue;
          }
          
          final blockId = map.getBlockId(ix, iy, iz);
          if (blockId == 0) continue;
          
          final blockMinX = ix.toDouble();
          final blockMaxX = ix.toDouble() + 1.0;
          final blockMinY = iy.toDouble();
          final blockMaxY = iy.toDouble() + 1.0;
          final blockMinZ = iz.toDouble();
          final blockMaxZ = iz.toDouble() + 1.0;
          
          final closestX = x.clamp(blockMinX, blockMaxX);
          final closestY = y.clamp(blockMinY, blockMaxY);
          final closestZ = z.clamp(blockMinZ, blockMaxZ);
          
          final dx = x - closestX;
          final dy = y - closestY;
          final dz = z - closestZ;
          final distanceSquared = dx * dx + dy * dy + dz * dz;
          
          if (distanceSquared < radius * radius) {
            return false;
          }
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