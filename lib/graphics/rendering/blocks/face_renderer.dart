import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart' show Colors, Matrix4;
import 'package:hio/graphics/rendering/textures/texture_atlas.dart';
import '../../core/rect_uv.dart';

class FaceRenderer {
  final TextureAtlasManager _atlasManager = TextureAtlasManager.instance;

  // Кэш для Paint с текстурами
  final Map<int, Paint> _texturePaintCache = {};

  // Режим рендеринга
  bool renderBothSides = true;
  bool showDebugBorders = false; // Для отладки

  FaceRenderer();

  void render(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    double opacity = 1.0,
    RectUV? uv,
    bool isInsideBlock = false,
  }) {
    if (points.length < 3) return;

    final path = Path();
    path.addPolygon(points, true);

    Paint paint;

    // Если есть UV координаты и текстура загружена
    if (uv != null) {
      final atlas = _atlasManager.getAtlas(uv.atlasId);
      if (atlas != null) {
        final textureRect = _atlasManager.getTextureRect(uv);
        if (textureRect != null) {
          paint = _getTexturePaint(atlas, textureRect, opacity, isInsideBlock);
        } else {
          paint = _getSolidPaint(color, opacity);
        }
      } else {
        paint = _getSolidPaint(color, opacity);
      }
    } else {
      paint = _getSolidPaint(color, opacity);
    }

    canvas.drawPath(path, paint);

    // Отладочные контуры
    if (showDebugBorders || (isInsideBlock && renderBothSides)) {
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(isInsideBlock ? 0.5 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  Paint _getTexturePaint(
      Image atlas, Rect textureRect, double opacity, bool isInsideBlock) {
    final hash = Object.hash(
        atlas.hashCode, textureRect.hashCode, opacity, isInsideBlock);

    if (_texturePaintCache.containsKey(hash)) {
      return _texturePaintCache[hash]!;
    }

    // Создаем матрицу для UV координат
    // Матрица преобразует UV координаты (0-1) в координаты текстуры в атласе
    final uvMatrix = Float64List.fromList([
      textureRect.width,
      0.0,
      0.0,
      textureRect.left,
      0.0,
      textureRect.height,
      0.0,
      textureRect.top,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ]);

    Matrix4 finalMatrix;

    if (isInsideBlock) {
      // Для внутренней стороны: отражаем текстуру
      final reflectMatrix = Matrix4.identity()
        ..translate(1.0, 1.0)
        ..scale(-1.0, -1.0, 1.0);

      finalMatrix = reflectMatrix * Matrix4.fromFloat64List(uvMatrix);
    } else {
      finalMatrix = Matrix4.fromFloat64List(uvMatrix);
    }

    // Создаем ImageShader с правильной матрицей
    final shader = ImageShader(
      atlas,
      TileMode.repeated,
      TileMode.repeated,
      finalMatrix.storage,
    );

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    if (opacity < 1.0) {
      paint.color = Colors.white.withOpacity(opacity);
    }

    _texturePaintCache[hash] = paint;
    return paint;
  }

  Paint _getSolidPaint(Color color, double opacity) {
    return Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
  }

  void clearCache() {
    _texturePaintCache.clear();
  }

  void setDebugMode(bool enabled) {
    showDebugBorders = enabled;
  }
}
