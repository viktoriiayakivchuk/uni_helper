import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/contact_item.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String searchQuery = "";
  String selectedCategory = "Всі";
  final List<String> categories = ["Всі", "Адміністрація", "Кафедри", "Студсенат"];

  // Оновлений метод запуску дій (дзвінок/пошта)
  Future<void> _makeAction(String url) async {
    final Uri uri = Uri.parse(url);
    debugPrint("🚀 Спроба відкрити URL: $url"); 

    try {
      // Прямий запуск без canLaunchUrl, щоб уникнути багів емулятора
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showErrorSnackBar("Не вдалося знайти додаток для: $url");
      }
    } catch (e) {
      debugPrint("❌ Помилка url_launcher: $e");
      if (mounted) {
        _showErrorSnackBar("Помилка при відкритті додатка");
      }
    }
  }

  // Допоміжний метод для показу помилок користувачеві
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Контакти"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Рядок пошуку
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Пошук за назвою...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
          
          // Фільтр категорій (ChoiceChips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (bool selected) {
                    setState(() => selectedCategory = cat);
                  },
                ),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // Список контактів із Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('contacts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Помилка завантаження"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs
                    .map((doc) => ContactItem.fromFirestore(doc))
                    .where((item) {
                      final matchesSearch = item.title.toLowerCase().contains(searchQuery);
                      final matchesCat = selectedCategory == "Всі" || item.category == selectedCategory;
                      return matchesSearch && matchesCat;
                    }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text("Контактів не знайдено"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.business, color: Color(0xFF2D5A40)),
                        ),
                        title: Text(
                          item.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "${item.name ?? ''}\nКабінет: ${item.office}\n${item.phone}",
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Кнопка дзвінка
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk, color: Colors.green),
                              onPressed: () => _makeAction("tel:${item.phone}"),
                            ),
                            // Кнопка email
                            IconButton(
                              icon: const Icon(Icons.alternate_email, color: Colors.blue),
                              onPressed: () => _makeAction("mailto:${item.email}"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}