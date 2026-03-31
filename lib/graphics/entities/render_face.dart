import 'dart:ui';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/core/rect_uv.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/entities/renderable.dart';
import 'package:hio/graphics/rendering/blocks/face_renderer.dart';

class RenderFace implements Renderable {
  final List<(double, double, double)> points3D;
  final Color color;
  final RectUV? uv;
  final double centerX, centerY, centerZ, nx, ny, nz;

  @override
  final double depth;
  double realDistance = 0.0;

  @override
  int get priority => 0;

  RenderFace({
    required this.points3D,
    required this.color,
    this.uv,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.depth,
    this.realDistance = 0.0,
    required this.nx,
    required this.ny,
    required this.nz,
  });

  RenderFace copyWithDistanceAndReal(double newDepth, double dist) {
    return RenderFace(
      points3D: points3D,
      color: color,
      uv: uv,
      centerX: centerX,
      centerY: centerY,
      centerZ: centerZ,
      depth: newDepth,
      realDistance: dist,
      nx: nx,
      ny: ny,
      nz: nz,
    );
  }

  @override
  void render(
    Canvas canvas,
    ProjectionCamera camera,
    FaceRenderer renderer,
    Player player,
  ) {
    final clip = camera.clipAndProjectQuad(points3D, player);
    if (clip != null) {
      renderer.render(
        canvas,
        clip.screenPoints,
        clip.uvPoints,
        color,
        distance: realDistance,
        uv: uv,
      );
    }
  }
}
