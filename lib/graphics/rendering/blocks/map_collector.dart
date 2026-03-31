import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/entities/render_face.dart';
import 'package:hio/graphics/entities/renderable.dart';
import 'package:hio/graphics/world/models/world_map.dart';

class MapCollector {
  final BlockRegistry _blockRegistry;
  final Map<int, _CachedColumnData> _columnCache = {};

  MapCollector(this._blockRegistry);

  List<Renderable> collect(Player player, WorldMap map, int renderDistance) {
    final List<Renderable> result = [];

    final px = player.x.floor();
    final py = player.y.floor();

    for (int tx = px - renderDistance; tx <= px + renderDistance; tx++) {
      for (int ty = py - renderDistance; ty <= py + renderDistance; ty++) {
        if (tx < 0 || tx >= map.width || ty < 0 || ty >= map.height) continue;

        final key = tx * 10000 + ty;
        final column = _getOrBuildColumn(tx, ty, map);

        if (column.faces.isEmpty) continue;

        for (final face in column.faces) {
          result.add(face);
        }
      }
    }
    return result;
  }

  _CachedColumnData _getOrBuildColumn(int x, int y, WorldMap map) {
    final key = x * 10000 + y;
    if (_columnCache.containsKey(key)) return _columnCache[key]!;

    final List<RenderFace> columnFaces = [];

    for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
      final blockId = map.getBlockId(x, y, z);
      if (blockId == 0) continue; // Воздух не рисуем

      final def = _blockRegistry.get(blockId);
      if (def == null) continue;

      if (map.getBlockId(x, y, z + 1) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.top);
      }
      if (map.getBlockId(x, y, z - 1) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.bottom);
      }
      if (map.getBlockId(x + 1, y, z) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.north);
      }
      if (map.getBlockId(x - 1, y, z) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.south);
      }
      if (map.getBlockId(x, y + 1, z) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.east);
      }
      if (map.getBlockId(x, y - 1, z) == 0) {
        _createFace(columnFaces, x, y, z, def, FaceDirection.west);
      }
    }

    final data = _CachedColumnData(columnFaces);
    _columnCache[key] = data;
    return data;
  }

  void _addIfVisible(List<RenderFace> faces, int x, int y, int z,
      BlockDefinition def, WorldMap map) {
    if (map.getBlockId(x, y, z + 1) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.top);
    }
    if (map.getBlockId(x, y, z - 1) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.bottom);
    }
    if (map.getBlockId(x + 1, y, z) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.north);
    }
    if (map.getBlockId(x - 1, y, z) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.south);
    }
    if (map.getBlockId(x, y + 1, z) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.east);
    }
    if (map.getBlockId(x, y - 1, z) == 0) {
      _createFace(faces, x, y, z, def, FaceDirection.west);
    }
  }

  void _createFace(List<RenderFace> faces, int x, int y, int z,
      BlockDefinition def, FaceDirection dir) {
    final double xf = x.toDouble();
    final double yf = y.toDouble();
    final double zf = z.toDouble();

    double nx = 0, ny = 0, nz = 0;
    switch (dir) {
      case FaceDirection.top:
        nz = 1;
        break;
      case FaceDirection.bottom:
        nz = -1;
        break;
      case FaceDirection.north:
        nx = 1;
        break;
      case FaceDirection.south:
        nx = -1;
        break;
      case FaceDirection.east:
        ny = 1;
        break;
      case FaceDirection.west:
        ny = -1;
        break;
    }

    final double cx = xf + 0.5 + (nx * 0.5);
    final double cy = yf + 0.5 + (ny * 0.5);
    final double cz = zf + 0.5 + (nz * 0.5);

    late List<(double, double, double)> p;
    switch (dir) {
      case FaceDirection.top:
        p = [
          (xf, yf, zf + 1),
          (xf + 1, yf, zf + 1),
          (xf + 1, yf + 1, zf + 1),
          (xf, yf + 1, zf + 1)
        ]; //
        break;
      case FaceDirection.bottom:
        p = [
          (xf, yf, zf),
          (xf, yf + 1, zf),
          (xf + 1, yf + 1, zf),
          (xf + 1, yf, zf)
        ]; //
        break;
      case FaceDirection.north: // X+
        p = [
          (xf + 1, yf, zf),
          (xf + 1, yf, zf + 1),
          (xf + 1, yf + 1, zf + 1),
          (xf + 1, yf + 1, zf)
        ]; //
        break;
      case FaceDirection.south: // X-
        p = [
          (xf, yf, zf),
          (xf, yf + 1, zf),
          (xf, yf + 1, zf + 1),
          (xf, yf, zf + 1)
        ]; //
        break;
      case FaceDirection.east: // Y+
        p = [
          (xf, yf + 1, zf),
          (xf + 1, yf + 1, zf),
          (xf + 1, yf + 1, zf + 1),
          (xf, yf + 1, zf + 1)
        ]; //
        break;
      case FaceDirection.west: // Y-
        p = [
          (xf, yf, zf),
          (xf, yf, zf + 1),
          (xf + 1, yf, zf + 1),
          (xf + 1, yf, zf)
        ]; //
        break;
    }

    faces.add(RenderFace(
      points3D: p,
      color: def.color,
      uv: def.getFaceUV(dir),
      centerX: cx,
      centerY: cy,
      centerZ: cz,
      nx: nx,
      ny: ny,
      nz: nz,
      depth: 0.0,
    ));
  }

  void clearCache() => _columnCache.clear();
}

class _CachedColumnData {
  final List<RenderFace> faces;
  _CachedColumnData(this.faces);
}
