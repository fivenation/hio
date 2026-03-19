import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera/player_camera.dart';
import 'rendering/wall_renderer.dart';
import 'ui/crosshair.dart';
import 'ui/minimap.dart';

class AppGraphics extends FlameGame with KeyboardEvents {
  final PlayerCamera playerCamera = PlayerCamera();
  late final WallRenderer wallRenderer;
  late final Crosshair crosshair;
  late final Minimap minimap;

  final Set<LogicalKeyboardKey> _keysPressed = {};

  @override
  Future<void> onLoad() async {
    wallRenderer = WallRenderer(camera: playerCamera);
    crosshair = Crosshair(camera: playerCamera);
    minimap = Minimap(camera: playerCamera);

    await add(wallRenderer);
    await add(minimap);
    await add(crosshair);

    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Убираем проверку на null, так как поле late final
    playerCamera.updateScreenSize(size.x, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    double moveSpeed = 3.0 * dt;
    double rotateSpeed = 2.0 * dt;

    if (_keysPressed.contains(LogicalKeyboardKey.keyQ)) {
      playerCamera.rotate(rotateSpeed);
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyE)) {
      playerCamera.rotate(-rotateSpeed);
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyW)) {
      playerCamera.moveForward(moveSpeed);
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS)) {
      playerCamera.moveBackward(moveSpeed);
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyA)) {
      playerCamera.strafeLeft(moveSpeed);
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD)) {
      playerCamera.strafeRight(moveSpeed);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      _keysPressed.addAll(keysPressed);
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }
    return KeyEventResult.handled;
  }
}
