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

    final centerX = roomStart + roomSize ~/ 2;
    final centerY = roomStart + roomSize ~/ 2;

    world.setBlockId(
        centerX, roomStart, 1, 10); // roomStart = минимальный Y = север

    world.setBlockId(
        centerX, roomEnd - 1, 1, 11); // roomEnd-1 = максимальный Y = юг

    world.setBlockId(
        roomEnd - 1, centerY, 1, 12); // roomEnd-1 = максимальный X = восток

    world.setBlockId(
        roomStart, centerY, 1, 13); // roomStart = минимальный X = запад

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

    print('=== MAP READY ===');
    print('Player spawn at ($playerX, $playerY, 0)');
    print('');
    print('COLOR LEGEND:');
    print('  🔵 BLUE   = NORTH (N) - look for BLUE on the north wall');
    print('  🔴 RED    = SOUTH (S) - look for RED on the south wall');
    print('  🟢 GREEN  = EAST  (E) - look for GREEN on the east wall');
    print('  🟡 YELLOW = WEST  (W) - look for YELLOW on the west wall');

    return world;
  }
}
