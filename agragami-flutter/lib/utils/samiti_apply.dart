/// সমিতিতে আবেদনের বোতাম দেখানো হবে কি না — খাঁটি ফাংশন,
/// যাতে টেস্ট করা যায় (Phase 7)।
///
/// অ্যাডমিনও সদস্য হতে পারে — অ্যাডমিন হওয়া আবেদনের বাধা
/// নয় (অনুমোদনে অ্যাডমিন রোল থাকেই — M10)। তাই বোতাম
/// লুকানো হয় শুধু দুই ক্ষেত্রে: ইতিমধ্যে অনুমোদিত সদস্য,
/// বা আবেদন প্রক্রিয়াধীন। নিয়মটা জমা-যাচাইয়ের (submit)
/// গার্ডের সাথে এক — ApplicationSubmitHandler একই দুই
/// অবস্থায় আবেদন ফেরায়।
bool shouldShowApplyButton({
  required bool isApprovedMember,
  required bool isPendingApplication,
}) {
  if (isApprovedMember) return false;
  if (isPendingApplication) return false;
  return true;
}
