import 'dart:math';
import 'dart:ui';
import 'package:hio/graphics/core/constants.dart';

import '../entities/player.dart';

class ProjectionCamera {
  double screenWidth;
  double screenHeight;
  final verticalFovRad = GraphicsConsts.defaultVerticalFov * pi / 180;

  double get aspectRatio => screenWidth / screenHeight;

  double get horizontalFovRad =>
      2 * atan(tan(verticalFovRad / 2) * aspectRatio);

  double get horizonY => screenHeight * 0.5;

  ProjectionCamera({
    required this.screenWidth,
    required this.screenHeight,
  });

  void resize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  Offset? worldToScreen(double x, double y, double z, Player player) {
    double dx = x - player.x;
    double dy = y - player.y;
    double dz = z - GraphicsConsts.playerHeight;

    double cosA = cos(player.angle);
    double sinA = sin(player.angle);

    double forward = dx * cosA + dy * sinA;

    double right = -dx * sinA + dy * cosA;

    double vertical = dz;

    if (forward <= 0.1) {
      return null;
    }

    double scale = screenWidth / 2 / tan(horizontalFovRad / 2);

    double screenX = screenWidth / 2 + (right / forward) * scale;
    double screenY =
        horizonY - (vertical / forward) * scale + tan(player.pitch) * scale;

    return Offset(screenX, screenY);
  }

  List<Offset> projectPoints(
      List<(double, double, double)> points, Player player) {
    final result = <Offset>[];
    for (final (x, y, z) in points) {
      final offset = worldToScreen(x, y, z, player);
      if (offset != null) {
        result.add(offset);
      }
    }
    return result;
  }
}
