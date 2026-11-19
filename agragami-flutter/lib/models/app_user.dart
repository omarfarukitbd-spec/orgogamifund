/// অ্যাপ ব্যবহারকারীর রোল।
/// Firestore-এর users কালেকশনের role ফিল্ডের সাথে মিলিয়ে রাখা হয়েছে।
enum UserRole { superAdmin, branchAdmin, member, pending }

enum ApprovalStatus { pending, approved, rejected }

class AppUser {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final String? branchId;
  final String? linkedMemberId;
  final ApprovalStatus approvalStatus;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.branchId,
    this.linkedMemberId,
    required this.approvalStatus,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final userEmail = (data['email'] as String?) ?? '';

    // রোল আর অনুমোদন আসে শুধু Firestore ডকুমেন্ট থেকে —
    // ইমেইল দেখে ক্লায়েন্ট কখনো রোল বদলায় না (M6)।
    // আগে এখানে hardcode করা ইমেইল দেখে superAdmin বসানো হতো,
    // যাতে Console থেকে রুট অ্যাকাউন্ট demote করাও যেত না।
    final rawRole = ((data['role'] as String?) ?? '').toLowerCase().replaceAll('_', '');
    final UserRole role;
    if (rawRole == 'superadmin') {
      role = UserRole.superAdmin;
    } else if (rawRole == 'branchadmin') {
      role = UserRole.branchAdmin;
    } else if (rawRole == 'member') {
      role = UserRole.member;
    } else {
      role = UserRole.pending;
    }

    final rawStatus = ((data['approvalStatus'] as String?) ?? '').toLowerCase().replaceAll('_', '');
    final ApprovalStatus approvalStatus;
    if (rawStatus == 'approved') {
      approvalStatus = ApprovalStatus.approved;
    } else if (rawStatus == 'rejected') {
      approvalStatus = ApprovalStatus.rejected;
    } else {
      approvalStatus = ApprovalStatus.pending;
    }

    return AppUser(
      id: id,
      email: userEmail,
      name: data['name'] as String?,
      role: role,
      branchId: data['branchId'] as String?,
      linkedMemberId: data['linkedMemberId'] as String?,
      approvalStatus: approvalStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'branchId': branchId,
      'linkedMemberId': linkedMemberId,
      'approvalStatus': approvalStatus.name,
    };
  }

  bool get isAdmin => role == UserRole.superAdmin || role == UserRole.branchAdmin;
  bool get canEnter => approvalStatus == ApprovalStatus.approved;
}
