class StudentCard {
  final String id;
  final String userId;
  final String cardNumber;
  final String fullName;
  final String photoUrl; // URL фото студентського у Firebase Storage
  final DateTime uploadedAt;
  final bool isVerified; // Чи був відпрацьований адміністратором

  StudentCard({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.fullName,
    required this.photoUrl,
    required this.uploadedAt,
    this.isVerified = false,
  });

  // Конвертація з Firestore
  factory StudentCard.fromFirestore(Map<String, dynamic> data, String docId) {
    return StudentCard(
      id: docId,
      userId: data['userId'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as DateTime?) ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  // Конвертація в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cardNumber': cardNumber,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'uploadedAt': uploadedAt,
      'isVerified': isVerified,
    };
  }
}
