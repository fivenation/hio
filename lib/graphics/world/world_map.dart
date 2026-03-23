/// Трёхмерная карта мира.
/// Хранит ID блоков в трёхмерном массиве [x][y][z].
class WorldMap {
  static const int zMin = -3;
  static const int zMax = 4;

  static const int zLevels = zMax - zMin + 1; // 8

  final int width;
  final int height;

  /// Трёхмерный массив ID блоков [x][y][zIndex]
  /// zIndex = z - zMin (0..7)
  final List<List<List<int>>> _blockIds;

  /// Создаёт пустую карту (все блоки = Air, ID=0)
  WorldMap({required this.width, required this.height})
      : _blockIds = List.generate(
          width,
          (_) => List.generate(
            height,
            (_) => List.filled(zLevels, 0),
          ),
        );

  /// Возвращает ID блока по координатам.
  /// Если координаты вне границ, возвращает 0 (Air).
  int getBlockId(int x, int y, int z) {
    if (!_isValidCoord(x, y, z)) return 0;
    final zIndex = z - zMin;
    return _blockIds[x][y][zIndex];
  }

  /// Устанавливает ID блока по координатам.
  /// Если координаты вне границ, ничего не делает.
  void setBlockId(int x, int y, int z, int id) {
    if (!_isValidCoord(x, y, z)) return;
    final zIndex = z - zMin;
    _blockIds[x][y][zIndex] = id;
  }

  /// Проверяет, находится ли блок в пределах карты.
  bool _isValidCoord(int x, int y, int z) {
    return x >= 0 &&
        x < width &&
        y >= 0 &&
        y < height &&
        z >= zMin &&
        z <= zMax;
  }

  /// Проверяет, является ли блок проходимым на уровне Z=0.
  /// Блок проходим, если его ID == 0 (Air).
  bool isWalkable(int x, int y) {
    final blockId = getBlockId(x, y, 0);
    return blockId == 0;
  }

  /// Создаёт копию карты (для тестов)
  WorldMap copy() {
    final copy = WorldMap(width: width, height: height);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        for (int z = WorldMap.zMin; z <= WorldMap.zMax; z++) {
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
