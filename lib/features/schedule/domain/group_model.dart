class Faculty {
  final String name;
  final String id;

  Faculty({required this.name, required this.id});
  
  // Важливо для правильної роботи Dropdown
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Faculty && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Group {
  final String name;
  final String id;

  Group({required this.name, required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}