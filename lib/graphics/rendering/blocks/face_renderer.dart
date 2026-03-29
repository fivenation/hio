import 'dart:ui';
import 'package:hio/graphics/rendering/textures/texture_lod.dart';
import '../../core/rect_uv.dart';

class FaceRenderer {
  final TextureLODManager _lodManager = TextureLODManager.instance;

  void render(
    Canvas canvas,
    List<Offset> points,
    List<Offset> uvs,
    Color color, {
    double opacity = 1.0,
    RectUV? uv,
    double distance = 0.0,
    bool isInsideBlock = false,
  }) {
    if (points.length < 3) return;

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

        final indices = <int>[];
        for (int i = 1; i < points.length - 1; i++) {
          indices.add(0);
          indices.add(i);
          indices.add(i + 1);
        }

        final vertices = Vertices(
          VertexMode.triangles,
          points,
          textureCoordinates: uvs,
          indices: indices,
        );

        canvas.drawVertices(vertices, BlendMode.srcOver, paint);
        return;
      }
    }

    paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void clearCache() {
    _lodManager.clearCache();
  }
}
