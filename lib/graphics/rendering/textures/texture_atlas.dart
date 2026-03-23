import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../core/rect_uv.dart';

class TextureAtlasManager {
  static final TextureAtlasManager _instance = TextureAtlasManager._internal();
  static TextureAtlasManager get instance => _instance;

  TextureAtlasManager._internal();

  final Map<int, Image> _atlases = {};
  int _cellSize = 64;

  /// Создаёт пустую текстуру-заглушку для тестирования
  Future<Image> _createPlaceholderImage() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF808080);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        _cellSize.toDouble(),
        _cellSize.toDouble(),
      ),
      paint,
    );
    final picture = recorder.endRecording();
    return picture.toImage(_cellSize, _cellSize);
  }

  void setTextureSize(int size) {
    _cellSize = size;
  }

  Future<void> loadAtlas(int atlasId) async {
    final path = 'resources/textures/atlas_${_cellSize}_$atlasId.png';
    try {
      final data = await rootBundle.load(path);
      final image = await _decodeImageFromListAsync(data.buffer.asUint8List());
      _atlases[atlasId] = image;
    } catch (e) {
      // Если файл не найден, создаём заглушку
      final placeholder = await _createPlaceholderImage();
      _atlases[atlasId] = placeholder;
    }
  }
  
  /// Вспомогательный метод для преобразования decodeImageFromList в Future
  Future<Image> _decodeImageFromListAsync(Uint8List bytes) {
    final completer = Completer<Image>();
    decodeImageFromList(bytes, (image) {
      completer.complete(image);
    });
    return completer.future;
  }

  Image? getAtlas(int atlasId) => _atlases[atlasId];

  bool isLoaded(int atlasId) => _atlases.containsKey(atlasId);

  Rect? getTextureRect(RectUV uv) {
    final atlas = _atlases[uv.atlasId];
    if (atlas == null) return null;

    final left = uv.left * atlas.width;
    final top = uv.top * atlas.height;
    final right = uv.right * atlas.width;
    final bottom = uv.bottom * atlas.height;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void dispose() {
    for (final image in _atlases.values) {
      image.dispose();
    }
    _atlases.clear();
  }
}