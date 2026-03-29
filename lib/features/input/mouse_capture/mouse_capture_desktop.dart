import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'mouse_capture.dart';

class DesktopMouseCapture implements MouseCaptureService {
  bool _isCaptured = false;
  late final DynamicLibrary _native;
  late final void Function(Pointer<Double>, Pointer<Double>) _getMouseDelta;
  late final void Function() _resetMouseDelta;

  DesktopMouseCapture() {
    if (Platform.isWindows) {
      _native = DynamicLibrary.process();

      final getDelta = _native.lookupFunction<
          Void Function(Pointer<Double>, Pointer<Double>),
          void Function(Pointer<Double>, Pointer<Double>)>('GetMouseDelta');
      _getMouseDelta = getDelta;

      final resetDelta = _native
          .lookupFunction<Void Function(), void Function()>('ResetMouseDelta');
      _resetMouseDelta = resetDelta;
    }
  }

  (double dx, double dy) getRawDelta() {
    if (!Platform.isWindows) return (0, 0);
    final dxPtr = calloc<Double>();
    final dyPtr = calloc<Double>();
    _getMouseDelta(dxPtr, dyPtr);
    final dx = dxPtr.value;
    final dy = dyPtr.value;
    calloc.free(dxPtr);
    calloc.free(dyPtr);

    _resetMouseDelta();

    return (dx, dy);
  }

  @override
  Future<void> capture(dynamic target) async {
    if (!Platform.isWindows) return;
    final captureFunc = _native
        .lookupFunction<Void Function(), void Function()>('CaptureMouse');
    captureFunc();
    _isCaptured = true;
  }

  @override
  Future<void> release() async {
    if (!Platform.isWindows) return;
    final releaseFunc = _native
        .lookupFunction<Void Function(), void Function()>('ReleaseMouse');
    releaseFunc();
    _isCaptured = false;
  }

  @override
  Future<void> center() async {
    if (!Platform.isWindows) return;
    try {
      final centerFunc = _native
          .lookupFunction<Void Function(), void Function()>('CenterMouse');
      centerFunc();
    } catch (e) {
      if (kDebugMode) {
        print('Center failed: $e');
      }
    }
  }

  @override
  bool get isCaptured => _isCaptured;
}
