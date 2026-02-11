import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  // Функція для відкриття посилань (п. 131 ТЗ) [cite: 131]
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Не вдалося відкрити $urlString');
      }
    } catch (e) {
      debugPrint('Помилка при переході: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Ресурси КНУВС', // Оновлена назва університету
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Глобальний фон (п. 132 ТЗ) [cite: 132]
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D5A40), Color(0xFF1B3A29)],
              ),
            ),
          ),
          SafeArea(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildResourceCard(
                  title: 'АСУ КНУВС',
                  subtitle: 'Інформаційна система',
                  icon: Icons.account_tree_rounded,
                  url: 'https://asu.pnu.edu.ua/',
                ),
                _buildResourceCard(
                  title: 'Розклад',
                  subtitle: 'Графік занять',
                  icon: Icons.calendar_month_rounded,
                  url: 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi',
                ),
                _buildResourceCard(
                  title: 'Журнал', // Оновлено зі "Списки груп" на "Журнал"
                  subtitle: 'Списки студентів',
                  icon: Icons.menu_book_rounded,
                  url: 'https://asu-srv.pnu.edu.ua/cgi-bin/classman.cgi?n=999&t=98',
                ),
                _buildResourceCard(
                  title: 'd-Learn',
                  subtitle: 'Дистанційне навчання',
                  icon: Icons.school_rounded,
                  url: 'https://d-learn.pnu.edu.ua/',
                ),
                _buildResourceCard(
                  title: 'Classroom',
                  subtitle: 'Google сервіс',
                  icon: Icons.cast_for_education_rounded,
                  url: 'https://classroom.google.com/',
                ),
                _buildResourceCard(
                  title: 'Сайт університету',
                  subtitle: 'Офіційні новини',
                  icon: Icons.language_rounded,
                  url: 'https://pnu.edu.ua/',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}