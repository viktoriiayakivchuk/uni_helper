import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:windows1251/windows1251.dart';
import 'package:intl/intl.dart';
import '../domain/lesson_model.dart';

class ScheduleRepository {
  // Базовий URL скрипта
  final String baseUrl = 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi';

  // Метод приймає ID групи (наприклад "-4636")
  Future<List<Lesson>> fetchSchedule(String groupId) async {
    try {
      // 1. Формуємо дати: від сьогодні до +30 днів
      // ВАЖЛИВО: Якщо зараз канікули, можна поставити хардкод дати для тесту, 
      // але для релізу залишаємо DateTime.now()
      final now = DateTime.now();
      // final now = DateTime(2026, 2, 12); // Розкоментуйте, якщо хочете тестувати 2026 рік
      
      final futureDate = now.add(const Duration(days: 30)); 
      
      final dateFormat = DateFormat('dd.MM.yyyy');
      final sdate = dateFormat.format(now);
      final edate = dateFormat.format(futureDate);

      // 2. Формуємо URL для GET запиту (це те, що спрацювало в тесті)
      // n=700 - це стандартний ID для ПНУ (схоже на потік або факультет)
      final String url = '$baseUrl?n=700&group=$groupId&sdate=$sdate&edate=$edate';
      
      print('Завантаження: $url');

      // 3. Виконуємо запит
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        // 4. Декодуємо Windows-1251
        String htmlBody = windows1251.decode(response.bodyBytes);
        
        // 5. Парсимо
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

    for (var block in dayBlocks) {
      // Заголовок дати
      var header = block.querySelector('h4');
      if (header == null) continue;

      String rawDate = header.text.trim().split(' ')[0]; 
      DateTime? date = _parseDate(rawDate);
      if (date == null) continue;

      var rows = block.querySelectorAll('tr');
      for (var row in rows) {
        var cells = row.querySelectorAll('td');
        
        // Перевірка на наявність пари
        if (cells.length >= 3) {
          var contentCell = cells[2];
          if (contentCell.text.trim().isNotEmpty) {
            var timeCell = cells[1];
            
            // Час: "09:00<br>10:20" -> "09:00", "10:20"
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
    return lessons;
  }

  Lesson _createLessonFromCell(Element cell, DateTime date, String startStr, String endStr) {
    // Витягуємо дані з HTML комірки
    String description = "";
    String title = "Пара";
    bool isRemote = false;

    if (cell.querySelector('.remote_work') != null || cell.text.contains('дист.')) {
      isRemote = true;
    }

    // Чистимо текст
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
    if (title.toLowerCase().contains('екз')) type = LessonType.exam;

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