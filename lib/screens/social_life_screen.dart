import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_helper/screens/news_detail_screen.dart';
import 'package:uni_helper/features/glossary/data/pnu_event_repository.dart';
import 'package:uni_helper/features/schedule/domain/lesson_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLifeScreen extends StatefulWidget {
  final String userGroup; 
  const SocialLifeScreen({super.key, this.userGroup = "ІПЗ -33"});

  @override
  State<SocialLifeScreen> createState() => _SocialLifeScreenState();
}

class _SocialLifeScreenState extends State<SocialLifeScreen> {
  final PnuEventRepository _pnuRepository = PnuEventRepository();
  
  List<Lesson> _pnuNews = [];
  List<Lesson> _announcements = []; // Список для анонсів
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Завантаження новин та анонсів одночасно
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _pnuRepository.fetchPnuEvents(),
        _pnuRepository.fetchAnnouncements(), // Цей метод ми додали в репозиторій
      ]);
      
      if (mounted) {
        setState(() {
          _pnuNews = results[0];
          _announcements = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Помилка завантаження даних: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Кількість вкладок: Новини, Анонси, Група
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F2),
        appBar: AppBar(
          title: const Text('Соціальне життя', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF2D5A40),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            isScrollable: false, // Можна поставити true, якщо назви не вміщаються
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.article), text: "Новини"),
              Tab(icon: Icon(Icons.campaign), text: "Анонси"),
              Tab(icon: Icon(Icons.group), text: "Група"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDataTab(_pnuNews),       // Вкладка новин
            _buildDataTab(_announcements), // Вкладка анонсів
            _buildGroupTab(),              // Вкладка групи
          ],
        ),
      ),
    );
  }

  // Універсальний метод для побудови списків новин та анонсів
  Widget _buildDataTab(List<Lesson> dataList) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)));
    }
    
    if (dataList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const Text("Даних поки немає (потягніть, щоб оновити)"),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF2D5A40),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dataList.length,
        itemBuilder: (context, index) => _buildNewsCard(dataList[index]),
      ),
    );
  }

  // Вкладка групи з Firebase
  Widget _buildGroupTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('group', isEqualTo: widget.userGroup)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Помилка завантаження"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)));
        }

        final students = snapshot.data?.docs ?? [];

        if (students.isEmpty) {
          return Center(child: Text("У групі ${widget.userGroup} поки порожньо"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            
            String name = data['name'] ?? data['displayName'] ?? data['fullName'] ?? "";
            final String email = data['email'] ?? "";

            if (name.isEmpty && email.isNotEmpty) {
              name = email.split('@')[0];
            } else if (name.isEmpty) {
              name = "Студент";
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2D5A40),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?", 
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.email, color: Color(0xFF2D5A40)),
                  onPressed: () => _sendEmail(email),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Картка для відображення новини/анонсу
  Widget _buildNewsCard(Lesson news) {
    final parts = news.description.split('|');
    final String articleUrl = parts[0];
    final String imageUrl = parts.length > 1 ? parts[1] : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(url: articleUrl, title: news.title),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty && imageUrl.contains('http'))
              Image.network(
                imageUrl, 
                height: 180, 
                width: double.infinity, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder()
              )
            else
              _buildPlaceholder(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                news.title, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                maxLines: 2, 
                overflow: TextOverflow.ellipsis
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 150, 
      width: double.infinity, 
      color: const Color(0xFFE8F0EA),
      child: const Icon(Icons.newspaper, size: 60, color: Color(0xFF2D5A40))
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}