import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hio/core/resources/paths.dart';
import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'models/block_textures.dart';
import 'block_registry.dart';
import '../core/rect_uv.dart';

class BlockLoader {
  static bool _loaded = false;
  
  static Future<void> loadAllBlocks() async {
    if (_loaded) return;
    
    if (kDebugMode) {
      print('🔍 Загрузка блоков: $Paths.blocks');
    }
    
    try {
      final jsonString = await rootBundle.loadString(Paths.blocks);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> blocksJson = data['blocks'];
      
      for (final blockJson in blocksJson) {
        final block = _parseBlockDefinition(blockJson);
        BlockRegistry.instance.register(block);
      }
      
      _loaded = true;
      if (kDebugMode) {
        print('✅ Все блоки загружены: ${blocksJson.length} шт');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка загрузки blocks.json: $e');
      }
      rethrow;
    }
  }

  static BlockDefinition _parseBlockDefinition(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final isSolid = json['isSolid'] as bool;
    final colorStr = json['color'] as String;
    final color = Color(int.parse(colorStr, radix: 16));
    
    BlockTextures? textures;
    
    if (json.containsKey('textures') && json['textures'] != null) {
      final texturesJson = json['textures'] as Map<String, dynamic>;
      
      if (texturesJson.containsKey('all')) {
        final uv = _parseRectUV(texturesJson['all']);
        textures = BlockTextures.uniform(uv);
      } else {
        textures = BlockTextures(
          top: _parseRectUV(texturesJson['top']),
          bottom: _parseRectUV(texturesJson['bottom']),
          north: _parseRectUV(texturesJson['north']),
          south: _parseRectUV(texturesJson['south']),
          east: _parseRectUV(texturesJson['east']),
          west: _parseRectUV(texturesJson['west']),
        );
      }
    }

    return BlockDefinition(
      id: id,
      name: name,
      isSolid: isSolid,
      textures: textures,
      color: color,
    );
  }

  static RectUV _parseRectUV(dynamic arr) {
    if (arr is List && arr.length >= 4) {
      return RectUV(
        (arr[0] as num).toDouble(),
        (arr[1] as num).toDouble(),
        (arr[2] as num).toDouble(),
        (arr[3] as num).toDouble(),
      );
    }
    return const RectUV(0.0, 0.0, 1.0, 1.0);
  }
}