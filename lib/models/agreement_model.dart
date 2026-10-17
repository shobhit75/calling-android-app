class AgreementModel {
  final String agreementId;
  final String ownerId;
  final String testerId;
  final String status; // 'active', 'withdrawn', 'pending'
  final DateTime? signedAt;
  final DateTime? withdrawnAt;
  final String? documentUrl;
  final String? ipAddress;
  final String? digitalSignature;

  AgreementModel({
    required this.agreementId,
    required this.ownerId,
    required this.testerId,
    required this.status,
    this.signedAt,
    this.withdrawnAt,
    this.documentUrl,
    this.ipAddress,
    this.digitalSignature,
  });

  factory AgreementModel.fromMap(Map<String, dynamic> map, String id) {
    return AgreementModel(
      agreementId: id,
      ownerId: map['ownerId'] ?? '',
      testerId: map['testerId'] ?? '',
      status: map['status'] ?? 'pending',
      signedAt: map['signedAt'] != null ? DateTime.parse(map['signedAt']) : null,
      withdrawnAt: map['withdrawnAt'] != null ? DateTime.parse(map['withdrawnAt']) : null,
      documentUrl: map['documentUrl'],
      ipAddress: map['ipAddress'],
      digitalSignature: map['digitalSignature'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'testerId': testerId,
      'status': status,
      'signedAt': signedAt?.toIso8601String(),
      'withdrawnAt': withdrawnAt?.toIso8601String(),
      'documentUrl': documentUrl,
      'ipAddress': ipAddress,
      'digitalSignature': digitalSignature,
    };
  }
}