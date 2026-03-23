import 'package:flutter/services.dart';
import 'package:hio/features/input/user_action.dart';
import 'package:hio/features/settings/model/key_bindings_model.dart';
import 'package:hio/graphics/entities/player.dart';
import 'input_manager.dart';
import '../settings/settings_cubit.dart';

class GameControls {
  final InputManager _input;
  final Player _player;
  final SettingsCubit _settingsCubit;

  double get _sensitivity => _settingsCubit.state.settings.mouseSensitivity;
  KeyBindings get _bindings => _settingsCubit.state.settings.keyBindings;

  GameControls({
    required InputManager input,
    required Player player,
    required SettingsCubit settingsCubit,
  })  : _input = input,
        _player = player,
        _settingsCubit = settingsCubit;

  void update(double dt) {
    _handleContinuousActions();
    _handleMouseLook();
  }

  void _handleContinuousActions() {
    // Движение
    _player.setMoveForward(_isKeyPressed(_bindings.moveForward));
    _player.setMoveBackward(_isKeyPressed(_bindings.moveBackward));
    _player.setStrafeLeft(_isKeyPressed(_bindings.strafeLeft));
    _player.setStrafeRight(_isKeyPressed(_bindings.strafeRight));

    // Поворот от клавиш
    double rotateDelta = 0.0;
    if (_isKeyPressed(_bindings.rotateLeft)) rotateDelta += 1.0;
    if (_isKeyPressed(_bindings.rotateRight)) rotateDelta -= 1.0;
    _player.setRotate(rotateDelta);

    // Вертикальный обзор от клавиш
    double pitchDelta = 0.0;
    if (_isKeyPressed(_bindings.lookUp)) pitchDelta += 1.0;
    if (_isKeyPressed(_bindings.lookDown)) pitchDelta -= 1.0;
    _player.setPitch(pitchDelta);
  }

  void _handleMouseLook() {
    final mouseDelta = _input.mouseDeltaX;
    if (mouseDelta != 0) {
      _player.setRotate(mouseDelta * _sensitivity);
    }

    final mousePitchDelta = _input.mouseDeltaY;
    if (mousePitchDelta != 0) {
      _player.setPitch(-mousePitchDelta * _sensitivity);
    }
  }

  bool _isKeyPressed(LogicalKeyboardKey key) {
    return _input.isKeyPressed(key);
  }

  /// Проверяет, было ли действие только что нажато (для дискретных действий)
  bool isActionJustPressed(UserAction action) {
    switch (action) {
      case UserAction.openMenu:
        return _isKeyJustPressed(_bindings.openMenu);
      case UserAction.interact:
        return _isKeyJustPressed(_bindings.interact);
      default:
        return false;
    }
  }

  bool _isKeyJustPressed(LogicalKeyboardKey key) {
    // TODO: реализовать отслеживание момента нажатия
    return false;
  }

  /// Получить текущие привязки клавиш
  KeyBindings getKeyBindings() => _bindings;

  /// Установить привязку клавиши
  void setKeyBinding(String actionId, LogicalKeyboardKey key) {
    _settingsCubit.setKeyBinding(actionId, key);
  }

  /// Сбросить привязки клавиш
  void resetKeyBindings() {
    _settingsCubit.resetKeyBindings();
  }
}
