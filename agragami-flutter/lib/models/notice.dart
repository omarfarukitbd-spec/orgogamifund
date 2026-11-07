/// একটি নোটিশ বা সভার কার্যবিবরণী।
/// Firestore কালেকশন: notices
enum NoticeScope { org, branch }

class Notice {
  final String id;
  final String title;
  final String body;
  final String? attachmentUrl;
  final NoticeScope scope;
  final String? branchId;
  final String postedBy;
  final DateTime postedAt;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    this.attachmentUrl,
    required this.scope,
    this.branchId,
    required this.postedBy,
    required this.postedAt,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> data) {
    return Notice(
      id: id,
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      scope: data['scope'] == 'branch' ? NoticeScope.branch : NoticeScope.org,
      branchId: data['branchId'] as String?,
      postedBy: (data['postedBy'] as String?) ?? '',
      postedAt:
          DateTime.tryParse((data['postedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'attachmentUrl': attachmentUrl,
      'scope': scope.name,
      'branchId': branchId,
      'postedBy': postedBy,
      'postedAt': postedAt.toIso8601String(),
    };
  }
}
