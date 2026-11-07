package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.AccessTimeFilled
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import com.helptrickbd.myapplicationsomithierp.ui.theme.financialColors
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

data class NotificationVisualProps(
    val icon: ImageVector,
    val accentColor: Color,
    val containerColor: Color,
    val categoryLabelBn: String,
    val categoryLabelEn: String
)

enum class TimelinePeriod {
    TODAY,
    YESTERDAY,
    EARLIER
}

@Composable
fun getNotificationVisualProps(type: NotificationType): NotificationVisualProps {
    val fc = MaterialTheme.financialColors
    val cs = MaterialTheme.colorScheme

    return when (type) {
        NotificationType.PAYMENT_RECEIVED -> NotificationVisualProps(
            icon = Icons.AutoMirrored.Filled.ReceiptLong,
            accentColor = fc.income,
            containerColor = fc.income.copy(alpha = 0.12f),
            categoryLabelBn = "জমা ও লেনদেন",
            categoryLabelEn = "Collection"
        )
        NotificationType.DUE_REMINDER -> NotificationVisualProps(
            icon = Icons.Filled.AccessTimeFilled,
            accentColor = fc.due,
            containerColor = fc.due.copy(alpha = 0.14f),
            categoryLabelBn = "চাঁদার তাগাদা",
            categoryLabelEn = "Due Reminder"
        )
        NotificationType.DEFAULTER_ALERT -> NotificationVisualProps(
            icon = Icons.Filled.Warning,
            accentColor = fc.expense,
            containerColor = fc.expense.copy(alpha = 0.12f),
            categoryLabelBn = "জরুরি বকেয়া",
            categoryLabelEn = "Overdue Alert"
        )
        NotificationType.NEW_NOTICE -> NotificationVisualProps(
            icon = Icons.Filled.Campaign,
            accentColor = cs.tertiary,
            containerColor = cs.tertiaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "সমিতি নোটিশ",
            categoryLabelEn = "Announcement"
        )
        NotificationType.EDIT_REQUEST_STATUS -> NotificationVisualProps(
            icon = Icons.Filled.EditNote,
            accentColor = cs.secondary,
            containerColor = cs.secondaryContainer.copy(alpha = 0.5f),
            categoryLabelBn = "তথ্য হালনাগাদ",
            categoryLabelEn = "Profile Edit"
        )
        NotificationType.DIVIDEND_PAYOUT -> NotificationVisualProps(
            icon = Icons.Filled.MonetizationOn,
            accentColor = fc.income,
            containerColor = fc.income.copy(alpha = 0.14f),
            categoryLabelBn = "মুনাফা বণ্টন",
            categoryLabelEn = "Dividend Payout"
        )
        NotificationType.SYSTEM_ALERT -> NotificationVisualProps(
            icon = Icons.Filled.Notifications,
            accentColor = cs.primary,
            containerColor = cs.primaryContainer.copy(alpha = 0.45f),
            categoryLabelBn = "সিস্টেম বার্তা",
            categoryLabelEn = "System Notice"
        )
    }
}

fun formatRelativeTime(timestamp: Long, isBangla: Boolean): String {
    val now = System.currentTimeMillis()
    val diff = (now - timestamp).coerceAtLeast(0L)

    return when {
        diff < 60_000L -> if (isBangla) "এইমাত্র" else "Just now"
        diff < 3600_000L -> {
            val mins = diff / 60_000L
            if (isBangla) "$mins মিনিট আগে" else "${mins}m ago"
        }
        diff < 86400_000L -> {
            val hours = diff / 3600_000L
            if (isBangla) "$hours ঘণ্টা আগে" else "${hours}h ago"
        }
        diff < 86400_000L * 2 -> if (isBangla) "গতকাল" else "Yesterday"
        else -> {
            val locale = if (isBangla) Locale("bn", "BD") else Locale.ENGLISH
            val sdf = SimpleDateFormat("dd MMM, yyyy", locale)
            sdf.format(Date(timestamp))
        }
    }
}

fun categorizeTimeline(timestamp: Long): TimelinePeriod {
    val now = Calendar.getInstance()
    val then = Calendar.getInstance().apply { timeInMillis = timestamp }

    val isSameYear = now.get(Calendar.YEAR) == then.get(Calendar.YEAR)
    val dayDiff = now.get(Calendar.DAY_OF_YEAR) - then.get(Calendar.DAY_OF_YEAR)

    return when {
        isSameYear && dayDiff == 0 -> TimelinePeriod.TODAY
        isSameYear && dayDiff == 1 -> TimelinePeriod.YESTERDAY
        else -> TimelinePeriod.EARLIER
    }
}

fun extractHighlightInfo(message: String): String? {
    val rcpRegex = Regex("""(RCP-[A-Za-z0-9\-]+)""")
    val rcpMatch = rcpRegex.find(message)
    if (rcpMatch != null) return rcpMatch.value

    val amountRegex = Regex("""(৳\s*[\d,]+)""")
    val amountMatch = amountRegex.find(message)
    if (amountMatch != null) return amountMatch.value

    return null
}
