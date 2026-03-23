import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:hio/features/settings/model/settings_model.dart';
import 'package:hio/features/settings/model/settings_state.dart';
import 'package:hio/features/settings/settings_content.dart';
import 'package:hio/features/settings/settings_cubit.dart';
import 'package:hio/graphics/graphics.dart';
import 'package:hio/graphics/world/models/lighting.dart';
import 'package:hio/graphics/world/models/player_data.dart';
import 'package:hio/graphics/world/models/world_map.dart';
import 'package:window_manager/window_manager.dart';

class GameScreen extends StatefulWidget {
  final WorldMap map;
  final PlayerData playerData;
  final double ambientLight;
  final List<LightSource> lightSources;

  const GameScreen({
    super.key,
    required this.map,
    required this.playerData,
    required this.ambientLight,
    required this.lightSources,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WindowListener {
  late final AppGraphics _game;
  bool _showMenu = false;
  bool _showSettings = false;
  bool _showAppPausedOverlay = false;
  final FocusNode _focusNode = FocusNode();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWindowManager();

    final settingsCubit = context.read<SettingsCubit>();
    
    // Создаём игру с загруженными данными
    _game = AppGraphics(
      map: widget.map,
      playerData: widget.playerData,
      ambientLight: widget.ambientLight,
      lightSources: widget.lightSources,
      settingsCubit: settingsCubit,
    );

    _game.onInputLocked = () {
      setState(() {
        _showMenu = true;
        _showSettings = false;
        _showAppPausedOverlay = false;
      });
    };

    _game.onInputUnlocked = () {
      setState(() {
        _showMenu = false;
        _showSettings = false;
        _showAppPausedOverlay = false;
      });
    };

    _game.onAppPaused = () {
      setState(() {
        _showAppPausedOverlay = true;
      });
    };

    _game.onAppResumed = () {
      setState(() {
        _showAppPausedOverlay = false;
      });
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _initWindowManager() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    // Устанавливаем минимальный размер окна
    await windowManager.setMinimumSize(const Size(800, 600));

    // Применяем сохранённые настройки
    final settings = context.read<SettingsCubit>().state.settings;
    await _applyResolution(settings.currentResolution);
    if (settings.fullscreen) {
      await windowManager.setFullScreen(true);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    windowManager.removeListener(this);
    _game.unlockInput();
    super.dispose();
  }

  void _toggleMenu() {
    if (_showMenu || _showSettings) {
      _game.unlockInput();
    } else {
      _game.lockInput();
    }
  }

  void _openSettings() {
    setState(() {
      _showSettings = true;
    });
  }

  void _closeSettings() {
    setState(() {
      _showSettings = false;
    });
  }

  void _exitGame() {
    _game.unlockInput();
    Navigator.of(context).pop();
  }

  Future<void> _applyFullscreen(bool fullscreen) async {
    await windowManager.setFullScreen(fullscreen);
  }

  Future<void> _applyResolution(Resolution resolution) async {
    await windowManager.setSize(
        Size(resolution.width.toDouble(), resolution.height.toDouble()));
    await windowManager.center();
  }

  // WindowListener методы
  @override
  void onWindowClose() async {
    // Можно добавить подтверждение выхода
    await windowManager.destroy();
  }

  @override
  void onWindowEnterFullScreen() {
    context.read<SettingsCubit>().setFullscreen(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    context.read<SettingsCubit>().setFullscreen(false);
  }

  @override
  void onWindowResize() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowShow() {}

  @override
  void onWindowHide() {}

  @override
  void onWindowMoved() {}

  @override
  void onWindowResized() {}

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            if (!_game.isAppPaused) {
              _toggleMenu();
            }
          }
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: GameWidget(
                  game: _game,
                ),
              ),
            ),
            if (_showAppPausedOverlay && !_showMenu && !_showSettings)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Приложение свернуто',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Вернитесь в игру для продолжения',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showMenu && !_showSettings && !_showAppPausedOverlay)
              Container(
                color: Colors.black54,
                child: Center(
                  child: AlertDialog(
                    title: const Text('Меню'),
                    content: const Text('Игра приостановлена'),
                    actions: [
                      TextButton(
                        onPressed: () => _toggleMenu(),
                        child: const Text('Продолжить'),
                      ),
                      TextButton(
                        onPressed: _openSettings,
                        child: const Text('Настройки'),
                      ),
                      TextButton(
                        onPressed: _exitGame,
                        child: const Text('Выход'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showSettings && !_showAppPausedOverlay)
              Container(
                color: Colors.black54,
                child: Center(
                  child: AlertDialog(
                    title: const Text('Настройки'),
                    content: SizedBox(
                      width: 350,
                      child: SettingsContent(
                        onClose: _closeSettings,
                        onFullscreenChanged: _applyFullscreen,
                        onResolutionChanged: _applyResolution,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
