/// খরচের ধরন — এই পাঁচটার বাইরে আর কিছু লেখা হয় না।
const List<String> expenseCategories = [
  'মাদ্রাসা উন্নয়ন',
  'সামাজিক কল্যাণ',
  'স্টেশনারি',
  'প্রশাসন',
  'জরুরি',
];

/// একটি খরচ।
/// Firestore কালেকশন: expenses
class Expense {
  final String id;
  final String branchId;
  final String category;
  final int amount;
  final DateTime date;
  final String description;
  final String? attachmentUrl;
  final String recordedBy;

  const Expense({
    required this.id,
    required this.branchId,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.attachmentUrl,
    required this.recordedBy,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      branchId: (data['branchId'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
      description: (data['description'] as String?) ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      recordedBy: (data['recordedBy'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'attachmentUrl': attachmentUrl,
      'recordedBy': recordedBy,
    };
  }
}
