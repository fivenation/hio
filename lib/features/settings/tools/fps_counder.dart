// features/settings/fps_counter/fps_counter.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class FpsCounter {
  int _frameCount = 0;
  double _lastTime = 0;
  double _currentFps = 0;
  final List<double> _fpsHistory = [];
  final int _historySize = 60;

  // Дополнительные метрики
  int _currentFacesCount = 0;
  int _currentShaderCacheSize = 0;
  int _currentColumnCacheSize = 0;
  double _currentFrameTime = 0;
  int _lastTimestamp = 0;
  final List<double> _frameTimeHistory = [];

  // Геттеры для внешнего доступа (если нужны)
  int get currentFacesCount => _currentFacesCount;
  int get currentShaderCacheSize => _currentShaderCacheSize;
  int get currentColumnCacheSize => _currentColumnCacheSize;
  double get currentFrameTime => _currentFrameTime;

  void update(double currentTime) {
    _frameCount++;

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (_lastTimestamp != 0) {
      _currentFrameTime = (now - _lastTimestamp) / 1000.0;
      _frameTimeHistory.add(_currentFrameTime);
      if (_frameTimeHistory.length > _historySize) {
        _frameTimeHistory.removeAt(0);
      }
    }
    _lastTimestamp = now;

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

  void updateMetrics({
    required int facesCount,
    required int shaderCacheSize,
    required int columnCacheSize,
  }) {
    _currentFacesCount = facesCount;
    _currentShaderCacheSize = shaderCacheSize;
    _currentColumnCacheSize = columnCacheSize;
  }

  double get averageFps {
    if (_fpsHistory.isEmpty) return 0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  double get averageFrameTime {
    if (_frameTimeHistory.isEmpty) return 0;
    return _frameTimeHistory.reduce((a, b) => a + b) / _frameTimeHistory.length;
  }

  void render(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final bgRect = Rect.fromLTWH(0, 0, 280, 110);
    canvas.drawRect(bgRect, paint);

    double y = 10;

    // FPS
    final fpsColor = _currentFps < 30 ? Colors.red : Colors.white;
    _drawText(
        canvas,
        'FPS: ${_currentFps.toStringAsFixed(1)} (avg: ${averageFps.toStringAsFixed(1)})',
        Offset(10, y),
        fpsColor);
    y += 18;

    // Время кадра
    final frameTimeColor =
        _currentFrameTime > 0.033 ? Colors.orange : Colors.white;
    _drawText(
        canvas,
        'Frame: ${(_currentFrameTime * 1000).toStringAsFixed(1)}ms (avg: ${(averageFrameTime * 1000).toStringAsFixed(1)}ms)',
        Offset(10, y),
        frameTimeColor);
    y += 18;

    // Грани
    final facesColor = _currentFacesCount > 10000
        ? Colors.red
        : (_currentFacesCount > 5000 ? Colors.orange : Colors.white);
    _drawText(canvas, 'Faces: $_currentFacesCount', Offset(10, y), facesColor);
    y += 18;

    // Кэши
    _drawText(
        canvas,
        'Shader: $_currentShaderCacheSize | Column: $_currentColumnCacheSize',
        Offset(10, y),
        Colors.cyan);
    y += 18;

    // Предупреждения
    if (_currentFps < 30) {
      _drawText(canvas, '⚠️ LOW FPS!', Offset(10, y), Colors.red);
      y += 18;
    }

    if (_currentFacesCount > 15000) {
      _drawText(canvas, '⚠️ TOO MANY FACES!', Offset(10, y), Colors.red);
      y += 18;
    }

    if (_currentShaderCacheSize > 500) {
      _drawText(
          canvas, '⚠️ SHADER CACHE GROWING!', Offset(10, y), Colors.orange);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}
