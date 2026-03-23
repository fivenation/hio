/// DTO для загрузки данных игрока из JSON карты
class PlayerData {
  final double x;
  final double y;
  final double angle;

  const PlayerData({
    required this.x,
    required this.y,
    required this.angle,
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      angle: (json['angle'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'angle': angle,
    };
  }
}
