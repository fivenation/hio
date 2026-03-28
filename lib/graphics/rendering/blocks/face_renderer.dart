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
    if (points.length < 3) return;
    
    final path = Path();
    path.addPolygon(points, true);
    
    Paint paint;
    
    if (uv != null) {
      final texturePaint = _lodManager.getTexturePaint(
        uv: uv,
        distance: distance,
        opacity: opacity,
        isInsideBlock: isInsideBlock,
      );
      
      if (texturePaint != null) {
        paint = texturePaint;
      } else {
        paint = Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.fill;
      }
    } else {
      paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
    }
    
    canvas.drawPath(path, paint);
  }
  
  void clearCache() {
    _lodManager.clearCache();
  }
}