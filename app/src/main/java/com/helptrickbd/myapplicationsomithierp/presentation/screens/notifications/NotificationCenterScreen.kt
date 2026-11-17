package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components.NotificationFilter
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components.NotificationFilterBar
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components.NotificationItemCard

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
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
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
                it.type == NotificationType.DUE_REMINDER || it.type == NotificationType.DEFAULTER_ALERT || it.type == NotificationType.LOAN_REMINDER
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
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = stringResource(R.string.notification_center_title),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        if (unreadCount > 0) {
                            Text(
                                text = if (isBangla) "$unreadCount টি অপঠিত বার্তা" else "$unreadCount unread messages",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    if (unreadCount > 0) {
                        IconButton(onClick = onMarkAllAsRead) {
                            Icon(
                                imageVector = Icons.Filled.DoneAll,
                                contentDescription = stringResource(R.string.mark_all_read),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    IconButton(onClick = { showMenu = !showMenu }) {
                        Icon(
                            imageVector = Icons.Filled.MoreVert,
                            contentDescription = "Options"
                        )
                    }
                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.mark_all_read)) },
                            leadingIcon = {
                                Icon(Icons.Filled.DoneAll, contentDescription = null)
                            },
                            onClick = {
                                onMarkAllAsRead()
                                showMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.clear_all_notifications)) },
                            leadingIcon = {
                                Icon(
                                    Icons.Filled.DeleteSweep,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error
                                )
                            },
                            onClick = {
                                onClearAll()
                                showMenu = false
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Modern Filter Carousel Bar
            NotificationFilterBar(
                selectedFilter = selectedFilter,
                unreadCount = unreadCount,
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
                    items(
                        items = filteredList,
                        key = { it.id }
                    ) { item ->
                        NotificationItemCard(
                            item = item,
                            isBangla = isBangla,
                            onClick = {
                                onMarkAsRead(item.id)
                                onNotificationClick(item)
                            },
                            onDelete = { onDeleteNotification(item.id) }
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
