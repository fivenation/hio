import 'dart:ui';
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
  }) {
    if (points.length < 4) return;

    Paint paint;

    if (uv != null) {
      final texturePaint = _lodManager.getTexturePaint(
        uv: uv,
        distance: distance,
        opacity: opacity,
        isInsideBlock: isInsideBlock,
      );

      if (texturePaint != null && texturePaint.shader != null) {
        paint = texturePaint;

        final positions = [
          points[0],
          points[1],
          points[2],
          points[3],
        ];

        final texCoords = [
          const Offset(0.0, 1.0),
          const Offset(1.0, 1.0),
          const Offset(1.0, 0.0),
          const Offset(0.0, 0.0),
        ];

        final indices = [0, 1, 2, 0, 3, 2];

        final vertices = Vertices(
          VertexMode.triangles,
          positions,
          textureCoordinates: texCoords,
          indices: indices,
        );

        canvas.drawVertices(vertices, BlendMode.srcOver, paint);
        return;
      }
    }

    paint = Paint()
      ..color = color.withAlpha((opacity * 255).round())
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addPolygon(points, true);
    canvas.drawPath(path, paint);
  }

  void clearCache() {
    _lodManager.clearCache();
  }
}
