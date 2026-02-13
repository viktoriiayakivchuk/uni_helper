import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('chatbot_faq').get();
      _categories = snapshot.docs.map((doc) => doc.data()).toList();
      
      setState(() {
        _messages.add(ChatMessage(
          text: "Привіт! Я твій віртуальний помічник UniHelper 🤖\nОбери категорію:", 
          isUser: false
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Помилка завантаження даних.", isUser: false));
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

  void _selectCategory(Map<String, dynamic> category) {
    setState(() {
      _messages.add(ChatMessage(text: category['category'], isUser: true));
      final questionsList = category['questions'] as List<dynamic>? ?? [];
      _currentQuestions = List<Map<String, dynamic>>.from(questionsList);
      _messages.add(ChatMessage(
        text: "Ось питання з теми «${category['category']}»:", 
        isUser: false
      ));
      _showingCategories = false;
    });
    _scrollToBottom();
  }

  void _selectQuestion(Map<String, dynamic> question) {
    setState(() {
      _messages.add(ChatMessage(text: question['q'], isUser: true));
      _messages.add(ChatMessage(text: question['a'], isUser: false));
      _messages.add(ChatMessage(
        text: "Ще щось цікавить? Обери тему:", 
        isUser: false
      ));
      _showingCategories = true;
      _currentQuestions = [];
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(left: 16, right: 16, top: topPadding + 20, bottom: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
                  ),
          ),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16), 
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35, 
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _showingCategories ? _buildCategoryChoices() : _buildQuestionChoices(),
                    ),
                  ),
                ),
                SizedBox(height: 70 + bottomPadding), 
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _categories.map((category) {
        return ActionChip(
          label: Text(category['category']),
          labelStyle: const TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.w600, fontSize: 13),
          backgroundColor: const Color(0xFFD9E8DD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          side: BorderSide.none,
          onPressed: () => _selectCategory(category),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionChoices() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._currentQuestions.map((q) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A40),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => _selectQuestion(q),
              child: Text(q['q'], style: const TextStyle(fontSize: 13)),
            ),
          );
        }),
        TextButton(
          onPressed: () => setState(() => _showingCategories = true),
          child: const Text("Назад до тем", style: TextStyle(color: Colors.black54, fontSize: 12)),
        )
      ],
    );
  }
}