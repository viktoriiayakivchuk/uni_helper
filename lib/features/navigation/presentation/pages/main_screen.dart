import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../schedule/presentation/pages/pages/schedule_page.dart';
import '../../../glossary/presentation/pages/glossary_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Оновлений список головних сторінок
  static final List<Widget> _pages = [
    const SchedulePage(), // Розклад
    const Center(child: Text('Чат-бот UniHelper\n(Ставимо запитання тут)', textAlign: TextAlign.center)), 
    const GlossaryPage(), // Словник
    const Center(child: Text('Профіль студента\n(Тут буде авторизація)', textAlign: TextAlign.center)),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      // Бічна панель (Drawer) для додаткових розділів
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
          icon: const Icon(Icons.menu, color: Color(0xFF2D5A40)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D5A40)),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Бічне меню (Drawer) - перенесли сюди Карту та Соц. життя
  Widget _buildSoftUIDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF0F4F1),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2D5A40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'UniHelper',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Додаткові сервіси',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.map_outlined, 'Карта університету'),
          _drawerItem(Icons.celebration_outlined, 'Соціальне життя'),
          _drawerItem(Icons.assignment_turned_in_outlined, 'План адаптації'),
          _drawerItem(Icons.description_outlined, 'Путівник по документах'),
          _drawerItem(Icons.favorite_border, 'Підтримка та мотивація'),
          const Divider(),
          _drawerItem(Icons.link, 'Офіційні ресурси'),
          _drawerItem(Icons.contact_phone_outlined, 'Корисні контакти'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D5A40)),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D5A40))),
      onTap: () {
        Navigator.pop(context);
        // Тут буде логіка переходу на відповідні сторінки
      },
    );
  }

  // Нижня панель навігації (замість Життя -> Профіль, замість Карти -> Бот)
  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white.withOpacity(0.7),
              selectedItemColor: const Color(0xFF2D5A40),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Розклад'),
                BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Бот'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Словник'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профіль'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}