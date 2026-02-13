import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Виправлений імпорт згідно вашої структури
import 'package:uni_helper/features/glossary/domain/glossary_item.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key});

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  String selectedCategory = 'Всі';
  String searchQuery = '';
  final List<String> categories = [
  'Всі', 
  'Навчання', 
  'Адміністрація', 
  'Фінанси', 
  'Побут', 
  'Права', 
  'Наука'
];

  @override
  Widget build(BuildContext context) {
    // Базовий запит до Firestore
    Query query = FirebaseFirestore.instance.collection('glossary').orderBy('term');

    // Додаємо фільтр за категорією, якщо обрано не "Всі"
    if (selectedCategory != 'Всі') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Словник'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Поле пошуку (пункт 2.35 ТЗ)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Пошук терміну...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                ),
              ),
              // Фільтрація за категоріями (пункт 2.36 ТЗ)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (selected) {
                        if (selected) setState(() => selectedCategory = cat);
                      },
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("DEBUG_ERROR: ${snapshot.error}"); // Виведе помилку в консоль
            return Center(
              child: Text(
                'Помилка Firestore: ${snapshot.error}', 
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Локальна фільтрація для пошуку
          final docs = snapshot.data!.docs.where((doc) {
            final term = (doc.data() as Map<String, dynamic>)['term'].toString().toLowerCase();
            return term.contains(searchQuery);
          }).toList();

          if (docs.isEmpty) return const Center(child: Text('Нічого не знайдено'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = GlossaryItem.fromFirestore(docs[index].data() as Map<String, dynamic>);
              return ExpansionTile(
                title: Text(item.term, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.category, style: const TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(item.definition),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}