// lib/graphics/world/test_map_generator.dart
import 'world_map.dart';

class TestMapGenerator {
  static WorldMap generateRoomMap() {
    const width = 70;
    const height = 70;
    const roomSize = 20;
    const roomStart = (width - roomSize) ~/ 2;
    const roomEnd = roomStart + roomSize;

    print('=== GENERATING TEST MAP WITH COLORED DIRECTIONS ===');

    final world = WorldMap(width: width, height: height);

    // ========== СТЕНЫ КОМНАТЫ (серые) ==========
    for (int z = -1; z <= 4; z++) {
      for (int x = roomStart; x < roomEnd; x++) {
        for (int y = roomStart; y < roomEnd; y++) {
          if (x == roomStart ||
              x == roomEnd - 1 ||
              y == roomStart ||
              y == roomEnd - 1) {
            world.setBlockId(x, y, z, 1);
          }
        }
      }
    }

    const centerX = roomStart + roomSize ~/ 2;
    const centerY = roomStart + roomSize ~/ 2;

    // Теперь цвета соответствуют системе координат:
    // Север (+Y) - синий
    world.setBlockId(
        centerX, roomStart, 1, 10);

    // Юг (-Y) - красный
    world.setBlockId(
        centerX, roomEnd - 1, 1, 11);

    // Восток (+X) - зеленый
    world.setBlockId(
        roomEnd - 1, centerY, 1, 12);

    // Запад (-X) - желтый
    world.setBlockId(
        roomStart, centerY, 1, 13); 

    // ========== ПОЛ И ПОТОЛОК ==========
    // Пол на Z = -1 (серый)
    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, -1, 1);
      }
    }

    // Потолок на Z = 4 (серый)
    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, 4, 1);
      }
    }

    // ========== ИГРОК В ЦЕНТРЕ ==========
    final playerX = centerX;
    final playerY = centerY;

    // Проверяем, что игрок не в блоке
    final blockAtPlayer = world.getBlockId(playerX, playerY, 0);
    print('Block at player spawn: ${blockAtPlayer == 0 ? "EMPTY" : "BLOCK"}');

    print('COLOR LEGEND:');
    print('  🔵 BLUE   = NORTH (+Y) - look for BLUE on the north wall');
    print('  🔴 RED    = SOUTH (-Y) - look for RED on the south wall');
    print('  🟢 GREEN  = EAST  (+X) - look for GREEN on the east wall');
    print('  🟡 YELLOW = WEST  (-X) - look for YELLOW on the west wall');

    return world;
  }
}
