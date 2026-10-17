class UserModel {
  final String userId;
  final String email;
  final String role; // 'owner', 'tester', 'user'
  final String status; // 'active', 'revoked', 'pending'
  final String? createdBy;
  final DateTime createdAt;
  final bool agreementSigned;
  final String? agreementId;

  UserModel({
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.agreementSigned = false,
    this.agreementId,
  });

  // Convert from Firebase document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'pending',
      createdBy: map['createdBy'],
      createdAt: DateTime.parse(map['createdAt']),
      agreementSigned: map['agreementSigned'] ?? false,
      agreementId: map['agreementId'],
    );
  }

  // Convert to Firebase document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'agreementSigned': agreementSigned,
      'agreementId': agreementId,
    };
  }
}