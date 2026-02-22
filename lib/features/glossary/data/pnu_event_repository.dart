import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:uni_helper/features/schedule/domain/lesson_model.dart';

class PnuEventRepository {
  final String baseUrl = "https://cnu.edu.ua";

  // --- МЕТОД ДЛЯ НОВИН ---
  Future<List<Lesson>> fetchPnuEvents() async {
    return _fetchFromSource(onlyMainContent: true, prefix: "news");
  }

  // --- МЕТОД ДЛЯ АНОНСІВ ---
  Future<List<Lesson>> fetchAnnouncements() async {
    return _fetchFromSource(onlyMainContent: false, prefix: "anon");
  }

  Future<List<Lesson>> _fetchFromSource({required bool onlyMainContent, required String prefix}) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var links = document.querySelectorAll('a[href*="/2025/"], a[href*="/2026/"]');
        
        List<Lesson> results = [];
        final Set<String> seenUrls = {};

        for (var link in links) {
          String? url = link.attributes['href'];
          if (url == null || seenUrls.contains(url)) continue;

          // ПЕРЕВІРКА: Де лежить це посилання?
          bool isInsideSidebar = _checkIfSidebar(link);

          // Якщо шукаємо НОВИНИ — беремо тільки те, що НЕ в сайдбарі
          // Якщо шукаємо АНОНСИ — беремо тільки те, що В САЙДБАРІ
          if (onlyMainContent == isInsideSidebar) continue;

          String title = link.text.trim();
          if (title.length < 20) continue;

          String imageUrl = _extractImageUrl(link);

          seenUrls.add(url);
          results.add(Lesson(
            id: "${prefix}_${url.hashCode}",
            title: title,
            description: "$url|$imageUrl",
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            type: LessonType.lecture,
            isUserCreated: false,
          ));

          if (results.length >= 10) break;
        }
        return results;
      }
    } catch (e) {
      debugPrint("❌ [REPO] Помилка $prefix: $e");
    }
    return [];
  }

  // Функція перевірки: Чи є батьківський елемент "віджетом" або "сайдбаром"
  bool _checkIfSidebar(dom.Element element) {
    dom.Element? parent = element.parent;
    for (int i = 0; i < 8; i++) { // Перевіряємо 8 рівнів вгору
      if (parent == null) break;
      
      String classes = parent.className.toLowerCase();
      // Типові класи для анонсів та бокових колонок на сайті ПНУ
      if (classes.contains('sidebar') || 
          classes.contains('widget') || 
          classes.contains('rpwe-li') || 
          classes.contains('elementor-widget-container')) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  String _extractImageUrl(dom.Element element) {
    dom.Element? current = element;
    for (int i = 0; i < 4; i++) {
      if (current == null) break;
      var img = current.querySelector('img');
      if (img != null) {
        String? src = img.attributes['src'] ?? img.attributes['data-src'];
        if (src != null && src.isNotEmpty) {
          if (src.startsWith('//')) return "https:$src";
          if (src.startsWith('/')) return "$baseUrl$src";
          return src;
        }
      }
      current = current.parent;
    }
    return "";
  }
}