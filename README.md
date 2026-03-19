# Hio

Hio — это 2.5D RPG, построенная на Flutter и Flame. Проект использует data-driven архитектуру.

## Ключевые особенности

- Псевдо-3D рендеринг через спрайт-стакинг (12 проекций на объект)
- Дискретный 2D-мир с multi-tile объектами (1x1, 2x2, 1x3)
- Динамическое освещение с множественными источниками света
- Полностью data-driven: карты, объекты, существа и их поведение в JSON
- Чистое разделение логики (2D grid) и рендеринга (2.5D спрайты)

## Структура проекта

lib/
├── core/ # Ядро, независимое от фич
│ ├── assets/ # Менеджеры ассетов
│ ├── di/ # Dependency Injection
│ └── utils/ # Утилиты
│
├── features/ # Фичи (модули)
│ ├── menu/ # Меню и загрузка
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ │
│ ├── world/ # Мир и карты
│ │ ├── data/ # Загрузка карт, JSON-модели
│ │ ├── domain/ # Логика мира, коллизии, occupancy grid
│ │ └── presentation/ # Flame-компоненты рендеринга
│ │
│ ├── player/ # Игрок
│ │ ├── domain/ # Логика игрока
│ │ └── presentation/ # Компоненты игрока
│ │
│ ├── entities/ # Объекты и существа
│ │ ├── domain/ # Базовые классы
│ │ └── presentation/ # Визуальные компоненты
│ │
│ └── inventory/ # Инвентарь
│ ├── domain/
│ └── presentation/
│
├── game/ # Интеграционный слой
│ ├── daggerfall_game.dart # Главный класс игры (FlameGame)
│ ├── game_bloc.dart # Состояние игры
│ └── game_widget.dart # Виджет, интегрирующий Flame и Flutter
│
└── main.dart # Точка входа

assets/
├── data/
│ ├── tiles/ # JSON тайлов
│ ├── objects/ # JSON объектов
│ ├── creatures/ # JSON существ
│ └── maps/ # JSON карт
│
└── images/
├── tiles/ # Текстуры тайлов
└── objects/ # Спрайт-листы объектов

docs/ # Документация
├── architecture/ # Архитектурные решения
├── features/ # Документация по фичам
├── data_formats/ # Описание JSON-форматов
└── images/ # Картинки для документации

## Стек технологий

- Flutter + Flame для рендеринга
- BLoC/Cubit для управления состоянием
- JSON + кодогенерация для data-классов
- FVM для управления версиями Flutter