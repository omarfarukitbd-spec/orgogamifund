/// একজন ব্যবহারকারীর একটি সমিতির সদস্যপদ।
/// Firestore কালেকশন: memberships
/// ডকুমেন্টের id: `${userId}_${branchId}` — একজনের এক সমিতিতে
/// একটাই সদস্যপদ থাকে। সদস্যপদ সমিতি অনুযায়ী আলাদা: A সমিতির
/// অনুমোদন B সমিতির তথ্য খুলে দেয় না।
/// পুরোনো members ডকুমেন্ট (এক সদস্যপদে একটা) যেমন ছিল তেমনই
/// থাকে — সদস্যের নাম, ফোন, এনআইডি সেখানে; এখানে শুধু
/// কার কোন সমিতিতে ঢোকার অধিকার আছে, সেটা থাকে।
enum MembershipStatus { pending, approved, rejected }

class Membership {
  final String id;
  final String userId;
  final String branchId;
  final MembershipStatus status;
  final String? applicationId;
  final String? memberId;
  final String? memberNumber;
  final DateTime appliedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectReason;

  const Membership({
    required this.id,
    required this.userId,
    required this.branchId,
    this.status = MembershipStatus.pending,
    this.applicationId,
    this.memberId,
    this.memberNumber,
    required this.appliedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectReason,
  });

  /// ডকুমেন্ট id — userId আর branchId জুড়ে বানানো হয়।
  static String docId(String userId, String branchId) =>
      '${userId}_$branchId';

  factory Membership.fromMap(String id, Map<String, dynamic> data) {
    return Membership(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      status: MembershipStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MembershipStatus.pending,
      ),
      applicationId: data['applicationId'] as String?,
      memberId: data['memberId'] as String?,
      memberNumber: data['memberNumber'] as String?,
      appliedAt: DateTime.tryParse((data['appliedAt'] as String?) ?? '') ??
          DateTime.now(),
      approvedBy: data['approvedBy'] as String?,
      approvedAt: data['approvedAt'] == null
          ? null
          : DateTime.tryParse(data['approvedAt'] as String),
      rejectReason: data['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'branchId': branchId,
      'status': status.name,
      'applicationId': applicationId,
      'memberId': memberId,
      'memberNumber': memberNumber,
      'appliedAt': appliedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectReason': rejectReason,
    };
  }

  bool get isApproved => status == MembershipStatus.approved;
  bool get isPending => status == MembershipStatus.pending;
  bool get isRejected => status == MembershipStatus.rejected;
}

/// সদস্যপদের অবস্থার বাংলা নাম।
String membershipStatusText(MembershipStatus status) {
  switch (status) {
    case MembershipStatus.pending:
      return 'আবেদন বাকি আছে';
    case MembershipStatus.approved:
      return 'সদস্য';
    case MembershipStatus.rejected:
      return 'আবেদন বাতিল হয়েছে';
  }
}
