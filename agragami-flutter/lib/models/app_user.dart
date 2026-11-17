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
    return AppUser(
      id: id,
      email: (data['email'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.pending,
      ),
      branchId: data['branchId'] as String?,
      linkedMemberId: data['linkedMemberId'] as String?,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['approvalStatus'],
        orElse: () => ApprovalStatus.pending,
      ),
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
