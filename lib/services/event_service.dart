import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/event_model.dart';

class EventService {
  Future<List<UniversityEvent>> fetchEvents() async {
    final response = await http.Client().get(Uri.parse('URL_ТВОГО_УНІВЕРСИТЕТУ/events'));
    
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      // Тут ми шукаємо елементи за CSS-селекторами, як у розкладі
      var eventElements = document.querySelectorAll('.event-card'); 

      return eventElements.map((element) {
        return UniversityEvent(
          title: element.querySelector('.title')?.text.trim() ?? 'Без назви',
          date: element.querySelector('.date')?.text.trim() ?? '',
          link: element.querySelector('a')?.attributes['href'] ?? '',
        );
      }).toList();
    } else {
      throw Exception('Не вдалося завантажити події');
    }
  }
}