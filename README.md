# Ogrogami Fund Somithi ERP (অগ্রগামী ফান্ড সমিতি ইআরপি)

A modern, transparent, and cloud-synced Android cooperative society management platform built with Jetpack Compose, Material 3, and Firebase Cloud Firestore.

---

## About The Project (প্রজেক্ট সম্পর্কে)

**অগ্রগামী ফান্ড** (Ogrogami Fund) is designed for cooperative savings societies and mutual welfare funds (একটি সঞ্চয় ও কল্যাণমূলক সমবায় প্রতিষ্ঠান). It provides an automated, digital replacement for manual paper registers with 100% transparency.

### Key Features (মূল বৈশিষ্ট্যসমূহ)
- **100% Edge-to-Edge Architecture**: Complete compliance with modern Android edge-to-edge guidelines and adaptive notification/status bar legibility across Light and Dark themes.
- **Strict Role-Based Access Control**: Root Super Admin, Branch Admin, and Approved Member portals with real-time Firestore security rules.
- **Member Management & Digital Passbook**: Automated monthly contribution collection, real-time balances, itemized vouchers, and printable receipts.
- **Digital Member ID Card Generator**: High-resolution, two-sided membership card generation with QR code.
- **Dual Language Support (বাংলা ও ইংরেজি)**: Seamless locale switching between Bangla and English backed by standard localized resources.
- **Cloud-First & Offline-Capable**: Real-time synchronization powered by Firebase Firestore and local caching.
- **Strict Navigation Hierarchy**: 1-to-1 backstack navigation with root exit confirmation dialogs.

---

## Tech Stack (প্রযুক্তি)
- **Language**: Kotlin
- **UI Framework**: Jetpack Compose with Material 3 Design Tokens
- **Architecture**: MVVM / Clean Architecture with StateFlow
- **Backend & Persistence**: Firebase Authentication, Cloud Firestore, Firebase Storage
- **Preferences**: Jetpack DataStore Preferences
- **Fonts**: Hind Siliguri (Bengali Typography)

---

## Setup & Development (সেটআপ ও ডেভেলপমেন্ট)
1. Clone the repository:
   ```bash
   git clone https://github.com/omarfarukitbd-spec/orgogamifund.git
   ```
2. Open the project in **Android Studio**.
3. Ensure `google-services.json` is configured with your Firebase project (`ogrogami-fund`).
4. Build and run the app directly using the Android Studio Run configuration.

---

## License & Organization
Developed for **অগ্রগামী ফান্ড সমবায় সমিতি** (Ogrogami Fund Cooperative Society).
