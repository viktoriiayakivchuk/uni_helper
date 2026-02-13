import 'package:flutter/material.dart';
import 'package:uni_helper/features/documents/data/documents_data.dart';
import 'document_detail_page.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Отримуємо список документів із нашого дата-файлу
    final allDocs = DocumentsData.universityDocuments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Путівник по документах',
          style: TextStyle(
            color: Color(0xFF1B3A29),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A29)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 10, 25, 20),
              child: Text(
                'Оберіть документ, щоб переглянути інструкцію та зразок заяви',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allDocs.length,
                itemBuilder: (context, index) {
                  final doc = allDocs[index];
                  return _buildDocumentCard(context, doc);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Map<String, dynamic> doc) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailPage(doc: doc),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // Напівпрозорий зелений фон згідно з вашим стилем
          color: const Color(0xFF2D5A40).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Круглий індикатор з іконкою документа
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFF1B3A29),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A29),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF1B3A29),
            ),
          ],
        ),
      ),
    );
  }
}
