import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hio/features/settings/settings_cubit.dart';
import 'package:hio/features/settings/tools/fps_counder.dart';
import 'package:hio/features/input/game_controls.dart';
import 'package:hio/features/input/input_manager.dart';
import 'package:hio/graphics/blocks/block_registry.dart';
import 'package:hio/graphics/core/camera.dart';
import 'package:hio/graphics/entities/player.dart';
import 'package:hio/graphics/rendering/blocks/world_renderer.dart';
import 'package:hio/graphics/rendering/minimap.dart';
import 'package:hio/graphics/world/game_world.dart';
import 'package:hio/graphics/rendering/textures/texture_atlas.dart';
import 'package:hio/graphics/world/models/lighting.dart';
import 'package:hio/graphics/world/models/player_data.dart';
import 'package:hio/graphics/core/constants.dart';
import 'package:hio/graphics/world/models/world_map.dart';

/// Главный игровой виджет Flame.
class AppGraphics extends FlameGame
    with KeyboardEvents, MouseMovementDetector, WidgetsBindingObserver {
  late final GameWorld _world;
  late final InputManager _inputManager;
  late final GameControls _gameControls;
  late final WorldRenderer _worldRenderer;
  late final Minimap _minimap;
  late final FpsCounter _fpsCounter;
  late final SettingsCubit _settingsCubit;

  // Important!
  late final ProjectionCamera _camera = ProjectionCamera(
    screenWidth: size.x,
    screenHeight: size.y,
  );

  // Загруженные данные
  final WorldMap _map;
  final PlayerData _playerData;
  final double _ambientLight;
  final List<LightSource> _lightSources;

  bool _isInputLocked = false;
  bool _isAppPaused = false;

  // Колбэки для внешнего UI
  VoidCallback? onInputLocked;
  VoidCallback? onInputUnlocked;
  VoidCallback? onAppPaused;
  VoidCallback? onAppResumed;

  AppGraphics({
    required WorldMap map,
    required PlayerData playerData,
    required double ambientLight,
    required List<LightSource> lightSources,
    required SettingsCubit settingsCubit,
  })  : _map = map,
        _playerData = playerData,
        _ambientLight = ambientLight,
        _lightSources = lightSources,
        _settingsCubit = settingsCubit;

  @override
  Future<void> onLoad() async {
    // Регистрируем блоки (пока хардкод, позже из JSON)
    final registry = BlockRegistry.instance;
    registry.registerDefaultBlocks();

    // Загружаем текстуры
    final textureManager = TextureAtlasManager.instance;
    textureManager.setTextureSize(64);
    await textureManager.loadAtlas(0);

    // Создаём игрока из загруженных данных
    final player = Player(
      x: _playerData.x,
      y: _playerData.y,
      angle: _playerData.angle,
      pitch: GraphicsConsts.defaultPlayerPitch,
    );

    // Создаём мир
    _world = GameWorld(
      map: _map,
      player: player,
      ambientLight: _ambientLight,
      lightSources: _lightSources,
    );

    // Система ввода
    _inputManager = InputManager();
    _gameControls = GameControls(
      input: _inputManager,
      player: _world.player,
      settingsCubit: _settingsCubit,
    );

    _fpsCounter = FpsCounter();

    // Рендерер
    _worldRenderer = WorldRenderer(
      camera: _camera,
      map: _world.map,
    );
    _minimap = Minimap();

    // Захватываем мышь
    await _inputManager.captureMouse();

    // Подписываемся на события приложения
    WidgetsBinding.instance.addObserver(this);

    return super.onLoad();
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _camera.resize(size.x, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _fpsCounter.update(DateTime.now().millisecondsSinceEpoch / 1000);

    // Обновляем только если управление не заблокировано И приложение активно
    if (!_isInputLocked && !_isAppPaused) {
      _gameControls.update(dt);
      _world.update(dt);
    }

    _inputManager.beginFrame();
  }

  @override
  void render(Canvas canvas) {
    _drawSky(canvas);
    _worldRenderer.render(canvas, _world);

    // Мини-карта
    canvas.save();
    canvas.translate(size.x - 210, 10);
    _minimap.render(canvas, _world);
    canvas.restore();

    _fpsCounter.render(canvas, Size(size.x, size.y));

    super.render(canvas);
  }

  void _drawSky(Canvas canvas) {
    final skyPaint = Paint()..color = const Color(0xFF87CEEB);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      skyPaint,
    );
  }

  // --- Обработка фокуса приложения ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppPaused = false;
        onAppResumed?.call();
        if (!_isInputLocked) {
          _inputManager.captureMouse();
        }
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppPaused = true;
        onAppPaused?.call();
        _inputManager.releaseMouse();
        break;

      default:
        break;
    }
  }

  // --- Управление режимом блокировки ---

  void lockInput() {
    if (_isInputLocked) return;
    _isInputLocked = true;
    _inputManager.releaseMouse();
    onInputLocked?.call();
  }

  void unlockInput() {
    if (!_isInputLocked) return;
    _isInputLocked = false;
    if (!_isAppPaused) {
      _inputManager.captureMouse();
    }
    onInputUnlocked?.call();
  }

  void toggleInputLock() {
    if (_isInputLocked) {
      unlockInput();
    } else {
      lockInput();
    }
  }

  bool get isInputLocked => _isInputLocked;
  bool get isAppPaused => _isAppPaused;
  bool get isGameActive => !_isInputLocked && !_isAppPaused;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      _inputManager.onKeyDown(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _inputManager.onKeyUp(event.logicalKey);
    }
    return KeyEventResult.handled;
  }
}
