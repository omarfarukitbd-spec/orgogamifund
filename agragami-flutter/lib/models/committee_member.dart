/// কমিটির একজন — সভাপতি, সম্পাদক, কোষাধ্যক্ষ বা অন্য দায়িত্ব।
/// Firestore কালেকশন: committee
/// প্রত্যেকেই একজন সদস্যের সাথে যুক্ত থাকেন, যাতে নাম আর ফোন
/// সদস্যের রেকর্ড থেকে মেলানো যায়।
class CommitteeMember {
  final String id;
  final String memberId;
  final String designation;
  final String? branchId;
  final DateTime? termStart;
  final DateTime? termEnd;

  const CommitteeMember({
    required this.id,
    required this.memberId,
    required this.designation,
    this.branchId,
    this.termStart,
    this.termEnd,
  });

  factory CommitteeMember.fromMap(String id, Map<String, dynamic> data) {
    return CommitteeMember(
      id: id,
      memberId: (data['memberId'] as String?) ?? '',
      designation: (data['designation'] as String?) ?? '',
      branchId: data['branchId'] as String?,
      termStart: data['termStart'] == null
          ? null
          : DateTime.tryParse(data['termStart'] as String),
      termEnd: data['termEnd'] == null
          ? null
          : DateTime.tryParse(data['termEnd'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'designation': designation,
      'branchId': branchId,
      'termStart': termStart?.toIso8601String(),
      'termEnd': termEnd?.toIso8601String(),
    };
  }
}
