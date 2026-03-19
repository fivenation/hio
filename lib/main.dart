import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hio/core/application/application.dart';

void main() {
  Flame.assets = AssetsCache(prefix: 'resources/');
  Flame.images = Images(prefix: 'resources/images/');
  
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setApplicationSwitcherDescription(
    const ApplicationSwitcherDescription(
      label: 'Hio',
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const RunApplication());
}
