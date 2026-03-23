import 'dart:ui';

import 'package:hio/graphics/block/block_defenition.dart';

import 'block_textures.dart';
import '../core/rect_uv.dart';

class BlockRegistry {
  static final BlockRegistry _instance = BlockRegistry._internal();
  static BlockRegistry get instance => _instance;

  BlockRegistry._internal();

  final Map<int, BlockDefinition> _blocks = {};

  void register(BlockDefinition block) {
    _blocks[block.id] = block;
  }

  BlockDefinition? get(int id) {
    return _blocks[id];
  }

  void registerDefaultBlocks() {
    // Блок для СЕВЕРА (синий)
    final northBlock = BlockDefinition(
      id: 10,
      name: 'north_marker',
      isSolid: true,
      textures: null,
      color: const Color(0xFF0000FF), // синий
    );
    register(northBlock);

// Блок для ЮГА (красный)
    final southBlock = BlockDefinition(
      id: 11,
      name: 'south_marker',
      isSolid: true,
      textures: null,
      color: const Color(0xFFFF0000), // красный
    );
    register(southBlock);

// Блок для ВОСТОКА (зеленый)
    final eastBlock = BlockDefinition(
      id: 12,
      name: 'east_marker',
      isSolid: true,
      textures: null,
      color: const Color(0xFF00FF00), // зеленый
    );
    register(eastBlock);

// Блок для ЗАПАДА (желтый)
    final westBlock = BlockDefinition(
      id: 13,
      name: 'west_marker',
      isSolid: true,
      textures: null,
      color: const Color(0xFFFFFF00), // желтый
    );
    register(westBlock);

    const stone = BlockDefinition(
      id: 1,
      name: 'stone',
      isSolid: true,
      textures: null,
      color: Color(0xFF808080),
    );
    register(stone);

    const wood = BlockDefinition(
      id: 2,
      name: 'wood',
      isSolid: true,
      textures: null,
      color: Color(0xFF8B4513),
    );
    register(wood);
  }

  bool has(int id) {
    return _blocks.containsKey(id);
  }

  int get count => _blocks.length;
}
