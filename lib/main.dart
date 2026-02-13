import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/foundation.dart'; 
import 'firebase_options.dart'; 
import 'features/navigation/presentation/pages/main_screen.dart';

// Імпорти сидерів
import 'features/social_life/data/events_seeder.dart'; 
import 'features/social_life/data/faq_seeder.dart'; // Додай цей рядок!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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