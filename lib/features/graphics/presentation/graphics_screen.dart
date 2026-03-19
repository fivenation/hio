import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:hio/core/resources/resource_manager.dart';
import 'package:hio/graphics/graphics.dart';
import 'package:provider/provider.dart';

class GraphicsScreen extends StatefulWidget {
  final String mapId;

  const GraphicsScreen({required this.mapId, super.key});

  @override
  State<GraphicsScreen> createState() => _GraphicsScreenState();
}

class _GraphicsScreenState extends State<GraphicsScreen> {
  late final AppGraphics _graphics;

  @override
  void initState() {
    super.initState();

    final resourcesManager =
        Provider.of<ResourcesManager>(context, listen: false);

    _graphics = AppGraphics(
        //mapId: widget.mapId,
        //resourcesManager: resourcesManager,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Фиксированное соотношение сторон 16:9 (1920x1080)
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: GameWidget(
              game: _graphics,
            ),
          ),
        ),
      ),
    );
  }
}
