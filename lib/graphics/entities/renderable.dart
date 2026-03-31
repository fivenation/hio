import 'dart:ui';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';

abstract class Renderable {
  double get depth;

  int get priority => 0;

  void render(
    Canvas canvas,
    ProjectionCamera camera,
    FaceRenderer faceRenderer,
    Player player,
  );
}