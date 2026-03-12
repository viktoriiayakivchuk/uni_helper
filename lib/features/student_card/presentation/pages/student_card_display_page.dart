import 'package:flutter/material.dart';
import 'dart:io';
import '../../../student_card/domain/student_card.dart';
import '../../../student_card/data/student_card_service.dart';

class StudentCardDisplayPage extends StatefulWidget {
  final StudentCard studentCard;

  const StudentCardDisplayPage({
    super.key,
    required this.studentCard,
  });

  @override
  State<StudentCardDisplayPage> createState() => _StudentCardDisplayPageState();
}

class _StudentCardDisplayPageState extends State<StudentCardDisplayPage> {
  final StudentCardService _service = StudentCardService();
  bool _isLoading = false;

  Future<void> _deleteStudentCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Видалити студентський?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5A40),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ця дія видалить дані з пам\'яті пристрою',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
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
                      child: const Text('Видалити', style: TextStyle(color: Colors.white)),
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
      setState(() => _isLoading = true);
      try {
        await _service.deleteStudentCard(widget.studentCard.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Видалено успішно'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деталі квитка'),
        backgroundColor: const Color(0xFF2D5A40),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _deleteStudentCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото квитка
            Center(
              child: Container(
                width: double.infinity,
                height: 400, // Збільшена висота
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.studentCard.photoUrl),
                    fit: BoxFit.contain, // ПОВНЕ ВІДОБРАЖЕННЯ
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Основна інформація
            _buildSectionTitle('Особисті дані'),
            _buildInfoContainer([
              _buildInfoRow('ПІБ', widget.studentCard.fullName),
              _buildInfoRow('Номер квитка', widget.studentCard.cardNumber),
            ]),

            const SizedBox(height: 20),

            // Навчання
            _buildSectionTitle('Навчальний заклад'),
            _buildInfoContainer([
              _buildInfoRow('Університет', widget.studentCard.university),
              _buildInfoRow('Факультет', widget.studentCard.faculty),
            ]),

            const SizedBox(height: 20),

            // Дати
            _buildSectionTitle('Термін дії'),
            _buildInfoContainer([
              _buildInfoRow('Дата видачі', widget.studentCard.issueDate),
              _buildInfoRow('Дійсний до', widget.studentCard.expiryDate),
              _buildInfoRow('Додано в додаток', _formatDate(widget.studentCard.uploadedAt)),
            ]),

            const SizedBox(height: 30),

            // Короткий опис
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[900]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Цей цифровий документ доступний лише на вашому пристрої.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D5A40),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }
}