import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_bindings_model.freezed.dart';

@freezed
class KeyBindings with _$KeyBindings {
  const factory KeyBindings({
    required LogicalKeyboardKey moveForward,
    required LogicalKeyboardKey moveBackward,
    required LogicalKeyboardKey strafeLeft,
    required LogicalKeyboardKey strafeRight,
    required LogicalKeyboardKey rotateLeft,
    required LogicalKeyboardKey rotateRight,
    required LogicalKeyboardKey lookUp,
    required LogicalKeyboardKey lookDown,
    required LogicalKeyboardKey openMenu,
    required LogicalKeyboardKey interact,
  }) = _KeyBindings;

  const KeyBindings._();

  /// Фабричный метод с значениями по умолчанию
  factory KeyBindings.defaultBindings() {
    return const KeyBindings(
      moveForward: LogicalKeyboardKey.keyW,
      moveBackward: LogicalKeyboardKey.keyS,
      strafeLeft: LogicalKeyboardKey.keyA,
      strafeRight: LogicalKeyboardKey.keyD,
      rotateLeft: LogicalKeyboardKey.keyQ,
      rotateRight: LogicalKeyboardKey.keyE,
      lookUp: LogicalKeyboardKey.arrowUp,
      lookDown: LogicalKeyboardKey.arrowDown,
      openMenu: LogicalKeyboardKey.escape,
      interact: LogicalKeyboardKey.keyE,
    );
  }

  /// Возвращает список всех действий
  List<({String name, LogicalKeyboardKey key, String actionId})> get allBindings {
    return [
      (name: 'Движение вперёд', key: moveForward, actionId: 'moveForward'),
      (name: 'Движение назад', key: moveBackward, actionId: 'moveBackward'),
      (name: 'Стрейф влево', key: strafeLeft, actionId: 'strafeLeft'),
      (name: 'Стрейф вправо', key: strafeRight, actionId: 'strafeRight'),
      (name: 'Поворот влево', key: rotateLeft, actionId: 'rotateLeft'),
      (name: 'Поворот вправо', key: rotateRight, actionId: 'rotateRight'),
      (name: 'Взгляд вверх', key: lookUp, actionId: 'lookUp'),
      (name: 'Взгляд вниз', key: lookDown, actionId: 'lookDown'),
      (name: 'Меню', key: openMenu, actionId: 'openMenu'),
      (name: 'Взаимодействие', key: interact, actionId: 'interact'),
    ];
  }

  KeyBindings copyWithKey(String actionId, LogicalKeyboardKey newKey) {
    switch (actionId) {
      case 'moveForward':
        return copyWith(moveForward: newKey);
      case 'moveBackward':
        return copyWith(moveBackward: newKey);
      case 'strafeLeft':
        return copyWith(strafeLeft: newKey);
      case 'strafeRight':
        return copyWith(strafeRight: newKey);
      case 'rotateLeft':
        return copyWith(rotateLeft: newKey);
      case 'rotateRight':
        return copyWith(rotateRight: newKey);
      case 'lookUp':
        return copyWith(lookUp: newKey);
      case 'lookDown':
        return copyWith(lookDown: newKey);
      case 'openMenu':
        return copyWith(openMenu: newKey);
      case 'interact':
        return copyWith(interact: newKey);
      default:
        return this;
    }
  }
}