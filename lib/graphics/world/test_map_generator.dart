import 'world_map.dart';

class TestMapGenerator {
  static WorldMap generateRoomMap() {
    const width = 70;
    const height = 70;
    const roomSize = 20;
    const roomStart = (width - roomSize) ~/ 2;
    const roomEnd = roomStart + roomSize;
    
    print('=== GENERATING TEST MAP ===');
    print('Room from X=$roomStart to $roomEnd, Y=$roomStart to $roomEnd');
    
    final world = WorldMap(width: width, height: height);
    
    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        if (x == roomStart || x == roomEnd - 1 || 
            y == roomStart || y == roomEnd - 1) {
          world.setBlockId(x, y, 0, 1);
        }
      }
    }
    
    final colStart = roomStart + 5;
    final colEnd = roomEnd - 6;
    
    world.setBlockId(colStart, colStart, 0, 1);     // северо-запад
    world.setBlockId(colStart, colEnd, 0, 1);       // северо-восток
    world.setBlockId(colEnd, colStart, 0, 1);       // юго-запад
    world.setBlockId(colEnd, colEnd, 0, 1);         // юго-восток
    
    print('Columns placed at: ($colStart,$colStart), ($colStart,$colEnd), ($colEnd,$colStart), ($colEnd,$colEnd)');
    
    // Z = 1, 2, 3 (стены и колонны вверх)
    for (int z = 1; z <= 3; z++) {
      // Стены
      for (int x = roomStart; x < roomEnd; x++) {
        for (int y = roomStart; y < roomEnd; y++) {
          if (x == roomStart || x == roomEnd - 1 || 
              y == roomStart || y == roomEnd - 1) {
            world.setBlockId(x, y, z, 1);
          }
        }
      }
      
      // Колонны
      world.setBlockId(colStart, colStart, z, 1);
      world.setBlockId(colStart, colEnd, z, 1);
      world.setBlockId(colEnd, colStart, z, 1);
      world.setBlockId(colEnd, colEnd, z, 1);
    }
    
    // Z = 4 (потолок)
    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, 4, 1);
      }
    }
    
    // Z = -1 (пол подвала)
    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, -1, 1);
      }
    }
    
    // Проверка позиции игрока
    final playerX = 35;
    final playerY = 35;
    final blockAtPlayer = world.getBlockId(playerX, playerY, 0);
    print('Block at player spawn ($playerX, $playerY, 0): $blockAtPlayer (0 = empty)');
    
    return world;
  }
}