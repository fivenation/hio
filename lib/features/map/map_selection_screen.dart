import 'package:flutter/material.dart';
import 'package:hio/features/map/game_screen.dart';
import 'package:hio/graphics/world/models/map_metadata.dart';
import 'package:hio/graphics/world/world_loader.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  List<MapMetadata> _maps = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    try {
      final maps = await WorldLoader.loadMapList();
      setState(() {
        _maps = maps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openMap(MapMetadata map) async {
    try {
      // Показываем лоадер
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final loaded = await WorldLoader.loadMap(map.name);

      // Закрываем лоадер
      Navigator.pop(context);

      // Открываем игровой экран
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              map: loaded.map,
              playerData: loaded.player,
              ambientLight: loaded.ambientLight,
              lightSources: loaded.lightSources,
            ),
          ),
        );
      }
    } catch (e) {
      // Закрываем лоадер если открыт
      Navigator.pop(context);
      
      // Показываем ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки карты: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMaps,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор карты'),
      ),
      body: ListView.builder(
        itemCount: _maps.length,
        itemBuilder: (context, index) {
          final map = _maps[index];
          return ListTile(
            title: Text(map.displayName),
            onTap: () => _openMap(map),
          );
        },
      ),
    );
  }
}