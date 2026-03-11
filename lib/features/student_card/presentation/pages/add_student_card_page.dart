import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../student_card/data/student_card_service.dart';
import '../../../student_card/data/student_card_extractor.dart';
import 'student_card_display_page.dart';
import 'scan_student_card_page.dart';

class AddStudentCardPage extends StatefulWidget {
  final VoidCallback onCardAdded;

  const AddStudentCardPage({super.key, required this.onCardAdded});

  @override
  State<AddStudentCardPage> createState() => _AddStudentCardPageState();
}

class _AddStudentCardPageState extends State<AddStudentCardPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final StudentCardService _service = StudentCardService();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _scanWithCamera() async {
    final result = await Navigator.of(context).push<StudentCardData>(
      MaterialPageRoute(
        builder: (context) => ScanStudentCardPage(
          onCardScanned: (cardData) {
            Navigator.pop(context, cardData);
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _cardNumberController.text = result.cardNumber;
        _fullNameController.text = result.fullName;
      });
      _showSuccess('✅ Дані розпізнані! Тепер виберіть фото студентського.');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Помилка при доступі до камери: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Помилка при доступі до галереї: $e');
    }
  }

  Future<void> _saveStudentCard() async {
    if (_cardNumberController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _selectedImage == null) {
      _showError('Заповніть всі поля та виберіть фото');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Завантажуємо фото
      final photoUrl = await _service.uploadStudentCardPhoto(_selectedImage!);

      // Створюємо студентський квиток
      final studentCard = await _service.createStudentCard(
        cardNumber: _cardNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        photoUrl: photoUrl,
      );

      if (mounted) {
        widget.onCardAdded();
        _showSuccess('Студентський успішно додано!');

        // Переходимо на сторінку перегляду
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    StudentCardDisplayPage(studentCard: studentCard),
              ),
            );
          }
        });
      }
    } catch (e) {
      _showError('Помилка: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додати студентський'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото студентського
            Center(
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2D5A40), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Немає фото',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Кнопки для вибору фото
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Кнопка розумного сканування
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanWithCamera,
                icon: const Icon(Icons.document_scanner),
                label: const Text('🤖 Розумне сканування'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D5A40),
                  side: const BorderSide(
                    color: Color(0xFF2D5A40),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Номер студентського
            Text(
              'Номер студентського',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                hintText: 'Наприклад: ФМ-2024-2024',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ПІБ студента
            Text(
              'Ваше ПІБ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: 'Ваше повне ім\'я',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Кнопка збереження
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStudentCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Додати студентський',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
