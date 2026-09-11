import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/takt_theme.dart';
import 'app/theme/theme_controller.dart';
import 'features/opening/presentation/takt_opening_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TaktApp()));
}

class TaktApp extends ConsumerWidget {
  const TaktApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(chassisThemeProvider);
    return MaterialApp(
      title: 'Takt Desk',
      debugShowCheckedModeBanner: false,
      theme: theme.isDarkMode ? TaktTheme.darkThemeData : TaktTheme.lightThemeData,
      home: const TaktOpeningScreen(),
    );
  }
}
