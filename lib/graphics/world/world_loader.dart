import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hio/graphics/world/models/lighting.dart';
import 'package:hio/graphics/world/models/map_metadata.dart';
import 'package:hio/graphics/world/models/player_data.dart';
import 'package:hio/graphics/world/models/world_map.dart';

class WorldLoader {
  static Future<List<MapMetadata>> loadMapList() async {
    try {
      // TODO --> To Path list file
      final String jsonString =
          await rootBundle.loadString('resources/maps/manifest.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> mapsJson = data['maps'];

      return mapsJson
          .map((json) => MapMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading map manifest: $e');
      }
      return [];
    }
  }

  static Future<
      ({
        WorldMap map,
        PlayerData player,
        double ambientLight,
        List<LightSource> lightSources,
      })> loadMap(String mapName) async {
    final path = 'resources/maps/$mapName.json';
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    return _parseWorldMap(data);
  }

  static ({
    WorldMap map,
    PlayerData player,
    double ambientLight,
    List<LightSource> lightSources,
  }) _parseWorldMap(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;

    // Создаём пустую карту
    final world = WorldMap(width: width, height: height);

    // Загружаем блоки
    final blocksList = json['blocks'] as List<dynamic>;
    for (final block in blocksList) {
      final x = block[0] as int;
      final y = block[1] as int;
      final z = block[2] as int;
      final id = block[3] as int;
      world.setBlockId(x, y, z, id);
    }

    final playerData =
        PlayerData.fromJson(json['player'] as Map<String, dynamic>);

    final ambientLight = (json['ambientLight'] as num?)?.toDouble() ?? 1.0;

    final lightSources = <LightSource>[];
    if (json['lightSources'] != null) {
      for (final source in json['lightSources'] as List<dynamic>) {
        lightSources.add(LightSource(
          x: (source['x'] as num).toDouble(),
          y: (source['y'] as num).toDouble(),
          z: (source['z'] as num).toDouble(),
          radius: (source['radius'] as num).toDouble(),
          intensity: (source['intensity'] as num).toDouble(),
        ));
      }
    }

    return (
      map: world,
      player: playerData,
      ambientLight: ambientLight,
      lightSources: lightSources,
    );
  }
}
