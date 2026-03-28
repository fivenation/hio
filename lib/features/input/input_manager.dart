import 'package:flutter/services.dart';
import 'package:hio/features/input/mouse_capture/mouse_capture.dart';
import 'package:hio/features/input/mouse_capture/mouse_capture_desktop.dart';

class InputManager {
  final Set<LogicalKeyboardKey> _keysPressed = {};
  double _mouseDeltaX = 0;
  double _mouseDeltaY = 0;
  double _lastMouseX = 0;
  double _lastMouseY = 0;
  bool _hasMousePosition = false;
  late final MouseCaptureService _mouseCapture;

  InputManager() {
    _mouseCapture = MouseCaptureService.create();
  }

  void onKeyDown(LogicalKeyboardKey key) {
    _keysPressed.add(key);
  }

  void onKeyUp(LogicalKeyboardKey key) {
    _keysPressed.remove(key);
  }

  void updateRawDelta() {
    if (!_mouseCapture.isCaptured) return;

    final (dx, dy) = (_mouseCapture as DesktopMouseCapture).getRawDelta();

    const double maxDelta = 50.0;
    _mouseDeltaX = dx.clamp(-maxDelta, maxDelta);
    _mouseDeltaY = dy.clamp(-maxDelta, maxDelta);
  }

  void beginFrame() {
    updateRawDelta();
  }

  bool _isCentering = false; // ← флаг в Dart

  void onMouseMove(double x, double y) {
    if (!_mouseCapture.isCaptured) {
      _mouseDeltaX = 0;
      _mouseDeltaY = 0;
      return;
    }

    // Игнорируем искусственное движение
    if (_isCentering) {
      _lastMouseX = x;
      _lastMouseY = y;
      _mouseDeltaX = 0;
      _mouseDeltaY = 0;
      _isCentering = false;
      return;
    }

    if (_hasMousePosition) {
      double rawDeltaX = x - _lastMouseX;
      double rawDeltaY = y - _lastMouseY;

      // Игнорируем слишком большие дельты (от центрирования)
      const double maxDelta = 100.0;
      if (rawDeltaX.abs() < maxDelta && rawDeltaY.abs() < maxDelta) {
        _mouseDeltaX = rawDeltaX;
        _mouseDeltaY = rawDeltaY;
      } else {
        _mouseDeltaX = 0;
        _mouseDeltaY = 0;
      }
    } else {
      _mouseDeltaX = 0;
      _mouseDeltaY = 0;
      _hasMousePosition = true;
    }

    _lastMouseX = x;
    _lastMouseY = y;

    // Центрируем
    _scheduleCenter();
  }

  void _scheduleCenter() {
    Future.microtask(() async {
      _isCentering = true;
      await _mouseCapture.center();
    });
  }

  Future<void> captureMouse() async {
    await _mouseCapture.capture(null);
  }

  Future<void> releaseMouse() async {
    await _mouseCapture.release();
  }

  bool get isMouseCaptured => _mouseCapture.isCaptured;
  bool isKeyPressed(LogicalKeyboardKey key) => _keysPressed.contains(key);
  double get mouseDeltaX => _mouseDeltaX;
  double get mouseDeltaY => _mouseDeltaY;
}
