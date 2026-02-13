import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:windows1251/windows1251.dart';
import 'package:intl/intl.dart';
import '../domain/lesson_model.dart';

class ScheduleRepository {
  // Базовий URL з параметром n=700 (як у формі на сайті)
  final String baseUrl = 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi?n=700';

  // ВАЖЛИВО: Тепер цей метод очікує НАЗВУ групи (напр. "ІПЗ-33"), а не ID
  Future<List<Lesson>> fetchSchedule(String groupName) async {
    try {
      final now = DateTime.now();
      // Завантажуємо розклад на весь семестр (120 днів)
      final futureDate = now.add(const Duration(days: 120)); 
      
      final dateFormat = DateFormat('dd.MM.yyyy');
      final sdate = dateFormat.format(now);
      final edate = dateFormat.format(futureDate);

      print('📅 Запит розкладу для групи: "$groupName" на період $sdate - $edate');

      // 1. КОДУВАННЯ НАЗВИ ГРУПИ (UTF-8 -> Windows-1251)
      // Це найважливіший крок. Сервер не розуміє UTF-8.
      List<int> groupBytes = windows1251.encode(groupName);
      
      // Перетворюємо байти у формат %XX (URL-encoded)
      String encodedGroup = groupBytes.map((b) => '%${b.toRadixString(16).toUpperCase()}').join('');
      
      // 2. ФОРМУВАННЯ ТІЛА ЗАПИТУ (Raw String)
      // Формуємо рядок вручну, щоб контролювати кодування
      String body = "n=700"
          "&faculty=0"         // "Оберіть факультет" (0 - щоб шукати скрізь)
          "&course=0"          // "Оберіть курс"
          "&group=$encodedGroup" // Наша закодована назва
          "&sdate=$sdate"
          "&edate=$edate"
          "&teacher=";

      // 3. ВІДПРАВКА POST ЗАПИТУ
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          // Referer обов'язковий, бо сервер перевіряє, чи прийшли ми з його сайту
          'Referer': 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi?n=700',
          'Origin': 'https://asu-srv.pnu.edu.ua',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Декодуємо відповідь (вона теж у Windows-1251)
        String htmlBody = windows1251.decode(response.bodyBytes);
        return _parseHtml(htmlBody);
      } else {
        throw Exception('Помилка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching schedule: $e");
      rethrow;
    }
  }

  List<Lesson> _parseHtml(String html) {
    var document = parser.parse(html);
    List<Lesson> lessons = [];

    var dayBlocks = document.querySelectorAll('div.col-md-6');
    
    // Регулярка для пошуку дати (напр. 12.02.2024)
    final dateRegExp = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})');

    for (var block in dayBlocks) {
      var header = block.querySelector('h4');
      if (header == null) continue;

      // Шукаємо дату в заголовку (ігноруємо назву дня тижня)
      final match = dateRegExp.firstMatch(header.text.trim());
      if (match == null) continue;

      String rawDate = match.group(0)!; 
      DateTime? date = _parseDate(rawDate);
      if (date == null) continue;

      var rows = block.querySelectorAll('tr');
      for (var row in rows) {
        var cells = row.querySelectorAll('td');
        
        if (cells.length >= 3) {
          var contentCell = cells[2];
          if (contentCell.text.trim().isNotEmpty) {
            var timeCell = cells[1];
            
            String timeHtml = timeCell.innerHtml;
            List<String> times = timeHtml.replaceAll('<br>', '-').split('-');
            
            if (times.length >= 2) {
              String startStr = times[0].trim();
              String endStr = times[1].trim();
              
              lessons.add(_createLessonFromCell(contentCell, date, startStr, endStr));
            }
          }
        }
      }
    }
    
    print("✅ Успішно завантажено: ${lessons.length} пар");
    return lessons;
  }

  // --- (Решта методів без змін: _createLessonFromCell, _parseDate, _looksLikeTeacher) ---
  // Скопіюйте їх зі старого файлу або з попередніх повідомлень
  
  Lesson _createLessonFromCell(Element cell, DateTime date, String startStr, String endStr) {
    String description = "";
    String title = "Пара";
    bool isRemote = false;

    if (cell.querySelector('.remote_work') != null || cell.text.contains('дист.')) {
      isRemote = true;
    }

    String cellHtml = cell.innerHtml.replaceAll('<br>', '\n').replaceAll('&nbsp;', ' ');
    String cellTextClean = parser.parse(cellHtml).documentElement!.text;
    List<String> lines = cellTextClean.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    String room = "";
    String teacher = "";
    String subjectCandidate = "";

    for (var line in lines) {
      if (line.contains('дист.') || line == 'Link' || line.contains('http')) continue;

      if (line.toLowerCase().contains('ауд.')) {
        room = line;
      } else if (_looksLikeTeacher(line)) {
        teacher = line;
      } else if (!line.toLowerCase().contains('збірна група') && !line.toLowerCase().contains('потік')) {
        if (line.length > subjectCandidate.length) {
          subjectCandidate = line;
        }
      }
    }
    
    if (subjectCandidate.isNotEmpty) title = subjectCandidate;
    
    List<String> descParts = [];
    if (isRemote) descParts.add("💻 Онлайн");
    if (room.isNotEmpty) descParts.add("📍 $room");
    if (teacher.isNotEmpty) descParts.add("👨‍🏫 $teacher");
    
    description = descParts.join('\n');

    LessonType type = LessonType.practice;
    if (title.toLowerCase().contains('(л)')) type = LessonType.lecture;
    if (title.toLowerCase().contains('(лаб)')) type = LessonType.lab;
    if (title.toLowerCase().contains('екз') || title.toLowerCase().contains('консульт')) type = LessonType.exam;

    final startParts = startStr.split(':').map(int.parse).toList();
    final endParts = endStr.split(':').map(int.parse).toList();

    return Lesson(
      id: "${date.millisecondsSinceEpoch}_$startStr",
      title: title,
      description: description,
      startTime: DateTime(date.year, date.month, date.day, startParts[0], startParts[1]),
      endTime: DateTime(date.year, date.month, date.day, endParts[0], endParts[1]),
      type: type,
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('.'); 
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return null;
    }
  }

  bool _looksLikeTeacher(String text) {
    return text.contains('.') && text.length < 35 && text[0].toUpperCase() == text[0];
  }
}