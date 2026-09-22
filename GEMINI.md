# Ogrogami Fund Somithi ERP - Permanent Agent Rules & Guidelines

This document establishes the mandatory, binding rules for AI agents operating on the `MyApplicationSomithiERP` codebase. Every rule listed below must be strictly adhered to during all phases of design, implementation, refactoring, and code review.

---

## 1. Light and Dark Mode Support (বাধ্যতামূলক লাইট ও ডার্ক মোড)
- **Zero Hardcoded Fixed Colors**: Never use hardcoded `Color.White`, `Color.Black`, or static contrast colors for backgrounds, card surfaces, borders, or text.
- **Strictly Use Material 3 ColorScheme Tokens**:
  - Backgrounds: `MaterialTheme.colorScheme.background`, `MaterialTheme.colorScheme.surface`, `MaterialTheme.colorScheme.surfaceVariant`
  - Text: `MaterialTheme.colorScheme.onSurface`, `MaterialTheme.colorScheme.onSurfaceVariant`, `MaterialTheme.colorScheme.onBackground`
  - Accents: `MaterialTheme.colorScheme.primary`, `MaterialTheme.colorScheme.onPrimary`, `MaterialTheme.colorScheme.secondary`
  - Dividers/Borders: `MaterialTheme.colorScheme.outlineVariant`, `MaterialTheme.colorScheme.outline`
- **Financial Status Colors (Income, Expense, Due)**:
  - When using `MoneyIncomeGreen`, `MoneyExpenseRed`, or `MoneyDueAmber`, always provide appropriate alpha containers or ensure legibility across both dark and light themes (e.g. `MoneyIncomeGreen.copy(alpha = 0.12f)` with `onSurface` or themed text).

---

## 2. Bilingual Support: Bangla & English (বাংলা ও ইংরেজি দ্বিভাষিক সমর্থন)
- **Every User-Facing String Must Be Bilingual**:
  - Every button, label, dialog, error message, toast, placeholder, and page title must support both Bangla (বাংলা) and English.
- **Implementation Strategies**:
  1. Use localized resource strings: `stringResource(id = R.string.xxx)` backed by both `res/values/strings.xml` (English) and `res/values-b+bn/strings.xml` (Bangla).
  2. For dynamic inline text: detect the current language locale via `LocalConfiguration.current.locales[0].language` or `preferences.language`:
     ```kotlin
     val isBangla = LocalConfiguration.current.locales[0].language == "bn"
     Text(text = if (isBangla) "সংরক্ষণ করুন" else "Save")
     ```
- **Bengali Typography**: The app uses the **Hind Siliguri** font family across the design system for crisp, beautiful Bangla rendering.

---

## 3. Strict Prohibitions (কঠোর নিষেধাজ্ঞা)
- **NO Terminal Build Commands**:
  - **NEVER** execute `./gradlew`, `./gradlew.bat`, `gradle`, or build tasks (`compileDebugKotlin`, `assembleDebug`, etc.) in the agent terminal.
  - The user explicitly builds and runs the project directly inside **Android Studio**.
  - The agent's responsibility is to write 100% clean, error-free, and syntactically flawless Kotlin and Compose code.
- **ZERO Emojis Anywhere**:
  - Do not use emojis (e.g., 🏛️, 💳, 💰, 👤, 📋) in any file, UI component, button, badge, header, or notification.
  - Exclusively use official Material 3 vector icons (`androidx.compose.material.icons.Icons`).

---

## 4. File Modularity & Line Limit (< 300 Lines Per File)
- **No file should exceed 300 lines**:
  - Keep all newly created and refactored files strictly under 300 lines.
  - Complex screens must be decomposed into focused, single-responsibility composables placed in a `components/` sub-package (e.g., `dashboard/components/`, `members/components/`).

---

## 5. Firebase Cloud Data Architecture (ফায়ারবেস ক্লাউড ডেটা আর্কিটেকচার)
- **Cloud-First Persistence**:
  - All operational data (`branches`, `members`, `payments`, `expenses`, `loans`, `memberApplications`, `users`, `notices`, `committee`) must sync in real-time with Firebase Cloud Firestore.
  - Reading: Use real-time snapshot listeners via `FirestoreDataManager.kt`.
  - Writing: Persist mutations directly to Firestore via `FirestoreWriteManager.kt`.
  - Seeding: `FirestoreDataSeeder.kt` ensures initial Bangladeshi Somithi data is populated if cloud collections are empty on first run.

---

## 6. Role-Based Access Control & Super Admin Gateway
- **Root Super Admin (`omarfaruktitbd@gmail.com`)**:
  - `omarfaruktitbd@gmail.com` (and legacy `omarfarukitbd@gmail.com`) is designated as the Root Super Admin with automatic `APPROVED` status and full administrative access across all branches and modules.
- **Pending Approval Gateway for All Other Users**:
  - Any user other than the Super Admin defaults to `ApprovalStatus.PENDING`.
  - Non-super users are gated at `PendingApprovalScreen` until explicitly approved by the Super Admin.
  - Users can view general branch info (names, terms, deposit plans) to apply for membership, but cannot view internal member directories or financial records until approved into that branch.
- **Security Rules**:
  - Keep `firestore.rules` synchronized with this permission model at all times.

---

## 7. Master System Documentation (সিস্টেমের পূর্ণাঙ্গ হ্যান্ডবুক)
- Refer to [`APP_DOCUMENTATION.md`](file:///d:/android/Project/MyApplicationSomithiERP/APP_DOCUMENTATION.md) for the complete background story, multi-somithi vision, functional workflows, and catalog of all features implemented in this project.

---

## 8. 100% Workability & Anti-Shortcut Policy (কাজের শতভাগ নিশ্চয়তা ও নো-শর্টকাট নীতি)
- **Zero Temporary Workarounds & Shortcuts**:
  - Never implement placeholder bypass buttons, dummy toggles, or fake mocks when the user expects a fully functioning system.
  - Every feature must be built to work 100% end-to-end: UI -> State Management -> ViewModel/Repository -> Firebase Auth/Firestore Persistence.
  - The agent must never stop prematurely or declare a task complete while core functionality remains incomplete or broken.

---

## 9. Direct Root-Cause Resolution & Real Cloud Auth Sync (মূল কারণ সমাধান ও রিয়েল ক্লাউড অথেনটিকেশন)
- **Always Fix the Root Cause**:
  - When the user reports an issue (e.g., "my Gmail does not show my profile or admin panel"), investigate and fix the actual underlying problem in `FirebaseAuth`, Google Sign-in flow, and Firestore `users/{uid}` mapping.
  - When `FirebaseAuth.getInstance().currentUser` is signed in as `omarfaruktitbd@gmail.com` (or legacy `omarfarukitbd@gmail.com`), the app must automatically and reactively:
    1. Set `userRole = UserRole.SUPER_ADMIN` and `approvalStatus = ApprovalStatus.APPROVED`.
    2. Populate the user's real Google display name, email, and profile photo across all screens (`Dashboard`, `Settings`, `Drawer`, `AdminHub`).
    3. Seamlessly grant full administrative privileges without requiring manual unlocks or overrides.

---

## 10. Strict User Intent Fidelity (ইউজারের নিজস্ব চাহিদা অক্ষরে অক্ষরে পালন)
- **Faithful Execution of User Directives**:
  - Strictly prioritize the user's explicit instructions and specifications over agent-assumed alternatives.
  - Do not introduce unrelated bloat, unwanted layout changes, or arbitrary designs that deviate from the user's core request.
  - If a task is complex, execute iteratively and relentlessly until the user's objective is fully accomplished.

---

## 11. Mandatory Definition of Done (DoD) Checklist (কাজের সমাপ্তি ঘোষণার চেকলিস্ট)
- Before claiming any task is complete, the agent must verify:
  1. **Flawless Code Quality**: 100% clean Kotlin/Compose code with no unresolved references or compiler warnings.
  2. **Rule Adherence**: Zero emojis, strictly < 300 lines per file, Material 3 design tokens only, full bilingual support.
  3. **End-to-End Functionality**: The requested feature works completely without requiring manual developer intervention or hacks.

---

## 12. 100% Edge-to-Edge Screen Architecture & Status Bar Legibility (বাধ্যতামূলক এজ-টু-এজ ও নোটিফিকেশন বার স্পষ্টতা)
- **Strict Edge-to-Edge Compliance**: The entire app must strictly comply 100% with modern Android Edge-to-Edge display system (`enableEdgeToEdge()`, transparent status bar and navigation bar).
- **Global Status Bar & Navigation Bar Icon Contrast (ডার্ক ও লাইট মোডে নোটিফিকেশন বার স্পষ্ট দৃশ্যমানতা)**:
  - Every screen in both Light and Dark mode MUST display 100% crystal-clear, razor-sharp status bar and notification icons (clock, battery, Wi-Fi, network, system icons).
  - In Light Mode (`darkTheme == false`): Status bar icons MUST be dark (`isAppearanceLightStatusBars = true`).
  - In Dark Mode (`darkTheme == true`): Status bar icons MUST be bright/light (`isAppearanceLightStatusBars = false`).
  - This is enforced globally at the root theme level (`ShomitiERPTheme.kt` via `WindowCompat.getInsetsController(window, view)`). Every existing and future screen automatically and globally inherits this behavior. White-on-white or dark-on-dark unreadable status bar icons are STRICTLY PROHIBITED.
- **Zero Content Clipping**: Interactive elements, top headers, and bottom buttons must never be obscured or clipped by the status bar, display notches/camera cutouts, or the navigation bar.
- **Safe Insets Consumption**: Always wrap screens with `Scaffold(modifier = Modifier.fillMaxSize())` and consume `innerPadding` or explicitly apply `WindowInsets.statusBars`, `WindowInsets.navigationBars`, or `Modifier.safeDrawingPadding()`.

---

## 13. Navigation Hierarchy & 1-to-1 Backstack (প্রতিটি ক্লিকে নিশ্চিত ব্যাক বাটন ও ব্যাকস্ট্যাক)
- **Mandatory Back Button on Every Forward Screen**: Whenever the user navigates to any new screen, detail page, or sub-view via click, that screen MUST include a visible TopAppBar / Header Back Button (`Icons.AutoMirrored.Filled.ArrowBack` or `Icons.Default.ArrowBack`).
- **Preserve 1-to-1 Backstack ("যতটা ক্লিক ততটা ব্যাক বাটন")**: Every forward navigation action must add a valid entry to the navigation backstack. Never use premature `popUpTo` with `inclusive = true` (except during explicit authentication logout). The user must be able to step backward through every single screen they visited.
- **Hardware & Gesture Back Synchronization**: System back gestures and the Android hardware back button must mirror the in-app back button behavior cleanly.

---

## 14. Root Screen Exit Confirmation Dialog (সর্বশেষ ধাপে এক্সিট পপআপ ডায়ালগ)
- **Exit Gating at Root Screen**: When the user reaches the root screen of the app (e.g., Dashboard or Login) and there are no further screens remaining in the navigation backstack, pressing the back button (or triggering the system back gesture) must NEVER immediately exit or kill the app without confirmation.
- **Bilingual Exit Popup Box**: A standard Material 3 `AlertDialog` must be displayed:
  - Title: "অ্যাপ থেকে প্রস্থান" (Bangla) / "Exit App" (English)
  - Message: "আপনি কি নিশ্চিত যে অগ্রগামী ফান্ড অ্যাপ থেকে প্রস্থান করতে চান?" / "Are you sure you want to exit Ogrogami Fund?"
  - Confirm Action: "হ্যাঁ, প্রস্থান করুন" / "Yes, Exit" (calls `activity.finish()`)
  - Dismiss Action: "না" / "Cancel" (closes dialog and remains in app)

---

## 15. Clean Material 3 Design & Prohibition of Ad-Hoc Shaped Cards (আজেবাজে শেপ ও ডাবল-বর্ডার কার্ড চিরতরে নিষিদ্ধ)
- **Zero Ad-Hoc Shaped Shortcut Banners**: Never introduce custom double-bordered, weirdly tinted, or arbitrarily shaped shortcut cards (such as the deleted "এডমিন কন্ট্রোল হাব" shape card).
- **Uniform Surface Architecture**: Every list item, card, and section must follow pure Material 3 guidelines using standard `ElevatedCard` or `Card` with `MaterialTheme.colorScheme.surface`, standard corner radius (12-16dp), clean typography, and zero artificial borders.


