import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/services.dart';
import 'firebase_options.dart'; 
import 'features/navigation/presentation/pages/main_screen.dart';

// Імпорти сидерів
// Додай цей рядок!

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Налаштування Platform Channel для Widget
  const platform = MethodChannel('com.uni_helper/widget');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'updateWidget') {
      final Map<String, dynamic> args = call.arguments as Map<String, dynamic>;
      // Обробка оновлення Widget (якщо потрібна додаткова логіка)
      return true;
    } else if (call.method == 'clearWidget') {
      // Обробка очищення Widget
      return true;
    }
    return false;
  });
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    
    debugPrint("Firebase ініціалізовано успішно!");

    // --- SEEDING (Наповнення бази) ---
    // Розкоментуй ці рядки, запусти застосунок один раз, а потім закоментуй знову.
    
     //await EventsSeeder.seedEvents(); 
     //await FAQSeeder.seedFAQ(); // Тепер це спрацює без помилок
    
  } catch (e) {
    debugPrint("Помилка ініціалізації Firebase: $e");
  }

  await NotificationService().init();

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