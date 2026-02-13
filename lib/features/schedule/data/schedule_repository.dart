import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:windows1251/windows1251.dart';
import 'package:intl/intl.dart';
import '../domain/lesson_model.dart';

class ScheduleRepository {
  final String baseUrl = 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi?n=700';

  Future<List<Lesson>> fetchSchedule(String groupName) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 120)); 
      
      final dateFormat = DateFormat('dd.MM.yyyy');
      final sdate = dateFormat.format(now);
      final edate = dateFormat.format(futureDate);

      print('📅 Запит розкладу для групи: "$groupName" на період $sdate - $edate');

      List<int> groupBytes = windows1251.encode(groupName);
      
      String encodedGroup = groupBytes.map((b) => '%${b.toRadixString(16).toUpperCase()}').join('');
      
      String body = "n=700"
          "&faculty=0"        
          "&course=0"         
          "&group=$encodedGroup"
          "&sdate=$sdate"
          "&edate=$edate"
          "&teacher=";

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': 'https://asu-srv.pnu.edu.ua/cgi-bin/timetable.cgi?n=700',
          'Origin': 'https://asu-srv.pnu.edu.ua',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: body,
      );

      if (response.statusCode == 200) {
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
    
    final dateRegExp = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})');

    for (var block in dayBlocks) {
      var header = block.querySelector('h4');
      if (header == null) continue;

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
  
Lesson _createLessonFromCell(Element cell, DateTime date, String startStr, String endStr) {
    String description = "";
    String title = "Пара";
    bool isRemote = false;

    if (cell.querySelector('.remote_work') != null || cell.text.contains('дист.')) {
      isRemote = true;
    }

    // --- ДОДАНО: Витягуємо посилання з HTML-тегів <a> ---
    List<String> extractedLinks = [];
    var aTags = cell.querySelectorAll('a');
    for (var a in aTags) {
      var href = a.attributes['href'];
      if (href != null && href.startsWith('http')) {
        extractedLinks.add(href);
      }
    }

    String cellHtml = cell.innerHtml.replaceAll('<br>', '\n').replaceAll('&nbsp;', ' ');
    String cellTextClean = parser.parse(cellHtml).documentElement!.text;
    List<String> lines = cellTextClean.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    String room = "";
    String teacher = "";
    String subjectCandidate = "";

    for (var line in lines) {
      // Ігноруємо непотрібний текст
      if (line.contains('дист.') || line == 'Link') continue;

      // --- ДОДАНО: Перевірка і додавання посилань, що залишились у тексті ---
      if (line.contains('http')) {
        // Відкидаємо три крапки для перевірки, якщо сайт скоротив лінк
        String cleanLine = line.replaceAll('...', '').trim();
        bool alreadyExtracted = extractedLinks.any((extractedLink) => extractedLink.contains(cleanLine));
        
        if (!alreadyExtracted) {
          extractedLinks.add(line);
        }
        continue;
      }

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
    
    // --- ДОДАНО: Додаємо всі знайдені посилання до опису ---
    for (var link in extractedLinks) {
      descParts.add("🔗 $link");
    }
    
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