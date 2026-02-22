import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsDetailScreen extends StatefulWidget {
  final String url;
  final String title;

  const NewsDetailScreen({super.key, required this.url, required this.title});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Налаштування контролера WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Дозволяємо JS для роботи сайту
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF2D5A40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Сама веб-сторінка
          WebViewWidget(controller: _controller),
          
          // Індикатор прогресу завантаження
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              color: const Color(0xFF2D5A40),
              backgroundColor: Colors.white,
            ),
          
          // Центрований спіннер, поки сторінка зовсім порожня
          if (_isLoading && _progress < 0.1)
            const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A40))),
        ],
      ),
    );
  }
}