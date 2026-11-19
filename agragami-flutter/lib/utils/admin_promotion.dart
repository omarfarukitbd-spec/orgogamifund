import '../models/app_user.dart';

/// শাখা অ্যাডমিন বানানো/সরানোর বোতাম দেখাবে কি না — আর
/// দেখালে কোনটা। Phase 6: সিদ্ধান্তটা Firestore ছাড়া শুদ্ধ
/// ফাংশন, যাতে UI আর রিপোজিটরি দুই জায়গায় একই নিয়ম চলে
/// আর ইউনিট টেস্টে যাচাই করা যায় (test/phase6_test.dart)।
enum AdminRoleSectionState {
  /// "অ্যাডমিন বানান" বোতাম দেখানো হবে।
  promote,

  /// "অ্যাডমিন সরান" বোতাম দেখানো হবে।
  demote,

  /// অংশটাই দেখানো হবে না (নিজের অ্যাকাউন্ট, সুপার অ্যাডমিন)।
  hidden,

  /// বোতাম নয়, শুধু সৎ কারণসহ নোট দেখানো হবে।
  info,
}

class AdminRoleDecision {
  final AdminRoleSectionState state;

  /// [AdminRoleSectionState.info] হলে দেখানোর বাংলা নোট।
  final String? note;

  const AdminRoleDecision(this.state, [this.note]);
}

/// সদস্যের লগইন প্রোফাইল দেখে অ্যাডমিন-অংশের সিদ্ধান্ত।
/// [linkedUserId] সদস্য রেকর্ডের লিঙ্কড লগইন (null মানে
/// লগইন অ্যাকাউন্ট নেই), [targetUser] ওই লগইনের users
/// ডকুমেন্ট (null মানে ডকুমেন্ট পাওয়া যায়নি),
/// [currentUid] এখন ঢুকে থাকা সুপার অ্যাডমিনের uid,
/// [branchId] দেখা সমিতির id।
AdminRoleDecision decideAdminRoleAction({
  required String? linkedUserId,
  required AppUser? targetUser,
  required String currentUid,
  required String branchId,
}) {
  // সমিতিই জানা নেই (ত্রুটিপূর্ণ রেকর্ড) — আন্দাজে এগোনো হয় না।
  if (branchId.isEmpty) {
    return const AdminRoleDecision(
      AdminRoleSectionState.info,
      'এই সদস্যের সমিতি জানা নেই — সমিতি ঠিক করে আবার চেষ্টা করুন',
    );
  }
  // লগইন অ্যাকাউন্ট নেই — বোতাম নেই, শুধু কারণ জানানো হয়।
  if (linkedUserId == null || linkedUserId.isEmpty) {
    return const AdminRoleDecision(
      AdminRoleSectionState.info,
      'এই সদস্যের লগইন অ্যাকাউন্ট নেই — অ্যাডমিন বানাতে হলে '
      'আগে তাকে অ্যাপে অ্যাকাউন্ট খুলতে হবে',
    );
  }
  // লগইন আছে কিন্তু প্রোফাইল ডকুমেন্ট পাওয়া যায়নি —
  // আন্দাজে এগোনো হয় না।
  if (targetUser == null) {
    return const AdminRoleDecision(
      AdminRoleSectionState.info,
      'এই সদস্যের লগইন প্রোফাইল পাওয়া যায়নি — আবার চেষ্টা করুন',
    );
  }
  // নিজের অ্যাকাউন্ট — অংশটাই লুকানো থাকে।
  if (targetUser.id == currentUid) {
    return const AdminRoleDecision(AdminRoleSectionState.hidden);
  }
  // সুপার অ্যাডমিনের রোল অ্যাপ থেকে কখনো বদলানো হয় না।
  if (targetUser.role == UserRole.superAdmin) {
    return const AdminRoleDecision(AdminRoleSectionState.hidden);
  }
  // অনুমোদিত অ্যাকাউন্ট ছাড়া অ্যাডমিন বানানো যায় না।
  if (!targetUser.canEnter) {
    return const AdminRoleDecision(
      AdminRoleSectionState.info,
      'এই সদস্যের অ্যাকাউন্ট এখনো অনুমোদিত নয় — অনুমোদনের '
      'পর অ্যাডমিন বানানো যাবে',
    );
  }
  if (targetUser.role == UserRole.branchAdmin) {
    // এই সমিতির অ্যাডমিন — সরানোর বোতাম। branchId না থাকলে
    // (পুরোনো ডকুমেন্ট) সে কোনো সমিতিরই কার্যকর অ্যাডমিন নয়,
    // তবুও এখান থেকে সরানো যায়।
    if (targetUser.branchId == null || targetUser.branchId == branchId) {
      return const AdminRoleDecision(AdminRoleSectionState.demote);
    }
    // অন্য সমিতির অ্যাডমিন — চুপচাপ তার সমিতি বদলে দেওয়া
    // হয় না; ওই সমিতির পাতা থেকে সরাতে হয়।
    return const AdminRoleDecision(
      AdminRoleSectionState.info,
      'এই সদস্য অন্য একটি সমিতির অ্যাডমিন — সেখান থেকে সরাতে '
      'ওই সমিতির পাতায় যান',
    );
  }
  return const AdminRoleDecision(AdminRoleSectionState.promote);
}
