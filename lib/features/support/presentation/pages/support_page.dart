import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/motivation_data.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendAnonymousMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      // Відправка без збереження userID для анонімності [cite: 162]
      await FirebaseFirestore.instance.collection('anonymous_support').add({
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ваше повідомлення надіслано анонімно')),
        );
      }
    } catch (e) {
      debugPrint("Помилка відправки: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Підтримка та мотивація')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Поради проти вигорання", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
            const SizedBox(height: 10),
            ...MotivationData.burnoutPreventionTips.map((tip) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(tip['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tip['content']!),
                leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF2D5A40)),
              ),
            )),
            const SizedBox(height: 30),
            const Text("Анонімне звернення", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
            const Text("Опишіть вашу ситуацію психологу або куратору", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ваше повідомлення...',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendAnonymousMessage,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A40)),
                child: _isSending ? const CircularProgressIndicator() : const Text("Надіслати анонімно", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}