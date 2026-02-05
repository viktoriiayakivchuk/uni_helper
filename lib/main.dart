import 'package:flutter/material.dart';
import 'features/navigation/presentation/pages/main_screen.dart';

void universityHelper() {
  runApp(const UniHelperApp());
}

// Якщо ваша точка входу називається main, використовуйте її:
void main() {
  runApp(const UniHelperApp());
}

class UniHelperApp extends StatelessWidget {
  const UniHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniHelper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Основний колір проєкту #2D5A40
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A40),
          primary: const Color(0xFF2D5A40),
        ),
        useMaterial3: true,
        // Налаштування шрифтів та загального стилю
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Світлий фон для Soft UI
      ),
      // Встановлюємо MainScreen як головну точку входу
      home: const MainScreen(),
    );
  }
}