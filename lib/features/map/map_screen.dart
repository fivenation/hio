import 'package:flutter/material.dart';
import 'package:hio/features/map/game_screen.dart';
import 'package:hio/graphics/world/models/map_metadata.dart';
import 'package:hio/graphics/world/world_loader.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
    // Показываем лоадер
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final loaded = await WorldLoader.loadMap(map.name);

      // Закрываем лоадер
      if (mounted) {
        Navigator.pop(context);
      }

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
      // Закрываем лоадер
      if (mounted) {
        Navigator.pop(context);
      }

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

    if (_maps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Выбор карты'),
        ),
        body: const Center(
          child: Text('Нет доступных карт'),
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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: map.previewImage != null
                  ? Image.asset(
                      'resources/maps/${map.previewImage}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.map),
                    )
                  : const Icon(Icons.map, size: 40),
              title: Text(
                map.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _openMap(map),
            ),
          );
        },
      ),
    );
  }
}