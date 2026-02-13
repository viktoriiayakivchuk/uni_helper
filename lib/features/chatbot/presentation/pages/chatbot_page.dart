import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Модель для повідомлення в чаті
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _currentQuestions = [];
  
  bool _isLoading = true;
  bool _showingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Завантажуємо дані з Firebase
  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('chatbot_faq').get();
      _categories = snapshot.docs.map((doc) => doc.data()).toList();
      
      setState(() {
        _messages.add(ChatMessage(
          text: "Привіт! Я твій віртуальний помічник UniHelper 🤖\nОбери категорію, яка тебе цікавить, і я спробую допомогти:", 
          isUser: false
        ));
        _isLoading = false;
        _showingCategories = true;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Помилка завантаження даних. Перевірте інтернет.", isUser: false));
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Обробка кліку на категорію
  void _selectCategory(Map<String, dynamic> category) {
    setState(() {
      _messages.add(ChatMessage(text: category['category'], isUser: true));
      
      final questionsList = category['questions'] as List<dynamic>? ?? [];
      _currentQuestions = List<Map<String, dynamic>>.from(questionsList);
      
      _messages.add(ChatMessage(
        text: "Ось що зазвичай питають з теми «${category['category']}»:", 
        isUser: false
      ));
      
      _showingCategories = false;
    });
    _scrollToBottom();
  }

  // Обробка кліку на конкретне питання
  void _selectQuestion(Map<String, dynamic> question) {
    setState(() {
      _messages.add(ChatMessage(text: question['q'], isUser: true));
      _messages.add(ChatMessage(text: question['a'], isUser: false));
      
      // Повертаємо бота до початкового стану
      _messages.add(ChatMessage(
        text: "Чи можу я ще чимось допомогти? Обери іншу категорію:", 
        isUser: false
      ));
      
      _showingCategories = true;
      _currentQuestions = [];
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Щоб було видно градієнт з MainScreen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("UniHelper Bot", style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // Приховуємо кнопку назад, якщо вона з'являється
      ),
      body: Column(
        children: [
          // Список повідомлень чату
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildChatBubble(message);
                    },
                  ),
          ),
          
          // Панель з вибором дій (Quick Replies)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: _showingCategories ? _buildCategoryChoices() : _buildQuestionChoices(),
            ),
          ),
          const SizedBox(height: 80), // Відступ для BottomNavigationBar з MainScreen
        ],
      ),
    );
  }

  // Дизайн бульбашки повідомлення
  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF2D5A40) : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: !message.isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Кнопки вибору категорій
  Widget _buildCategoryChoices() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _categories.map((category) {
        return ActionChip(
          label: Text(category['category']),
          labelStyle: const TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.w600),
          backgroundColor: const Color(0xFFD9E8DD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          onPressed: () => _selectCategory(category),
        );
      }).toList(),
    );
  }

  // Кнопки вибору конкретних питань
  Widget _buildQuestionChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._currentQuestions.map((q) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A40),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => _selectQuestion(q),
              child: Text(q['q'], style: const TextStyle(fontSize: 14)),
            ),
          );
        }),
        // Кнопка "Назад до категорій"
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showingCategories = true;
              _currentQuestions = [];
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.black54),
          label: const Text("Назад до тем", style: TextStyle(color: Colors.black54)),
        )
      ],
    );
  }
}