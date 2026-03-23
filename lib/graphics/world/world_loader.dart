import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/world_map.dart';

class WorldLoader {
  static Future<WorldMap> loadFromJson(String name) async {
    final path = 'resources/maps/$name.json';
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    return _parseWorldMap(data);
  }
  
  static WorldMap _parseWorldMap(Map<String, dynamic> json) {
    final version = json['version'] as int;
    final width = json['width'] as int;
    final height = json['height'] as int;
    final zMin = json['zMin'] as int;
    final zMax = json['zMax'] as int;
    
    // Проверка соответствия константам
    if (zMin != WorldMap.zMin || zMax != WorldMap.zMax) {
      throw Exception('Map Z range ($zMin..$zMax) does not match world constants (${WorldMap.zMin}..${WorldMap.zMax})');
    }
    
    final world = WorldMap(width: width, height: height);
    final blocksList = json['blocks'] as List<dynamic>;
    
    for (final block in blocksList) {
      final x = block[0] as int;
      final y = block[1] as int;
      final z = block[2] as int;
      final id = block[3] as int;
      world.setBlockId(x, y, z, id);
    }
    
    return world;
  }
}