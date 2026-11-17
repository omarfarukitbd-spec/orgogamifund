package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.FactCheck
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Handshake
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmberDark
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRedDark
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreenDark
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class NotificationVisualProps(
    val icon: ImageVector,
    val iconColor: Color,
    val containerColor: Color,
    val categoryLabelBn: String,
    val categoryLabelEn: String,
)

@Composable
fun getNotificationVisualProps(type: NotificationType): NotificationVisualProps {
    val isDark = isSystemInDarkTheme()
    val incomeGreen = if (isDark) MoneyIncomeGreenDark else MoneyIncomeGreen
    val expenseRed = if (isDark) MoneyExpenseRedDark else MoneyExpenseRed
    val dueAmber = if (isDark) MoneyDueAmberDark else MoneyDueAmber

    return when (type) {
        NotificationType.PAYMENT_RECEIVED -> NotificationVisualProps(
            icon = Icons.Filled.Payments,
            iconColor = incomeGreen,
            containerColor = incomeGreen.copy(alpha = 0.14f),
            categoryLabelBn = "জমা লেনদেন",
            categoryLabelEn = "Deposit",
        )
        NotificationType.DIVIDEND_PAYOUT -> NotificationVisualProps(
            icon = Icons.Filled.Savings,
            iconColor = incomeGreen,
            containerColor = incomeGreen.copy(alpha = 0.14f),
            categoryLabelBn = "লভ্যাংশ বিতরণ",
            categoryLabelEn = "Dividend",
        )
        NotificationType.DUE_REMINDER -> NotificationVisualProps(
            icon = Icons.Filled.HourglassTop,
            iconColor = dueAmber,
            containerColor = dueAmber.copy(alpha = 0.16f),
            categoryLabelBn = "কিস্তি তাগাদা",
            categoryLabelEn = "Due Reminder",
        )
        NotificationType.DEFAULTER_ALERT -> NotificationVisualProps(
            icon = Icons.Filled.WarningAmber,
            iconColor = expenseRed,
            containerColor = expenseRed.copy(alpha = 0.14f),
            categoryLabelBn = "বকেয়া সতর্কতা",
            categoryLabelEn = "Overdue Alert",
        )
        NotificationType.NEW_NOTICE -> NotificationVisualProps(
            icon = Icons.Filled.Campaign,
            iconColor = MaterialTheme.colorScheme.primary,
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "জরুরি বিজ্ঞপ্তি",
            categoryLabelEn = "Notice",
        )
        NotificationType.LOAN_REMINDER -> NotificationVisualProps(
            icon = Icons.Filled.Handshake,
            iconColor = MaterialTheme.colorScheme.secondary,
            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "ঋণ হিসাব",
            categoryLabelEn = "Loan Info",
        )
        NotificationType.EDIT_REQUEST_STATUS -> NotificationVisualProps(
            icon = Icons.AutoMirrored.Filled.FactCheck,
            iconColor = MaterialTheme.colorScheme.tertiary,
            containerColor = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "তথ্য পরিবর্তন",
            categoryLabelEn = "Edit Request",
        )
        NotificationType.SYSTEM_ALERT -> NotificationVisualProps(
            icon = Icons.Filled.Security,
            iconColor = MaterialTheme.colorScheme.primary,
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "সিস্টেম বার্তা",
            categoryLabelEn = "System Alert",
        )
    }
}

fun formatRelativeNotificationTime(timestamp: Long, isBangla: Boolean): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    return when {
        diff < 60_000L -> if (isBangla) "এইমাত্র" else "Just now"
        diff < 3600_000L -> {
            val mins = diff / 60_000L
            if (isBangla) "$mins মিনিট আগে" else "$mins min ago"
        }
        diff < 86400_000L -> {
            val hours = diff / 3600_000L
            if (isBangla) "$hours ঘণ্টা আগে" else "$hours hrs ago"
        }
        diff < (86400_000L * 2) -> if (isBangla) "গতকাল" else "Yesterday"
        else -> {
            val locale = if (isBangla) Locale.forLanguageTag("bn-BD") else Locale.getDefault()
            val sdf = SimpleDateFormat("dd MMM, yyyy", locale)
            sdf.format(Date(timestamp))
        }
    }
}
