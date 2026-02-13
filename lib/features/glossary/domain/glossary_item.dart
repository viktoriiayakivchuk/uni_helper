class GlossaryItem {
  final String term;
  final String definition;
  final String category; // Додаємо поле категорії

  GlossaryItem({
    required this.term, 
    required this.definition, 
    required this.category
  });

  factory GlossaryItem.fromFirestore(Map<String, dynamic> data) {
    return GlossaryItem(
      term: data['term'] ?? '',
      definition: data['definition'] ?? '',
      category: data['category'] ?? 'Загальне', // Значення за замовчуванням
    );
  }
}