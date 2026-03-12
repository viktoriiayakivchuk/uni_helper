import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../student_card/data/student_card_service.dart';
import 'student_card_display_page.dart';

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
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2D5A40)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (photo != null) setState(() => _selectedImage = File(photo.path));
    } catch (e) {
      _showError('Помилка при виборі фото: $e');
    }
  }

  Future<void> _saveStudentCard() async {
    if (_cardNumberController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _universityController.text.isEmpty ||
        _selectedImage == null) {
      _showError('Заповніть основні поля та виберіть фото');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'student_card_$_userId.jpg';
      final savedImageLocalPath = path.join(appDir.path, fileName);
      final File localImage = await _selectedImage!.copy(savedImageLocalPath);

      final studentCard = await _service.createStudentCard(
        cardNumber: _cardNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        university: _universityController.text.trim(),
        faculty: _facultyController.text.trim(),
        issueDate: _issueDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim(),
        photoUrl: localImage.path,
      );

      if (mounted) {
        widget.onCardAdded();
        _showSuccess('Студентський успішно збережено!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => StudentCardDisplayPage(studentCard: studentCard),
          ),
        );
      }
    } catch (e) {
      _showError('Помилка збереження: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _fullNameController.dispose();
    _universityController.dispose();
    _facultyController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додати квиток'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ПРЕВ'Ю ФОТО (ВИПРАВЛЕНО ДЛЯ ВЕРТИКАЛЬНИХ ФОТО)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8, // 80% ширини екрану
                height: 400, // Збільшена висота для вертикального квитка
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.2)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain, // Вписуємо без обрізки
                        ),
                      )
                    : InkWell(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('Додайте фото квитка', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A40),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A40),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),

            _buildFieldLabel('Повне ім\'я'),
            _buildTextField(_fullNameController, 'Прізвище Ім\'я По батькові'),

            _buildFieldLabel('Номер квитка'),
            _buildTextField(_cardNumberController, 'Наприклад: ВА15086858'),

            _buildFieldLabel('Навчальний заклад'),
            _buildTextField(_universityController, 'Наприклад: ПНУ ім. В. Стефаника'),

            _buildFieldLabel('Факультет'),
            _buildTextField(_facultyController, 'Наприклад: Факультет математики'),

            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Виданий'),
                      _buildDateField(_issueDateController),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Дійсний до'),
                      _buildDateField(_expiryDateController),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStudentCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ЗБЕРЕГТИ ЛОКАЛЬНО', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        hintText: 'дд.мм.рррр',
        prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2D5A40)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}