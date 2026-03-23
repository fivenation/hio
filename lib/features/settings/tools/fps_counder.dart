// Создаём новый файл: lib/graphics/rendering/fps_counter.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class FpsCounter {
  int _frameCount = 0;
  double _lastTime = 0;
  double _currentFps = 0;
  final List<double> _fpsHistory = [];
  final int _historySize = 60; // храним последние 60 кадров

  void update(double currentTime) {
    _frameCount++;
    
    if (currentTime - _lastTime >= 1.0) {
      _currentFps = _frameCount / (currentTime - _lastTime);
      _fpsHistory.add(_currentFps);
      if (_fpsHistory.length > _historySize) {
        _fpsHistory.removeAt(0);
      }
      
      _frameCount = 0;
      _lastTime = currentTime;
    }
  }

  double get fps => _currentFps;
  double get averageFps {
    if (_fpsHistory.isEmpty) return 0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  void render(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FPS: ${_currentFps.toStringAsFixed(1)} (avg: ${averageFps.toStringAsFixed(1)})',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'monospace',
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }
}