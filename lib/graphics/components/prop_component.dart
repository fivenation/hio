import 'dart:ui';
import 'package:flame/components.dart';
import 'package:hio/core/resources/resource_manager.dart';
import '../../core/resources/paths.dart';

class PropComponent extends PositionComponent {
  final ResourcesManager resourcesManager;
  final int objectId;
  final double globalRotation;

  static const int PROJECTIONS = 12;
  static const double ANGLE_STEP = 30.0;

  late Map<String, dynamic> _data;
  late Image _spriteSheet;
  late double _frameSize;
  late List<double> _size3d;

  PropComponent({
    required this.resourcesManager,
    required this.objectId,
    required Vector2 pixelPosition,
    required this.globalRotation,
  }) : super(position: pixelPosition);

  @override
  Future<void> onLoad() async {
    print('📦 Загружаю сундук...');

    _data = await resourcesManager.loadJson(Paths.objectJson(objectId));
    _spriteSheet = await resourcesManager.loadImage(_data['spritesheet']);

    _frameSize = (_data['frame_size'] as num).toDouble();
    _size3d =
        (_data['size_3d'] as List).map((e) => (e as num).toDouble()).toList();

    print('✅ Сундук загружен');
  }

  int _getFrameIndex(double relativeAngle) {
    return ((relativeAngle + ANGLE_STEP / 2) % 360 / ANGLE_STEP).floor();
  }

  @override
  void render(Canvas canvas) {
    double globalCameraAngle = 0;
    double localAngle = (globalCameraAngle - globalRotation) % 360;

    int frameIndex = _getFrameIndex(localAngle);

    Rect sourceRect = Rect.fromLTWH(
      frameIndex * _frameSize,
      0,
      _frameSize,
      _frameSize,
    );

    canvas.drawImageRect(
      _spriteSheet,
      sourceRect,
      Rect.fromLTWH(
        position.x - _frameSize / 2,
        position.y - _frameSize / 2,
        _frameSize,
        _frameSize,
      ),
      Paint(),
    );

    // Красная точка для отладки центра
    canvas.drawCircle(
      Offset(position.x, position.y),
      5,
      Paint()..color = const Color(0xFFFF0000),
    );
  }
}
