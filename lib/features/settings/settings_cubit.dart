import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hio/features/settings/model/key_bindings_model.dart';
import 'package:hio/features/settings/model/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState.initial());

  void setMouseSensitivity(double value) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        mouseSensitivity: value.clamp(0.002, 0.05),
      ),
    ));
  }

  void setFullscreen(bool value) {
    emit(state.copyWith(
      settings: state.settings.copyWith(fullscreen: value),
    ));
  }

  void setResolutionIndex(int index) {
    emit(state.copyWith(
      settings: state.settings.copyWith(resolutionIndex: index),
    ));
  }

  void setKeyBinding(String actionId, LogicalKeyboardKey key) {
    final newBindings = state.settings.keyBindings.copyWithKey(actionId, key);
    emit(state.copyWith(
      settings: state.settings.copyWith(keyBindings: newBindings),
    ));
  }

  void resetKeyBindings() {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        keyBindings: KeyBindings.defaultBindings(),
      ),
    ));
  }

  void loadSettings() {
    // TODO: загрузка из shared_preferences
    emit(state);
  }

  void saveSettings() {
    // TODO: сохранение в shared_preferences
  }
}
