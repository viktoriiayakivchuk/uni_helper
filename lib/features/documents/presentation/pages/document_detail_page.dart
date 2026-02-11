import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class DocumentDetailPage extends StatefulWidget {
  final Map<String, dynamic> doc;

  const DocumentDetailPage({super.key, required this.doc});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Текст скопійовано!'),
          backgroundColor: Color(0xFF1B3A29)),
    );
  }

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
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("ПОДИВИТИСЯ ЗРАЗОК З ФОРМАТУВАННЯМ"),
                onPressed: () => _openPdfPreview(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A29),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 35),
            const Text("ТЕКСТОВА ВЕРСІЯ (ДЛЯ КОПІЮВАННЯ)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5A40).withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: const Color(0xFF2D5A40).withOpacity(0.1)),
              ),
              child: SelectableText(widget.doc['template']),
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
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1B3A29),
      ),
      body: PdfView(
        controller: _pdfController,
      ),
    );
  }
}
