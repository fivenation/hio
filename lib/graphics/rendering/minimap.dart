import 'dart:math';
import 'dart:ui';
import '../world/game_world.dart';

/// Простая 2D мини-карта для отладки.
/// Показывает вид сверху: стены, игрока, направление взгляда.
class Minimap {
  final int size = 200; // пикселей
  final int cellSize = 4; // пикселей на клетку

  void render(Canvas canvas, GameWorld world) {
    final map = world.map;
    final player = world.player;

    // Рисуем фон
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), bgPaint);

    // Определяем область карты для отображения (центр на игроке)
    final centerX = player.x.toInt();
    final centerY = player.y.toInt();
    final halfView = (size / cellSize / 2).floor();

    for (int dx = -halfView; dx <= halfView; dx++) {
      for (int dy = -halfView; dy <= halfView; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;

        if (x < 0 || x >= map.width || y < 0 || y >= map.height) continue;

        // Проверяем блок на уровне Z=0
        final blockId = map.getBlockId(x, y, 0);
        final isWall = blockId != 0;

        final screenX = (dx + halfView) * cellSize;
        final screenY = (dy + halfView) * cellSize;

        final paint = Paint()
          ..color = isWall ? const Color(0xFF808080) : const Color(0xFF202020);
        canvas.drawRect(
          Rect.fromLTWH(screenX.toDouble(), screenY.toDouble(),
              cellSize.toDouble(), cellSize.toDouble()),
          paint,
        );
      }
    }

    // Рисуем игрока
    final playerX = (size / 2).toDouble();
    final playerY = (size / 2).toDouble();
    final playerPaint = Paint()..color = const Color(0xFFFF0000);
    canvas.drawCircle(
        Offset(playerX, playerY), cellSize.toDouble(), playerPaint);

    // Рисуем направление взгляда
    final directionX = playerX + cos(player.angle) * cellSize * 3;
    final directionY = playerY + sin(player.angle) * cellSize * 3;
    final dirPaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(playerX, playerY), Offset(directionX, directionY), dirPaint);
  }
}
