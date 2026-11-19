// শাখা-ভিত্তিক স্কোপের শেয়ার্ড নিয়ম — খাঁটি ফাংশন,
// যাতে টেস্ট করা যায় (Phase 8, G3/G4/G5)।
//
// ভুলটা ছিল: অনেক জায়গায় `isAdmin` গ্লোবাল ধরা হতো
// (সব সমিতির অ্যাডমিন), অথচ rules শাখা-ভিত্তিক। এখন
// স্কোপের নিয়ম এক জায়গায় — খরচ, ঋণ, রিপোর্ট, হোম,
// জমা, নোটিশ-বেল — সব জায়গায় একই ফাংশন চলে।

/// দেখার মতো সমিতিগুলোর id।
///
/// - সুপার অ্যাডমিন → null (সব সমিতি — ফিল্টার নেই)।
/// - শাখা অ্যাডমিন → {অ্যাডমিন-সমিতি} ∪ অনুমোদিত সদস্যপদ।
/// - সাধারণ সদস্য → শুধু অনুমোদিত সদস্যপদ।
///
/// শাখা অ্যাডমিনের `adminBranchId` খালি হলে সেটা যোগ হয়
/// না — স্কোপ তখন শুধু অনুমোদিত সদস্যপদ। খালি তালিকা
/// মানে দেখার মতো কোনো সমিতি নেই (null মানে সব — দুটো
/// আলাদা জিনিস)।
List<String>? scopedBranchIds({
  required bool isSuperAdmin,
  required bool isBranchAdmin,
  required String? adminBranchId,
  required List<String> approvedIds,
}) {
  if (isSuperAdmin) return null;
  if (!isBranchAdmin) return approvedIds;
  final ids = <String>{...approvedIds};
  if (adminBranchId != null && adminBranchId.isNotEmpty) {
    ids.add(adminBranchId);
  }
  return ids.toList();
}

/// এই সমিতির অ্যাডমিন কি না — শাখা-ভিত্তিক পরীক্ষা
/// (G1/G3)। সুপার অ্যাডমিন সব সমিতির অ্যাডমিন; শাখা
/// অ্যাডমিন শুধু নিজের সমিতির।
bool isAdminForBranch({
  required bool isSuperAdmin,
  required bool isBranchAdmin,
  required String? adminBranchId,
  required String branchId,
}) {
  if (isSuperAdmin) return true;
  if (!isBranchAdmin) return false;
  return adminBranchId != null && adminBranchId == branchId;
}
