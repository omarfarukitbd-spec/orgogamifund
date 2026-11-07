package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components.*

enum class NotificationFilter {
    ALL, UNREAD, PAYMENTS, REMINDERS, NOTICES
}

@Composable
fun NotificationCenterScreen(
    notifications: List<NotificationItem>,
    onNotificationClick: (NotificationItem) -> Unit = {},
    onMarkAsRead: (String) -> Unit = {},
    onMarkAllAsRead: () -> Unit = {},
    onDeleteNotification: (String) -> Unit = {},
    onClearAll: () -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var selectedFilter by remember { mutableStateOf(NotificationFilter.ALL) }
    var showClearDialog by remember { mutableStateOf(false) }

    val unreadCount = remember(notifications) { notifications.count { !it.isRead } }

    val filteredList = remember(notifications, selectedFilter) {
        when (selectedFilter) {
            NotificationFilter.ALL -> notifications
            NotificationFilter.UNREAD -> notifications.filter { !it.isRead }
            NotificationFilter.PAYMENTS -> notifications.filter {
                it.type == NotificationType.PAYMENT_RECEIVED || it.type == NotificationType.DIVIDEND_PAYOUT
            }
            NotificationFilter.REMINDERS -> notifications.filter {
                it.type == NotificationType.DUE_REMINDER || it.type == NotificationType.DEFAULTER_ALERT
            }
            NotificationFilter.NOTICES -> notifications.filter {
                it.type == NotificationType.NEW_NOTICE || it.type == NotificationType.SYSTEM_ALERT
            }
        }
    }

    if (showClearDialog) {
        NotificationClearAllDialog(
            onConfirm = {
                showClearDialog = false
                onClearAll()
            },
            onDismiss = { showClearDialog = false }
        )
    }

    Scaffold(
        topBar = {
            NotificationTopBar(
                unreadCount = unreadCount,
                onNavigateBack = onNavigateBack,
                onMarkAllAsRead = onMarkAllAsRead,
                onPromptClearAll = { showClearDialog = true }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            NotificationFilterPills(
                selectedFilter = selectedFilter,
                unreadCount = unreadCount,
                totalCount = notifications.size,
                onFilterSelected = { selectedFilter = it }
            )

            if (filteredList.isEmpty()) {
                NotificationEmptyState(
                    selectedFilter = selectedFilter,
                    onResetFilter = { selectedFilter = NotificationFilter.ALL },
                    modifier = Modifier.weight(1f)
                )
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .weight(1f),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    item(key = "hero_banner") {
                        NotificationHeroBanner(
                            unreadCount = unreadCount,
                            totalCount = notifications.size,
                            onMarkAllAsRead = onMarkAllAsRead,
                            modifier = Modifier.padding(bottom = 6.dp)
                        )
                    }

                    val todayItems = filteredList.filter { categorizeTimeline(it.timestamp) == TimelinePeriod.TODAY }
                    val yesterdayItems = filteredList.filter { categorizeTimeline(it.timestamp) == TimelinePeriod.YESTERDAY }
                    val earlierItems = filteredList.filter { categorizeTimeline(it.timestamp) == TimelinePeriod.EARLIER }

                    if (todayItems.isNotEmpty()) {
                        item(key = "header_today") {
                            NotificationTimelineHeader(period = TimelinePeriod.TODAY, count = todayItems.size)
                        }
                        items(items = todayItems, key = { it.id }) { item ->
                            NotificationCard(
                                item = item,
                                onClick = {
                                    onMarkAsRead(item.id)
                                    onNotificationClick(item)
                                },
                                onDelete = { onDeleteNotification(item.id) },
                                onMarkAsRead = { onMarkAsRead(item.id) }
                            )
                        }
                    }

                    if (yesterdayItems.isNotEmpty()) {
                        item(key = "header_yesterday") {
                            NotificationTimelineHeader(period = TimelinePeriod.YESTERDAY, count = yesterdayItems.size)
                        }
                        items(items = yesterdayItems, key = { it.id }) { item ->
                            NotificationCard(
                                item = item,
                                onClick = {
                                    onMarkAsRead(item.id)
                                    onNotificationClick(item)
                                },
                                onDelete = { onDeleteNotification(item.id) },
                                onMarkAsRead = { onMarkAsRead(item.id) }
                            )
                        }
                    }

                    if (earlierItems.isNotEmpty()) {
                        item(key = "header_earlier") {
                            NotificationTimelineHeader(period = TimelinePeriod.EARLIER, count = earlierItems.size)
                        }
                        items(items = earlierItems, key = { it.id }) { item ->
                            NotificationCard(
                                item = item,
                                onClick = {
                                    onMarkAsRead(item.id)
                                    onNotificationClick(item)
                                },
                                onDelete = { onDeleteNotification(item.id) },
                                onMarkAsRead = { onMarkAsRead(item.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationEmptyState(
    selectedFilter: NotificationFilter,
    onResetFilter: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(76.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.NotificationsNone,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(38.dp)
                )
            }

            Text(
                text = if (isBangla) "কোনো বিজ্ঞপ্তি পাওয়া যায়নি" else "No Notifications Found",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Text(
                text = if (isBangla) "এই ক্যাটাগরিতে বর্তমানে কোনো অপঠিত বা নতুন বার্তা নেই।"
                else "There are currently no updates or unread messages in this section.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 24.dp)
            )

            if (selectedFilter != NotificationFilter.ALL) {
                Spacer(modifier = Modifier.height(4.dp))
                FilledTonalButton(
                    onClick = onResetFilter,
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = if (isBangla) "সকল বার্তা দেখুন" else "Show All Notifications",
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}
