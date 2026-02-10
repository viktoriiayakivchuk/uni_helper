import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/foundation.dart'; // Додано для debugPrint
import 'firebase_options.dart'; 
import 'features/navigation/presentation/pages/main_screen.dart';

// Імпорти твоїх сидерів
import 'package:uni_helper/features/glossary/data/glossary_seeder.dart';
import 'package:uni_helper/features/contacts/data/contacts_seeder.dart'; // Наш новий сидер

void main() async {
  // 1. Обов'язково ініціалізуємо зв'язок із нативною частиною
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Ініціалізація Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    
    debugPrint("Firebase ініціалізовано успішно!");

    // 3. НАПОВНЕННЯ БАЗИ ДАНИХ (SEEDING)
    // Розкоментуй ці рядки, запусти додаток один раз, і закоментуй назад.
    
    //await GlossarySeeder.seedDatabase(); 
    //await ContactsSeeder.seed(); // Виклик завантаження контактів у Firestore [cite: 112]

  } catch (e) {
    // Використовуємо debugPrint замість print для чистоти коду
    debugPrint("Помилка ініціалізації Firebase: $e");
  }

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
      home: const MainScreen(), // Головний екран навігації [cite: 149]
    );
  }
}