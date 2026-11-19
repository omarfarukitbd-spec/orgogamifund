/// রুট অ্যাডমিনের ইমেইল — একমাত্র জায়গা যেখানে এই ঠিকানা থাকে।
///
/// সতর্কতা: ক্লায়েন্ট কোড কখনো এই তালিকা দিয়ে রোল বা অনুমোদন
/// ঠিক করবে না — রোল আসে শুধু Firestore-এর users ডকুমেন্ট থেকে
/// (ভবিষ্যতে Firebase custom claims থেকে, Admin SDK দিয়ে বসানো)।
/// এই ফাইল শুধু ঠিকানাটার একক উৎস, যাতে এটা কোডে পাঁচ জায়গায়
/// ছড়িয়ে না থাকে আর বানান ভুল (আগের `omarfaruktitbd`) না হয়।
/// দেখুন: audit-01-login.md, M6।
const rootAdminEmails = {'omarfarukitbd@gmail.com'};

/// রুট অ্যাডমিনের ইমেইল কি না — শুধু তথ্যগত যাচাইয়ের জন্য
/// (যেমন সাপোর্ট বার্তায়), অনুমোদন/রোল নির্ধারণের জন্য নয়।
bool isRootAdminEmail(String email) =>
    rootAdminEmails.contains(email.trim().toLowerCase());
