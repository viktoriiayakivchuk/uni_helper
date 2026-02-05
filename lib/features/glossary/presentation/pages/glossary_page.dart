import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/glossary_item.dart';

class GlossaryPage extends StatelessWidget {
  const GlossaryPage({super.key});

  static final List<GlossaryItem> _items = [
    GlossaryItem(term: 'ECTS', definition: 'Європейська система перенесення і накопичення кредитів.'),
    GlossaryItem(term: 'Деканат', definition: 'Адміністративний центр управління факультетом.'),
    GlossaryItem(term: 'Академічна різниця', definition: 'Кількість предметів, які відрізняються в навчальних планах.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Словничок термінів', style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25), // Наш стандарт Soft UI
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              title: Text(_items[index].term, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
              subtitle: Text(_items[index].definition),
            ),
          );
        },
      ),
    );
  }
}