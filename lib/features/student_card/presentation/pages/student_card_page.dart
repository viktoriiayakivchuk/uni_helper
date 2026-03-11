import 'package:flutter/material.dart';
import '../../../student_card/domain/student_card.dart';
import '../../../student_card/data/student_card_service.dart';
import 'add_student_card_page.dart';
import 'student_card_display_page.dart';

class StudentCardPage extends StatefulWidget {
  const StudentCardPage({super.key});

  @override
  State<StudentCardPage> createState() => _StudentCardPageState();
}

class _StudentCardPageState extends State<StudentCardPage> {
  final StudentCardService _service = StudentCardService();

  void _refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Студентський'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<StudentCard?>(
        stream: _service.watchStudentCard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D5A40),
              ),
            );
          }

          final studentCard = snapshot.data;

          if (studentCard == null) {
            // Студентський не додано - показуємо пропозицію додати
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2D5A40).withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 64,
                        color: Color(0xFF2D5A40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Студентського не додано',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Додайте фото вашого студентського квитка, щоб йма можна було показувати охоронцю при вході',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddStudentCardPage(
                              onCardAdded: _refreshPage,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Додати студентський'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5A40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Показуємо існуючий студентський
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudentCardDisplayPage(
                    studentCard: studentCard,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  _refreshPage();
                }
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Превю студентського
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        studentCard.photoUrl,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 48),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Інформація
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A40).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2D5A40).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Номер:', studentCard.cardNumber),
                        const SizedBox(height: 12),
                        _buildDetailRow('ПІБ:', studentCard.fullName),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Статус:',
                          studentCard.isVerified ? '✓ Перевірено' : 'На перевірці',
                          valueColor: studentCard.isVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Підказка
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.blue[900],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Натисніть, щоб розглянути студентський у повному форматі',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Кнопка для додавання нового
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddStudentCardPage(
                              onCardAdded: _refreshPage,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Додати іншу карточку'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
