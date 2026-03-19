import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../world/map.dart';
import '../camera/player_camera.dart';

class WallRenderer extends Component {
  final PlayerCamera camera;

  static const double horizonRatio = 0.3;
  static const double viewDistance = 15.0;
  static const double renderDistance =
      12.0; // ← общий радиус отрисовки и для стен и для пола

  static const Color wallColor = Color(0xFF808080);
  static const Color wallOutlineColor = Color(0xFF404040);
  static const Color floorNormalColor = Color(0xFF2D5A27);
  static const Color floorSpecialColor = Color(0xFF2A6F97);

  WallRenderer({required this.camera});

  @override
  void render(Canvas canvas) {
    final screenWidth = camera.screenWidth;
    final screenHeight = camera.screenHeight;

    if (screenWidth == 0 || screenHeight == 0) return;

    double horizonY = screenHeight * horizonRatio;

    Paint skyPaint = Paint()..color = const Color(0xFF87CEEB);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, horizonY),
      skyPaint,
    );

    _drawFloorAroundCamera(canvas);
    _drawWallsAroundCamera(canvas);
  }

  bool _isInRenderDistance(double x, double y) {
    double dx = x - camera.position.x;
    double dy = y - camera.position.y;
    double distance = sqrt(dx * dx + dy * dy);
    return distance <= renderDistance;
  }

  void _drawFloorAroundCamera(Canvas canvas) {
    final screenWidth = camera.screenWidth;
    final screenHeight = camera.screenHeight;
    double horizonY = screenHeight * horizonRatio;

    // Определяем диапазон клеток вокруг камеры
    int minX = (camera.position.x - renderDistance).floor();
    int maxX = (camera.position.x + renderDistance).ceil();
    int minY = (camera.position.y - renderDistance).floor();
    int maxY = (camera.position.y + renderDistance).ceil();

    // Ограничиваем картой
    minX = max(0, minX);
    maxX = min(gameMap.length - 1, maxX);
    minY = max(0, minY);
    maxY = min(gameMap[0].length - 1, maxY);

    for (int mapX = minX; mapX <= maxX; mapX++) {
      for (int mapY = minY; mapY <= maxY; mapY++) {
        double worldX = mapX.toDouble() + 0.5;
        double worldY = mapY.toDouble() + 0.5;

        if (_isInRenderDistance(worldX, worldY)) {
          if (gameMap[mapX][mapY] == 0 || gameMap[mapX][mapY] == 2) {
            _drawFloorTile(
                canvas,
                mapX.toDouble(),
                mapY.toDouble(),
                gameMap[mapX][mapY] == 2
                    ? floorSpecialColor
                    : floorNormalColor);
          }
        }
      }
    }
  }

  void _drawWallsAroundCamera(Canvas canvas) {
    List<_WallInfo> walls = [];

    // Определяем диапазон клеток вокруг камеры
    int minX = (camera.position.x - renderDistance).floor();
    int maxX = (camera.position.x + renderDistance).ceil();
    int minY = (camera.position.y - renderDistance).floor();
    int maxY = (camera.position.y + renderDistance).ceil();

    // Ограничиваем картой
    minX = max(0, minX);
    maxX = min(gameMap.length - 1, maxX);
    minY = max(0, minY);
    maxY = min(gameMap[0].length - 1, maxY);

    for (int mapX = minX; mapX <= maxX; mapX++) {
      for (int mapY = minY; mapY <= maxY; mapY++) {
        if (gameMap[mapX][mapY] == 1) {
          double worldX = mapX.toDouble() + 0.5;
          double worldY = mapY.toDouble() + 0.5;

          if (_isInRenderDistance(worldX, worldY)) {
            walls.add(_WallInfo(
              x: mapX.toDouble(),
              y: mapY.toDouble(),
              distance: _getDistanceToWall(mapX.toDouble(), mapY.toDouble()),
            ));
          }
        }
      }
    }

    walls.sort((a, b) => b.distance.compareTo(a.distance));

    for (var wall in walls) {
      _drawWallTile(canvas, wall.x, wall.y);
    }
  }

  void _drawFloorTile(Canvas canvas, double x, double y, Color color) {
    final screenWidth = camera.screenWidth;
    final screenHeight = camera.screenHeight;
    double horizonY = screenHeight * horizonRatio;

    List<Vector3> corners = [
      Vector3(x, y, 0),
      Vector3(x + 1, y, 0),
      Vector3(x + 1, y + 1, 0),
      Vector3(x, y + 1, 0),
    ];

    List<Offset> screenPoints = [];

    for (var corner in corners) {
      double dx = corner.x - camera.position.x;
      double dy = corner.y - camera.position.y;
      double dz = corner.z - camera.playerHeight;

      double cosA = cos(camera.angle);
      double sinA = sin(camera.angle);

      double rotatedX = dx * sinA - dy * cosA;
      double rotatedY = dx * cosA + dy * sinA;

      if (rotatedY > 0.1) {
        double screenX = screenWidth -
            ((rotatedX / rotatedY) * (screenWidth / 2) + screenWidth / 2);
        double screenY = horizonY - (dz / rotatedY) * (screenWidth / 2);

        screenPoints.add(Offset(screenX, screenY));
      }
    }

    if (screenPoints.length == 4) {
      Path floorPath = Path()
        ..moveTo(screenPoints[0].dx, screenPoints[0].dy)
        ..lineTo(screenPoints[1].dx, screenPoints[1].dy)
        ..lineTo(screenPoints[2].dx, screenPoints[2].dy)
        ..lineTo(screenPoints[3].dx, screenPoints[3].dy)
        ..close();

      Paint floorPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawPath(floorPath, floorPaint);
    }
  }

  List<String> _getVisibleFaces(double wallX, double wallY) {
    double dx = camera.position.x - (wallX + 0.5);
    double dy = camera.position.y - (wallY + 0.5);

    List<String> visibleFaces = [];

    if (dy > 0.3) visibleFaces.add('south');
    if (dy < -0.3) visibleFaces.add('north');
    if (dx > 0.3) visibleFaces.add('east');
    if (dx < -0.3) visibleFaces.add('west');

    return visibleFaces;
  }

  double _getDistanceToWall(double x, double y) {
    double dx = (x + 0.5) - camera.position.x;
    double dy = (y + 0.5) - camera.position.y;
    return sqrt(dx * dx + dy * dy);
  }

  void _drawWallTile(Canvas canvas, double x, double y) {
    Vector3 bottomNW = Vector3(x, y, 0);
    Vector3 bottomNE = Vector3(x + 1, y, 0);
    Vector3 bottomSW = Vector3(x, y + 1, 0);
    Vector3 bottomSE = Vector3(x + 1, y + 1, 0);

    Vector3 topNW = Vector3(x, y, camera.wallHeight);
    Vector3 topNE = Vector3(x + 1, y, camera.wallHeight);
    Vector3 topSW = Vector3(x, y + 1, camera.wallHeight);
    Vector3 topSE = Vector3(x + 1, y + 1, camera.wallHeight);

    List<String> visibleFaces = _getVisibleFaces(x, y);

    for (String face in visibleFaces) {
      switch (face) {
        case 'north':
          _drawWallFace(canvas, [bottomNW, bottomNE, topNE, topNW]);
          break;
        case 'south':
          _drawWallFace(canvas, [bottomSE, bottomSW, topSW, topSE]);
          break;
        case 'east':
          _drawWallFace(canvas, [bottomNE, bottomSE, topSE, topNE]);
          break;
        case 'west':
          _drawWallFace(canvas, [bottomSW, bottomNW, topNW, topSW]);
          break;
      }
    }
  }

  void _drawWallFace(Canvas canvas, List<Vector3> corners) {
    final screenWidth = camera.screenWidth;
    final screenHeight = camera.screenHeight;
    double horizonY = screenHeight * horizonRatio;

    List<Offset> screenPoints = [];

    for (var corner in corners) {
      double dx = corner.x - camera.position.x;
      double dy = corner.y - camera.position.y;
      double dz = corner.z - camera.playerHeight;

      double cosA = cos(camera.angle);
      double sinA = sin(camera.angle);

      double rotatedX = dx * sinA - dy * cosA;
      double rotatedY = dx * cosA + dy * sinA;

      if (rotatedY > 0.1) {
        double screenX = screenWidth -
            ((rotatedX / rotatedY) * (screenWidth / 2) + screenWidth / 2);
        double screenY = horizonY - (dz / rotatedY) * (screenWidth / 2);

        screenPoints.add(Offset(screenX, screenY));
      }
    }

    if (screenPoints.length == 4) {
      Path facePath = Path()
        ..moveTo(screenPoints[0].dx, screenPoints[0].dy)
        ..lineTo(screenPoints[1].dx, screenPoints[1].dy)
        ..lineTo(screenPoints[2].dx, screenPoints[2].dy)
        ..lineTo(screenPoints[3].dx, screenPoints[3].dy)
        ..close();

      Paint fillPaint = Paint()
        ..color = wallColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(facePath, fillPaint);

      Paint outlinePaint = Paint()
        ..color = wallOutlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(facePath, outlinePaint);
    }
  }
}

class _WallInfo {
  final double x;
  final double y;
  final double distance;

  _WallInfo({required this.x, required this.y, required this.distance});
}
