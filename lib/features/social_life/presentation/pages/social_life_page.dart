import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Переконайся, що цей пакет додано у pubspec.yaml
import '../../domain/event_item.dart';

class SocialLifePage extends StatelessWidget {
  const SocialLifePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Соціальне життя"),
          backgroundColor: const Color(0xFF2D5A40),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Події"),
              Tab(text: "FAQ / Клуби"),
              Tab(text: "Група"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EventsTab(),
            OrganizationsTab(),
            MyGroupTab(),
          ],
        ),
      ),
    );
  }
}

// --- Вкладка 1: АНОНСИ ПОДІЙ ---
class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final events = snapshot.data!.docs.map((doc) => EventItem.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.celebration, color: Color(0xFF2D5A40)),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${DateFormat('dd.MM HH:mm').format(e.date)} • ${e.location}"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(e.title),
                      content: Text(e.description),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Закрити"))],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- Вкладка 2: FAQ ПО КЛУБАХ ---
class OrganizationsTab extends StatelessWidget {
  const OrganizationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('organizations_faq').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline, color: Colors.orange),
                title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(doc['description']),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// --- Вкладка 3: МОЯ ГРУПА ТА КУРАТОР (ОНОВЛЕНО) ---
class MyGroupTab extends StatelessWidget {
  const MyGroupTab({super.key});

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String myGroup = data?['group'] ?? "Не вказано";

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF2D5A40).withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xFF2D5A40)),
                  const SizedBox(width: 10),
                  Text("Група: $myGroup", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('group', isEqualTo: myGroup)
                    .snapshots(),
                builder: (context, groupSnapshot) {
                  if (!groupSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final members = groupSnapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final member = members[i].data() as Map<String, dynamic>;
                      final String memberEmail = member['email'] ?? "";
                      final bool isMe = member['uid'] == user?.uid;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMe ? const Color(0xFF2D5A40) : Colors.grey[200],
                            child: Icon(isMe ? Icons.star : Icons.person, 
                                        color: isMe ? Colors.white : Colors.grey[600]),
                          ),
                          // Використовуємо fullName як у Firebase
                          title: Text(member['fullName'] ?? "Студент", 
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(memberEmail),
                          trailing: !isMe && memberEmail.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.alternate_email, color: Color(0xFF2D5A40)),
                                onPressed: () => _sendEmail(memberEmail),
                              )
                            : (isMe ? const Text("Ви", style: TextStyle(color: Colors.grey)) : null),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}