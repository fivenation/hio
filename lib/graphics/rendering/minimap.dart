import 'dart:math';
import 'package:flutter/material.dart';

import '../world/game_world.dart';

class Minimap {
  final int size = 200;
  final int cellSize = 4;

  void render(Canvas canvas, GameWorld world) {
    final map = world.map;
    final player = world.player;

    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      bgPaint,
    );

    final centerX = player.x.toInt();
    final centerY = player.y.toInt();
    final halfView = (size / cellSize / 2).floor();

    for (int dx = -halfView; dx <= halfView; dx++) {
      for (int dy = -halfView; dy <= halfView; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;

        if (x < 0 || x >= map.width || y < 0 || y >= map.height) continue;

        final blockId = map.getBlockId(x, y, 0);
        final isWall = blockId != 0;

        final screenX = (dx + halfView) * cellSize;
        final screenY = (dy + halfView) * cellSize;

        final paint = Paint()
          ..color = isWall ? const Color(0xFF808080) : const Color(0xFF202020);
        canvas.drawRect(
          Rect.fromLTWH(
            screenX.toDouble(),
            screenY.toDouble(),
            cellSize.toDouble(),
            cellSize.toDouble(),
          ),
          paint,
        );
      }
    }

    final playerX = (size / 2).toDouble();
    final playerY = (size / 2).toDouble();
    final playerPaint = Paint()..color = const Color(0xFFFF0000);
    canvas.drawCircle(
      Offset(playerX, playerY),
      cellSize.toDouble(),
      playerPaint,
    );

    final dirX = playerX + cos(player.angle) * cellSize * 4;
    final dirY = playerY + sin(player.angle) * cellSize * 4;

    final dirPaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(playerX, playerY),
      Offset(dirX, dirY),
      dirPaint,
    );

    final angleDeg = (player.angle * 180 / pi).toStringAsFixed(0);
    String direction;

    if (player.angle >= -pi / 4 && player.angle < pi / 4) {
      direction = "E";
    } else if (player.angle >= pi / 4 && player.angle < 3 * pi / 4) {
      direction = "N";
    } else if (player.angle >= 3 * pi / 4 || player.angle < -3 * pi / 4) {
      direction = "W";
    } else {
      direction = "S";
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Angle: $angleDeg° ($direction)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(5, 5));

    final labels = [
      ('N', playerX, playerY - 15),
      ('S', playerX, playerY + 15),
      ('E', playerX + 15, playerY),
      ('W', playerX - 15, playerY),
    ];

    for (final (label, x, y) in labels) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(x, y));
    }
  }
}
