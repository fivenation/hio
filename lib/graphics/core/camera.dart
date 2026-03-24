/*
 * Модуль проекционной камеры для 3D-рендеринга.
 * 
 * ОСНОВНАЯ ЗАДАЧА:
 * Преобразование мировых координат (X, Y, Z) в экранные координаты (X, Y)
 * с использованием перспективной проекции.
 * 
 * МАТЕМАТИЧЕСКАЯ МОДЕЛЬ:
 * 
 * 1. СИСТЕМА КООРДИНАТ КАМЕРЫ
 *    - Игрок находится в точке (player.x, player.y) на высоте playerHeight
 *    - Направление взгляда определяется углом angle (горизонталь) и pitch (вертикаль)
 *    - Ось Z направлена вверх, Y - на север, X - на восток
 * 
 * 2. ПРЕОБРАЗОВАНИЕ В ПРОСТРАНСТВО КАМЕРЫ
 *    Вектор от игрока до точки: (dx, dy, dz) = (x - player.x, y - player.y, z - playerHeight)
 *    
 *    Поворот в систему камеры:
 *    - forward (глубина) = dx * cos(angle) + dy * sin(angle)
 *    - right (боковое смещение) = -dx * sin(angle) + dy * cos(angle)
 *    - vertical (вертикаль) = dz
 * 
 * 3. ПЕРСПЕКТИВНАЯ ПРОЕКЦИЯ
 *    scale = screenWidth / 2 / tan(horizontalFov / 2)
 *    
 *    screenX = screenWidth / 2 + (right / forward) * scale
 *    screenY = horizonY - (vertical / forward) * scale + tan(pitch) * scale
 * 
 * 4. ОПТИМИЗАЦИЯ (КЭШИРОВАНИЕ)
 *    - Все тригонометрические вычисления (cos, sin, tan) выполняются 1 раз за кадр
 *    - Метод updateCache() вызывается перед рендерингом
 *    - Кэшированные значения используются во всех worldToScreen вызовах
 * 
 * ПАРАМЕТРЫ:
 *    - verticalFovDegrees: вертикальное поле зрения в градусах (по умолчанию 60°)
 *    - horizonY: линия горизонта (центр экрана)
 *    - playerHeight: высота глаз игрока над полом (1.5 метра)
 */

import 'dart:math';
import 'dart:ui';
import '../../graphics/entities/player.dart';
import '../core/constants.dart';

class ProjectionCamera {
  double screenWidth;
  double screenHeight;
  final double verticalFovDegrees;
  late final double verticalFovRad;

  double get aspectRatio => screenWidth / screenHeight;

  double get horizontalFovRad =>
      2 * atan(tan(verticalFovRad / 2) * aspectRatio);

  double get horizonY => screenHeight * 0.5;

  double _cachedCosA = 0;
  double _cachedSinA = 0;
  double _cachedScale = 0;
  double _cachedTanPitch = 0;
  bool _cacheValid = false;

  ProjectionCamera({
    required this.screenWidth,
    required this.screenHeight,
    this.verticalFovDegrees = GraphicsConsts.defaultVerticalFov,
  }) {
    verticalFovRad = verticalFovDegrees * pi / 180;
  }

  void resize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
    _cacheValid = false;
  }

  void updateCache(Player player) {
    _cachedCosA = cos(player.angle);
    _cachedSinA = sin(player.angle);
    _cachedScale = screenWidth / 2 / tan(horizontalFovRad / 2);
    _cachedTanPitch = tan(player.pitch);
    _cacheValid = true;
  }

  Offset? worldToScreen(double x, double y, double z, Player player) {
    if (!_cacheValid) {
      updateCache(player);
    }

    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - GraphicsConsts.playerHeight;

    final forward = dx * _cachedCosA + dy * _cachedSinA;

    if (forward <= 0.1) return null;

    final right = -dx * _cachedSinA + dy * _cachedCosA;
    final vertical = dz;

    final screenX = screenWidth / 2 + (right / forward) * _cachedScale;
    final screenY = horizonY -
        (vertical / forward) * _cachedScale +
        _cachedTanPitch * _cachedScale;

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
