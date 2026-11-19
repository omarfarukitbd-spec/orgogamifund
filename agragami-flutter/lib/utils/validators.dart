/// শেয়ার্ড ফর্ম যাচাই — লগইন আর প্রথম সেটআপে ইমেইল
/// যাচাইয়ের নিয়ম আলাদা ছিল (m2), এখন একটাই নিয়ম।
bool isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}
