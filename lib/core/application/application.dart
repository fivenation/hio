import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hio/core/application/app_dependencies.dart';
import 'package:hio/features/menu/menu_screen.dart';
import 'package:hio/graphics/graphics.dart';

class RunApplication extends StatelessWidget {
  const RunApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      child: MaterialApp(
        title: 'Hio',
        theme: ThemeData.dark(),
        home: const MenuScreen(),
      ),
    );
  }
}