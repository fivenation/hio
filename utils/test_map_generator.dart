// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/world/models/world_map.dart';

class PlayerData {
  final double x;
  final double y;
  final double angle;

  PlayerData({required this.x, required this.y, required this.angle});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'angle': angle,
      };
}

void main() {
  final world = TestMapGenerator.generateRoomMap();

  final mapData = {
    'name': 'room_2',
    'displayName': 'Тестовая комната 2',
    'width': world.width,
    'height': world.height,
    'player': PlayerData(x: 35.0, y: 35.0, angle: 3.14).toJson(),
    'ambientLight': 1.0,
    'lightSources': [],
    'blocks': _exportBlocks(world),
  };

  final jsonString = const JsonEncoder.withIndent('  ').convert(mapData);
  File('../../../resources/maps/room_2.json').writeAsStringSync(jsonString);

  print('✅ Карта сохранена в assets/maps/room.json');
  print('📊 Всего блоков: ${(mapData['blocks'] as Map).length}');
}

List<List<int>> _exportBlocks(WorldMap world) {
  final blocks = <List<int>>[];

  for (int x = 0; x < world.width; x++) {
    for (int y = 0; y < world.height; y++) {
      for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
        final id = world.getBlockId(x, y, z);
        if (id != 0) {
          blocks.add([x, y, z, id]);
        }
      }
    }
  }

  return blocks;
}

class TestMapGenerator {
  static WorldMap generateRoomMap() {
    const width = 70;
    const height = 70;
    const roomSize = 20;
    const roomStart = (width - roomSize) ~/ 2;
    const roomEnd = roomStart + roomSize;

    print('=== GENERATING TEST MAP WITH COLORED DIRECTIONS ===');

    final world = WorldMap(width: width, height: height);

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

    world.setBlockId(centerX, roomStart, 1, 10);

    world.setBlockId(centerX, roomEnd - 1, 1, 11);

    world.setBlockId(roomEnd - 1, centerY, 1, 12);

    world.setBlockId(roomStart, centerY, 1, 13);

    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, -1, 1);
      }
    }

    for (int x = roomStart; x < roomEnd; x++) {
      for (int y = roomStart; y < roomEnd; y++) {
        world.setBlockId(x, y, 4, 1);
      }
    }

    return world;
  }
}
