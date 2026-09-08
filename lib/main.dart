import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/takt_theme.dart';
import 'features/desk/presentation/desk_canvas_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TaktApp()));
}

class TaktApp extends StatelessWidget {
  const TaktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Takt Desk',
      debugShowCheckedModeBanner: false,
      theme: TaktTheme.darkThemeData,
      home: const DeskCanvasScreen(),
    );
  }
}
