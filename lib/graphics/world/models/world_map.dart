import 'package:hio/graphics/core/constants.dart';

class WorldMap {
  final int width;
  final int height;

  final List<List<List<int>>> _blockIds;

  WorldMap({required this.width, required this.height})
      : _blockIds = List.generate(
          width,
          (_) => List.generate(
            height,
            (_) => List.filled(GraphicsConsts.zLevels, 0),
          ),
        );

  int getBlockId(int x, int y, int z) {
    if (!_isValidCoord(x, y, z)) return 0;
    final zIndex = z - GraphicsConsts.zMin;
    return _blockIds[x][y][zIndex];
  }

  void setBlockId(int x, int y, int z, int id) {
    if (!_isValidCoord(x, y, z)) return;
    final zIndex = z - GraphicsConsts.zMin;
    _blockIds[x][y][zIndex] = id;
  }

  bool _isValidCoord(int x, int y, int z) {
    return x >= 0 &&
        x < width &&
        y >= 0 &&
        y < height &&
        z >= GraphicsConsts.zMin &&
        z <= GraphicsConsts.zMax;
  }

  bool isWalkable(int x, int y) {
    final blockId = getBlockId(x, y, 0);
    return blockId == 0;
  }

  WorldMap copy() {
    final copy = WorldMap(width: width, height: height);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
          final id = getBlockId(x, y, z);
          if (id != 0) {
            copy.setBlockId(x, y, z, id);
          }
        }
      }
    }
    return copy;
  }
}
