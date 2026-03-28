import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';

import 'models/block_textures.dart';
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

  // В методе registerDefaultBlocks добавьте:
  void registerDefaultBlocks() {
    // Тестовый блок с явными UV координатами
    register(BlockDefinition(
      id: 1,
      name: 'Test Block',
      isSolid: true,
      textures: BlockTextures(
        top: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        bottom: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        north: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        south: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        east: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        west: const RectUV(0.0, 0.0, 0.0625, 0.0625),
      ),
      color: Colors.grey,
    ));

    // Блок травы (для примера)
    register(BlockDefinition(
      id: 2,
      name: 'Grass',
      isSolid: true,
      textures: BlockTextures(
        top: const RectUV(0.0, 0.0, 0.0625, 0.0625),
        bottom: const RectUV(0.0625, 0.0, 0.125, 0.0625),
        north: const RectUV(0.125, 0.0, 0.1875, 0.0625),
        south: const RectUV(0.125, 0.0, 0.1875, 0.0625),
        east: const RectUV(0.125, 0.0, 0.1875, 0.0625),
        west: const RectUV(0.125, 0.0, 0.1875, 0.0625),
      ),
      color: Colors.green,
    ));
  }

  bool has(int id) {
    return _blocks.containsKey(id);
  }

  int get count => _blocks.length;
}
