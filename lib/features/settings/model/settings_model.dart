import 'package:freezed_annotation/freezed_annotation.dart';
import 'key_bindings_model.dart';

part 'settings_model.freezed.dart';

class Resolution {
  final int width;
  final int height;
  final String name;

  const Resolution(this.width, this.height, this.name);
}

@freezed
class SettingsModel with _$SettingsModel {
  const factory SettingsModel({
    required double mouseSensitivity,
    required bool fullscreen,
    required int resolutionIndex,
    required KeyBindings keyBindings,
    required List<Resolution> resolutions,
  }) = _SettingsModel;

  const SettingsModel._();

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      mouseSensitivity: 0.008,
      fullscreen: false,
      resolutionIndex: 5,
      keyBindings: KeyBindings.defaultBindings(),
      resolutions: const [
        Resolution(800, 600, '800x600'),
        Resolution(1024, 768, '1024x768'),
        Resolution(1280, 720, '1280x720 (HD)'),
        Resolution(1366, 768, '1366x768'),
        Resolution(1600, 900, '1600x900'),
        Resolution(1920, 1080, '1920x1080 (Full HD)'),
        Resolution(2560, 1440, '2560x1440 (2K)'),
        Resolution(3840, 2160, '3840x2160 (4K)'),
      ],
    );
  }

  Resolution get currentResolution => resolutions[resolutionIndex];
}