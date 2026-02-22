import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:uni_helper/features/schedule/domain/lesson_model.dart'; // Можна використати ту саму модель або створити EventModel

class EventRepository {
  // Замініть на реальну адресу новин вашого універу
  final String eventsUrl = "https://pnu.edu.ua/category/events/"; 

  Future<List<Lesson>> fetchUniversityEvents() async {
    try {
      final response = await http.get(Uri.parse(eventsUrl));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        List<Lesson> events = [];

        // ТУТ МАГІЯ: Потрібно знайти теги на сайті. 
        // Припустимо, кожна новина лежить в <article class="post">
        var articles = document.querySelectorAll('article');

        for (var element in articles) {
          String title = element.querySelector('h2')?.text.trim() ?? "Подія";
          String desc = element.querySelector('.entry-content')?.text.trim() ?? "";
          String? link = element.querySelector('a')?.attributes['href'];
          
          // Створюємо об'єкт Lesson (або Event), щоб він відображався у календарі
          events.add(Lesson(
            id: title.hashCode.toString(),
            title: "📌 $title",
            description: "$desc\n\nПосилання: $link",
            startTime: DateTime.now(), // Тут треба буде парсити дату з сайту
            endTime: DateTime.now().add(const Duration(hours: 1)),
            type: LessonType.lecture,
            isUserCreated: false,
          ));
        }
        return events;
      }
    } catch (e) {
      print("Помилка парсингу подій: $e");
    }
    return [];
  }
}