import 'dart:ui';
import 'package:hio/graphics/rendering/textures/texture_lod.dart';
import '../../core/rect_uv.dart';

class FaceRenderer {
  final TextureLODManager _lodManager = TextureLODManager.instance;

  // КЭШ: Храним сгенерированные объекты Vertices, чтобы не создавать их заново
  // Ключ - это хэш из координат и UV
  final Map<int, Vertices> _verticesCache = {};

  // Ограничитель нагрузки
  static const int maxTrianglesPerFrame = 5000;
  int _currentFrameTriangles = 0;

  void resetFrameBudget() => _currentFrameTriangles = 0;

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

    final double safeDistance =
        (distance.isNaN || distance < 0.05) ? 0.05 : distance;

    if (uv != null) {
      final texturePaint = _lodManager.getTexturePaint(
        uv: uv,
        distance: safeDistance,
        opacity: opacity,
        isInsideBlock: isInsideBlock,
      );

      if (texturePaint != null && texturePaint.shader != null) {
        int n = 1;
        if (_currentFrameTriangles < maxTrianglesPerFrame) {
          if (safeDistance < 2.0) {
            n = 4;
          } else if (safeDistance < 6.0) {
            n = 2;
          }
        }

        // Пытаемся взять из кэша или создаем новое
        if (points.length == 4 && n > 1) {
          _currentFrameTriangles += (n * n * 2);
          _drawWithCache(canvas, points, uvs, texturePaint, n);
        } else {
          _currentFrameTriangles += (points.length - 2);
          _renderSimplePoly(canvas, points, uvs, texturePaint);
        }
        return;
      }
    }

    _renderFallbackPath(canvas, points, color, opacity);
  }

  // Метод отрисовки с использованием кэша
  void _drawWithCache(
      Canvas canvas, List<Offset> p, List<Offset> u, Paint paint, int n) {
    // Создаем уникальный ключ для этой геометрии
    // Используем координаты точек (округленные), чтобы кэш работал, когда игрок не двигается
    int cacheKey = Object.hashAll([...p, ...u, n]);

    Vertices? v = _verticesCache[cacheKey];

    if (v == null) {
      // Если в кэше нет — создаем (используем старую логику _renderSubdividedQuad)
      v = _buildSubdividedVertices(p, u, n);

      // Если кэш слишком раздулся — чистим его (защита ОП)
      if (_verticesCache.length > 300) _verticesCache.clear();

      _verticesCache[cacheKey] = v;
    }

    canvas.drawVertices(v, BlendMode.srcOver, paint);
  }

  Vertices _buildSubdividedVertices(List<Offset> p, List<Offset> u, int n) {
    final List<Offset> meshPoints = [];
    final List<Offset> meshUVs = [];
    final List<int> indices = [];

    // ... (Тут твоя логика генерации сетки из предыдущего шага) ...
    // Для краткости: генерируем meshPoints, meshUVs и indices для сетки NxN
    for (int j = 0; j <= n; j++) {
      double vFactor = j / n;
      Offset rowStart = Offset.lerp(p[0], p[3], vFactor)!;
      Offset rowEnd = Offset.lerp(p[1], p[2], vFactor)!;
      Offset uvStart = Offset.lerp(u[0], u[3], vFactor)!;
      Offset uvEnd = Offset.lerp(u[1], u[2], vFactor)!;
      for (int i = 0; i <= n; i++) {
        double hFactor = i / n;
        meshPoints.add(Offset.lerp(rowStart, rowEnd, hFactor)!);
        meshUVs.add(Offset.lerp(uvStart, uvEnd, hFactor)!);
      }
    }
    for (int j = 0; j < n; j++) {
      for (int i = 0; i < n; i++) {
        int root = j * (n + 1) + i;
        indices.addAll([
          root,
          root + 1,
          root + n + 1,
          root + 1,
          root + n + 2,
          root + n + 1
        ]);
      }
    }

    return Vertices(VertexMode.triangles, meshPoints,
        textureCoordinates: meshUVs, indices: indices);
  }

  void _renderSimplePoly(
      Canvas canvas, List<Offset> points, List<Offset> uvs, Paint paint) {
    final indices = <int>[];
    for (int i = 1; i < points.length - 1; i++) {
      indices.addAll([0, i, i + 1]);
    }
    canvas.drawVertices(
      Vertices(VertexMode.triangles, points,
          textureCoordinates: uvs, indices: indices),
      BlendMode.srcOver,
      paint,
    );
  }

  void _renderFallbackPath(
      Canvas canvas, List<Offset> points, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withAlpha((opacity * 255).round())
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  // ПРИНУДИТЕЛЬНАЯ ОЧИСТКА
  void clearCache() {
    _verticesCache.clear();
    _currentFrameTriangles = 0;
  }
}
