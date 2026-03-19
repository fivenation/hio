import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'package:flame/image_composition.dart';

class ResourcesManager {
  // Chaches
  final Map<String, Map<String, dynamic>> _jsonCache = {};
  final Map<String, Image> _imageCache = {};

  // Load JSON
  Future<Map<String, dynamic>> loadJson(String path) async {
    if (_jsonCache.containsKey(path)) {
      return _jsonCache[path]!;
    }

    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    _jsonCache[path] = jsonData;
    return jsonData;
  }

  // Load image
  Future<Image> loadImage(String path) async {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    final image = await Flame.images.load(path);
    _imageCache[path] = image;
    return image;
  }

  // Clear cache
  void clearCache() {
    _jsonCache.clear();
    _imageCache.clear();
  }
}
