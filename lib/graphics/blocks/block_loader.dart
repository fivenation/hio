import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'models/block_textures.dart';
import 'block_registry.dart';
import '../core/rect_uv.dart';

/// Загрузчик определений блоков из JSON файлов.
class BlockLoader {
  /// Загружает блок из файла resources/blocks/{id}.json
  static Future<BlockDefinition> loadFromJson(int id) async {
    final path = 'resources/blocks/$id.json';
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    return _parseBlockDefinition(data);
  }

  /// Загружает и регистрирует блок.
  static Future<void> loadAndRegister(int id) async {
    final block = await loadFromJson(id);
    BlockRegistry.instance.register(block);
  }

  static BlockDefinition _parseBlockDefinition(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final isSolid = json['isSolid'] as bool;
    final texturesJson = json['textures'] as Map<String, dynamic>;
    final color = json['color'] as String;

    final textures = BlockTextures(
      top: _parseRectUV(texturesJson['top']),
      bottom: _parseRectUV(texturesJson['bottom']),
      north: _parseRectUV(texturesJson['north']),
      south: _parseRectUV(texturesJson['south']),
      east: _parseRectUV(texturesJson['east']),
      west: _parseRectUV(texturesJson['west']),
    );

    return BlockDefinition(
      id: id,
      name: name,
      isSolid: isSolid,
      textures: textures,
      color: Color(int.tryParse(color, radix: 16) ?? 0xAABBCC),
    );
  }

  static RectUV _parseRectUV(List<dynamic> arr) {
    return RectUV(
      arr[0].toInt(),
      arr[1].toDouble(),
      arr[2].toDouble(),
      arr[3].toDouble(),
      arr[4].toDouble(),
    );
  }
}
