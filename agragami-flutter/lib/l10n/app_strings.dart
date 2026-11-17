/// অ্যাপের সব লেখা এখানে এক জায়গায়।
/// ডিফল্ট ভাষা বাংলা। ইংরেজি পরে যোগ হবে — কোনো লেখাই
/// এআই-এর মতো শোনায় এমনভাবে লেখা যাবে না, সহজ মানুষের ভাষায় লিখতে হবে।
class AppStrings {
  // সাধারণ
  static const String appName = 'অগ্রগামী ফান্ড';
  static const String appTagline = 'সমিতির হিসাব, এক জায়গায়';
  static const String halalNote = 'সম্পূর্ণ হালাল — সুদমুক্ত';

  // নেভিগেশন
  static const String navHome = 'হোম';
  static const String navSamiti = 'সমিতি';
  static const String navDeposit = 'জমা দিন';
  static const String navProfile = 'প্রোফাইল';
  static const String navDashboard = 'ড্যাশবোর্ড';
  static const String navMembers = 'সদস্য';
  static const String navAccounts = 'হিসাব';
  static const String navReports = 'রিপোর্ট';
  static const String navSettings = 'সেটিংস';
  static const String navApproval = 'অনুমোদন কেন্দ্র';
  static const String navPassbook = 'পাসবই';
  static const String navIdCard = 'আইডি কার্ড';
  static const String navExpenses = 'খরচ';
  static const String navLoans = 'ঋণ';
  static const String navPaymentMethods = 'পেমেন্ট মাধ্যম';
  static const String navNotices = 'নোটিশ';
  static const String navCommittee = 'কমিটি';

  // লগইন
  static const String loginTitle = 'অগ্রগামী ফান্ডে স্বাগতম';
  static const String loginSubtitle = 'আপনার অ্যাকাউন্টে ঢুকুন';
  static const String email = 'ইমেইল';
  static const String password = 'পাসওয়ার্ড';
  static const String confirmPassword = 'পাসওয়ার্ড আবার লিখুন';
  static const String loginButton = 'ঢুকুন';
  static const String loginWithGoogle = 'গুগল দিয়ে ঢুকুন';
  static const String googleCancelled = 'গুগল দিয়ে ঢোকা বাতিল করেছেন';
  static const String googleNotAvailable =
      'এই ফোনে গুগল দিয়ে ঢোকা এখনো চালু হয়নি — ইমেইল দিয়ে ঢুকুন';
  static const String googleAccountExistsDifferent =
      'এই ইমেইল দিয়ে ইমেইল-পাসওয়ার্ডের অ্যাকাউন্ট আছে — সেইভাবে ঢুকুন';
  static const String noAccount = 'অ্যাকাউন্ট নেই? সদস্য হতে আবেদন করুন';
  static const String firstSetupLink =
      'প্রথমবার অ্যাপ খুলছেন? অ্যাডমিন সেটআপ করুন';
  static const String loginWrong = 'ইমেইল বা পাসওয়ার্ড ভুল — আবার দেখুন';
  static const String loginNoNetwork = 'নেট নেই — নেট দেখে আবার চেষ্টা করুন';
  static const String loginTooMany =
      'অনেকবার ভুল হয়েছে — একটু পরে আবার চেষ্টা করুন';

  // প্রথম অ্যাডমিন সেটআপ (একবারই)
  static const String setupTitle = 'প্রথমবার সেটআপ';
  static const String setupSubtitle =
      'অ্যাপের প্রথম অ্যাডমিনের অ্যাকাউন্ট বানান। এটা শুধু একবারই করা যাবে — অ্যাডমিন তৈরি হলে এই পাতা আর খুলবে না।';
  static const String setupName = 'আপনার নাম';
  static const String setupButton = 'অ্যাডমিন অ্যাকাউন্ট বানান';
  static const String setupAlreadyExists =
      'অ্যাডমিন আগেই তৈরি হয়েছে — লগইন করুন';
  static const String setupDone = 'অ্যাডমিন অ্যাকাউন্ট তৈরি হয়েছে';

  // সাইন-আপ ও আবেদন
  static const String validEmail = 'সঠিক ইমেইল দিন';
  static const String passwordTooShort =
      'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
  static const String passwordsDontMatch = 'দুটো পাসওয়ার্ড মেলেনি';
  static const String emailInUse =
      'এই ইমেইল দিয়ে অ্যাকাউন্ট আছে — লগইন করুন';
  static const String applyAccountFailed =
      'অ্যাকাউন্ট খোলা যায়নি — ইমেইল আর পাসওয়ার্ড দেখে আবার চেষ্টা করুন';
  static const String applyFailedAfterAccount =
      'অ্যাকাউন্ট হয়েছে, কিন্তু আবেদন জমা হয়নি — লগইন করে আবার চেষ্টা করুন';

  // অনুমোদনের অপেক্ষা
  static const String pendingTitle = 'অনুমোদনের অপেক্ষায় আছেন';
  static const String pendingBody =
      'আপনার আবেদনটি অ্যাডমিন দেখছেন। অনুমোদন হলে জানিয়ে দেওয়া হবে।';
  static const String pendingCompleteApplication =
      'সদস্য হওয়ার আবেদন সম্পূর্ণ করুন';

  // হোম
  static const String totalFund = 'মোট তহবিল';
  static const String totalMembers = 'মোট সদস্য';
  static const String dueThisMonth = 'এই মাসে বকেয়া';
  static const String pendingApprovals = 'অনুমোদন বাকি';
  static const String pendingDeposits = 'জমা যাচাই বাকি';

  // সমিতি
  static const String samitiList = 'সমিতিসমূহ';
  static const String monthlyDonation = 'মাসিক দান';
  static const String createSamiti = 'নতুন সমিতি খুলুন';
  static const String samitiEmptyTitle = 'এখনো কোনো সমিতি তৈরি হয়নি';
  static const String samitiEmptyBody =
      'অ্যাডমিন নতুন সমিতি খুললে এখানে দেখা যাবে।';
  static const String samitiEmptyAdminBody =
      'প্রথম সমিতিটা খুলে শুরু করুন — নাম, উদ্দেশ্য আর মাসিক দান বসালেই হবে।';
  static const String samitiNameLabel = 'সমিতির নাম';
  static const String samitiPurposeLabel = 'সমিতির উদ্দেশ্য';
  static const String samitiDescriptionLabel = 'বিবরণ (ঐচ্ছিক)';
  static const String samitiCreated = 'সমিতি খোলা হয়েছে';
  static const String samitiCreateFailed =
      'সমিতি খোলা যায়নি — ইন্টারনেট দেখে আবার চেষ্টা করুন।';
  static const String memberCountLabel = 'সদস্য';
  static const String joinSamiti = 'সদস্য হতে আবেদন করুন';
  static const String alreadyMember = 'আপনি এই সমিতির সদস্য';
  static const String applicationPending =
      'এই সমিতিতে আপনার আবেদন বাকি আছে — অ্যাডমিন দেখছেন';
  static const String applicationRejected =
      'আপনার আবেদনটি বাতিল হয়েছে — আবার আবেদন করতে পারেন';
  static const String notMemberTitle =
      'এই সমিতির সদস্য না হলে তথ্য দেখা যাবে না';
  static const String notMemberBody =
      'কে সদস্য, কত টাকা আছে, কে জমা দিলো, কার বকেয়া আছে — এগুলো শুধু ওই সমিতির সদস্যরাই দেখতে পায়। সদস্য হতে আবেদন করুন, অ্যাডমিন অনুমোদন দিলে তবেই দেখা যাবে।';
  static const String notMemberAnyTitle = 'এখনো কোনো সমিতির সদস্য নন';
  static const String notMemberAnyBody =
      'সমিতির ভেতরের হিসাব দেখতে প্রথমে কোনো একটা সমিতির সদস্য হতে হবে। সমিতি দেখে আবেদন করুন।';
  static const String viewSamitis = 'সমিতিগুলো দেখুন';
  static const String alreadyAppliedForBranch =
      'এই সমিতিতে আপনার আবেদন বাকি আছে — অ্যাডমিন দেখছেন';
  static const String alreadyMemberOfBranch =
      'আপনি এই সমিতির সদস্য — আর আবেদন করতে হবে না';
  static const String lockedBranchNote =
      'এই সমিতির জন্যই আবেদন করছেন — সমিতি বদলানো যাবে না';
  static const String membersOnlyNote =
      'সদস্য হলে ভেতরের হিসাব — সদস্য তালিকা, মোট টাকা, জমার খাতা, বকেয়া — দেখা যাবে।';
  static const String recountMembers = 'সদস্য সংখ্যা আবার গুনুন';
  static const String recountDone = 'সদস্য সংখ্যা মিলিয়ে নেওয়া হয়েছে';
  static const String adminOnlyPage = 'এই পাতা শুধু অ্যাডমিন দেখতে পারেন';

  // জমা
  static const String depositTitle = 'জমা দিন';
  static const String depositAmount = 'টাকার পরিমাণ';
  static const String depositMonth = 'কোন মাসের জমা';
  static const String trxId = 'লেনদেন নম্বর (TrxID)';
  static const String depositSubmit = 'জমা দিন';
  static const String depositPending = 'যাচাইাধীন';
  static const String depositSent = 'জমা পাঠানো হয়েছে — যাচাইাধীন';
  static const String depositApproved = 'জমা অনুমোদন হয়েছে, রসিদ নম্বর বসেছে';

  // সদস্য হওয়ার আবেদন
  static const String applyTitle = 'সদস্য হওয়ার আবেদন';
  static const String applySent = 'আবেদন জমা হয়েছে — অ্যাডমিন দেখছেন';
  static const String applyApproved = 'সদস্য অনুমোদন হয়েছে';

  // পাসবই
  static const String passbookTitle = 'আমার পাসবই';
  static const String totalDeposit = 'মোট জমা';
  static const String dues = 'বকেয়া';
  static const String activeLoan = 'চলতি কর্জে হাসানা';
  static const String pendingDepositTotal = 'যাচাইাধীন জমা';
  static const String ledgerTitle = 'লেনদেনের খাতা';
  static const String filterAll = 'সকল';
  static const String filterApproved = 'অনুমোদিত';
  static const String filterPending = 'যাচাইাধীন';

  // আইডি কার্ড
  static const String idCardTitle = 'আমার আইডি কার্ড';
  static const String idCardPngFront = 'সামনের ছবি নামান (PNG)';
  static const String idCardPngBack = 'পেছনের ছবি নামান (PNG)';
  static const String idCardPdf = 'PDF হিসেবে নিন';

  // খরচ
  static const String expenseTitle = 'খরচের হিসাব';
  static const String addExpense = 'খরচ লিখুন';

  // কর্জে হাসানা ঋণ
  static const String loanTitle = 'কর্জে হাসানা ঋণ';
  static const String issueLoan = 'ঋণ দিন';
  static const String loanDetail = 'ঋণের বিস্তারিত';

  // রিপোর্ট
  static const String reportTitle = 'মাসিক রিপোর্ট';
  static const String defaulterTitle = 'বকেয়া সদস্য';

  // নোটিশ ও কমিটি
  static const String noticeTitle = 'নোটিশ বোর্ড';
  static const String committeeTitle = 'কমিটি';

  // সাধারণ বোতাম ও অবস্থা
  static const String approve = 'অনুমোদন করুন';
  static const String reject = 'বাতিল করুন';
  static const String save = 'সংরক্ষণ করুন';
  static const String cancel = 'বাতিল';
  static const String searchHint = 'নাম, ফোন বা সদস্য নম্বর লিখুন';
  static const String emptyTitle = 'এখানে এখনো কিছু নেই';
  static const String loading = 'আসছে…';
  static const String tryAgain = 'আবার চেষ্টা করুন';
}
