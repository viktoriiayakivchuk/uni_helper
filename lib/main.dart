import 'package:flutter/material.dart';
import 'features/schedule/presentation/pages/pages/schedule_page.dart';

void main() => runApp(const UniHelperApp());

class UniHelperApp extends StatelessWidget {
  const UniHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniHelper',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        primaryColor: const Color(0xFF2D5A40),
      ),
      // Тепер головний екран викликається з окремого файлу
      home: const SchedulePage(),
    );
  }
}