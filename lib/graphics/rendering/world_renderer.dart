import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/entities/render_face.dart';
import 'package:hio/graphics/entities/renderable.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';
import 'package:hio/graphics/rendering/blocks/map_collector.dart';
import 'package:hio/graphics/world/game_world.dart';
import 'package:hio/graphics/core/constants.dart';

class WorldRenderer {
  final ProjectionCamera _camera;
  final FaceRenderer _faceRenderer;
  final MapCollector _mapCollector;

  final renderDistance = GraphicsConsts.defaultRenderDistance.toInt();

  final List<Renderable> _allRenderables = [];

  static const int _bucketCount = 50;
  final List<List<Renderable>> _buckets =
      List.generate(_bucketCount, (_) => []);

  int _frameCounter = 0;

  WorldRenderer({
    required ProjectionCamera camera,
    required FaceRenderer faceRenderer,
    required BlockRegistry blockRegistry,
  })  : _camera = camera,
        _faceRenderer = faceRenderer,
        _mapCollector = MapCollector(blockRegistry);

  void render(Canvas canvas, GameWorld world) {
    // 1. Обслуживание кэша (автоматическая очистка старых данных)
    _cleanupCaches();

    final player = world.player;

    // Подготовка инструментов отрисовки и камеры
    _faceRenderer.resetFrameBudget();
    _camera.updateCache(player);

    // 2. Сбор потенциально видимых граней из MapCollector (использует кэш колонок)
    final List<Renderable> collected =
        _mapCollector.collect(player, world.map, renderDistance);
    if (collected.isEmpty) return;

    for (var bucket in _buckets) {
      bucket.clear();
    }

    // 3. Фильтрация и распределение по дистанции
    for (final r in collected) {
      final f = r as RenderFace;

      final double dx = f.centerX - player.x;
      final double dy = f.centerY - player.y;
      final double dz = f.centerZ - player.z;

      final double distSq = dx * dx + dy * dy + dz * dz;

      bool isVisible = distSq < 0.36; // 0.6 * 0.6

      if (!isVisible) {
        final double dot = dx * f.nx + dy * f.ny + dz * f.nz;
        if (dot < 0.1) {
          isVisible = true;
        }
      }

      if (!isVisible) continue;

      final double dotDepth =
          dx * _camera.forwardX + dy * _camera.forwardY + dz * _camera.forwardZ;

      if (dotDepth < -0.2 && !isVisible) continue;

      final double realDist = sqrt(distSq);
      final processedFace = f.copyWithDistanceAndReal(dotDepth, realDist);

      int index = ((dotDepth / renderDistance) * (_bucketCount - 1))
          .floor()
          .clamp(0, _bucketCount - 1);
      _buckets[index].add(processedFace);
    }

    // 4. Painter's Algorithm
    for (int i = _bucketCount - 1; i >= 0; i--) {
      if (_buckets[i].isEmpty) continue;

      _buckets[i].sort((a, b) => b.depth.compareTo(a.depth));

      for (final face in _buckets[i]) {
        face.render(canvas, _camera, _faceRenderer, player);
      }
    }
  }

  void _cleanupCaches() {
    _frameCounter++;
    _allRenderables.clear();

    if (_frameCounter % 300 == 0) {
      _camera.clearCache();
      _faceRenderer.clearCache();
      _mapCollector.clearCache();
    }
  }
}
