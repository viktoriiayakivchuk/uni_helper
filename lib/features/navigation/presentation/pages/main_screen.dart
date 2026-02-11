import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Твої існуючі імпорти (залишаємо без змін)
import '../../../schedule/presentation/pages/pages/schedule_page.dart';
import '../../../glossary/presentation/pages/glossary_page.dart';
import '../../../../screens/social_life_screen.dart';
import '../../../contacts/presentation/pages/contacts_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/complete_profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
        const SchedulePage(),
        const Center(child: Text('Чат-бот UniHelper\n(Ставимо запитання тут)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2D5A40)))),
        const GlossaryPage(),
        _buildProfileTab(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- РОЗУМНА ВКЛАДКА ПРОФІЛЮ З GLASS DESIGN ---
  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage(onLoginSuccess: () => setState(() {}));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return CompleteProfilePage(onSaved: () => setState(() {}));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        if (data['faculty'] == null || data['group'] == null) {
          return CompleteProfilePage(onSaved: () => setState(() {}));
        }

        // Повертаємо стилізований профіль
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Головна картка студента (Glassmorphism)
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF2D5A40),
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user.displayName ?? 'Студент ПНУ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
                        ),
                        const SizedBox(height: 5),
                        Text(user.email ?? '', style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Colors.white54),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat("КУРС", data['course'] ?? "-"),
                            _buildMiniStat("ГРУПА", data['group'] ?? "-"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Картка факультету
              _buildSimpleInfoCard(Icons.account_balance_rounded, "Факультет", data['faculty']),
              const SizedBox(height: 30),
              // Кнопка виходу
              _buildLogoutButton(),
              const SizedBox(height: 120), // Відступ від BottomNav
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
      ],
    );
  }

  Widget _buildSimpleInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2D5A40)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        setState(() {});
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      label: const Text("ВИЙТИ З АКАУНТА", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, // Контент заходить під прозорий BottomNav
      drawer: _buildSoftUIDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'UniHelper',
          style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D5A40)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D5A40)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Глобальний фон для всього екрану
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0F4F1), Color(0xFFD9E8DD)],
              ),
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- DRAWER (Твій оригінальний стиль, трохи підправлений під кольори) ---
  Widget _buildSoftUIDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF0F4F1),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2D5A40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('UniHelper', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Додаткові сервіси', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerItem(Icons.map_outlined, 'Карта університету', () => Navigator.pop(context)),
          _drawerItem(Icons.celebration_outlined, 'Соціальне життя', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialLifeScreen()));
          }),
          _drawerItem(Icons.assignment_turned_in_outlined, 'План адаптації', () => Navigator.pop(context)),
          _drawerItem(Icons.description_outlined, 'Путівник по документах', () => Navigator.pop(context)),
          _drawerItem(Icons.favorite_border, 'Підтримка та мотивація', () => Navigator.pop(context)),
          const Divider(),
          _drawerItem(Icons.link, 'Офіційні ресурси', () => Navigator.pop(context)),
          _drawerItem(Icons.contact_phone_outlined, 'Корисні контакти', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactsPage()));
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D5A40)),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white.withOpacity(0.3), // Прозорість для ефекту скла
              selectedItemColor: const Color(0xFF2D5A40),
              unselectedItemColor: Colors.black38,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Розклад'),
                BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Бот'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Словник'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профіль'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}