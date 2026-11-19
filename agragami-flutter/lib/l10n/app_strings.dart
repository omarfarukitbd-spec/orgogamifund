import 'package:flutter/material.dart';

/// অগ্রগামী ফান্ডের সম্পূর্ণ দ্বিভাষিক টেক্সট রিসোর্স (বাংলা ও ইংরেজি)
class AppStrings {
  static Locale currentLocale = const Locale('bn', 'BD');
  static bool get isBangla => currentLocale.languageCode == 'bn';

  static String _s(String bn, String en) => isBangla ? bn : en;

  // ভাষা — নাম সবসময় নিজের ভাষায় দেখানো হয়, যাতে
  // ভাষা বদলানোর বোতাম সবাই চিনতে পারে।
  static String get bangla => 'বাংলা';
  static String get english => 'English';

  // সাধারণ
  static String get appName => _s('অগ্রগামী ফান্ড', 'Ogrogami Fund');
  static String get appTagline =>
      _s('সমিতির হিসাব, এক জায়গায়', 'Somithi Accounting, in One Place');
  static String get halalNote =>
      _s('সম্পূর্ণ হালাল — সুদমুক্ত', '100% Halal - Interest Free');

  // নেভিগেশন
  static String get navHome => _s('হোম', 'Home');
  static String get navSamiti => _s('সমিতি', 'Somithi');
  static String get navDeposit => _s('জমা দিন', 'Deposit');
  static String get navProfile => _s('প্রোফাইল', 'Profile');
  static String get navDashboard => _s('ড্যাশবোর্ড', 'Dashboard');
  static String get navMembers => _s('সদস্য', 'Members');
  static String get navAccounts => _s('হিসাব', 'Accounts');
  static String get navReports => _s('রিপোর্ট', 'Reports');
  static String get navSettings => _s('সেটিংস', 'Settings');
  static String get navApproval => _s('অনুমোদন কেন্দ্র', 'Approval Center');
  static String get navPassbook => _s('পাসবই', 'Passbook');
  static String get navIdCard => _s('আইডি কার্ড', 'ID Card');
  static String get navExpenses => _s('খরচ', 'Expenses');
  static String get navLoans => _s('ঋণ', 'Loans');
  static String get navPaymentMethods =>
      _s('পেমেন্ট মাধ্যম', 'Payment Methods');
  static String get navNotices => _s('নোটিশ', 'Notices');
  static String get navCommittee => _s('কমিটি', 'Committee');

  // লগইন
  static String get loginTitle =>
      _s('অগ্রগামী ফান্ডে স্বাগতম', 'Welcome to Ogrogami Fund');
  static String get loginSubtitle =>
      _s('আপনার অ্যাকাউন্টে ঢুকুন', 'Sign in to your account');
  static String get email => _s('ইমেইল', 'Email');
  static String get password => _s('পাসওয়ার্ড', 'Password');
  static String get confirmPassword =>
      _s('পাসওয়ার্ড আবার লিখুন', 'Confirm Password');
  static String get loginButton => _s('ঢুকুন', 'Sign In');
  static String get logout => _s('লগআউট', 'Sign Out');
  static String get loginWithGoogle =>
      _s('গুগল দিয়ে ঢুকুন', 'Sign in with Google');
  static String get googleCancelled =>
      _s('গুগল দিয়ে ঢোকা বাতিল করেছেন', 'Google Sign-in cancelled');
  static String get googleNotAvailable => _s(
      'এই ফোনে গুগল দিয়ে ঢোকা এখনো চালু হয়নি — ইমেইল দিয়ে ঢুকুন',
      'Google Sign-in unavailable on this device - use Email');
  static String get googleAccountExistsDifferent => _s(
      'এই ইমেইল দিয়ে ইমেইল-পাসওয়ার্ডের অ্যাকাউন্ট আছে — সেইভাবে ঢুকুন',
      'An account exists with this email - please sign in with password');
  static String get noAccount => _s('অ্যাকাউন্ট নেই? সদস্য হতে আবেদন করুন',
      'No account? Apply for membership');
  static String get firstSetupLink => _s(
      'প্রথমবার অ্যাপ খুলছেন? অ্যাডমিন সেটআপ করুন', 'First time? Setup Admin');
  static String get loginWrong =>
      _s('ইমেইল বা পাসওয়ার্ড ভুল — আবার দেখুন', 'Invalid email or password');
  static String get loginNoNetwork =>
      _s('নেট নেই — নেট দেখে আবার চেষ্টা করুন', 'No internet connection');
  static String get loginTooMany => _s(
      'অনেকবার ভুল হয়েছে — একটু পরে আবার চেষ্টা করুন',
      'Too many attempts - please try later');
  static String get forgotPassword =>
      _s('পাসওয়ার্ড ভুলে গেছেন?', 'Forgot password?');
  static String get resetLinkSent => _s(
      'পাসওয়ার্ড রিসেটের লিংক ইমেইলে পাঠানো হয়েছে',
      'Password reset link sent to your email');
  static String get resetLinkEnterEmail => _s(
      'রিসেট লিংক পাঠাতে আগে সঠিক ইমেইল লিখুন',
      'Enter a valid email first to receive a reset link');

  // প্রথম অ্যাডমিন সেটআপ
  static String get setupTitle => _s('প্রথমবার সেটআপ', 'Initial Setup');
  static String get setupSubtitle => _s(
      'অ্যাপের প্রথম অ্যাডমিনের অ্যাকাউন্ট বানান।',
      'Create the first Super Admin account.');
  static String get setupName => _s('আপনার নাম', 'Your Name');
  static String get setupButton =>
      _s('অ্যাডমিন অ্যাকাউন্ট বানান', 'Create Admin Account');
  static String get setupAlreadyExists => _s(
      'অ্যাডমিন আগেই তৈরি হয়েছে — লগইন করুন',
      'Admin already exists - please log in');
  static String get setupDone => _s(
      'অ্যাডমিন অ্যাকাউন্ট তৈরি হয়েছে', 'Admin account created successfully');

  // সাইন-আপ ও আবেদন
  static String get validEmail => _s('সঠিক ইমেইল দিন', 'Enter a valid email');
  static String get passwordTooShort => _s(
      'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে',
      'Password must be at least 6 characters');
  static String get passwordsDontMatch =>
      _s('দুটো পাসওয়ার্ড মেলেনি', 'Passwords do not match');
  static String get emailInUse => _s(
      'এই ইমেইল দিয়ে অ্যাকাউন্ট আছে — লগইন করুন',
      'Email already in use - sign in');
  static String get applyAccountFailed => _s(
      'অ্যাকাউন্ট খোলা যায়নি — আবার চেষ্টা করুন',
      'Account creation failed - try again');
  static String get applyFailedAfterAccount => _s(
      'অ্যাকাউন্ট হয়েছে, কিন্তু আবেদন জমা হয়নি',
      'Account created but application failed');

  // অনুমোদনের অপেক্ষা
  static String get pendingTitle =>
      _s('অনুমোদনের অপেক্ষায় আছেন', 'Pending Approval');
  static String get pendingBody => _s(
      'আপনার আবেদনটি অ্যাডমিন দেখছেন। অনুমোদন হলে জানিয়ে দেওয়া হবে।',
      'Your application is under review by the Admin.');
  static String get pendingCompleteApplication =>
      _s('সদস্য হওয়ার আবেদন সম্পূর্ণ করুন', 'Complete Membership Application');
  static String get checkAgain => _s('আবার দেখুন', 'Check again');
  static String get rejectedTitle =>
      _s('আবেদন বাতিল হয়েছে', 'Application rejected');
  static String get rejectedBody => _s(
      'আপনার আবেদনটি বাতিল হয়েছে — কারণ জানতে অ্যাডমিনের সাথে যোগাযোগ করুন।',
      'Your application was rejected — contact the admin to know why.');
  static String get profileNotFoundTitle =>
      _s('প্রোফাইল পাওয়া যায়নি', 'Profile not found');
  static String get profileNotFoundBody => _s(
      'আপনার অ্যাকাউন্ট আছে, কিন্তু প্রোফাইলের তথ্য পাওয়া যাচ্ছে না — অ্যাডমিনের সাথে যোগাযোগ করুন।',
      'Your account exists, but the profile could not be found — please contact the admin.');

  // বায়োমেট্রিক
  static String get biometricSuccess =>
      _s('বায়োমেট্রিক সফল হয়েছে', 'Biometric verified');
  static String get biometricUnavailable => _s('এই ফোনে বায়োমেট্রিক চালু নেই',
      'Biometrics are not available on this device');
  static String get biometricCancelled =>
      _s('বায়োমেট্রিক বাতিল', 'Verification cancelled');
  static String get biometricFailed => _s(
      'বায়োমেট্রিক যাচাই হয়নি — আবার চেষ্টা করুন',
      'Biometric verification failed — try again');

  // হোম
  static String get totalFund => _s('মোট তহবিল', 'Total Fund');
  static String get totalMembers => _s('মোট সদস্য', 'Total Members');
  static String get dueThisMonth => _s('এই মাসে বকেয়া', 'Due This Month');
  static String get pendingApprovals => _s('অনুমোদন বাকি', 'Pending Approvals');
  static String get pendingDeposits => _s('জমা যাচাই বাকি', 'Pending Deposits');

  // সমিতি
  static String get samitiList => _s('সমিতিসমূহ', 'Somithis');
  // F32: "দান" নয় — এটা সদস্যের মাসিক জমা।
  static String get monthlyDonation => _s('মাসিক জমা', 'Monthly Deposit');
  static String get createSamiti => _s('নতুন সমিতি খুলুন', 'Create Somithi');
  static String get samitiEmptyTitle =>
      _s('এখনো কোনো সমিতি তৈরি হয়নি', 'No Somithi created yet');
  static String get samitiEmptyBody => _s(
      'অ্যাডমিন নতুন সমিতি খুললে এখানে দেখা যাবে।',
      'New Somithis will appear here.');
  static String get samitiEmptyAdminBody => _s('প্রথম সমিতিটা খুলে শুরু করুন।',
      'Create the first Somithi to get started.');
  static String get samitiNameLabel => _s('সমিতির নাম', 'Somithi Name');
  static String get samitiPurposeLabel =>
      _s('সমিতির উদ্দেশ্য', 'Somithi Purpose');
  static String get samitiDescriptionLabel =>
      _s('বিবরণ (ঐচ্ছিক)', 'Description (Optional)');
  static String get samitiCreated =>
      _s('সমিতি খোলা হয়েছে', 'Somithi created successfully');
  static String get samitiCreateFailed => _s(
      'সমিতি খোলা যায়নি — আবার চেষ্টা করুন।',
      'Failed to create Somithi - try again.');
  static String get memberCountLabel => _s('সদস্য', 'Members');
  static String get joinSamiti =>
      _s('সদস্য হতে আবেদন করুন', 'Apply for Membership');
  static String get alreadyMember =>
      _s('আপনি এই সমিতির সদস্য', 'You are a member of this Somithi');
  static String get applicationPending => _s(
      'এই সমিতিতে আপনার আবেদন বাকি আছে', 'Your application is pending review');
  static String get applicationRejected =>
      _s('আপনার আবেদনটি বাতিল হয়েছে', 'Your application was rejected');
  static String get notMemberTitle =>
      _s('এই সমিতির সদস্য না হলে তথ্য দেখা যাবে না', 'Members Only Content');
  static String get notMemberBody => _s(
      'অভ্যন্তরীণ তথ্য শুধু ওই সমিতির সদস্যরা দেখতে পান।',
      'Internal records are restricted to approved members.');
  static String get notMemberAnyTitle =>
      _s('এখনো কোনো সমিতির সদস্য নন', 'Not a member of any Somithi yet');
  static String get notMemberAnyBody => _s(
      'হিসাব দেখতে প্রথমে কোনো একটা সমিতির সদস্য হতে আবেদন করুন।',
      'Please join a Somithi to view financial records.');
  static String get viewSamitis => _s('সমিতিগুলো দেখুন', 'View Somithis');
  static String get alreadyAppliedForBranch => _s(
      'এই সমিতিতে আপনার আবেদন বাকি আছে',
      'Application already pending for this Somithi');
  static String get alreadyMemberOfBranch =>
      _s('আপনি এই সমিতির সদস্য', 'You are already a member of this branch');
  static String get lockedBranchNote => _s(
      'এই সমিতির জন্যই আবেদন করছেন', 'Applying specifically for this Somithi');
  static String get membersOnlyNote => _s('সদস্য হলে ভেতরের হিসাব দেখা যাবে।',
      'Internal records become accessible upon approval.');
  static String get recountMembers =>
      _s('সদস্য সংখ্যা আবার গুনুন', 'Recount Members');
  static String get recountDone =>
      _s('সদস্য সংখ্যা মিলিয়ে নেওয়া হয়েছে', 'Member count synchronized');
  static String get adminOnlyPage =>
      _s('এই পাতা শুধু অ্যাডমিন দেখতে পারেন', 'Admin access only');

  // জমা
  static String get depositTitle => _s('জমা দিন', 'Make Deposit');
  static String get depositAmount => _s('টাকার পরিমাণ', 'Deposit Amount');
  static String get depositMonth => _s('কোন মাসের জমা', 'Deposit Month');
  static String get trxId =>
      _s('লেনদেন নম্বর (TrxID)', 'Transaction ID (TrxID)');
  static String get depositSubmit => _s('জমা দিন', 'Submit Deposit');
  static String get depositPending => _s('যাচাইাধীন', 'Pending Review');
  static String get depositSent => _s(
      'জমা পাঠানো হয়েছে — যাচাইাধীন', 'Deposit submitted - pending approval');
  static String get depositApproved =>
      _s('জমা অনুমোদন হয়েছে', 'Deposit approved');

  // সদস্য হওয়ার আবেদন
  static String get applyTitle =>
      _s('সদস্য হওয়ার আবেদন', 'Membership Application');
  static String get applySent => _s(
      'আবেদন জমা হয়েছে — অ্যাডমিন দেখছেন', 'Application submitted for review');
  static String get applyApproved =>
      _s('সদস্য অনুমোদন হয়েছে', 'Membership approved');

  // পাসবই
  static String get passbookTitle => _s('আমার পাসবই', 'My Passbook');
  static String get totalDeposit => _s('মোট জমা', 'Total Deposit');
  static String get dues => _s('বকেয়া', 'Dues');
  static String get activeLoan => _s('চলতি কর্জে হাসানা', 'Active Loan');
  static String get pendingDepositTotal =>
      _s('যাচাইাধীন জমা', 'Pending Deposits');
  static String get ledgerTitle => _s('লেনদেনের খাতা', 'Transaction Ledger');
  static String get filterAll => _s('সকল', 'All');
  static String get filterApproved => _s('অনুমোদিত', 'Approved');
  static String get filterPending => _s('যাচাইাধীন', 'Pending');

  // আইডি কার্ড
  static String get idCardTitle => _s('আমার আইডি কার্ড', 'My ID Card');
  static String get idCardPngFront =>
      _s('সামনের ছবি নামান (PNG)', 'Download Front (PNG)');
  static String get idCardPngBack =>
      _s('পেছনের ছবি নামান (PNG)', 'Download Back (PNG)');
  static String get idCardPdf => _s('PDF হিসেবে নিন', 'Export as PDF');

  // খরচ
  static String get expenseTitle => _s('খরচের হিসাব', 'Expense Register');
  static String get addExpense => _s('খরচ লিখুন', 'Add Expense');

  // কর্জে হাসানা ঋণ
  static String get loanTitle => _s('কর্জে হাসানা ঋণ', 'Qard Hasan (Loan)');
  static String get issueLoan => _s('ঋণ দিন', 'Disburse Loan');
  static String get loanDetail => _s('ঋণের বিস্তারিত', 'Loan Details');

  // রিপোর্ট
  static String get reportTitle => _s('মাসিক রিপোর্ট', 'Monthly Report');
  static String get defaulterTitle => _s('বকেয়া সদস্য', 'Defaulters');

  // নোটিশ ও কমিটি
  static String get noticeTitle => _s('নোটিশ বোর্ড', 'Notice Board');
  static String get committeeTitle => _s('কমিটি', 'Committee');

  // সাধারণ বোতাম ও অবস্থা
  static String get approve => _s('অনুমোদন করুন', 'Approve');
  static String get reject => _s('বাতিল করুন', 'Reject');
  static String get save => _s('সংরক্ষণ করুন', 'Save');
  static String get cancel => _s('বাতিল', 'Cancel');
  static String get searchHint =>
      _s('নাম, ফোন বা সদস্য নম্বর লিখুন', 'Search by name, phone or ID');
  static String get emptyTitle => _s('এখানে এখনো কিছু নেই', 'Nothing here yet');
  static String get loading => _s('আসছে…', 'Loading...');
  static String get tryAgain => _s('আবার চেষ্টা করুন', 'Try Again');

  // থিম ও ভাষা
  static String get themeModeTitle => _s('থিম মোড', 'Theme Mode');
  static String get themeLight => _s('লাইট মোড', 'Light Mode');
  static String get themeDark => _s('ডার্ক মোড', 'Dark Mode');
  static String get themeSystem => _s('সিস্টেম ডিফল্ট', 'System Default');
  static String get languageTitle => _s('ভাষা', 'Language');
  // চালুর ভুল আর পাওয়া-না-যাওয়া পাতা (M3, m1, m13)
  static String get startupErrorTitle => _s(
      'সার্ভারের সাথে যুক্ত হওয়া যায়নি', 'Could not connect to the server');
  static String get startupErrorBody => _s(
      'অ্যাপের তথ্যের ব্যবস্থা (Firebase) চালু হয়নি — নেট দেখে আবার চেষ্টা করুন।',
      'The app backend (Firebase) did not start — check your connection and try again.');
  static String get notFoundTitle =>
      _s('এই পাতাটি পাওয়া যায়নি', 'Page not found');
  static String get notFoundBody => _s(
      'আপনি যে ঠিকানায় যেতে চেয়েছেন সেটা এই অ্যাপে নেই।',
      'The address you opened does not exist in this app.');
  static String get backHome => _s('হোমে ফিরে যান', 'Back to Home');
  static String get markAllRead => _s('সব পড়া হয়েছে', 'Mark all read');
  static String get somethingWrong =>
      _s('কিছু একটা ভুল হয়েছে', 'Something went wrong');
  static String get restartAppHint => _s(
      'অ্যাপ বন্ধ করে আবার খুললে ঠিক হয়ে যেতে পারে।',
      'Closing and reopening the app may fix it.');
}
