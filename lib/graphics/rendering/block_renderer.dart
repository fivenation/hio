import 'dart:ui';
import 'camera.dart';
import 'face_renderer.dart';
import '../entities/player.dart';
import '../world/world_map.dart';

class BlockRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final WorldMap _map;

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
    int blockId,
    Player player,
    double light,
  ) {
    if (blockId == 0) return;

    if (x == 25 && y == 25 && z == 4) {
      print('Rendering block at (25,25,4)');
    }

    final x1 = x.toDouble();
    final y1 = y.toDouble();
    final z1 = z.toDouble();
    final x2 = x + 1.0;
    final y2 = y + 1.0;
    final z2 = z + 1.0;

    // Цвет блока (камень = серый)
    final color =
        blockId == 1 ? const Color(0xFF808080) : const Color(0xFF8B4513);

    // NORTH (+Y)
    if (_isFaceVisible(x, y + 1, z, z)) {
      _renderFace(
          canvas,
          [(x1, y2, z1), (x2, y2, z1), (x2, y2, z2), (x1, y2, z2)],
          player,
          light,
          color);
    }

    // SOUTH (-Y)
    if (_isFaceVisible(x, y - 1, z, z)) {
      _renderFace(
          canvas,
          [(x1, y1, z1), (x1, y1, z2), (x2, y1, z2), (x2, y1, z1)],
          player,
          light,
          color);
    }

    // EAST (+X)
    if (_isFaceVisible(x + 1, y, z, z)) {
      _renderFace(
          canvas,
          [(x2, y1, z1), (x2, y2, z1), (x2, y2, z2), (x2, y1, z2)],
          player,
          light,
          color);
    }

    // WEST (-X)
    if (_isFaceVisible(x - 1, y, z, z)) {
      _renderFace(
          canvas,
          [(x1, y1, z1), (x1, y2, z1), (x1, y2, z2), (x1, y1, z2)],
          player,
          light,
          color);
    }

    // TOP (+Z)
    if (_isFaceVisible(x, y, z + 1, z)) {
      _renderFace(
          canvas,
          [(x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2)],
          player,
          light,
          color);
    }

    // BOTTOM (-Z)
    if (_isFaceVisible(x, y, z - 1, z)) {
      _renderFace(
          canvas,
          [(x1, y1, z1), (x1, y2, z1), (x2, y2, z1), (x2, y1, z1)],
          player,
          light,
          color);
    }
  }

  bool _isFaceVisible(int nx, int ny, int nz, int currentZ) {
    if (nx < 0 || nx >= _map.width || ny < 0 || ny >= _map.height) {
      return true;
    }

    final neighborId = _map.getBlockId(nx, ny, nz);

    return neighborId == 0;
  }

  void _renderFace(
    Canvas canvas,
    List<(double, double, double)> corners,
    Player player,
    double light,
    Color color,
  ) {
    final screenPoints = _camera.projectPoints(corners, player);
    if (screenPoints.length == 4) {
      _faceRenderer.render(canvas, screenPoints, light, color);
    }
  }
}
