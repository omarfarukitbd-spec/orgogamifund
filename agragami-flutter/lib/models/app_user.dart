/// অ্যাপ ব্যবহারকারীর রোল।
/// Firestore-এর users কালেকশনের role ফিল্ডের সাথে মিলিয়ে রাখা হয়েছে।
enum UserRole { superAdmin, branchAdmin, member, pending }

enum ApprovalStatus { pending, approved, rejected }

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String? branchId;
  final String? linkedMemberId;
  final ApprovalStatus approvalStatus;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.branchId,
    this.linkedMemberId,
    required this.approvalStatus,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final userEmail = (data['email'] as String?) ?? '';
    final isRootAdmin = userEmail.toLowerCase() == 'omarfaruktitbd@gmail.com' ||
        userEmail.toLowerCase() == 'omarfarukitbd@gmail.com';

    final rawRole = ((data['role'] as String?) ?? '').toLowerCase().replaceAll('_', '');
    final UserRole role;
    if (isRootAdmin || rawRole == 'superadmin') {
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
    if (isRootAdmin || rawStatus == 'approved') {
      approvalStatus = ApprovalStatus.approved;
    } else if (rawStatus == 'rejected') {
      approvalStatus = ApprovalStatus.rejected;
    } else {
      approvalStatus = ApprovalStatus.pending;
    }

    return AppUser(
      id: id,
      email: userEmail,
      role: role,
      branchId: data['branchId'] as String?,
      linkedMemberId: data['linkedMemberId'] as String?,
      approvalStatus: approvalStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.name,
      'branchId': branchId,
      'linkedMemberId': linkedMemberId,
      'approvalStatus': approvalStatus.name,
    };
  }

  bool get isAdmin => role == UserRole.superAdmin || role == UserRole.branchAdmin;
  bool get canEnter => approvalStatus == ApprovalStatus.approved;
}
