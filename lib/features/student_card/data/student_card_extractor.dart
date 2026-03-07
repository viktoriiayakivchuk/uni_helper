import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class StudentCardExtractor {
  static final textRecognizer = TextRecognizer();

  /// Витягти дані зі студентського квитка
  Future<StudentCardData?> extractDataFromImage(File imageFile) async {
    try {
      // Розпізнати текст на зображенні
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final text = recognizedText.text.toUpperCase();
      print('Розпізнаний текст: $text');

      // Витягти номер студентського
      // Формати: ФМ-2024-2024, ФМ 2024 2024, FM-2024-2024
      final cardNumberPattern = RegExp(r'[А-Я]{2}[-\s]?\d{3,4}[-\s]?\d{3,4}');
      final cardNumberMatch = cardNumberPattern.firstMatch(text);
      final cardNumber = cardNumberMatch?.group(0) ?? '';

      // Витягти ПІБ (вся назва до номера студентського)
      String fullName = '';
      if (cardNumberMatch != null) {
        final namePart = text.substring(0, cardNumberMatch.start).trim();
        // Очистити від сміття
        fullName = namePart
            .replaceAll(RegExp(r'\d+'), '') // Видалити цифри
            .replaceAll(RegExp(r'[^А-Яa-z\s]'), '') // Видалити спецсимволи
            .trim()
            .split('\n')
            .where((line) => line.isNotEmpty)
            .join(' ')
            .replaceAll(RegExp(r'\s+'), ' ');
      }

      // Якщо не знайшли ПІБ, спробуємо витягти перший рядок тексту
      if (fullName.isEmpty) {
        final lines = text.split('\n');
        for (var line in lines) {
          final cleaned = line
              .replaceAll(RegExp(r'\d+'), '')
              .replaceAll(RegExp(r'[^А-Яa-z\s]'), '')
              .trim();
          if (cleaned.length > 5) {
            fullName = cleaned;
            break;
          }
        }
      }

      // Перевіримо чи знайшли хоча б номер
      if (cardNumber.isEmpty) {
        print('❌ Не знайдено номер студентського');
        return null;
      }

      print('✅ Знайдено:');
      print('   Номер: $cardNumber');
      print('   ПІБ: ${fullName.isNotEmpty ? fullName : '(не розпізнано)'}');

      return StudentCardData(
        cardNumber: cardNumber.replaceAll(RegExp(r'\s'), '-'), // Нормалізувати
        fullName: fullName.isNotEmpty
            ? fullName
            : 'Студент ПНУ', // За замовчуванням
      );
    } catch (e) {
      print('❌ Помилка при витягуванні даних: $e');
      return null;
    }
  }

  /// Покращити якість зображення перед розпізнаванням
  Future<File> enhanceImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);

      if (image == null) {
        print('Неможливо декодувати зображення');
        return imageFile;
      }

      // Покращити контрастність
      var luminance = 1.2;
      image = img.adjustColor(image, saturation: 1.2);

      // Змінити розмір, якщо занадто великий
      if (image.width > 2000 || image.height > 2000) {
        image = img.copyResize(image,
            width: 2000, height: 2000, interpolation: img.Interpolation.linear);
      }

      // Зберегти в тимчасовий файл
      final enhancedFile = File('${imageFile.path}_enhanced.jpg');
      await enhancedFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      return enhancedFile;
    } catch (e) {
      print('Помилка при покращенні зображення: $e');
      return imageFile;
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}

class StudentCardData {
  final String cardNumber;
  final String fullName;

  StudentCardData({
    required this.cardNumber,
    required this.fullName,
  });
}
