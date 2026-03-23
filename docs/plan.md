# План написания кода

## Фаза 1: Ядро данных (Pure Dart, без Flame)

### 1.1. Базовые типы и утилиты
**Файл:** `lib/game/core/point.dart`
- Класс `Point3D` (x, y, z)
- Методы: сложение, вычитание, расстояние

**Файл:** `lib/game/core/rect.dart`
- Класс `RectUV` (left, top, right, bottom)
- Для UV-координат текстур

**Проверка:** Создать тест, проверяющий создание точек и вычисление расстояния.

---

### 1.2. Определение блока
**Файл:** `lib/game/block/block_definition.dart`
- Класс `BlockDefinition`
  - `id: int`
  - `isSolid: bool`
  - `textures: BlockTextures`

**Файл:** `lib/game/block/block_textures.dart`
- Класс `BlockTextures`
  - `top: RectUV`
  - `bottom: RectUV`
  - `north: RectUV`
  - `south: RectUV`
  - `east: RectUV`
  - `west: RectUV`

**Проверка:** Создать объект BlockDefinition для блока "камень" с тестовыми UV.

---

### 1.3. Реестр блоков
**Файл:** `lib/game/block/block_registry.dart`
- Класс `BlockRegistry`
  - `Map<int, BlockDefinition> _blocks`
  - `void register(BlockDefinition block)`
  - `BlockDefinition? get(int id)`
  - `BlockDefinition getSolid()` // возвращает блок по умолчанию (id=1)

**Проверка:** Зарегистрировать 2 блока, получить по ID.

---

### 1.4. Загрузка блоков из JSON
**Файл:** `lib/game/block/block_loader.dart`
- Функция `Future<BlockDefinition> loadBlockFromJson(String path)`
- Читает JSON, парсит, создаёт BlockDefinition

**Проверка:** Загрузить JSON файл блока "камень", проверить поля.

---

### 1.5. Карта мира
**Файл:** `lib/game/world/world_map.dart`
- Класс `WorldMap`
  - `final int width`
  - `final int height`
  - `List<List<List<int>>> _blockIds` // [x][y][z]
  - `int getBlockId(int x, int y, int z)`
  - `void setBlockId(int x, int y, int z, int id)`
  - Константы: `zMin = -3`, `zMax = 4`, `zLevels = 8`

**Проверка:** Создать карту 10×10, установить блок в центре на Z=0, прочитать.

---

### 1.6. Загрузка карты из JSON
**Файл:** `lib/game/world/world_loader.dart`
- Функция `Future<WorldMap> loadWorldFromJson(String path)`
- Читает JSON, создаёт WorldMap, заполняет блоки из списка `blocks`

**Проверка:** Создать JSON с 3 блоками, загрузить карту, проверить позиции.

---

### 1.7. Тестовая карта
**Файл:** `assets/maps/test_map.json`
- Сгенерировать JSON для карты 70×70 с комнатой и колоннами (по спецификации)
- Использовать псевдокод из документации

**Проверка:** Загрузить карту, убедиться, что блоки на местах.

---

## Фаза 2: Игровая логика (Pure Dart)

### 2.1. Игрок
**Файл:** `lib/game/entities/player.dart`
- Класс `Player`
  - `double x, y` // позиция
  - `double angle` // угол поворота (радианы)
  - `double pitch` // вертикальный угол (радианы)
  - `double speed = 3.0`
  - `double rotationSpeed = 2.0`
  - Методы: `moveForward()`, `moveBackward()`, `strafeLeft()`, `strafeRight()`, `rotate()`, `lookUp/Down()`
  - Команды (флаги) для накопления ввода

**Проверка:** Создать игрока, вызвать rotate(), проверить изменение угла.

---

### 2.2. Мир (связка карты и игрока)
**Файл:** `lib/game/world/game_world.dart`
- Класс `GameWorld`
  - `WorldMap map`
  - `Player player`
  - `double ambientLight = 1.0`
  - `bool canMoveTo(double x, double y, double radius)`
  - `void update(double dt)` // вызывает player.update(dt, this)

**Проверка:** Создать GameWorld, проверить коллизию в пустой клетке и в стене.

---

### 2.3. Обновление игрока с коллизиями
**Файл:** `lib/game/entities/player.dart` (дополнение)
- Метод `update(double dt, GameWorld world)`
- Применяет накопленные команды с учётом коллизий
- Движение раздельно по X и Y

**Проверка:** Запустить цикл update, убедиться, что игрок не проходит сквозь стены.

---

### 2.4. Освещение
**Файл:** `lib/game/world/lighting.dart`
- Класс `LightSource`
  - `double x, y, z`
  - `double radius`
  - `double intensity`
- Класс `LightingSystem`
  - `List<LightSource> sources`
  - `double ambientLight`
  - `double calculateLight(double x, double y, double z)`

**Проверка:** Создать источник света, рассчитать освещение в точке.

---

## Фаза 3: Ввод (Pure Dart, но с Flutter-зависимостями)

### 3.1. Перечисление действий
**Файл:** `lib/input/user_action.dart`
- `enum UserAction`
  - `moveForward`, `moveBackward`
  - `strafeLeft`, `strafeRight`
  - `rotateLeft`, `rotateRight`
  - `lookUp`, `lookDown`
  - `openMenu`

**Проверка:** Импортировать enum, использовать в коде.

---

### 3.2. Менеджер ввода
**Файл:** `lib/input/input_manager.dart`
- Класс `InputManager`
  - `Set<LogicalKeyboardKey> _keysPressed`
  - `double _mouseDeltaX, _mouseDeltaY`
  - `void onKeyDown(LogicalKeyboardKey key)`
  - `void onKeyUp(LogicalKeyboardKey key)`
  - `void onMouseMove(double dx, double dy)`
  - `bool isKeyPressed(LogicalKeyboardKey key)`
  - `double get mouseDeltaX`
  - `double get mouseDeltaY`
  - `void beginFrame()` // сброс дельты мыши

**Проверка:** Эмулировать нажатия, проверить состояние.

---

### 3.3. Преобразование ввод → действия
**Файл:** `lib/input/game_controls.dart`
- Класс `GameControls`
  - `final InputManager _input`
  - `final Player _player`
  - `Map<LogicalKeyboardKey, UserAction> _keyBindings`
  - `void update(double dt)`
  - Чтение клавиш и мыши, вызов методов player

**Проверка:** Создать GameControls, вызвать update, проверить вызовы player.

---

## Фаза 4: Рендеринг (Flame)

### 4.1. Камера (проекция)
**Файл:** `lib/rendering/camera.dart`
- Класс `ProjectionCamera`
  - `double screenWidth, screenHeight`
  - `double fov = 60°` // вертикальный
  - `double horizonRatio = 0.3`
  - `Offset worldToScreen(double x, double y, double z, Player player)`
  - Вычисление экранных координат точки в 3D

**Проверка:** Передать точку в 3D, получить Offset на экране.

---

### 4.2. Текстурный атлас
**Файл:** `lib/rendering/texture_atlas.dart`
- Класс `TextureAtlas`
  - `Image image`
  - `int cellSize` // 128, 64, 32
  - `Rect getUV(int blockId, String face)`
  - `Future<void> load(String path, int cellSize)`

**Проверка:** Загрузить атлас, получить UV для блока.

---

### 4.3. Рендерер грани
**Файл:** `lib/rendering/face_renderer.dart`
- Класс `FaceRenderer`
  - `void render(Canvas canvas, Rect uv, List<Offset> screenPoints, double light)`
  - Отрисовка одного четырёхугольника с текстурой

**Проверка:** Нарисовать квадрат с текстурой на Canvas.

---

### 4.4. Рендерер блоков
**Файл:** `lib/rendering/block_renderer.dart`
- Класс `BlockRenderer`
  - `ProjectionCamera camera`
  - `TextureAtlas atlas`
  - `BlockRegistry registry`
  - `void renderBlock(Canvas canvas, int x, int y, int z, int blockId, Player player, double light)`
  - Проверка видимости каждой грани
  - Вызов FaceRenderer для видимых граней

**Проверка:** Отрисовать один блок с текстурой.

---

### 4.5. Рендерер мира
**Файл:** `lib/rendering/world_renderer.dart`
- Класс `WorldRenderer`
  - `WorldMap map`
  - `BlockRenderer blockRenderer`
  - `int renderDistance = 64`
  - `void render(Canvas canvas, Player player)`
  - Обход блоков в радиусе, вызов renderBlock

**Проверка:** Отрисовать тестовую карту, убедиться в видимости стен и колонн.

---

## Фаза 5: Интеграция с Flame

### 5.1. AppGraphics (точка входа)
**Файл:** `lib/graphics/graphics.dart`
- Класс `AppGraphics extends FlameGame with KeyboardEvents, MouseMovementDetector`
  - `GameWorld world`
  - `InputManager inputManager`
  - `GameControls gameControls`
  - `WorldRenderer renderer`
  - `void update(double dt)`
  - `void render(Canvas canvas)`
  - `void onKeyEvent(...)`
  - `void onMouseMove(...)`

**Проверка:** Запустить игру, увидеть отрисованную карту, двигаться WASD.

---

### 5.2. GraphicsScreen (Flutter виджет)
**Файл:** `lib/screens/graphics_screen.dart`
- Класс `GraphicsScreen extends StatefulWidget`
  - Загрузка карты и блоков в initState
  - Создание GameWorld
  - Создание AppGraphics
  - GameWidget в build
  - Кнопка паузы (временная)

**Проверка:** Полный запуск игры, проверка движения и рендеринга.

---

## Фаза 6: Настройки и оптимизация

### 6.1. Настройки графики
**Файл:** `lib/settings/graphics_settings.dart`
- Класс `GraphicsSettings`
  - Поля: renderDistance, textureSize, ambientLight, useMipmaps, fogEnabled
  - Методы: applyLowPreset, applyMediumPreset, applyHighPreset

**Проверка:** Изменить настройки, убедиться в изменении рендеринга.

---

### 6.2. Mipmaps (подготовка)
**Файл:** `lib/rendering/mipmap.dart`
- Класс `MipmapChain`
  - `List<Image> levels`
  - `Future<void> generate(Image original, int levels)`

**Проверка:** Сгенерировать цепочку mipmaps для тестовой текстуры.

---

### 6.3. Оптимизация рендеринга
**Файл:** `lib/rendering/world_renderer.dart` (дополнение)
- Добавить выбор уровня mipmap по расстоянию
- Добавить туман (смешивание цветов)

**Проверка:** Убедиться, что дальние блоки используют меньшие текстуры.

---

## Итоговая структура файлов

```
lib/
├── game/
│   ├── core/
│   │   ├── point.dart
│   │   └── rect.dart
│   ├── block/
│   │   ├── block_definition.dart
│   │   ├── block_textures.dart
│   │   ├── block_registry.dart
│   │   └── block_loader.dart
│   ├── world/
│   │   ├── world_map.dart
│   │   ├── world_loader.dart
│   │   ├── game_world.dart
│   │   └── lighting.dart
│   └── entities/
│       └── player.dart
├── input/
│   ├── user_action.dart
│   ├── input_manager.dart
│   └── game_controls.dart
├── rendering/
│   ├── camera.dart
│   ├── texture_atlas.dart
│   ├── face_renderer.dart
│   ├── block_renderer.dart
│   ├── world_renderer.dart
│   └── mipmap.dart
├── settings/
│   └── graphics_settings.dart
├── graphics/
│   └── graphics.dart
└── screens/
    └── graphics_screen.dart

assets/
├── blocks/
│   ├── 1.json
│   └── ...
├── textures/
│   ├── atlas_128.png
│   ├── atlas_64.png
│   └── atlas_32.png
└── maps/
    └── test_map.json
```

---

## Принципы при написании кода

1. **Один файл — одна ответственность**
2. **Не смешивать Pure Dart и Flame** — логика в `game/`, рендеринг в `rendering/`
3. **Минимум зависимостей между модулями** — использовать интерфейсы
4. **Тестируемость** — каждый класс должен быть тестируемым изолированно
5. **Имена** — понятные, отражающие суть

---

**Готов начать? С какого пункта начинаем?**