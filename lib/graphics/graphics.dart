import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hio/features/settings/settings_cubit.dart';
import '../features/input/game_controls.dart';
import '../features/input/input_manager.dart';
import '../graphics/entities/player.dart';
import '../graphics/world/game_world.dart';
import '../graphics/world/test_map_generator.dart';
import '../graphics/rendering/camera.dart';
import '../graphics/rendering/world_renderer.dart';
import '../graphics/block/block_registry.dart';
import '../graphics/rendering/texture_atlas.dart';
import '../graphics/rendering/minimap.dart';

/// Главный игровой виджет Flame.
class AppGraphics extends FlameGame
    with KeyboardEvents, MouseMovementDetector, WidgetsBindingObserver {
  late final GameWorld _world;
  late final InputManager _inputManager;
  late final GameControls _gameControls;
  late final ProjectionCamera _camera = ProjectionCamera(
    screenWidth: size.x,
    screenHeight: size.y,
  );
  late final WorldRenderer _worldRenderer;
  late final Minimap _minimap;
  late final SettingsCubit _settingsCubit;

  bool _isInputLocked = false; // Ручная блокировка (меню, инвентарь)
  bool _isAppPaused = false; // Автоматическая пауза при потере фокуса

  // Колбэки для внешнего UI
  VoidCallback? onInputLocked;
  VoidCallback? onInputUnlocked;
  VoidCallback? onAppPaused;
  VoidCallback? onAppResumed;

  AppGraphics({required SettingsCubit settingsCubit}) {
    _settingsCubit = settingsCubit;
  }

  @override
  Future<void> onLoad() async {
    // Регистрируем блоки
    final registry = BlockRegistry.instance;
    registry.registerDefaultBlocks();

    // Загружаем текстуры
    final textureManager = TextureAtlasManager.instance;
    textureManager.setTextureSize(64);
    await textureManager.loadAtlas(0);

    // Создаём карту
    final map = TestMapGenerator.generateRoomMap();
    final player = Player(x: 35, y: 35, angle: 3.14);
    _world = GameWorld(map: map, player: player);

    // Система ввода
    _inputManager = InputManager();
    _gameControls = GameControls(
      input: _inputManager,
      player: _world.player,
      settingsCubit: _settingsCubit,
    );

    // Рендерер
    _worldRenderer = WorldRenderer(
      camera: _camera,
      map: _world.map,
      renderDistance: 64,
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
    // Отписываемся при удалении
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    print('Game resized: ${size.x}x${size.y}');
    _camera.resize(size.x, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

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
        // Приложение вернулось на передний план
        _isAppPaused = false;
        onAppResumed?.call();
        // Если управление не заблокировано вручную, восстанавливаем захват мыши
        if (!_isInputLocked) {
          _inputManager.captureMouse();
        }
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Приложение ушло в фон или потеряло фокус
        _isAppPaused = true;
        onAppPaused?.call();
        // Всегда освобождаем мышь при потере фокуса
        _inputManager.releaseMouse();
        break;

      default:
        break;
    }
  }

  // --- Управление режимом блокировки ---

  /// Заблокировать управление (открыть меню, инвентарь)
  void lockInput() {
    if (_isInputLocked) return;
    _isInputLocked = true;
    _inputManager.releaseMouse();
    onInputLocked?.call();
  }

  /// Разблокировать управление (закрыть меню, инвентарь)
  void unlockInput() {
    if (!_isInputLocked) return;
    _isInputLocked = false;
    // Если приложение активно, захватываем мышь
    if (!_isAppPaused) {
      _inputManager.captureMouse();
    }
    onInputUnlocked?.call();
  }

  /// Переключить блокировку управления
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

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {}

    return KeyEventResult.handled;
  }
}
