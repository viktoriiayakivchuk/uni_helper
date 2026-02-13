import 'package:cloud_firestore/cloud_firestore.dart';

class FAQSeeder {
  static Future<void> seedFAQ() async {
    final collection = FirebaseFirestore.instance.collection('organizations_faq');
    
    final faqData = [
      {
        "id": "stud_senat",
        "title": "Студентський сенат",
        "description": "Це орган студентського самоврядування. Вони захищають права студентів, допомагають із поселенням у гуртожитки та організовують дозвілля.",
        "link": "https://t.me/senat_knuvs"
      },
      {
        "id": "scientific_society",
        "title": "Наукове товариство",
        "description": "Для тих, хто цікавиться дослідженнями. Організовують конференції, дебатні турніри та допомагають із написанням тез.",
        "link": ""
      },
      {
        "id": "sport_club",
        "title": "Спортивні секції",
        "description": "Університет має секції з футболу, волейболу та настільного тенісу. Запис проводиться на кафедрі фізвиховання у перші два тижні вересня.",
        "link": ""
      }
    ];

    for (var item in faqData) {
      await collection.doc(item['id'] as String).set(item);
    }
    print("✅ FAQ по організаціях завантажено!");
  }
}