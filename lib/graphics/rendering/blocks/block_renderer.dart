import 'dart:math';
import 'dart:ui';
import 'package:hio/graphics/block/block_defenition.dart';
import 'package:hio/graphics/rendering/camera.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/world/world_map.dart';
import 'face_renderer.dart';

class _RenderFace {
  final List<(double, double, double)> corners;
  final Color color;
  final double depth; // средняя глубина для сортировки

  _RenderFace({
    required this.corners,
    required this.color,
    required this.depth,
  });
}

class BlockRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final WorldMap _map;

  // Собираем все грани для сортировки
  final List<_RenderFace> _facesToRender = [];

  BlockRenderer({
    required ProjectionCamera camera,
    required WorldMap map,
  })  : _camera = camera,
        _faceRenderer = FaceRenderer(),
        _map = map;

  void renderBlock(
    Canvas canvas,
    int x,
    int y,
    int z,
    BlockDefinition block,
    Player player,
    double light,
  ) {
    // Очищаем список граней для этого блока
    _facesToRender.clear();

    final x1 = x.toDouble();
    final y1 = y.toDouble();
    final z1 = z.toDouble();
    final x2 = x + 1.0;
    final y2 = y + 1.0;
    final z2 = z + 1.0;

    // NORTH (+Y)
    if (_isFaceVisible(x, y + 1, z)) {
      _addFace(
        [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
        block.color,
        player,
        light,
      );
    }

    // SOUTH (-Y)
    if (_isFaceVisible(x, y - 1, z)) {
      _addFace(
        [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
        block.color,
        player,
        light,
      );
    }

    // EAST (+X)
    if (_isFaceVisible(x + 1, y, z)) {
      _addFace(
        [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
        block.color,
        player,
        light,
      );
    }

    // WEST (-X)
    if (_isFaceVisible(x - 1, y, z)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
        block.color,
        player,
        light,
      );
    }

    // TOP (+Z)
    if (_isFaceVisible(x, y, z + 1)) {
      _addFace(
        [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
        block.color,
        player,
        light,
      );
    }

    // BOTTOM (-Z)
    if (_isFaceVisible(x, y, z - 1)) {
      _addFace(
        [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
        block.color,
        player,
        light,
      );
    }

    // Сортируем грани по глубине (от дальних к ближним)
    _facesToRender.sort((a, b) => b.depth.compareTo(a.depth));

    // Рендерим отсортированные грани
    for (final face in _facesToRender) {
      final screenPoints = _camera.projectPoints(face.corners, player);
      if (screenPoints.length == 4) {
        _faceRenderer.render(
          canvas,
          screenPoints,
          face.color,
          light,
        );
      }
    }
  }

  void _addFace(
    List<(double, double, double)> corners,
    Color color,
    Player player,
    double light,
  ) {
    // Вычисляем среднюю глубину грани (вперед от камеры)
    double totalForward = 0.0;
    int validPoints = 0;

    for (final (x, y, z) in corners) {
      // Вектор от игрока до точки
      final dx = x - player.x;
      final dy = y - player.y;
      final dz = z - 1.5; // высота игрока

      final cosA = cos(player.angle);
      final sinA = sin(player.angle);

      // Глубина в пространстве камеры - это forward
      final forward = dx * cosA + dy * sinA;

      totalForward += forward;
      validPoints++;
    }

    if (validPoints > 0) {
      final avgForward = totalForward / validPoints;

      _facesToRender.add(_RenderFace(
        corners: corners,
        color: Color.fromARGB(
          255,
          (color.red * light).toInt().clamp(0, 255),
          (color.green * light).toInt().clamp(0, 255),
          (color.blue * light).toInt().clamp(0, 255),
        ),
        depth: avgForward, // глубина - это forward расстояние
      ));
    }
  }

  bool _isFaceVisible(int nx, int ny, int nz) {
    // Если сосед за границей карты, грань видна
    if (nx < 0 || nx >= _map.width || ny < 0 || ny >= _map.height) {
      return true;
    }

    final neighborId = _map.getBlockId(nx, ny, nz);
    return neighborId == 0; // Видна, если сосед - воздух
  }
}
