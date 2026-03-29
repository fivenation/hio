// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

/// Утилита для сборки текстур в атласы
/// 
/// Вход: папка с текстурами (raw)
/// Выход: 3 атласа:
///   - atlas_32.png (512x512, сетка 16x16 текстур 32x32)
///   - atlas_64.png (1024x1024, сетка 16x16 текстур 64x64)
///   - atlas_128.png (2048x2048, сетка 16x16 текстур 128x128)
/// 
/// Использование:
/// dart tools/texture_atlas_builder.dart
class TextureAtlasBuilder {
  final String inputDir;
  final String outputDir;
  
  // Константы
  static const int gridSize = 16;        // 16x16 сетка
  static const int maxTextures = 256;    // 16 * 16 = 256 текстур максимум
  
  // Размеры тайлов и атласов
  static const List<int> tileSizes = [32, 64, 128];
  
  TextureAtlasBuilder({
    required this.inputDir,
    required this.outputDir,
  });

  /// Сканирует текстуры в папке и сортирует по имени
  Future<List<File>> scanTextures() async {
    final dir = Directory(inputDir);
    if (!await dir.exists()) {
      print('❌ Папка не найдена: $inputDir');
      print('📁 Создаю папку...');
      await dir.create(recursive: true);
      print('   Положи текстуры в: $inputDir');
      print('   Формат: grass.png, stone.png, dirt.png и т.д.');
      return [];
    }

    final textures = <File>[];
    final files = await dir.list().toList();

    for (final file in files) {
      if (file is File) {
        final ext = file.path.split('.').last.toLowerCase();
        if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
          textures.add(file);
        }
      }
    }

    // Сортируем по имени для предсказуемого порядка
    textures.sort((a, b) => a.path.compareTo(b.path));
    
    return textures;
  }

  /// Создает атлас для заданного размера тайла
  Future<void> createAtlas({
    required List<File> textureFiles,
    required int tileSize,
  }) async {
    final atlasSize = gridSize * tileSize;
    const maxTexturesForSize = gridSize * gridSize;
    
    print('\n📦 Создаю атлас ${tileSize}x$tileSize');
    print('   Размер атласа: ${atlasSize}x$atlasSize');
    print('   Сетка: ${gridSize}x$gridSize');
    print('   Максимум текстур: $maxTexturesForSize');
    print('   Текстур для обработки: ${textureFiles.length}');

    if (textureFiles.isEmpty) {
      print('   ⚠️ Нет текстур для обработки');
      return;
    }

    if (textureFiles.length > maxTexturesForSize) {
      print('   ⚠️ Внимание! Текстур больше чем может вместить атлас!');
      print('   Будет использовано только первых $maxTexturesForSize текстур');
    }

    // Создаем пустой атлас
    final atlas = img.Image(width: atlasSize, height: atlasSize);
    img.fill(atlas, color: img.ColorRgba8(0, 0, 0, 0));
    
    int currentX = 0;
    int currentY = 0;
    int textureIndex = 0;
    
    // Обрабатываем только первые maxTexturesForSize текстур
    final texturesToProcess = textureFiles.take(maxTexturesForSize).toList();
    
    for (final file in texturesToProcess) {
      // Загружаем изображение
      final bytes = await file.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      
      if (original == null) {
        print('      ✗ Ошибка загрузки: ${file.path.split('/').last}');
        continue;
      }
      
      // Изменяем размер
      final resized = img.copyResize(original, 
        width: tileSize, 
        height: tileSize
      );
      
      // Вставляем в атлас
      img.compositeImage(atlas, resized, dstX: currentX, dstY: currentY);
      
      // Выводим информацию о позиции
      final fileName = file.path.split(Platform.pathSeparator).last;
      final col = textureIndex % gridSize;
      final row = textureIndex ~/ gridSize;
      print('      ✓ ${textureIndex + 1}: $fileName -> позиция ($col, $row)');
      
      // Перемещаемся к следующей текстуре
      currentX += tileSize;
      if (currentX >= atlasSize) {
        currentX = 0;
        currentY += tileSize;
      }
      textureIndex++;
    }
    
    // Сохраняем атлас
    final atlasPath = '$outputDir/atlas_$tileSize.png';
    final pngBytes = img.encodePng(atlas);
    await File(atlasPath).writeAsBytes(pngBytes);
    
    // Получаем размер файла в КБ
    final fileSize = await File(atlasPath).length();
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);
    
    print('   💾 Сохранен: ${atlasPath.split('/').last} ($fileSizeKB KB)');
    print('   📊 Использовано текстур: $textureIndex из ${textureFiles.length}');
    
    if (textureFiles.length > maxTexturesForSize) {
      print('   ⚠️ ${textureFiles.length - maxTexturesForSize} текстур не поместились!');
    }
  }

  /// Генерирует файл с информацией о расположении текстур
  Future<void> generateIndexFile(List<File> textureFiles) async {
    const maxTexturesForSize = gridSize * gridSize;
    final texturesToProcess = textureFiles.take(maxTexturesForSize).toList();
    
    final index = <Map<String, dynamic>>[];
    
    for (int i = 0; i < texturesToProcess.length; i++) {
      final file = texturesToProcess[i];
      final fileName = file.path.split(Platform.pathSeparator).last;
      final baseName = fileName.split('.').first;
      
      final col = i % gridSize;
      final row = i ~/ gridSize;
      
      // UV координаты для всех размеров
      final uv32 = {
        'u1': col / gridSize,
        'v1': row / gridSize,
        'u2': (col + 1) / gridSize,
        'v2': (row + 1) / gridSize,
      };
      
      final uv64 = {
        'u1': col / gridSize,
        'v1': row / gridSize,
        'u2': (col + 1) / gridSize,
        'v2': (row + 1) / gridSize,
      };
      
      final uv128 = {
        'u1': col / gridSize,
        'v1': row / gridSize,
        'u2': (col + 1) / gridSize,
        'v2': (row + 1) / gridSize,
      };
      
      index.add({
        'index': i,
        'name': baseName,
        'file': fileName,
        'position': {
          'col': col,
          'row': row,
        },
        'uv': {
          '32': uv32,
          '64': uv64,
          '128': uv128,
        },
      });
    }
    
    // Сохраняем индекс
    final indexPath = '$outputDir/texture_index.json';
    final jsonString = const JsonEncoder.withIndent('  ').convert(index);
    await File(indexPath).writeAsString(jsonString);
    
    print('\n📄 Создан индекс: $indexPath');
    print('   Содержит информацию о ${index.length} текстурах');
  }

  /// Основной процесс сборки
  Future<void> build() async {
    print('=' * 70);
    print('🎨 Texture Atlas Builder');
    print('=' * 70);
    print('📁 Входная папка: $inputDir');
    print('📁 Выходная папка: $outputDir');
    print('📐 Сетка: ${gridSize}x$gridSize (максимум $maxTextures текстур)');
    print('📏 Размеры атласов:');
    for (final tileSize in tileSizes) {
      final atlasSize = gridSize * tileSize;
      print('   - ${tileSize}x$tileSize текстур -> атлас ${atlasSize}x$atlasSize');
    }
    
    // Создаем выходную папку
    final outDir = Directory(outputDir);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    
    // Сканируем текстуры
    final textures = await scanTextures();
    if (textures.isEmpty) {
      print('\n❌ Нет текстур для обработки');
      print('   Положи текстуры в: $inputDir');
      print('   Поддерживаемые форматы: PNG, JPG, JPEG, WEBP');
      return;
    }
    
    print('\n📁 Найдено ${textures.length} текстур:');
    for (int i = 0; i < textures.length && i < 10; i++) {
      print('   ${i + 1}. ${textures[i].path.split('/').last}');
    }
    if (textures.length > 10) {
      print('   ... и еще ${textures.length - 10} текстур');
    }
    
    if (textures.length > maxTextures) {
      print('\n⚠️ ВНИМАНИЕ! Найдено ${textures.length} текстур');
      print('   Атлас вмещает только $maxTextures текстур');
      print('   Будет использовано первых $maxTextures текстур');
      print('   Остальные ${textures.length - maxTextures} текстур будут проигнорированы');
    }
    
    print('\n${'=' * 70}');
    print('🎨 Генерация атласов');
    print('=' * 70);
    
    // Создаем атласы для каждого размера
    for (final tileSize in tileSizes) {
      await createAtlas(
        textureFiles: textures,
        tileSize: tileSize,
      );
    }
    
    // Генерируем индексный файл
    await generateIndexFile(textures);
    
    print('\n${'=' * 70}');
    print('✨ Готово!');
    print('=' * 70);
    print('\n📖 Как использовать в блоке:');
    print('   В JSON блока укажи:');
    print('   {');
    print('     "id": 1,');
    print('     "name": "stone",');
    print('     "textures": {');
    print('       "top": [1, u1, v1, u2, v2],   // для 128x128');
    print('       "bottom": [1, u1, v1, u2, v2],');
    print('       "north": [1, u1, v1, u2, v2],');
    print('       ...');
    print('     }');
    print('   }');
    print('\n   UV координаты смотри в файле: texture_index.json');
    print('   Например, для текстуры "grass" (index 0):');
    print('   u1 = 0.0, v1 = 0.0, u2 = 0.0625, v2 = 0.0625');
    print('\n   Формула:');
    print('   u1 = col / 16');
    print('   v1 = row / 16');
    print('   u2 = (col + 1) / 16');
    print('   v2 = (row + 1) / 16');
  }
}

void main() async {
  final builder = TextureAtlasBuilder(
    inputDir: 'resources/images/textures/raw',
    outputDir: 'resources/images/textures',
  );
  
  await builder.build();
}