# Master Development Prompt — "Shomiti Manager" Android App

Copy everything below this line into your AI coding tool (Claude Code, etc.) or hand it to a developer as the full project specification.

---

## 1. Project Summary

Build a **production-grade, highly polished native Android app** using **Jetpack Compose** for a community/cooperative organization ("Shomiti") to fully digitize member contribution (chada) collection, expense tracking, loans, committee/organizational management, and reporting — replacing manual registers with a complete ERP-like system. Data accuracy, transparency, auditability, and a premium modern UI/UX are all top priorities. The app must work fully offline with automatic sync. Default UI language is **English**, with a full **Bangla UI toggle** available in Settings.

---

## 2. Tech Stack

- **UI:** Jetpack Compose (Material 3, dynamic theming), Navigation Compose
- **Architecture:** MVVM + Clean Architecture (data / domain / presentation layers), unidirectional data flow with `StateFlow`/`Flow`
- **DI:** Hilt
- **Backend:** Firebase
  - **Firebase Authentication** — Email/Password + Google Sign-In
  - **Cloud Firestore** — primary database, offline persistence enabled (native offline cache + auto-sync)
  - **Firebase Storage** — member photos, NID scans, expense/loan receipt attachments, committee photos
  - **Firebase Cloud Messaging (FCM)** — all push notifications
  - **Cloud Functions** — server-side triggers: notifications, balance aggregation, defaulter computation, pre-due reminders, dividend calculation, audit logging enforcement
- **Local:** Jetpack DataStore (user preferences: theme, language, notification mute settings, onboarding-seen flag)
- **Security:** `BiometricPrompt` API (fingerprint/face unlock), PIN fallback
- **Widget:** Jetpack Glance (home-screen widget)
- **PDF Generation:** Android `PdfDocument` API + Android Print Framework (`PrintManager`) for direct printing — used for receipts, reports, and Membership ID Cards
- **Excel/JSON export:** Apache POI (or similar) for Excel export, native JSON serialization for full backup
- **Charts:** Compose-compatible charting library (e.g., Vico) for dashboard graphs
- **Image loading:** Coil
- **Animations:** Compose `AnimatedContent`/`AnimatedVisibility`, shared-element transitions, shimmer-effect skeleton loaders
- **Localization:** Android resource-based (`values/strings.xml` + `values-bn/strings.xml`), runtime locale switching
- **Async:** Kotlin Coroutines + Flow
- **In-app update check:** custom mechanism (see §9) since the app is NOT on Play Store

---

## 3. User Roles & Permissions

| Role | Scope | Permissions |
|---|---|---|
| **Super Admin** | Whole Shomiti (all branches) | Full control: create/manage branches, assign Branch Admins, manage all members, approve/reject signups & member edit-requests, edit/delete any record (with audit log), view full audit trail, org-wide announcements/notices, manage payment-method list, full data backup/export, manage active sessions/devices, configure branding (logo + Shomiti name), manage Committee/Executive Body info, run annual dividend distribution, process member exit/resignation settlements |
| **Branch Admin / Treasurer** | One assigned branch | Manage members within their branch, record payments/expenses/loans for their branch, approve their branch members' edit-requests, send branch announcements/notices, view branch dashboard & reports |
| **Member** | Self only | View own profile, own payment/loan history, submit profile edit-requests, view org-wide defaulter list, contact defaulters (Call/WhatsApp buttons), receive notifications, download/print own receipts & ID card, view Notice Board and Committee info, view home-screen widget summary |

**Signup flow:** Email/Password or Google Sign-In → account enters **"Pending Approval"** → Super Admin/Branch Admin approves and links the account to a Member record + branch → only then full access is granted.

---

## 4. Branding & Theming

- **Settings panel** lets Super Admin configure: Shomiti name and logo image (uploaded by the org — auto-applied across the entire app: app bar, splash screen, PDF receipts/reports, ID cards, notification icon).
- **Material 3** design system throughout; custom adaptive launcher icon.
- **Full Light + Dark mode** support, following system default with manual override in Settings.
- Clean, modern, ERP-dashboard aesthetic — generous whitespace, clear typography hierarchy, BDT (৳) currency formatting with thousand separators.

---

## 5. Organizational Structure

- One top-level **Shomiti (Organization)**.
- Multiple **Branches/Sub-groups**, each with its own member list, its own Branch Admin/Treasurer, and its own running fund balance.
- Super Admin has a consolidated org-wide dashboard plus per-branch drill-down.

---

## 6. Core Feature Modules

### 6.1 Member Management
- Full CRUD (Admin/Branch Admin only)
- Fields: Full Name, Phone, Address, Photo, Joining Date, Branch, NID (+ NID photo), Emergency Contact (name + phone)
- **Custom fields:** Admin can define additional dynamic fields (text/number/date) per organization
- **Member Self-Service Edit Requests:** a member can request a change to their own info; creates a pending `editRequests` entry; Admin/Branch Admin reviews and approves/rejects — only then does the live record update
- **Member Exit / Resignation Workflow:**
  - Admin marks a member as "Exiting" → system auto-calculates: total contributed − outstanding dues − outstanding loan balance = **final settlement/refund amount**
  - Admin records the refund payout (amount, date, method) → member status becomes **"Left"** (historical record retained, no longer counted in active dashboards/defaulter lists)
- **Printable Membership ID Card:** generate a PDF ID card per member with photo, name, member ID, branch, joining date, and Shomiti logo — printable or shareable
- Member detail screen: profile, full payment ledger, loan history, current dues, outstanding balance

### 6.2 Contribution / Payment Management
- Types: **Monthly, Yearly, Special/One-time, Fine (late penalty)**
- Payment method: admin-configurable list, pre-seeded with **Cash, bKash, Bank Transfer**
- Entry: **Admin/Branch Admin manually records each payment one at a time** (no bulk entry, no member self-submission)
- On save: auto-generate receipt number, auto-generate printable PDF receipt, auto-notify the concerned member
- **Duplicate Payment Soft Warning:** if a payment already exists for the same member + same month/type, show a warning dialog — Admin can review and still confirm/save if intentional (e.g., legitimately two payments in one month)
- **Pre-due Reminder:** automatic notification sent to members **2–3 days before** the monthly due date (configurable), in addition to the after-the-fact defaulter list
- **Defaulter tracking:** auto-computed monthly, visible to **all members**, each entry has **Call** and **WhatsApp** quick-action buttons
- Member's own ledger screen: full history filterable by month/year/type/medium

### 6.3 Expense (Kharoch) Management — Full ERP Style
- Category, amount, date, description, receipt/attachment upload, recorded-by
- Branch-wise and org-wide tracking
- Running balance = Total Income (contributions + loan repayments) − Total Expense − Loans Disbursed − Refunds Paid + Dividends Retained

### 6.4 Loan / Dadon Management
- Admin disburses loans from the Shomiti fund to a member
- Fields: amount, date issued, reason, repayment schedule/installments, amount repaid, outstanding balance
- **Optional interest support:** simple/flat interest calculation can be enabled per loan (interest-free by default, toggle available)
- Overdue repayment tracking & reminders

### 6.5 Committee / Executive Body
- Super Admin maintains the Shomiti's official committee: **President, Secretary, Treasurer**, and any other designations, each linked to a Member profile, with term/tenure dates
- Displayed as a dedicated "Committee" screen visible to all members (builds trust/transparency)

### 6.6 Notice Board / Meeting Minutes
- Admin/Branch Admin can post **Notices/Announcements** (org-wide or branch-scoped) and **Meeting Minutes** (e.g., AGM records)
- All members can view the Notice Board; each notice can carry an attachment (PDF/image) and a timestamp
- Feeds into the notification system when a new notice is posted

### 6.7 Annual Profit/Dividend Distribution
- At year-end, Super Admin can run a **Dividend Distribution** calculation: total distributable profit is split among members **proportionally to each member's total contribution during that year**
- System auto-computes each member's share, Admin reviews and confirms, then records the payout per member (feeds into that member's ledger)

### 6.8 Dashboard & Analytics
- Visual charts: Income vs Expense over time, monthly collection trend, branch-wise comparison, top defaulters, loans disbursed vs repaid, dividend distribution summary
- Role-scoped views (Super Admin: org-wide + per-branch; Branch Admin: own branch; Member: personal summary)

### 6.9 Global Search
- A single search bar searches across **members, payments, receipt numbers, and phone numbers** simultaneously, with filter and sort options (date, branch, type, amount range, etc.)

### 6.10 Notifications (FCM)
- Payment recorded confirmation, pre-due reminders, monthly defaulter reminders, admin/branch announcements & new notices, loan repayment due reminders, member edit-request status, dividend payout notice
- **Notification Preferences (Settings):** per-type mute toggles, sound/vibration on-off
- In-app notification center/history log

### 6.11 Reports, Receipts & Printing
- Printable/exportable as PDF: individual receipts, member statements, monthly/yearly org summary, expense reports, loan statements, Membership ID Cards, dividend distribution reports
- Direct print via Android Print Framework, plus Share/Download as PDF

### 6.12 Audit Trail
- Every edit/delete of a payment, expense, or loan logs: who, when, old value → new value, optional note
- Viewable by Super Admin (org-wide) and Branch Admin (own branch); never editable/deletable

### 6.13 Offline Support
- Full usability offline (cached member lists, payment history, dashboard)
- New admin entries made offline queue locally and auto-sync on reconnect, with a clear "Offline — will sync automatically" indicator

### 6.14 Full Data Backup / Export (Admin only)
- Super Admin can trigger a full database export (Excel and/or JSON) covering members, payments, expenses, loans, notices, committee info, and audit logs — for disaster-recovery/safekeeping

### 6.15 Home Screen Widget (Jetpack Glance)
- Member: quick view of their own total contributed / outstanding dues
- Admin: quick view of the Shomiti's total fund balance

### 6.16 Security
- App-open lock via **Biometric (fingerprint/face) or PIN**
- Auto session timeout for Admin roles after inactivity
- **Active Session/Device Management:** Admin/Treasurer can see all devices currently logged into their account and remotely log out any of them

### 6.17 Onboarding
- Short first-launch tutorial (a few swipeable screens) explaining core app usage, shown once (tracked via DataStore), skippable

### 6.18 Localization
- Full **English ⇄ Bangla** UI toggle in Settings, switching all interface strings at runtime (data itself, e.g. member names, already supports Bangla Unicode regardless of UI language)

### 6.19 Help & Support
- In-app Help/FAQ section
- Admin/developer contact info with quick Call / WhatsApp / Email action buttons

---

## 7. UI/UX Polish Requirements

- Smooth screen transitions and micro-interactions (Compose `AnimatedContent`/`AnimatedVisibility`)
- Shimmer-effect **skeleton loaders** while data loads (never a blank white screen)
- Custom **empty-state illustrations** for empty lists (no members yet, no payments yet, etc.)
- Consistent Material 3 component usage, accessible tap targets, proper contrast in both Light and Dark themes
- Role-based navigation (different bottom nav / drawer items per role)

---

## 8. Logo & Branding Asset

- Logo will be **created and uploaded by the organization** via the Branding settings panel described in §4 — no in-app logo generation needed. Just build the upload/storage/display pipeline (Firebase Storage → applied across app bar, splash, PDFs, ID cards, notification icon).

---

## 9. Distribution & Updates

- **Private distribution only** — no Google Play Store. Distributed as a shareable APK.
- Because there's no Play Store auto-update, build a lightweight **in-app "Check for Update"** feature: app checks a hosted version file/endpoint (e.g., a small JSON on Firebase Hosting or Firestore doc) on launch or on-demand; if a newer version exists, shows a dialog with a direct APK download link.

---

## 10. Suggested Firestore Data Model

```
organizations/{orgId}
  ├─ name, logoUrl, settings, paymentMethods[], customMemberFields[]
  │
  ├─ branches/{branchId}
  │     ├─ name, treasurerUserId, balance
  │
  ├─ committee/{committeeMemberId}
  │     ├─ memberId, designation (President/Secretary/Treasurer/...), termStart, termEnd
  │
  ├─ members/{memberId}
  │     ├─ name, phone, address, photoUrl, nid, nidPhotoUrl,
  │     │  emergencyContact{name, phone}, branchId, joinDate,
  │     │  status (active/left), exitDate, customFields{}, linkedUserId
  │
  ├─ users/{userId}
  │     ├─ email, role (superAdmin/branchAdmin/member),
  │     │  branchId (if branchAdmin), linkedMemberId (if member),
  │     │  approvalStatus (pending/approved/rejected),
  │     │  preferences{language, theme, notificationMutes[], biometricLockEnabled}
  │
  ├─ sessions/{sessionId}
  │     ├─ userId, deviceInfo, loginTime, lastActiveTime, isActive
  │
  ├─ payments/{paymentId}
  │     ├─ memberId, branchId, type (monthly/yearly/special/fine),
  │     │  amount, method, forMonth/forYear, purposeNote,
  │     │  date, recordedBy, receiptNumber, receiptPdfUrl
  │
  ├─ expenses/{expenseId}
  │     ├─ branchId, category, amount, date, description,
  │     │  attachmentUrl, recordedBy
  │
  ├─ loans/{loanId}
  │     ├─ memberId, branchId, amount, dateIssued, reason,
  │     │  interestEnabled, interestRate, status,
  │     │  repayments: [{amount, date, method}]
  │
  ├─ editRequests/{requestId}
  │     ├─ memberId, requestedChanges{}, status (pending/approved/rejected),
  │     │  requestedAt, reviewedBy, reviewedAt
  │
  ├─ memberExits/{exitId}
  │     ├─ memberId, totalContributed, outstandingDues, outstandingLoan,
  │     │  finalSettlementAmount, payoutDate, payoutMethod, processedBy
  │
  ├─ dividends/{dividendRunId}
  │     ├─ year, totalDistributableAmount, calculatedAt, confirmedBy,
  │     │  allocations: [{memberId, contributionShare, amountPaid}]
  │
  ├─ notices/{noticeId}
  │     ├─ title, body, attachmentUrl, type (notice/meetingMinutes),
  │     │  scope (org/branchId), postedBy, postedAt
  │
  ├─ auditLogs/{logId}
  │     ├─ entityType, entityId, action (edit/delete),
  │     │  changedBy, timestamp, before{}, after{}, note
  │
  └─ notifications/{notificationId}
        ├─ toUserId / toBranchId / broadcast, title, body,
        │  type, timestamp, read
```

---

## 11. Security Rules (Firestore)

- `member` role: read-only on their own `members/{memberId}`, own `payments`/`loans`, the org-wide defaulter list, `committee`, and `notices`; can only create `editRequests` for themselves.
- `branchAdmin`: read/write limited to documents where `branchId` matches their assigned branch.
- `superAdmin`: full read/write across the organization, including `committee`, `dividends`, and `memberExits`.
- `auditLogs`: written only via Cloud Functions (never directly client-writable) — client writes to `payments`/`expenses`/`loans` are intercepted server-side to also write the matching audit entry.
- New `users` documents default to `approvalStatus: pending` with no data access until approved.
- `sessions`: a user can only read/deactivate their own session documents; deactivating a session forces that device to log out (checked on app resume/auth token refresh).

---

## 12. Non-Functional Requirements

- **Data accuracy is priority #1:** use Firestore transactions/batched writes wherever a payment/expense/loan/dividend/exit-settlement affects both its own record and a branch balance total.
- Full input validation (amounts, phone numbers, required fields).
- BDT (৳) currency formatting with thousand separators.
- Bangla Unicode text must work correctly everywhere (names, notes) regardless of UI language setting.
- Scalable to hundreds of members and multiple branches with proper Firestore pagination/indexing.

---

## 13. Suggested Build Order (Milestones)

1. Firebase project setup + Auth (Email/Password + Google) + Admin approval flow + session/device tracking
2. Data models + Firestore structure + security rules
3. Branding/theming system (logo & name settings, Light/Dark Material 3 theme) + Localization (English/Bangla toggle)
4. Member management (CRUD, custom fields, photo/NID upload, self-service edit-requests, ID card generation)
5. Payment recording + PDF receipt generation + duplicate-payment warning + pre-due reminders
6. Expense module
7. Loan/Dadon module (with optional interest)
8. Committee/Executive Body module + Notice Board/Meeting Minutes
9. Member Exit/Resignation settlement workflow
10. Annual Dividend Distribution module
11. Dashboard with charts + Global Search
12. Notifications (FCM) + preferences + defaulter highlighting with Call/WhatsApp actions
13. Reports & printing (all screens)
14. Audit trail logging
15. Offline persistence + sync UX
16. Biometric/PIN app lock + active session management
17. Onboarding tutorial + Home screen widget (Glance)
18. In-app update checker + Help/FAQ section
19. Full data backup/export (Admin)
20. UI polish pass: animations, skeleton loaders, empty-state illustrations
21. Role-based end-to-end QA across all three roles

---

*End of prompt.*
