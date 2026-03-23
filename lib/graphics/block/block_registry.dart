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

  /// Регистрирует стандартные блоки для тестирования
  void registerDefaultBlocks() {
    // Блок камня (ID=1)
    const stoneUV = RectUV(
      0,
      0.0625,
      0.0,
      0.125,
      0.0625,
    );

    final stone = BlockDefinition(
      id: 1,
      name: 'stone',
      isSolid: true,
      textures: BlockTextures.uniform(stoneUV),
    );

    register(stone);
  }

  bool has(int id) {
    return _blocks.containsKey(id);
  }

  int get count => _blocks.length;
}
