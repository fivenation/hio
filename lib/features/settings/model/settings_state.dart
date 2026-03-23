import 'package:freezed_annotation/freezed_annotation.dart';
import 'settings_model.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required SettingsModel settings,
    @Default(true) bool isLoaded,
  }) = _SettingsState;

  const SettingsState._();

  /// Фабричный метод с настройками по умолчанию
  factory SettingsState.initial() {
    return SettingsState(
      settings: SettingsModel.defaultSettings(),
    );
  }
}