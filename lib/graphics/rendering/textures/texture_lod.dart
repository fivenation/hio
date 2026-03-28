import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hio/graphics/core/rect_uv.dart';
import 'package:hio/graphics/rendering/textures/texture_atlas.dart';

enum TextureLOD { high, medium, low, fog, none }

class TextureLODManager {
  static final TextureLODManager _instance = TextureLODManager._internal();
  static TextureLODManager get instance => _instance;

  final TextureAtlasManager _atlasManager = TextureAtlasManager.instance;

  final Map<int, Paint> _shaderCache = {};

  static const int _maxCacheSize = 500;

  TextureLODManager._internal();

  TextureLOD getLOD(double distance) {
    if (distance < 8.0) return TextureLOD.high;
    if (distance < 16.0) return TextureLOD.medium;
    if (distance < 32.0) return TextureLOD.low;
    if (distance < 48.0) return TextureLOD.fog;
    return TextureLOD.none;
  }

  int getTextureSize(TextureLOD lod) {
    switch (lod) {
      case TextureLOD.high:
        return 128;
      case TextureLOD.medium:
        return 64;
      case TextureLOD.low:
        return 32;
      default:
        return 0;
    }
  }

  Paint? getTexturePaint({
    required RectUV uv,
    required double distance,
    required double opacity,
    required bool isInsideBlock,
  }) {
    final lod = getLOD(distance);
    if (lod == TextureLOD.none || lod == TextureLOD.fog) return null;

    final textureSize = getTextureSize(lod);
    final atlas = _atlasManager.getAtlas(textureSize);
    if (atlas == null) return null;

    final textureRect = _atlasManager.getTextureRect(uv, textureSize);
    if (textureRect == null) return null;

    // Генерируем ключ кэша
    final cacheKey = Object.hash(
      uv.left,
      uv.top,
      uv.right,
      uv.bottom,
      textureSize,
      opacity,
    );

    if (_shaderCache.containsKey(cacheKey)) {
      final cachedPaint = _shaderCache[cacheKey]!;
      if (opacity < 1.0) {
        cachedPaint.color = const Color(0xFFFFFFFF).withOpacity(opacity);
      }
      return cachedPaint;
    }

    final uScale = 1 / textureSize;
    final vScale = 1 / textureSize;
    final cellIndex = (textureRect.left / textureSize);
    final rowIndex = (textureRect.top / textureRect.height);

    final matrix = Float64List.fromList([
      uScale, 0.0, 0.0, 0.0, //
      0.0, vScale, 0.0, 0.0, //
      0.0, 0.0, 1.0, 0.0, //
      -cellIndex, -rowIndex, 0.0, 1.0, //
    ]);

    final transform = Matrix4.fromFloat64List(matrix);

    final shader = ImageShader(
      atlas,
      TileMode.clamp,
      TileMode.clamp,
      transform.storage,
    );

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.none;

    if (opacity < 1.0) {
      paint.color = const Color(0xFFFFFFFF).withOpacity(opacity);
    }
// Сохраняем в кэш
    _shaderCache[cacheKey] = paint;

    _cleanupIfNeeded();

    return paint;
  }

  void _cleanupIfNeeded() {
    if (_shaderCache.length > _maxCacheSize) {
      final keysToRemove =
          _shaderCache.keys.take(_shaderCache.length ~/ 2).toList();
      for (final key in keysToRemove) {
        _shaderCache.remove(key);
      }
    }
  }

  void clearCache() {
    _shaderCache.clear();
  }

  int getCacheSize() => _shaderCache.length;
}
