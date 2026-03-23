import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hio/features/settings/model/settings_state.dart';
import '../settings/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _waitingForAction;
  final FocusNode _focusNode = FocusNode();
  late final HardwareKeyboard _hardwareKeyboard;

  @override
  void initState() {
    super.initState();
    _hardwareKeyboard = HardwareKeyboard.instance;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startListeningForKeys(String actionId) {
    setState(() {
      _waitingForAction = actionId;
    });
    _focusNode.requestFocus();
  }

  void _stopListening() {
    setState(() {
      _waitingForAction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settingsCubit.resetKeyBindings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Привязки клавиш сброшены')),
              );
            },
            child: const Text('Сбросить клавиши'),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (_waitingForAction != null && event is KeyDownEvent) {
              final key = event.logicalKey;
              
              if (key == LogicalKeyboardKey.escape) {
                _stopListening();
              } else {
                final actionId = _waitingForAction!;
                _stopListening();
                settingsCubit.setKeyBinding(actionId, key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Клавиша ${_keyToString(key)} назначена')),
                );
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final settings = state.settings;
              
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Чувствительность мыши
                  const Text('Чувствительность мыши', style: TextStyle(fontSize: 16)),
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
                  const SizedBox(height: 20),

                  // Полноэкранный режим
                  Row(
                    children: [
                      const Text('Полноэкранный режим', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: settings.fullscreen,
                        onChanged: (value) {
                          settingsCubit.setFullscreen(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Разрешение экрана
                  const Text('Разрешение экрана', style: TextStyle(fontSize: 16)),
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
                    onChanged: (value) {
                      if (value != null) {
                        settingsCubit.setResolutionIndex(value);
                      }
                    },
                  ),
                  const SizedBox(height: 30),

                  // Привязка клавиш
                  const Text('Управление', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...settings.keyBindings.allBindings.map((binding) {
                    final isWaiting = _waitingForAction == binding.actionId;
                    
                    return ListTile(
                      title: Text(binding.name),
                      trailing: isWaiting
                          ? const SizedBox(
                              width: 120,
                              child: Text('Нажми клавишу...', style: TextStyle(color: Colors.orange)),
                            )
                          : SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: () {
                                  _startListeningForKeys(binding.actionId);
                                },
                                child: Text(_keyToString(binding.key)),
                              ),
                            ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),

                  // Сохранить
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        settingsCubit.saveSettings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Настройки сохранены')),
                        );
                      },
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _keyToString(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyW) return 'W';
    if (key == LogicalKeyboardKey.keyA) return 'A';
    if (key == LogicalKeyboardKey.keyS) return 'S';
    if (key == LogicalKeyboardKey.keyD) return 'D';
    if (key == LogicalKeyboardKey.keyQ) return 'Q';
    if (key == LogicalKeyboardKey.keyE) return 'E';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.escape) return 'ESC';
    if (key == LogicalKeyboardKey.space) return 'Пробел';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.keyR) return 'R';
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.keyX) return 'X';
    if (key == LogicalKeyboardKey.keyC) return 'C';
    if (key == LogicalKeyboardKey.keyV) return 'V';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.shift) return 'Shift';
    if (key == LogicalKeyboardKey.control) return 'Ctrl';
    if (key == LogicalKeyboardKey.alt) return 'Alt';
    return key.keyLabel.isNotEmpty ? key.keyLabel.toUpperCase() : '?';
  }
}