import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'features/navigation/presentation/pages/main_screen.dart';
import 'package:uni_helper/features/glossary/data/glossary_seeder.dart';

void main() async {
  // 1. Обов'язково ініціалізуємо зв'язок із нативною частиною
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Встановлюємо тайм-аут для ініціалізації, щоб не чекати вічно
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    
    print("Firebase ініціалізовано успішно!");
  } catch (e) {
    // Якщо Firebase не зміг завантажитись, ми все одно запускаємо додаток,
    // але виводимо помилку в консоль
    print("Помилка ініціалізації Firebase: $e");
  }
  //await GlossarySeeder.seedDatabase();

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A40),
          primary: const Color(0xFF2D5A40),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MainScreen(),
    );
  }
} 