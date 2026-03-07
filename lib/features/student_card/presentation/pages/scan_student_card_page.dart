import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/student_card_extractor.dart';

class ScanStudentCardPage extends StatefulWidget {
  final Function(StudentCardData) onCardScanned;

  const ScanStudentCardPage({Key? key, required this.onCardScanned})
      : super(key: key);

  @override
  State<ScanStudentCardPage> createState() => _ScanStudentCardPageState();
}

class _ScanStudentCardPageState extends State<ScanStudentCardPage> {
  final StudentCardExtractor _extractor = StudentCardExtractor();
  bool _isProcessing = false;

  Future<void> _scanDocument() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Відкрити камеру
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );

      if (photo != null) {
        final imageFile = File(photo.path);

        // Показуємо діалог обробки
        _showProcessingDialog();

        // Покращуємо якість зображення
        final enhancedImage = await _extractor.enhanceImage(imageFile);

        // Витягуємо дані зі студентського
        final cardData =
            await _extractor.extractDataFromImage(enhancedImage);

        Navigator.pop(context); // Закрити діалог обробки

        if (cardData != null) {
          // Показуємо результати розпізнавання
          _showResultDialog(cardData, imageFile);
        } else {
          _showError(
            'Не вдалося розпізнати студентський квиток.\n'
            'Спробуйте ще раз з кращим освітленням та якістю.',
          );
        }
      }
    } catch (e) {
      Navigator.pop(context, null); // Закрити діалог якщо була помилка
      _showError('Помилка при сканування: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Обробка документа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF2D5A40)),
            SizedBox(height: 20),
            Text('Розпізнавання тексту...\nБудь ласка, зачекайте.'),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(StudentCardData cardData, File imageFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Результати сканування'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoField('Номер студентського:', cardData.cardNumber),
              const SizedBox(height: 12),
              _buildInfoField('ПІБ:', cardData.fullName),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[900], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Перевірте дані перед збереженням',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCardScanned(cardData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5A40),
              foregroundColor: Colors.white,
            ),
            child: const Text('Використати'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _extractor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканування студентського'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Заголовок
            Text(
              'Відсканіруйте студентський квиток',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Опис
            Text(
              'Камера автоматично розпізнає номер та ПІБ зі студентського квитка.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 40),

            // Інструкція
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поради для кращого результату:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Добре освітліть студентський квиток'),
                  _buildTip('Розмістіть квиток прямо перед камерою'),
                  _buildTip('Уникайте відблисків та тіней'),
                  _buildTip('Процес сканування автоматичний'),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Кнопка сканування
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _scanDocument,
                icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.camera),
                label: Text(
                  _isProcessing ? 'Обробка...' : 'Розпочати сканування',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.blue[900]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
