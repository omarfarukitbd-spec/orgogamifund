package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun AdminMemberControlCategory(
    isBangla: Boolean,
    pendingApplicationsCount: Int,
    onNavigateToApprovals: () -> Unit,
    onNavigateToMembers: () -> Unit,
    onNavigateToAddMember: () -> Unit,
    onNavigateToEditRequests: () -> Unit
) {
    AdminSectionHeader(title = if (isBangla) "১. সদস্য অন্তর্ভুক্তি ও অনুমোদন নিয়ন্ত্রণ" else "1. Member Admission & Identity Control")
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            AdminActionTile(
                title = if (isBangla) "সদস্য আবেদন ও অনুমোদন" else "Membership Applications & Approvals",
                subtitle = if (isBangla) "নতুন সদস্যদের আবেদন, পরিচয় ও তথ্য যাচাই করে অনুমোদন" else "Review applications, verify NID and photos for approval",
                icon = Icons.Default.VerifiedUser,
                badgeCount = pendingApplicationsCount,
                iconColor = if (pendingApplicationsCount > 0) MoneyDueAmber else MoneyIncomeGreen,
                onClick = onNavigateToApprovals
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "সদস্য তালিকা ও ডিজিটাল আইডি কার্ড" else "Member Directory & ID Cards",
                subtitle = if (isBangla) "সকল সদস্যের তথ্য, প্রোফাইল এবং পিভিসি কার্ড প্রিন্ট" else "Member info, profiles, and PVC card printing",
                icon = Icons.Default.Badge,
                iconColor = Color(0xFF6366F1),
                onClick = onNavigateToMembers
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "নতুন সদস্য সরাসরি অন্তর্ভুক্তি" else "Direct Member Registration",
                subtitle = if (isBangla) "এডমিন কর্তৃক সদস্য সরাসরি ডাটাবেসে যোগ করুন" else "Directly add new members into database by admin",
                icon = Icons.Default.PersonAdd,
                iconColor = Color(0xFF0D9488),
                onClick = onNavigateToAddMember
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "প্রোফাইল পরিবর্তন আবেদন" else "Profile Edit Requests",
                subtitle = if (isBangla) "সদস্যদের ফোন নম্বর ও ঠিকানা সংশোধনের অনুমোদন" else "Approve member phone number & address changes",
                icon = Icons.Default.EditNote,
                iconColor = Color(0xFF64748B),
                onClick = onNavigateToEditRequests
            )
        }
    }
}

@Composable
fun AdminFinancialControlCategory(
    isBangla: Boolean,
    pendingDepositsCount: Int,
    onNavigateToPendingDeposits: () -> Unit,
    onNavigateToCollectPayment: () -> Unit,
    onNavigateToAddExpense: () -> Unit,
    onNavigateToIssueLoan: () -> Unit,
    onNavigateToDividends: () -> Unit,
    onNavigateToDefaulters: () -> Unit
) {
    AdminSectionHeader(title = if (isBangla) "২. আর্থিক প্রশাসন ও হিসাব অডিট" else "2. Financial Governance & Audit")
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            AdminActionTile(
                title = if (isBangla) "অপেক্ষমাণ জমা যাচাই ও অনুমোদন" else "Pending Deposits Review & Approval",
                subtitle = if (isBangla) "বিকাশ, নগদ ও ব্যাংকে পাঠানো জমার ট্রানজেকশন যাচাই" else "Verify member deposits via bKash, Nagad & Bank TrxID",
                icon = Icons.Default.Payments,
                badgeCount = pendingDepositsCount,
                iconColor = if (pendingDepositsCount > 0) MoneyDueAmber else MoneyIncomeGreen,
                onClick = onNavigateToPendingDeposits
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "চাঁদা ও সঞ্চয় গ্রহণ" else "Collect Contributions & Savings",
                subtitle = if (isBangla) "সদস্যদের মাসিক চাঁদা সরাসরি গ্রহণ ও তাৎক্ষণিক মানি রিসিট" else "Directly record member contributions & issue instant receipts",
                icon = Icons.Default.Add,
                iconColor = MoneyIncomeGreen,
                onClick = onNavigateToCollectPayment
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "খরচ রেজিস্টার ও ভাউচার" else "Expense Register & Vouchers",
                subtitle = if (isBangla) "সমিতির দৈনন্দিন ও উন্নয়ন ব্যয়ের এন্ট্রি এবং ভাউচার" else "Record & manage operational expenses and vouchers",
                icon = Icons.Default.MoneyOff,
                iconColor = MoneyExpenseRed,
                onClick = onNavigateToAddExpense
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "কল্যাণ ঋণ ও কর্জে হাসানা প্রদান" else "Issue Welfare Loans (Qard Hasan)",
                subtitle = if (isBangla) "সদস্যদের সুদবিহীন ঋণ মঞ্জুরি ও কিস্তি সূচি নির্ধারণ" else "Approve interest-free loans and set repayment schedules",
                icon = Icons.Default.CreditCard,
                iconColor = Color(0xFFD97706),
                onClick = onNavigateToIssueLoan
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "বার্ষিক লভ্যাংশ বণ্টন" else "Annual Dividend Distribution",
                subtitle = if (isBangla) "বাৎসরিক উদ্বৃত্ত সদস্যদের মাঝে সুষমভাবে বণ্টন" else "Distribute annual surplus among members proportionally",
                icon = Icons.Default.PieChart,
                iconColor = Color(0xFFF59E0B),
                onClick = onNavigateToDividends
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "বকেয়াদারদের তালিকা ও নোটিশ" else "Defaulters List & Reminders",
                subtitle = if (isBangla) "যাদের কিস্তি বকেয়া তাদের সাথে দ্রুত যোগাযোগের ব্যবস্থা" else "View overdue payments and quickly contact members",
                icon = Icons.Default.Warning,
                iconColor = MoneyDueAmber,
                onClick = onNavigateToDefaulters
            )
        }
    }
}

@Composable
fun AdminSystemControlCategory(
    isBangla: Boolean,
    onNavigateToCreateSomithi: () -> Unit,
    onNavigateToBranches: () -> Unit,
    onNavigateToCommittee: () -> Unit,
    onNavigateToNotices: () -> Unit,
    onNavigateToReports: () -> Unit,
    onTriggerBackup: () -> Unit
) {
    AdminSectionHeader(title = if (isBangla) "৩. প্রাতিষ্ঠানিক সমিতি ও সিস্টেম কন্ট্রোল" else "3. Societies & System Governance")
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            AdminActionTile(
                title = if (isBangla) "নতুন সমিতি ফান্ড তৈরি ও পারমিশন" else "Create Somithi Fund & Permissions",
                subtitle = if (isBangla) "নতুন ফান্ড সৃষ্টি, বিকাশ/নগদ নম্বর ও মেম্বার ভিউ পারমিশন নির্ধারণ" else "Create new somithi, configure payment accounts & set member view permissions",
                icon = Icons.Default.Apartment,
                iconColor = Color(0xFF0284C7),
                onClick = onNavigateToCreateSomithi
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "সমিতি ও শাখা তালিকা পরিচালনা" else "Manage Somithi Branches",
                subtitle = if (isBangla) "বিদ্যমান সমিতি সমূহের ফান্ড ও কোষাধ্যক্ষ পরিচালনা" else "Manage existing branches, fund balances & assigned treasurers",
                icon = Icons.Default.Apartment,
                iconColor = Color(0xFF0D9488),
                onClick = onNavigateToBranches
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "কমিটি ও পরিচালনা পর্ষদ" else "Executive Committee Directory",
                subtitle = if (isBangla) "সভাপতি, সাধারণ সম্পাদক ও অন্যান্য কর্মকর্তাদের তালিকা" else "List of President, Secretary & Executive members",
                icon = Icons.Default.Star,
                iconColor = Color(0xFF8B5CF6),
                onClick = onNavigateToCommittee
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "নোটিশ ও রেজুলেশন পাবলিশার" else "Notices & Meeting Resolutions",
                subtitle = if (isBangla) "সদস্যদের জন্য সাধারণ নোটিশ বা মিটিং রেজুলেশন প্রকাশ" else "Publish general notices and AGM resolutions",
                icon = Icons.Default.Campaign,
                iconColor = Color(0xFFE11D48),
                onClick = onNavigateToNotices
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "হিসাব বিবরণী রিপোর্ট ও অডিট প্রিন্ট" else "Financial Reports & Audit Print",
                subtitle = if (isBangla) "মাসিক ও বার্ষিক আয়-ব্যয় এবং ব্যালেন্স শীট এক্সপোর্ট" else "Export monthly/annual income, expense & balance sheets",
                icon = Icons.Default.Print,
                iconColor = Color(0xFF4F46E5),
                onClick = onNavigateToReports
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            AdminActionTile(
                title = if (isBangla) "ডাটাবেস ব্যাকআপ ও ক্লাউড সিঙ্ক" else "Database Backup & Export",
                subtitle = if (isBangla) "সমিতির সমস্ত তথ্যের অফলাইন ব্যাকআপ ও ফাইল শেয়ার" else "Offline JSON backup & data export",
                icon = Icons.Default.SettingsBackupRestore,
                iconColor = Color(0xFF0F766E),
                onClick = onTriggerBackup
            )
        }
    }
}
