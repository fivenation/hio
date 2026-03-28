enum QualityPreset { low, medium, high }

class GraphicsSettings {
  static const int renderDistance = 64;
  static const double fogStartDistance = 40.0;
  static const double fogEndDistance = 64.0;

  static const double lodHighDistance = 16.0;
  static const double lodMediumDistance = 32.0;
  static const double lodLowDistance = 48.0;
  static const double lodFogDistance = 64.0;

  static void applyPreset(QualityPreset preset) {
    switch (preset) {
      case QualityPreset.low:
        break;
      case QualityPreset.medium:
        break;
      case QualityPreset.high:
        break;
    }
  }
}
