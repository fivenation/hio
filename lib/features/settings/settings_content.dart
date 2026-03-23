import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hio/features/settings/model/settings_model.dart';
import 'package:hio/features/settings/model/settings_state.dart';
import 'package:hio/features/settings/settings_cubit.dart';

class SettingsContent extends StatelessWidget {
  final VoidCallback onClose;
  final Future<void> Function(bool) onFullscreenChanged;
  final Future<void> Function(Resolution) onResolutionChanged;

  const SettingsContent({
    super.key,
    required this.onClose,
    required this.onFullscreenChanged,
    required this.onResolutionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Чувствительность мыши', style: TextStyle(fontSize: 14)),
            Slider(
              value: settings.mouseSensitivity,
              min: 0.002,
              max: 0.05,
              divisions: 48,
              label: (settings.mouseSensitivity * 1000).toStringAsFixed(0),
              onChanged: (value) {
                settingsCubit.setMouseSensitivity(value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Полноэкранный режим',
                    style: TextStyle(fontSize: 14)),
                const Spacer(),
                Switch(
                  value: settings.fullscreen,
                  onChanged: (value) async {
                    settingsCubit.setFullscreen(value);
                    await onFullscreenChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Разрешение экрана', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: settings.resolutionIndex,
              isExpanded: true,
              items: settings.resolutions.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value.name),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  settingsCubit.setResolutionIndex(value);
                  await onResolutionChanged(settings.resolutions[value]);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onClose,
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
