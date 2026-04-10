# Система рендеринга HIO

> Документация может содержать ошибки и неточности :D

## Оглавление

1. [Архитектура рендеринга](#1-архитектура-рендеринга)
2. [Система координат](#2-система-координат)
3. [Блоки (Blocks)](#3-блоки-blocks)
4. [Renderable и его реализации](#4-renderable-и-его-реализации)
    - 4.1. [Интерфейс Renderable](#41-интерфейс-renderable)
    - 4.2. [RenderFace (грань блока)](#42-renderface-грань-блока)
    - 4.3. [BillboardEntity (билборд)](#43-billboardentity-билборд)
5. [Камера и проекция](#5-камера-и-проекция)
6. [FaceRenderer и отрисовка граней](#6-facerenderer-и-отрисовка-граней)
7. [Текстурная система и LOD](#7-текстурная-система-и-lod)
8. [Освещение](#8-освещение)
9. [Сбор геометрии (MapCollector)](#9-сбор-геометрии-mapcollector)
10. [Оптимизации и кэширование](#10-оптимизации-и-кэширование)
11. [Мини-карта и диагностика](#11-мини-карта-и-диагностика)
12. [Планы по переходу к Mesh-системе](#12-планы-по-переходу-к-mesh-системе)

---

## 1. Архитектура рендеринга

### 1.1. Общая схема

```
┌─────────────────────────────────────────────────────────────────┐
│                      AppGraphics.render()                        │
│                            │                                     │
│                            ▼                                     │
│                   WorldRenderer.render()                         │
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              ▼                           ▼                      │
│       MapCollector.collect()      _cleanupCaches()              │
│              │                                                  │
│              ▼                                                  │
│       Список Renderable                                         │
│              │                                                  │
│              ▼                                                  │
│       Фильтрация и сортировка (Painter's Algorithm)             │
│              │                                                  │
│              ▼                                                  │
│       Для каждого Renderable:                                   │
│         renderable.render(canvas, camera, faceRenderer, player) │
│                            │                                     │
│                            ▼                                     │
│                   FaceRenderer.render()                          │
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              ▼                           ▼                      │
│      TextureLODManager            Subdivision (для близких)      │
│    (выбор LOD, шейдер)           (разбиение на сетку)           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2. Ключевые классы

| Класс | Файл | Назначение |
|-------|------|------------|
| `AppGraphics` | `graphics.dart` | Главный игровой виджет, управление камерой и вводом |
| `WorldRenderer` | `world_renderer.dart` | Координация сбора и отрисовки объектов |
| `MapCollector` | `map_collector.dart` | Сбор видимых граней блоков из карты |
| `FaceRenderer` | `face_renderer.dart` | Отрисовка отдельных граней с текстурами |
| `ProjectionCamera` | `camera.dart` | Проекция 3D → 2D, кэширование проекций |
| `TextureLODManager` | `texture_lod.dart` | Выбор LOD, создание шейдеров для текстур |
| `TextureAtlasManager` | `texture_atlas.dart` | Загрузка и хранение текстурных атласов |

---

## 2. Система координат

### 2.1. Мировые координаты

- **X, Y** — горизонтальная плоскость (метры)
- **Z** — вертикальная ось (метры)
- Игрок находится на уровне **Z = 0** (камера на высоте 1.5)

### 2.2. Диапазон высот блоков

| Параметр | Значение |
|----------|----------|
| Z_min | -3 |
| Z_max | +4 |
| Всего уровней | 8 |

**Константы:** `GraphicsConsts.zMin`, `GraphicsConsts.zMax`, `GraphicsConsts.zLevels`

### 2.3. Преобразование координат

```dart
blockX = floor(worldX)
blockY = floor(worldY)
blockZ = floor(worldZ)
zIndex = blockZ - GraphicsConsts.zMin   // 0..7 для доступа в массиве
```

**Реализация:** `WorldMap` (`world_map.dart`) — методы `getBlockId()`, `setBlockId()`

---

## 3. Блоки (Blocks)

### 3.1. Определение блока

Блок занимает объём **1×1×1 метр**. Каждый блок описывается классом `BlockDefinition`:

```dart
class BlockDefinition {
  final int id;           // Уникальный идентификатор (0 = Air)
  final String name;      // Имя блока
  final bool isSolid;     // Проходимость
  final BlockTextures? textures;  // UV-координаты для 6 граней
  final Color color;      // Fallback цвет
  final int rotation;     // Поворот блока (0-3: 0=север, 1=восток, 2=юг, 3=запад)
}
```

**Файлы:** `block_definition.dart`, `block_textures.dart`

### 3.2. Текстуры блока

`BlockTextures` содержит UV-координаты для каждой грани:

```dart
class BlockTextures {
  final RectUV top, bottom, north, south, east, west;
  
  RectUV? getFace(FaceDirection direction) { ... }
}
```

### 3.3. Регистрация блоков

Блоки регистрируются в `BlockRegistry` (singleton):

```dart
BlockRegistry.instance.register(block);
BlockDefinition? def = BlockRegistry.instance.get(id);
```

### 3.4. Загрузка из JSON

**Путь:** `resources/data/blocks.json`

```json
{
  "blocks": [
    {
      "id": 1,
      "name": "stone",
      "isSolid": true,
      "color": "FF808080",
      "rotation": 0,
      "textures": {
        "all": [0.0, 0.0, 0.0625, 0.0625]
      }
    }
  ]
}
```

**Загрузчик:** `BlockLoader.loadAllBlocks()`

---

## 4. Renderable и его реализации

### 4.1. Интерфейс Renderable

Все объекты, которые могут быть отрендерены, реализуют `Renderable`:

```dart
abstract class Renderable {
  double get depth;      // Глубина для сортировки (painter's algorithm)
  int get priority;      // Приоритет (0 = opaque, 1 = transparent, 2 = billboard)
  
  void render(
    Canvas canvas,
    ProjectionCamera camera,
    FaceRenderer faceRenderer,
    Player player,
  );
}
```

**Файл:** `renderable.dart`

### 4.2. RenderFace (грань блока)

Реализация `Renderable` для граней блоков. Представляет собой четырёхугольную грань куба, жёстко привязанную к целочисленной 3D-сетке.

```dart
class RenderFace implements Renderable {
  final List<(double, double, double)> points3D;  // 4 вершины в 3D
  final Color color;                               // Базовый цвет
  final RectUV? uv;                                // UV в атласе
  final double centerX, centerY, centerZ;          // Центр грани
  final double nx, ny, nz;                         // Нормаль
  final double depth;                              // Глубина от камеры
  double realDistance;                             // Реальное расстояние
  
  @override
  int get priority => 0;  // Opaque
  
  @override
  void render(Canvas canvas, ProjectionCamera camera, 
              FaceRenderer renderer, Player player) {
    final clip = camera.clipAndProjectQuad(points3D, player);
    if (clip != null) {
      renderer.render(
        canvas,
        clip.screenPoints,
        clip.uvPoints,
        color,
        distance: realDistance,
        uv: uv,
      );
    }
  }
}
```

**Файл:** `render_face.dart`

### 4.3. BillboardEntity (билборд)

Реализация `Renderable` для спрайтов, всегда повёрнутых лицом к камере. В отличие от `RenderFace`, билборды **не привязаны к целочисленной 3D-сетке** и могут располагаться в произвольных мировых координатах.

```dart
class BillboardEntity implements Renderable {
  final double x, y, z;       // Позиция в мире (произвольная, не привязана к сетке)
  final double width;         // Ширина спрайта в мировых единицах
  final double height;        // Высота спрайта в мировых единицах
  final RectUV uv;            // UV-координаты в атласе
  
  @override
  late final double depth;    // Вычисляется в конструкторе
  
  @override
  int get priority => 2;      // Рендерится после opaque и transparent
  
  BillboardEntity({
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.uv,
    required Player player,
  }) {
    final dx = x - player.x;
    final dy = y - player.y;
    depth = dx * dx + dy * dy;  // Квадрат расстояния для сортировки
  }
  
  @override
  void render(
    Canvas canvas,
    ProjectionCamera camera,
    FaceRenderer faceRenderer,
    Player player,
  ) {
    // 1. Проверка, находится ли билборд перед камерой
    if (!camera.isPointInFront(x, y, z, player)) return;
    
    // 2. Проекция центра билборда на экран
    final screenCenter = camera.worldToScreen(x, y, z, player);
    if (screenCenter == null) return;
    
    // 3. Вычисление размера на экране в зависимости от расстояния
    final dx = x - player.x;
    final dy = y - player.y;
    final dz = z - player.z;
    final distance = sqrt(dx * dx + dy * dy + dz * dz);
    
    // 4. Вычисление экранных координат углов спрайта
    //    (всегда повёрнут лицом к камере)
    // ...
    
    // 5. Отрисовка через FaceRenderer (как обычную грань)
    // ...
  }
}
```

**Файл:** `billboard.dart`

**Особенности билбордов:**
- **Динамическое позиционирование:** могут перемещаться каждый кадр
- **Не привязаны к сетке:** координаты `(x, y, z)` — произвольные double
- **Всегда лицом к камере:** вершины вычисляются относительно направления взгляда
- **Приоритет 2:** рендерится после всех opaque (0) и transparent (1) объектов
- **Поддержка анимации:** можно менять `uv` для анимации спрайта

---

## 5. Камера и проекция

### 5.1. ProjectionCamera

Камера с перспективной проекцией:

```dart
class ProjectionCamera {
  double get screenWidth;
  double get screenHeight;
  double get verticalFovDegrees;  // По умолчанию 60°
  
  // Направления камеры (обновляются в updateCache)
  double forwardX, forwardY, forwardZ;
  
  void resize(double width, double height);
  void updateCache(Player player);
  Offset? worldToScreen(double x, double y, double z, Player player);
  ClipResult? clipAndProjectQuad(List<(double, double, double)> corners, Player player);
  bool isPointInFront(double x, double y, double z, Player player);
}
```

### 5.2. Проекция точки

```dart
// camera.dart — worldToScreen()
dx = x - player.x
dy = y - player.y
dz = z - player.z

forwardDepth = dx * forwardX + dy * forwardY + dz * forwardZ
depth = max(forwardDepth, minDepth)  // minDepth = 0.05

rightOffset = dx * rightX + dy * rightY + dz * rightZ
upOffset = dx * upX + dy * upY + dz * upZ

screenX = screenWidth / 2 + (rightOffset / depth) * scale
screenY = screenHeight / 2 - (upOffset / depth) * scale
```

### 5.3. Клиппинг граней

Метод `clipAndProjectQuad`:
1. Переводит 4 вершины в пространство вида (view space)
2. Отсекает части грани, находящиеся за near plane (z < minDepth)
3. Создаёт новые вершины на пересечении с near plane
4. Проецирует результат на экран

**UV-координаты для вершин:**
```dart
const uvs = [
  Offset(0.0, 1.0),  // левый-нижний
  Offset(1.0, 1.0),  // правый-нижний
  Offset(1.0, 0.0),  // правый-верхний
  Offset(0.0, 0.0),  // левый-верхний
];
```

### 5.4. Кэширование проекций

- Кэш живёт **1 кадр** (`_currentFrameId`)
- Ключ: `Object.hash(round(x*100), round(y*100), round(z*100), _currentFrameId)`
- Очищается в `updateCache()`

---

## 6. FaceRenderer и отрисовка граней

### 6.1. Основной метод render()

```dart
void render(
  Canvas canvas,
  List<Offset> points,      // Экранные координаты (3 или 4 точки)
  List<Offset> uvs,         // UV-координаты вершин
  Color color,              // Базовый цвет
  {
    double opacity = 1.0,
    RectUV? uv,             // UV-регион в атласе
    double distance = 0.0,
    bool isInsideBlock = false,
  }
)
```

### 6.2. Логика выбора рендеринга

```
Если есть uv (текстура):
  ├─ Получить texturePaint через TextureLODManager
  ├─ Если текстура получена:
  │   ├─ Определить уровень subdivision (n) по distance
  │   ├─ Если points.length == 4 и n > 1:
  │   │   └─ _drawWithCache() — subdivision на сетку n×n
  │   └─ Иначе:
  │       └─ _renderSimplePoly() — обычный полигон
  └─ Если текстура не получена:
      └─ _renderFallbackPath() — заливка цветом
```

### 6.3. Динамический subdivision

Для устранения аффинных искажений текстур на близких расстояниях:

| Расстояние | Сетка (n) | Треугольников | Применение |
|------------|-----------|---------------|------------|
| < 2.0 | 4 | 32 (4×4×2) | Максимальная детализация |
| 2.0 - 6.0 | 2 | 8 (2×2×2) | Средняя детализация |
| > 6.0 | 1 | 2 | Стандартный рендер |

**Метод:** `_drawWithCache()` — создаёт и кэширует `Vertices` с разбиением.

### 6.4. Кэширование subdivided vertices

```dart
final Map<int, Vertices> _verticesCache = {};

int cacheKey = Object.hashAll([...points, ...uvs, n]);
Vertices? v = _verticesCache[cacheKey];

if (v == null) {
  v = _buildSubdividedVertices(points, uvs, n);
  _verticesCache[cacheKey] = v;
}
```

### 6.5. Бюджет треугольников

```dart
static const int maxTrianglesPerFrame = 5000;
int _currentFrameTriangles = 0;

void resetFrameBudget() => _currentFrameTriangles = 0;
```

---

## 7. Текстурная система и LOD

### 7.1. Текстурные атласы

| Размер текстур | Разрешение атласа | Ячеек (16×16) |
|----------------|-------------------|---------------|
| 128 px | 2048×2048 | 256 |
| 64 px | 1024×1024 | 256 |
| 32 px | 512×512 | 256 |

**Класс:** `TextureAtlasManager` (`texture_atlas.dart`)

```dart
Future<void> loadAllAtlases();
ui.Image? getAtlas(int size);
Rect? getTextureRect(RectUV uv, int textureSize);
```

### 7.2. LOD (Level of Detail)

`TextureLODManager` выбирает уровень детализации по расстоянию:

| Расстояние | LOD | Размер текстуры |
|------------|-----|-----------------|
| < 12.0 | high | 128px |
| 12.0 - 24.0 | medium | 64px |
| 24.0 - 36.0 | low | 32px |
| 36.0 - 48.0 | fog | туман (нет текстуры) |
| > 48.0 | none | не рисуется |

### 7.3. Создание Paint с шейдером

```dart
Paint? getTexturePaint({
  required RectUV uv,
  required double distance,
  required double opacity,
  required bool isInsideBlock,
}) {
  final lod = getLOD(distance);
  final textureSize = getTextureSize(lod);
  final atlas = _atlasManager.getAtlas(textureSize);
  final textureRect = _atlasManager.getTextureRect(uv, textureSize);
  
  // Создаём матрицу трансформации для шейдера
  final matrix = Float64List.fromList([...]);
  final transform = Matrix4.fromFloat64List(matrix);
  
  final shader = ImageShader(atlas, TileMode.clamp, TileMode.clamp, transform.storage);
  
  return Paint()
    ..shader = shader
    ..filterQuality = FilterQuality.none;
}
```

### 7.4. Кэширование шейдеров

- Кэш до 500 записей
- Ключ: `Object.hash(uv.left, uv.top, uv.right, uv.bottom, textureSize, opacity)`
- Автоматическая очистка при превышении лимита

---

## 8. Освещение

### 8.1. Текущее состояние

**На данный момент освещение не интегрировано в рендеринг.** В `FaceRenderer.render()` параметр `opacity` используется только для общей прозрачности, но не для освещения.

### 8.2. Существующая инфраструктура

В проекте уже есть классы для освещения:

```dart
// lighting.dart
class LightSource {
  final double x, y, z;
  final double radius;
  final double intensity;
  
  double contributeAt(double px, double py, double pz);
}

class LightingSystem {
  double ambientLight;
  final List<LightSource> sources;
  
  double calculateLight(double x, double y, double z);
}
```

**Данные загружаются из JSON карты:**
```json
{
  "ambientLight": 1.0,
  "lightSources": [
    {"x": 10, "y": 10, "z": 2, "radius": 5, "intensity": 0.8}
  ]
}
```

### 8.3. План интеграции

Необходимо:
1. Передавать `brightness` в `RenderFace` при создании
2. Добавить параметр `brightness` в `FaceRenderer.render()`
3. Применять `brightness` к `opacity` текстуры или цвету

---

## 9. Сбор геометрии (MapCollector)

### 9.1. Алгоритм сбора

```dart
List<Renderable> collect(Player player, WorldMap map, int renderDistance) {
  final result = <Renderable>[];
  
  final px = player.x.floor();
  final py = player.y.floor();
  
  for (int tx = px - renderDistance; tx <= px + renderDistance; tx++) {
    for (int ty = py - renderDistance; ty <= py + renderDistance; ty++) {
      if (tx < 0 || tx >= map.width || ty < 0 || ty >= map.height) continue;
      
      final column = _getOrBuildColumn(tx, ty, map);
      result.addAll(column.faces);
    }
  }
  
  return result;
}
```

### 9.2. Кэширование колонок

Каждая колонка (x, y) кэшируется для повторного использования в течение кадра:

```dart
final Map<int, _CachedColumnData> _columnCache = {};

_CachedColumnData _getOrBuildColumn(int x, int y, WorldMap map) {
  final key = x * 10000 + y;
  if (_columnCache.containsKey(key)) return _columnCache[key]!;
  
  // Строим грани для всей колонки
  final faces = <RenderFace>[];
  for (int z = GraphicsConsts.zMin; z <= GraphicsConsts.zMax; z++) {
    // ... создание граней
  }
  
  final data = _CachedColumnData(faces);
  _columnCache[key] = data;
  return data;
}
```

### 9.3. Создание грани (_createFace)

Для каждого блока проверяются 6 соседних позиций. Грань создаётся, если соседняя позиция пуста (ID = 0).

**Порядок вершин для граней (исправлено для правильной ориентации текстур):**

| Грань | Направление | Порядок вершин (относительно "лица" грани) |
|-------|-------------|-------------------------------------------|
| North | X+ | левый-нижний, правый-нижний, правый-верхний, левый-верхний |
| South | X- | левый-нижний, правый-нижний, правый-верхний, левый-верхний |
| East | Y+ | левый-нижний, правый-нижний, правый-верхний, левый-верхний |
| West | Y- | левый-нижний, правый-нижний, правый-верхний, левый-верхний |
| Top | Z+ | с учётом поворота блока |
| Bottom | Z- | с учётом поворота блока |

**Важно:** Порядок вершин должен соответствовать UV-маппингу:
- Индекс 0 → UV(0,1) — левый-нижний
- Индекс 1 → UV(1,1) — правый-нижний
- Индекс 2 → UV(1,0) — правый-верхний
- Индекс 3 → UV(0,0) — левый-верхний

### 9.4. Очистка кэша

```dart
void clearCache() => _columnCache.clear();
```

Вызывается каждые 300 кадров в `WorldRenderer._cleanupCaches()`.

---

## 10. Оптимизации и кэширование

### 10.1. Сводная таблица кэшей

| Кэш | Класс | Время жизни | Ключ | Очистка |
|-----|-------|-------------|------|---------|
| Проекции точек | `ProjectionCamera` | 1 кадр | `hash(x,y,z, frameId)` | `updateCache()` |
| Subdivided vertices | `FaceRenderer` | До 300 записей | `hash(points, uvs, n)` | При переполнении |
| Шейдеры текстур | `TextureLODManager` | До 500 записей | `hash(uv, size, opacity)` | При переполнении |
| Колонки карты | `MapCollector` | 1 кадр | `x * 10000 + y` | `clearCache()` |

### 10.2. Периодическая очистка

В `WorldRenderer._cleanupCaches()` каждые 300 кадров:
```dart
if (_frameCounter % 300 == 0) {
  _camera.clearCache();
  _faceRenderer.clearCache();
  _mapCollector.clearCache();
}
```

### 10.3. Painter's Algorithm с бакетами

Для правильного порядка отрисовки (back-to-front) используется bucketing:

```dart
static const int _bucketCount = 50;
final List<List<Renderable>> _buckets = List.generate(_bucketCount, (_) => []);

// Распределение по бакетам
int index = ((dotDepth / renderDistance) * (_bucketCount - 1))
    .floor()
    .clamp(0, _bucketCount - 1);
_buckets[index].add(processedFace);

// Отрисовка от дальних к ближним
for (int i = _bucketCount - 1; i >= 0; i--) {
  _buckets[i].sort((a, b) => b.depth.compareTo(a.depth));
  for (final face in _buckets[i]) {
    face.render(...);
  }
}
```

---

## 11. Мини-карта и диагностика

### 11.1. Minimap

Отображается в правом верхнем углу:
- Размер: 200×200 px
- Отображает блоки на уровне Z=0 в радиусе вокруг игрока
- Красный круг — позиция игрока
- Жёлтая линия — направление взгляда
- Текстовые метки сторон света (N, S, E, W)

**Класс:** `Minimap` (`minimap.dart`)

### 11.2. FpsCounter

Отображает диагностическую информацию:
- Текущий FPS / средний FPS
- Время кадра (ms)
- Количество отрендеренных граней
- Размер кэшей (шейдеры, колонки)

**Класс:** `FpsCounter` (`fps_counder.dart`)

---

## 12. Планы по переходу к Mesh-системе

### 12.1. Текущие ограничения

Сейчас система рендеринга жёстко завязана на:
- Целочисленную 3D-сетку (блоки 1×1×1)
- Только кубические формы для статических объектов
- `RenderFace` как реализацию для блоков
- `BillboardEntity` как отдельную реализацию для спрайтов

### 12.2. Цель рефакторинга

Перейти к унифицированной системе, где:
- **Блок** — частный случай **Mesh** (куб 1×1×1), располагаемый в сетке
- **Динамические объекты** (двери, предметы) — также Mesh, но с возможностью перемещения и анимации
- **Билборды** — остаются отдельным типом для спрайтов (трава крестом, эффекты)
- Геометрия описывается декларативно (JSON)
- Единый рендеринг через `FaceRenderer`

### 12.3. Предлагаемая архитектура

```
Mesh (данные геометрии)
  ├─ vertices: List<Vector3>      // локальные координаты (0..1)
  ├─ faces: List<MeshFace>        // грани
  ├─ flags: isTransparent, doubleSided, isAnimated
  └─ animations: List<Animation>  // для дверей и т.п.

MeshEntity implements Renderable
  ├─ mesh: Mesh
  ├─ worldPosition: Vector3       // может быть нецелочисленной
  ├─ rotation: int (0-3)
  ├─ animationState: AnimationState?  // текущее состояние анимации
  └─ render() → FaceRenderer.renderMeshFace()

BillboardEntity implements Renderable
  ├─ остаётся отдельной реализацией
  └─ используется для спрайтов, всегда повёрнутых к камере
```

### 12.4. Типы объектов и их особенности

| Тип | Расположение | Статичность | Анимация | Приоритет |
|-----|--------------|-------------|----------|-----------|
| Блок (Mesh) | Целочисленная сетка | Статический | Нет | 0/1 |
| Дверь (Mesh) | Целочисленная сетка | Динамическая | Открывание/закрывание | 0/1 |
| Предмет (Mesh) | Произвольное | Динамический | Подбирание/вращение | 0/1 |
| Трава (Mesh) | Целочисленная сетка | Статическая | Нет | 1 (transparent) |
| Билборд | Произвольное | Динамический | Спрайтовая анимация | 2 |

### 12.5. Интеграция освещения

Планируется:
1. Вычислять `brightness` для каждой грани через `LightingSystem.calculateLight()`
2. Передавать `brightness` в `FaceRenderer.render()`
3. Применять как множитель к `opacity` текстуры или к цвету

```dart
// В MeshEntity.render()
final center = face.center;
final brightness = world.lighting.calculateLight(center.x, center.y, center.z);
faceRenderer.renderMeshFace(canvas, face, camera, player, 
  distance: distance, 
  brightness: brightness
);
```

### 12.6. Поддержка прозрачности и backface culling

Для объектов с прозрачными текстурами (трава, двери со стеклом):
- `Mesh.isTransparent = true`
- `Renderable.priority = 1` (рендерится после opaque)
- `Mesh.doubleSided = true` (отключает backface culling)

### 12.7. Система анимаций для Mesh

Для динамических объектов (двери) планируется:

```dart
class MeshAnimation {
  final String name;           // "open", "close"
  final double duration;       // длительность в секундах
  final List<Vector3> targetVertices;  // целевые позиции вершин
  final List<int> affectedFaces;       // какие грани анимируются
}

class AnimatedMeshEntity extends MeshEntity {
  AnimationController? _controller;
  double _animationProgress = 0.0;
  
  void playAnimation(String name) {
    // Запуск анимации, интерполяция вершин
  }
  
  @override
  void update(double dt) {
    // Обновление прогресса анимации
    // Пересчёт worldVertices с учётом анимации
  }
}
```

### 12.8. Примеры JSON для будущих мешей

**Дверь (с анимацией):**
```json
{
  "name": "door_wooden",
  "vertices": [
    [0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [1.0, 0.125, 0.0], [0.0, 0.125, 0.0],
    [0.0, 0.0, 2.0], [1.0, 0.0, 2.0], [1.0, 0.125, 2.0], [0.0, 0.125, 2.0]
  ],
  "faces": [
    {"indices": [0,1,2,3], "uv": [0,0,1,0.0625]},
    {"indices": [4,5,6,7], "uv": [0,0,1,0.0625]},
    {"indices": [0,3,7,4], "uv": [0,0,0.0625,1]},
    {"indices": [1,2,6,5], "uv": [0,0,0.0625,1]},
    {"indices": [3,2,6,7], "uv": [0,0,1,1]}
  ],
  "animations": {
    "open": {
      "duration": 0.5,
      "rotateAround": [0.0, 0.0, 0.0],
      "angle": -90.0
    }
  }
}
```

**Трава (крест из 2 плоскостей):**
```json
{
  "name": "grass",
  "vertices": [
    [0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [1.0, 0.0, 1.0], [0.0, 0.0, 1.0],
    [0.0, 1.0, 0.5], [1.0, 1.0, 0.5]
  ],
  "faces": [
    {"indices": [0, 1, 5, 4], "uv": [0,0,1,1], "material": "cutout"},
    {"indices": [3, 2, 5, 4], "uv": [0,0,1,1], "material": "cutout"}
  ],
  "isTransparent": true,
  "doubleSided": true
}
```

**Призма (скос):**
```json
{
  "name": "prism_slope",
  "vertices": [
    [0,0,0], [1,0,0], [1,1,0], [0,1,0],
    [0,0,0.5], [1,0,1]
  ],
  "faces": [
    {"indices": [0,1,5], "uv": [0,0,1,1]},
    {"indices": [0,5,4], "uv": [0,0,1,1]},
    {"indices": [0,4,3], "uv": [0,0,1,1]},
    {"indices": [1,2,3,5], "uv": [0,0,1,1]},
    {"indices": [2,3,4,5], "uv": [0,0,1,1]}
  ]
}
```

### 12.9. Этапы реализации

1. **Создать базовые классы:** `Mesh`, `MeshFace`, `MeshEntity`
2. **Адаптировать `FaceRenderer`:** добавить `renderMeshFace()`
3. **Перевести блоки на Mesh:** `Mesh.createCube(BlockDefinition)`
4. **Добавить загрузчик из JSON:** `MeshLoader.fromJson()`
5. **Интегрировать освещение:** вычисление `brightness` для каждой грани
6. **Добавить поддержку анимаций:** `AnimatedMeshEntity`
7. **Реализовать новые типы объектов:** двери, трава, призмы
8. **Сохранить `BillboardEntity`** как отдельную реализацию для спрайтов

---

## Приложение A: Константы (GraphicsConsts)

```dart
class GraphicsConsts {
  // Диапазон высот
  static const int zMin = -3;
  static const int zMax = 4;
  static const int zLevels = 8;
  
  // Игрок
  static const double playerHeight = 1.5;
  static const double playerRadius = 0.45;
  static const double playerSpeed = 5.0;
  static const double playerRotationSpeed = 2.0;
  static const double playerPitchSpeed = 1.5;
  
  // Рендеринг
  static const double defaultRenderDistance = 64.0;
  static const double defaultVerticalFov = 60.0;
  static const double fogStartDistance = 40.0;
  static const double fogEndDistance = 64.0;
}
```

---

## Приложение B: Глоссарий

| Термин | Определение |
|--------|-------------|
| **Renderable** | Интерфейс для всех объектов, которые могут быть отрендерены |
| **RenderFace** | Грань блока, реализует Renderable |
| **BillboardEntity** | Спрайт, всегда повёрнутый лицом к камере |
| **Mesh** | 3D-модель, состоящая из вершин и граней |
| **MeshEntity** | Экземпляр Mesh в мире, реализует Renderable |
| **LOD** | Level of Detail — выбор разрешения текстуры по расстоянию |
| **Subdivision** | Разбиение грани на сетку для устранения искажений текстур |
| **Painter's Algorithm** | Отрисовка объектов от дальних к ближним |
| **Backface Culling** | Отбрасывание граней, повёрнутых от камеры |
| **UV** | Координаты текстуры (0..1) |
| **RectUV** | Прямоугольная область в текстурном атласе |
