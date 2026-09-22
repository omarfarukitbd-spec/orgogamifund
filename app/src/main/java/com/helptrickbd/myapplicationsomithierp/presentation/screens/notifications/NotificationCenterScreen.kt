package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.AccessTimeFilled
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class NotificationFilter {
    ALL, UNREAD, PAYMENTS, REMINDERS, NOTICES
}

@OptIn(ExperimentalMaterial3Api::class)
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
    var showMenu by remember { mutableStateOf(false) }

    val filteredList = remember(notifications, selectedFilter) {
        when (selectedFilter) {
            NotificationFilter.ALL -> notifications
            NotificationFilter.UNREAD -> notifications.filter { !it.isRead }
            NotificationFilter.PAYMENTS -> notifications.filter { it.type == NotificationType.PAYMENT_RECEIVED || it.type == NotificationType.DIVIDEND_PAYOUT }
            NotificationFilter.REMINDERS -> notifications.filter { it.type == NotificationType.DUE_REMINDER || it.type == NotificationType.DEFAULTER_ALERT || it.type == NotificationType.LOAN_REMINDER }
            NotificationFilter.NOTICES -> notifications.filter { it.type == NotificationType.NEW_NOTICE || it.type == NotificationType.SYSTEM_ALERT }
        }
    }

    val unreadCount = remember(notifications) { notifications.count { !it.isRead } }

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
                                text = "$unreadCount টি অপঠিত বার্তা",
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
                                Icon(Icons.Filled.DeleteSweep, contentDescription = null, tint = MaterialTheme.colorScheme.error)
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
            // Filter Chips Row
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedFilter == NotificationFilter.ALL,
                        onClick = { selectedFilter = NotificationFilter.ALL },
                        label = { Text(stringResource(R.string.filter_all)) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == NotificationFilter.UNREAD,
                        onClick = { selectedFilter = NotificationFilter.UNREAD },
                        label = {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(stringResource(R.string.filter_unread))
                                if (unreadCount > 0) {
                                    Surface(
                                        shape = CircleShape,
                                        color = MaterialTheme.colorScheme.primary
                                    ) {
                                        Text(
                                            text = "$unreadCount",
                                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                            color = MaterialTheme.colorScheme.onPrimary,
                                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp)
                                        )
                                    }
                                }
                            }
                        }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == NotificationFilter.PAYMENTS,
                        onClick = { selectedFilter = NotificationFilter.PAYMENTS },
                        label = { Text(stringResource(R.string.filter_payments)) }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == NotificationFilter.REMINDERS,
                        onClick = { selectedFilter = NotificationFilter.REMINDERS },
                        label = { Text(stringResource(R.string.filter_reminders)) }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == NotificationFilter.NOTICES,
                        onClick = { selectedFilter = NotificationFilter.NOTICES },
                        label = { Text(stringResource(R.string.filter_notices)) }
                    )
                }
            }

            // Notification Items or Empty State
            if (filteredList.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyStateView(
                        icon = Icons.Filled.NotificationsNone,
                        title = stringResource(R.string.no_notifications),
                        description = stringResource(R.string.no_notifications_desc)
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(
                        items = filteredList,
                        key = { it.id }
                    ) { item ->
                        NotificationItemCard(
                            item = item,
                            onClick = {
                                onMarkAsRead(item.id)
                                onNotificationClick(item)
                            },
                            onDelete = { onDeleteNotification(item.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationItemCard(
    item: NotificationItem,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    val visualProps = getNotificationVisualProps(item.type)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (!item.isRead) {
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
            } else {
                MaterialTheme.colorScheme.surface
            }
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (!item.isRead) 2.dp else 0.5.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Category Icon Badge
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(visualProps.containerColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = visualProps.icon,
                    contentDescription = null,
                    tint = visualProps.iconColor,
                    modifier = Modifier.size(22.dp)
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            // Text info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = if (!item.isRead) FontWeight.Bold else FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    // Unread Dot
                    if (!item.isRead) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = item.message,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 18.sp
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatRelativeTime(item.timestamp),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline
                    )

                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Delete,
                            contentDescription = "Delete",
                            tint = MaterialTheme.colorScheme.outline.copy(alpha = 0.6f),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }
    }
}

private data class NotificationVisualProps(
    val icon: ImageVector,
    val iconColor: Color,
    val containerColor: Color
)

@Composable
private fun getNotificationVisualProps(type: NotificationType): NotificationVisualProps {
    return when (type) {
        NotificationType.PAYMENT_RECEIVED -> NotificationVisualProps(
            icon = Icons.AutoMirrored.Filled.ReceiptLong,
            iconColor = Color(0xFF16A34A),
            containerColor = Color(0xFFDCFCE7)
        )
        NotificationType.DUE_REMINDER, NotificationType.DEFAULTER_ALERT -> NotificationVisualProps(
            icon = Icons.Filled.AccessTimeFilled,
            iconColor = Color(0xFFD97706),
            containerColor = Color(0xFFFEF3C7)
        )
        NotificationType.NEW_NOTICE -> NotificationVisualProps(
            icon = Icons.Filled.Campaign,
            iconColor = Color(0xFF0284C7),
            containerColor = Color(0xFFE0F2FE)
        )
        NotificationType.LOAN_REMINDER -> NotificationVisualProps(
            icon = Icons.Filled.AccountBalance,
            iconColor = Color(0xFF7C3AED),
            containerColor = Color(0xFFEDE9FE)
        )
        NotificationType.DIVIDEND_PAYOUT -> NotificationVisualProps(
            icon = Icons.Filled.MonetizationOn,
            iconColor = Color(0xFF059669),
            containerColor = Color(0xFFD1FAE5)
        )
        else -> NotificationVisualProps(
            icon = Icons.Filled.Notifications,
            iconColor = MaterialTheme.colorScheme.primary,
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
        )
    }
}

private fun formatRelativeTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    return when {
        diff < 60_000L -> "এইমাত্র"
        diff < 3600_000L -> "${diff / 60_000L} মিনিট আগে"
        diff < 86400_000L -> "${diff / 3600_000L} ঘণ্টা আগে"
        diff < 86400_000L * 2 -> "গতকাল"
        else -> {
            val sdf = SimpleDateFormat("dd MMM, yyyy", Locale.getDefault())
            sdf.format(Date(timestamp))
        }
    }
}
