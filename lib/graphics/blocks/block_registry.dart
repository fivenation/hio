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

  void registerDefaultBlocks() {
    register(BlockDefinition(
      id: 7,
      name: 'test_texture',
      isSolid: true,
      textures: BlockTextures.uniform(const RectUV(0.9375, 0.9375, 1.0, 1.0)),
      color: Colors.white,
    ));
  }

  bool has(int id) {
    return _blocks.containsKey(id);
  }

  int get count => _blocks.length;
}
