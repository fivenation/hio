import 'dart:ui';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/core/rect_uv.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/entities/renderable.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';

class BillboardEntity implements Renderable {
  final double x, y, z;
  final double width;
  final double height;
  final RectUV uv;
  
  @override
  late final double depth;

  @override
  int get priority => 2;

  BillboardEntity({
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.uv,
    required Player player,
  }) {
    final dx = x - player.x;
    final dy = y - player.y;
    depth = (dx * dx + dy * dy); 
  }

  @override
  void render(
    Canvas canvas,
    ProjectionCamera camera,
    FaceRenderer faceRenderer,
    Player player,
  ) {
    // Здесь мы:
    // 1. Проверим, не за спиной ли билборд (через camera.isPointInFront)
    // 2. Спроецируем центр (x, y, z) в экранные координаты
    // 3. Вычислим размер спрайта на экране в зависимости от Z-глубины
    // 4. Вызовем отрисовку плоского Rect!
    
    // TODO: Будет реализовано на следующем шаге :)
  }
}