import 'package:hio/graphics/world/lighting.dart';

import 'world_map.dart';
import '../entities/player.dart';

/// Игровой мир. Объединяет карту и игрока, управляет коллизиями.
class GameWorld {
  /// Карта мира
  final WorldMap map;
  
  /// Игрок
  final Player player;
  
  /// Глобальная яркость (0.0 - 1.0)
  double ambientLight;
  
  /// Радиус игрока для коллизий (метры)
  static const double playerRadius = 0.35;
  
  /// Система освещения
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
  
  /// Обновляет состояние мира.
  /// Должен вызываться каждый кадр.
  void update(double dt) {
    // 1. Применяем поворот и наклон
    player.updateRotation(dt);
    
    // 2. Вычисляем желаемое движение
    final (dx, dy) = player.calculateMovement(dt);
    
    // 3. Применяем движение с коллизиями (раздельно по X и Y)
    if (dx != 0) {
      final newX = player.x + dx;
      if (canMoveTo(newX, player.y, playerRadius)) {
        player.x = newX;
      }
    }
    
    if (dy != 0) {
      final newY = player.y + dy;
      if (canMoveTo(player.x, newY, playerRadius)) {
        player.y = newY;
      }
    }
    
    // 4. Сбрасываем команды движения
    player.clearMovementCommands();
  }
  
  /// Проверяет, может ли игрок переместиться в указанную позицию.
  bool canMoveTo(double x, double y, double radius) {
    // Определяем границы проверяемой области
    final minX = (x - radius).floor();
    final maxX = (x + radius).floor();
    final minY = (y - radius).floor();
    final maxY = (y + radius).floor();
    
    for (int ix = minX; ix <= maxX; ix++) {
      for (int iy = minY; iy <= maxY; iy++) {
        // Проверка границ карты
        if (ix < 0 || ix >= map.width || iy < 0 || iy >= map.height) {
          return false;
        }
        
        // Проверка блока на уровне Z = 0
        final blockId = map.getBlockId(ix, iy, 0);
        if (blockId != 0) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Проверяет, находится ли игрок в пределах карты.
  bool isWithinBounds() {
    return player.x >= 0 && player.x < map.width &&
           player.y >= 0 && player.y < map.height;
  }
}