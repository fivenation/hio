class GraphicsConsts {
  // Диапазон высот блоков
  static const int zMin = -3;
  static const int zMax = 4;
  static const int zLevels = zMax - zMin + 1; // 8

  // Параметры игрока
  static const double playerHeight = 1.5;
  static const double defaultPlayerPitch = 0.0;
  static const double playerRadius = 0.45;
  static const double playerSpeed = 5.0;
  static const double playerRotationSpeed = 2.0;
  static const double playerPitchSpeed = 1.5;

  // Рендеринг
  static const double fogStartDistance = 40.0;
  static const double fogEndDistance = 64.0;
  static const double defaultRenderDistance = 64.0;
  static const double defaultVerticalFov = 60.0;
  static const double cameraDepth = 0.0;

  // Коллизии
  static const int collisionCheckZ = 0;
}
