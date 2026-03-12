import 'package:flutter/material.dart';
import 'dart:io';
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

  Future<void> _confirmDelete(StudentCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 20),
              const Text(
                'Видалити студентський?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ні'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Так, видалити', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _service.deleteStudentCard(card.id);
      _refreshPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Світлий фон всієї сторінки
      appBar: AppBar(
        title: const Text('Студентський квиток'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<StudentCard?>(
        stream: _service.watchStudentCard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)));
          }

          final studentCard = snapshot.data;

          if (studentCard == null) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ПРЕВ'Ю КАРТКИ (Оптимізовано для вертикальних фото)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudentCardDisplayPage(studentCard: studentCard),
                      ),
                    ).then((_) => _refreshPage());
                  },
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 480), // Збільшена висота
                      decoration: BoxDecoration(
                        color: Colors.white, // Білий або дуже світлий фон
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(studentCard.photoUrl),
                          fit: BoxFit.contain, // Не обрізаємо краї
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ІНФОРМАЦІЯ
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("Дані документа", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('ПІБ:', studentCard.fullName),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _buildDetailRow('Номер:', studentCard.cardNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ПІДКАЗКА
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_in, size: 20, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        "Натисніть на фото для повного екрану",
                        style: TextStyle(fontSize: 13, color: Colors.blue[800], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // КНОПКА ВИДАЛЕННЯ
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _confirmDelete(studentCard),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text('Видалити документ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_card_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text('Студентський не додано', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AddStudentCardPage(onCardAdded: _refreshPage)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ДОДАТИ ЗАРАЗ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
      ],
    );
  }
}