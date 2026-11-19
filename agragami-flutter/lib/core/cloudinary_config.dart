/// Cloudinary সেটিংস — সদস্যের ছবি, এনআইডির ছবি, খরচের রসিদ আর
/// নোটিশের ছবি আপলোডের জন্য।
///
/// এই প্রজেক্টে Firebase Storage নেই (Spark প্ল্যানে বাকেট বানানো যায় না),
/// তাই ছবি যায় Cloudinary-র ফ্রি টিয়ারে — unsigned upload preset দিয়ে।
/// অ্যাপে কোনো API key বা secret থাকে না; unsigned preset-এ শুধু cloud name
/// আর preset নাম লাগে।
///
/// আসল মান কোথায় পাবেন:
///  - Cloud name: Cloudinary ড্যাশবোর্ডে (console.cloudinary.com) উপরে দেখা যায়।
///  - Upload preset: Settings → Upload → Upload presets → "Add upload preset",
///    Signing Mode = Unsigned (ছবির ফোল্ডার/সাইজের সীমা preset-এ বসাতে হয়)।
///
/// ⚠️ Unsigned আপলোডে যে কেউ preset নাম জানলে ছবি তুলতে পারে, আর আপলোড
/// হওয়া ছবি URL জানলে যে কেউ দেখতে পারে — এনআইডির ছবির জন্য এটা মাথায়
/// রাখবেন। (ব্যবহারকারী জেনেই এই পথ বেছেছেন।)
class CloudinaryConfig {
  /// Cloudinary ড্যাশবোর্ডে দেখা cloud name।
  /// TODO(ব্যবহারকারী): আসল cloud name এখানে বসান।
  static const String cloudName = 'YOUR_CLOUD_NAME';

  /// Settings → Upload → Upload presets-এ বানানো unsigned preset-এর নাম।
  /// TODO(ব্যবহারকারী): আসল preset নাম এখানে বসান।
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET';

  /// আসল মান বসানো হয়েছে কি না।
  static bool get isConfigured =>
      cloudName != 'YOUR_CLOUD_NAME' &&
      uploadPreset != 'YOUR_UPLOAD_PRESET' &&
      cloudName.isNotEmpty &&
      uploadPreset.isNotEmpty;

  /// ছবি আপলোডের endpoint (Cloudinary Upload API, resource_type = image)।
  /// শুধু [isConfigured] সত্য হলে ব্যবহার করবেন।
  static Uri get uploadUri => Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
}
