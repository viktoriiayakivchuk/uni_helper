import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DocumentDetailPage extends StatefulWidget {
  final Map<String, dynamic> doc;

  const DocumentDetailPage({super.key, required this.doc});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  // Копіювання тексту шаблону
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Текст скопійовано!'),
          backgroundColor: Color(0xFF1B3A29)),
    );
  }

  // Перегляд PDF через екран прев'ю
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

  // Збереження файлу у папку "Завантаження" (Downloads)
  Future<void> _savePdf(String assetPath, String fileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Завантаження у браузері обмежене')),
        );
      } else {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // Прямий шлях до папки завантажень Android
          downloadsDir = Directory('/storage/emulated/0/Download');
          
          // Якщо папка недоступна, використовуємо зовнішнє сховище додатка
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          // Для iOS використовуємо документи додатка
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        final savePath = "${downloadsDir?.path}/$fileName.pdf";
        final file = File(savePath);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Збережено у Завантаження: $fileName.pdf'),
              backgroundColor: const Color(0xFF1B3A29),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Помилка завантаження: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка при збереженні файлу')),
        );
      }
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