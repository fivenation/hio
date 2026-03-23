import 'dart:math';

/// Источник света.
class LightSource {
  /// Позиция источника (X, Y, Z)
  final double x;
  final double y;
  final double z;
  
  /// Радиус действия (метры)
  final double radius;
  
  /// Интенсивность (0.0 - 1.0)
  final double intensity;
  
  const LightSource({
    required this.x,
    required this.y,
    required this.z,
    required this.radius,
    required this.intensity,
  });
  
  /// Вычисляет вклад источника в точке.
  double contributeAt(double px, double py, double pz) {
    final dx = px - x;
    final dy = py - y;
    final dz = pz - z;
    final distance = sqrt(dx * dx + dy * dy + dz * dz);
    
    if (distance >= radius) return 0.0;
    
    // Линейное затухание
    final falloff = 1.0 - (distance / radius);
    return intensity * falloff;
  }
}

/// Система освещения.
class LightingSystem {
  /// Глобальная яркость (0.0 - 1.0)
  double ambientLight;
  
  /// Список динамических источников света
  final List<LightSource> sources;
  
  LightingSystem({
    this.ambientLight = 1.0,
    this.sources = const [],
  });
  
  /// Рассчитывает итоговую яркость в точке.
  double calculateLight(double x, double y, double z) {
    double total = ambientLight;
    
    for (final source in sources) {
      total += source.contributeAt(x, y, z);
    }
    
    // Ограничиваем значение
    if (total > 1.0) total = 1.0;
    if (total < 0.0) total = 0.0;
    
    return total;
  }
  
  /// Добавляет источник света.
  void addSource(LightSource source) {
    sources.add(source);
  }
  
  /// Удаляет все источники.
  void clearSources() {
    sources.clear();
  }
}