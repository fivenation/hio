import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'texture_atlas.dart';
import '../../core/rect_uv.dart';

enum TextureLOD { high, medium, low, fog, none }

class TextureLODManager {
  static final TextureLODManager _instance = TextureLODManager._internal();
  static TextureLODManager get instance => _instance;

  final TextureAtlasManager _atlasManager = TextureAtlasManager.instance;
  final Map<int, Paint> _shaderCache = {};
  bool _debugPrinted = false;

  TextureLODManager._internal();

  TextureLOD getLOD(double distance) {
    if (distance < 16.0) return TextureLOD.high;
    if (distance < 32.0) return TextureLOD.medium;
    if (distance < 48.0) return TextureLOD.low;
    if (distance < 64.0) return TextureLOD.fog;
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

    // Отладка только для камня (вторая текстура)
    if (!_debugPrinted && uv.left == 0.0625 && uv.top == 0.0) {
      _debugPrinted = true;
      print('🔍 Текстура камня (UV: $uv)');
      print('   Атлас: ${atlas.width}x${atlas.height}');
      print(
          '   textureRect: left=${textureRect.left}, top=${textureRect.top}, width=${textureRect.width}, height=${textureRect.height}');
    }

    final hash =
        Object.hash(atlas.hashCode, textureRect.hashCode, isInsideBlock);

    if (_shaderCache.containsKey(hash)) {
      return _shaderCache[hash]!;
    }

    final matrix = Float64List.fromList([
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

    final transform = isInsideBlock
        ? (Matrix4.identity()
          ..translate(1.0, 1.0)
          ..scale(-1.0, -1.0, 1.0)
          ..multiply(Matrix4.fromFloat64List(matrix)))
        : Matrix4.fromFloat64List(matrix);

    final shader = ImageShader(
      atlas,
      TileMode.clamp,
      TileMode.clamp,
      transform.storage,
    );

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.high;

    if (opacity < 1.0) {
      paint.color = const Color(0xFFFFFFFF).withOpacity(opacity);
    }

    _shaderCache[hash] = paint;
    return paint;
  }

  void clearCache() {
    _shaderCache.clear();
    _debugPrinted = false;
  }
}
