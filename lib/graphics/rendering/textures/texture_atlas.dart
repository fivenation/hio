import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:hio/core/resources/paths.dart';
import '../../core/rect_uv.dart';

class TextureAtlasManager {
  static final TextureAtlasManager _instance = TextureAtlasManager._internal();
  static TextureAtlasManager get instance => _instance;

  TextureAtlasManager._internal();

  ui.Image? _atlas32;
  ui.Image? _atlas64;
  ui.Image? _atlas128;
  bool _debugPrinted = false;

  Future<void> loadAllAtlases() async {
    await Future.wait([
      loadAtlas(32),
      loadAtlas(64),
      loadAtlas(128),
    ]);
  }

  Future<void> loadAtlas(int size) async {
    final path = Paths.texture('atlas_$size.png');
    
    try {
      final data = await rootBundle.load(path);
      final image = await _decodeImageFromList(data.buffer.asUint8List());
      
      switch (size) {
        case 32:
          _atlas32 = image;
          break;
        case 64:
          _atlas64 = image;
          break;
        case 128:
          _atlas128 = image;
          break;
      }
      
      print('✅ Атлас ${size}px загружен (${image.width}x${image.height})');
    } catch (e) {
      print('❌ Атлас ${size}px не найден: $path');
    }
  }

  ui.Image? getAtlas(int size) {
    switch (size) {
      case 32:
        return _atlas32;
      case 64:
        return _atlas64;
      case 128:
        return _atlas128;
      default:
        return null;
    }
  }

  Rect? getTextureRect(RectUV uv, int textureSize) {
    final atlas = getAtlas(textureSize);
    if (atlas == null) return null;

    final rect = Rect.fromLTWH(
      uv.left * atlas.width,
      uv.top * atlas.height,
      (uv.right - uv.left) * atlas.width,
      (uv.bottom - uv.top) * atlas.height,
    );
    
    if (!_debugPrinted && uv.left == 0.0625 && uv.top == 0.0 && textureSize == 128) {
      _debugPrinted = true;
      print('   Расчет для атласа ${textureSize}px:');
      print('   ${uv.left} * ${atlas.width} = ${uv.left * atlas.width}');
      print('   ${uv.top} * ${atlas.height} = ${uv.top * atlas.height}');
      print('   (${uv.right}-${uv.left}) * ${atlas.width} = ${(uv.right - uv.left) * atlas.width}');
    }
    
    return rect;
  }

  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (image) {
      completer.complete(image);
    });
    return completer.future;
  }
}