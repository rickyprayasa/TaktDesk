lib/
├── app/
│   ├── app.dart
│   ├── theme/
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   └── shadows.dart
│   └── audio/
│       ├── audio_service.dart
│       └── audio_constants.dart
├── core/
│   ├── sensors/
│   │   └── parallax_controller.dart
│   ├── haptics/
│   │   └── haptic_service.dart
│   └── database/
│       └── isar_service.dart
└── features/
    ├── desk/
    │   ├── presentation/
    │   │   ├── desk_canvas_screen.dart
    │   │   └── widgets/
    │   │       ├── isometric_desk_layout.dart
    │   │       └── ambient_lighting_layer.dart
    │   └── domain/
    ├── timer/
    │   ├── presentation/
    │   │   ├── chrono_dial_widget.dart
    │   │   └── chrono_dial_controller.dart
    │   ├── domain/
    │   │   └── timer_session_model.dart
    │   └── data/
    │       └── timer_repository.dart
    ├── tasks/
    │   ├── presentation/
    │   │   ├── receipt_runner_widget.dart
    │   │   └── task_input_sheet.dart
    │   ├── domain/
    │   │   └── task_model.dart
    │   └── data/
    │       └── task_repository.dart
    └── vinyl/
        ├── presentation/
        │   ├── vinyl_player_widget.dart
        │   └── vinyl_controller.dart
        └── domain/
            └── track_model.dart