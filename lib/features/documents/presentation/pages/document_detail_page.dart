import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io'; 
import 'package:path_provider/path_provider.dart'; 

class DocumentDetailPage extends StatefulWidget {
  final Map<String, dynamic> doc;

  const DocumentDetailPage({super.key, required this.doc});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  // Функція для копіювання тексту
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Текст скопійовано!'),
          backgroundColor: Color(0xFF1B3A29)),
    );
  }

  // Функція для перегляду PDF
  void _openPdfPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          assetPath: widget.doc['pdfPath'],
          title: widget.doc['title'],
        ),
      ),
    );
  }

  // Кросплатформна функція збереження
  Future<void> _savePdf(String assetPath, String fileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // Логіка для Web (за потреби реалізуємо через універсальний пакет)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Завантаження у браузері наразі обмежене')),
        );
      } else {
        // Логіка для Mobile (Android/iOS)
        final directory = await getApplicationDocumentsDirectory();
        final path = "${directory.path}/$fileName.pdf";
        final file = File(path);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл збережено у документи додатка'),
            backgroundColor: const Color(0xFF1B3A29),
          ),
        );
      }
    } catch (e) {
      debugPrint("Помилка завантаження: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.doc['title'],
            style: const TextStyle(
                color: Color(0xFF1B3A29), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A29)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doc['description'],
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                    label: const Text("ПЕРЕГЛЯНУТИ"),
                    onPressed: () => _openPdfPreview(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3A29),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download, color: Color(0xFF1B3A29)),
                    label: const Text("ЗБЕРЕГТИ"),
                    onPressed: () => _savePdf(
                        widget.doc['pdfPath'], widget.doc['title']),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1B3A29)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ТЕКСТОВА ВЕРСІЯ (ДЛЯ КОПІЮВАННЯ)",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.copy_all, color: Color(0xFF1B3A29)),
                  onPressed: () =>
                      _copyToClipboard(context, widget.doc['template']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5A40).withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: const Color(0xFF2D5A40).withOpacity(0.1)),
              ),
              child: SelectableText(widget.doc['template'],
                  style: const TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      ),
    );
  }
}

// ВІДЖЕТ ПЕРЕГЛЯДУ (ЯКИЙ БУВ ВІДСУТНІЙ)
class PdfPreviewScreen extends StatefulWidget {
  final String assetPath;
  final String title;

  const PdfPreviewScreen(
      {super.key, required this.assetPath, required this.title});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openAsset(widget.assetPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title), backgroundColor: const Color(0xFF1B3A29)),
      body: PdfView(controller: _pdfController),
    );
  }
}