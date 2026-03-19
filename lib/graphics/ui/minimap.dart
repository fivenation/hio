import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../camera/player_camera.dart';
import '../world/map.dart';

class Minimap extends Component {
  final PlayerCamera camera;
  
  // Размеры миникарты
  static const double mapSize = 150.0;
  static const double cellSize = mapSize / 10; // 15px на клетку
  
  // Цвета для миникарты
  static const Color wallColor = Color(0xFF808080);
  static const Color floorNormalColor = Color(0xFF2D5A27);
  static const Color floorSpecialColor = Color(0xFF2A6F97);
  static const Color playerColor = Color(0xFFFF0000);
  static const Color outlineColor = Color(0xFF000000);
  
  Minimap({required this.camera});
  
  @override
  void render(Canvas canvas) {
    // Фон миникарты
    Paint backgroundPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(10, 10, mapSize, mapSize),
      backgroundPaint,
    );
    
    // Рисуем клетки
    for (int x = 0; x < 10; x++) {
      for (int y = 0; y < 10; y++) {
        double cellX = 10 + x * cellSize;
        double cellY = 10 + y * cellSize;
        
        // Выбираем цвет клетки
        Color cellColor;
        if (gameMap[x][y] == 1) {
          cellColor = wallColor;
        } else if (gameMap[x][y] == 2) {
          cellColor = floorSpecialColor;
        } else {
          cellColor = floorNormalColor;
        }
        
        // Рисуем клетку
        Paint cellPaint = Paint()..color = cellColor;
        canvas.drawRect(
          Rect.fromLTWH(cellX, cellY, cellSize - 1, cellSize - 1),
          cellPaint,
        );
        
        // Обводка клетки
        Paint outlinePaint = Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(
          Rect.fromLTWH(cellX, cellY, cellSize - 1, cellSize - 1),
          outlinePaint,
        );
      }
    }
    
    // Рисуем игрока (красный круг)
    double playerX = 10 + camera.position.x * cellSize;
    double playerY = 10 + camera.position.y * cellSize;
    
    Paint playerPaint = Paint()..color = playerColor;
    canvas.drawCircle(
      Offset(playerX, playerY),
      cellSize / 3,
      playerPaint,
    );
    
    // Рисуем направление взгляда игрока (линия)
    double lookX = playerX + cos(camera.angle) * cellSize;
    double lookY = playerY + sin(camera.angle) * cellSize;
    
    Paint lookPaint = Paint()
      ..color = playerColor
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(playerX, playerY),
      Offset(lookX, lookY),
      lookPaint,
    );
    
    // Рамка миникарты
    Paint borderPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(10, 10, mapSize, mapSize),
      borderPaint,
    );
  }
}