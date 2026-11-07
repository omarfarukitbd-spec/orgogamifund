/// টাকা জমা দেওয়ার মাধ্যম — অ্যাডমিন নিজে যোগ করেন।
/// Firestore কালেকশন: paymentMethods
/// কোডে কোনো নম্বর লেখা থাকে না — সব মাধ্যম এখান থেকে আসে।
/// অ্যাডমিন যেকোনো সময় নতুন মাধ্যম যোগ করতে পারেন,
/// পুরোনোটা বদলাতে বা বন্ধ করতে পারেন। বন্ধ করলেও
/// আগের জমার হিসাব মুছে না — জমার সাথে মাধ্যমের
/// নাম-নম্বরের ছাপ (snapshot) লেখা থাকে।
enum PaymentMethodType { mobileBanking, bank, cash }

class PaymentMethodConfig {
  final String id;
  final String name;
  final PaymentMethodType type;
  final String accountNumber;
  final String accountHolderName;
  final String? branchId;
  final bool isActive;
  final int sortOrder;
  final String? instructions;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentMethodConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    required this.accountHolderName,
    this.branchId,
    this.isActive = true,
    this.sortOrder = 0,
    this.instructions,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// ধরনের নাম — সদস্য আর অ্যাডমিনের স্ক্রিনে দেখানো হয়।
  String get typeLabel => switch (type) {
        PaymentMethodType.mobileBanking => 'মোবাইল ব্যাংকিং',
        PaymentMethodType.bank => 'ব্যাংক',
        PaymentMethodType.cash => 'নগদ টাকা',
      };

  factory PaymentMethodConfig.fromMap(String id, Map<String, dynamic> data) {
    return PaymentMethodConfig(
      id: id,
      name: (data['name'] as String?) ?? '',
      type: PaymentMethodType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => PaymentMethodType.mobileBanking,
      ),
      accountNumber: (data['accountNumber'] as String?) ?? '',
      accountHolderName: (data['accountHolderName'] as String?) ?? '',
      branchId: data['branchId'] as String?,
      isActive: (data['isActive'] as bool?) ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      instructions: data['instructions'] as String?,
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
              DateTime.now(),
      updatedAt: DateTime.tryParse((data['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'branchId': branchId,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'instructions': instructions,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
