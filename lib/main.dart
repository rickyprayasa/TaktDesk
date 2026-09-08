import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: TaktApp()));
}

class TaktApp extends StatelessWidget {
  const TaktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Takt Desk',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF141517),
        body: Center(
          child: Text(
            'TAKT DESK',
            style: TextStyle(color: Color(0xFFEFECE6), letterSpacing: 4.0),
          ),
        ),
      ),
    );
  }
}
