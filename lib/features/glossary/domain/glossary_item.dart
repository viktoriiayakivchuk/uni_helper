class GlossaryItem {
  final String term;
  final String definition;
  final String category; 

  GlossaryItem({
    required this.term, 
    required this.definition,
    this.category = 'Загальне', 
  });
}