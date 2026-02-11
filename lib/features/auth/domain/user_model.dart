class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? faculty; // Може бути null при першому вході
  final String? group;   // Може бути null при першому вході
  final int? course;     // Може бути null при першому вході

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.faculty,
    this.group,
    this.course,
  });

  // Перетворюємо в Map для збереження у Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'faculty': faculty,
      'group': group,
      'course': course,
    };
  }

  // Створюємо об'єкт моделі з даних Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      faculty: map['faculty'],
      group: map['group'],
      course: map['course'],
    );
  }
}