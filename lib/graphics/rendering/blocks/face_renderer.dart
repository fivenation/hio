import 'dart:ui';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/rendering/textures/texture_lod.dart';
import '../../core/rect_uv.dart';

class FaceRenderer {
  final TextureLODManager _lodManager = TextureLODManager.instance;

  void render(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    double opacity = 1.0,
    RectUV? uv,
    double distance = 0.0,
    bool isInsideBlock = false,
    List<(double, double, double)>? points3D,
    ProjectionCamera? camera,
    Player? player,
  }) {
    if (points.length < 4) return;

    if (uv != null && points3D != null && camera != null && player != null) {
      final texturePaint = _lodManager.getTexturePaint(
        uv: uv,
        distance: distance,
        opacity: opacity,
        isInsideBlock: isInsideBlock,
      );

      if (texturePaint != null && texturePaint.shader != null) {
        int subdivisions = distance < 2 ? 4 : (distance < 6 ? 2 : 1);

        if (subdivisions > 1) {
          _renderSubdividedFace(
              canvas, points3D, texturePaint, subdivisions, camera, player);
          return;
        }

        _renderSimpleFace(canvas, points, texturePaint);
        return;
      }
    }

    final paint = Paint()
      ..color = color.withAlpha((opacity * 255).round())
      ..style = PaintingStyle.fill;
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, paint);
  }

  void _renderSimpleFace(Canvas canvas, List<Offset> points, Paint paint) {
    const texCoords = [Offset(0, 1), Offset(1, 1), Offset(1, 0), Offset(0, 0)];
    final vertices = Vertices(VertexMode.triangles, points,
        textureCoordinates: texCoords, indices: [0, 1, 2, 0, 3, 2]);
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  void _renderSubdividedFace(
    Canvas canvas,
    List<(double, double, double)> p,
    Paint paint,
    int div,
    ProjectionCamera camera,
    Player player,
  ) {
    final List<Offset> gridPoints = [];
    final List<Offset> gridUVs = [];
    final List<int> indices = [];

    for (int j = 0; j <= div; j++) {
      double v = j / div;
      for (int i = 0; i <= div; i++) {
        double u = i / div;

        double x = _lerp4(p[0].$1, p[1].$1, p[2].$1, p[3].$1, u, v);
        double y = _lerp4(p[0].$2, p[1].$2, p[2].$2, p[3].$2, u, v);
        double z = _lerp4(p[0].$3, p[1].$3, p[2].$3, p[3].$3, u, v);

        final screenPoint = camera.worldToScreen(x, y, z, player);
        gridPoints.add(screenPoint ?? Offset.zero);
        gridUVs.add(Offset(u, 1.0 - v));
      }
    }

    for (int j = 0; j < div; j++) {
      for (int i = 0; i < div; i++) {
        int row1 = j * (div + 1);
        int row2 = (j + 1) * (div + 1);
        indices.addAll([row1 + i, row1 + i + 1, row2 + i + 1]);
        indices.addAll([row1 + i, row2 + i + 1, row2 + i]);
      }
    }

    final vertices = Vertices(
      VertexMode.triangles,
      gridPoints,
      textureCoordinates: gridUVs,
      indices: indices,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  double _lerp4(double a, double b, double c, double d, double u, double v) {
    return (a * (1 - u) * (1 - v)) +
        (b * u * (1 - v)) +
        (c * u * v) +
        (d * (1 - u) * v);
  }

  void clearCache() {
    _lodManager.clearCache();
  }
}
