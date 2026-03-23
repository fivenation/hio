import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'mouse_capture_desktop.dart';

abstract class MouseCaptureService {
  Future<void> capture(dynamic target);
  Future<void> release();
  Future<void> center();
  bool get isCaptured;
  
  /// Фабричный метод для создания сервиса в зависимости от платформы
  static MouseCaptureService create() {
    if (kIsWeb) {
      return WebMouseCapture();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return DesktopMouseCapture();
    } else {
      return MobileMouseCapture();
    }
  }
}

class WebMouseCapture implements MouseCaptureService {
  bool _isCaptured = false;
  @override Future<void> capture(dynamic target) async => _isCaptured = true;
  @override Future<void> release() async => _isCaptured = false;
  @override Future<void> center() async {}
  @override bool get isCaptured => _isCaptured;
}

class MobileMouseCapture implements MouseCaptureService {
  bool _isCaptured = false;
  @override Future<void> capture(dynamic target) async => _isCaptured = true;
  @override Future<void> release() async => _isCaptured = false;
  @override Future<void> center() async {}
  @override bool get isCaptured => _isCaptured;
}