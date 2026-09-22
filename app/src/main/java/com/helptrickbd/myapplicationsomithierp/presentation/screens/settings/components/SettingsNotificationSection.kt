package com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun SettingsNotificationSection(
    pushNotifEnabled: Boolean,
    paymentAlertsEnabled: Boolean,
    reminderAlertsEnabled: Boolean,
    onPushNotifToggle: (Boolean) -> Unit,
    onPaymentAlertsToggle: (Boolean) -> Unit,
    onReminderAlertsToggle: (Boolean) -> Unit,
    onNavigateToNotifications: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = if (isBangla) "নোটিফিকেশন ও অ্যালার্ট" else "Notifications & Alerts",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(horizontal = 4.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Column {
                SettingsClickableRow(
                    icon = Icons.Default.Notifications,
                    title = if (isBangla) "নোটিফিকেশন সেন্টার" else "Notification Center",
                    subtitle = if (isBangla) "আগত সকল বার্তা ও লেনদেনের নোটিশ দেখুন" else "View all announcements and alerts",
                    onClick = onNavigateToNotifications
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsToggleRow(
                    icon = Icons.Default.NotificationsActive,
                    title = if (isBangla) "পুশ নোটিফিকেশন" else "Push Notifications",
                    subtitle = if (isBangla) "অ্যাপ বন্ধ থাকলেও নোটিফিকেশন প্রদর্শন" else "Show alerts when app is in background",
                    checked = pushNotifEnabled,
                    onCheckedChange = onPushNotifToggle
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsToggleRow(
                    icon = Icons.Default.Receipt,
                    title = if (isBangla) "চাঁদা ও লেনদেন বার্তা" else "Payment Alerts",
                    subtitle = if (isBangla) "টাকা জমা ও খরচের সাথে সাথে নিশ্চিতকরণ" else "Instant receipt confirmation messages",
                    checked = paymentAlertsEnabled,
                    onCheckedChange = onPaymentAlertsToggle
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsToggleRow(
                    icon = Icons.Default.AccessTime,
                    title = if (isBangla) "বকেয়া ও কিস্তি তাগাদা" else "Due Reminders",
                    subtitle = if (isBangla) "তারিখ পার হওয়ার আগে স্বয়ংক্রিয় স্মরণ" else "Remind before contribution due date",
                    checked = reminderAlertsEnabled,
                    onCheckedChange = onReminderAlertsToggle
                )
            }
        }
    }
}
