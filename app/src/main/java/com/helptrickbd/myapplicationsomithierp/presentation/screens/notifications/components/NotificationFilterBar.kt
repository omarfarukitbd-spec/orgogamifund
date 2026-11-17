package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AllInbox
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.MarkEmailUnread
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.R

enum class NotificationFilter {
    ALL, UNREAD, PAYMENTS, REMINDERS, NOTICES
}

@Composable
fun NotificationFilterBar(
    selectedFilter: NotificationFilter,
    unreadCount: Int,
    onFilterSelected: (NotificationFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    val chipShape = RoundedCornerShape(10.dp)

    LazyRow(
        modifier = modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            ModernFilterChipItem(
                selected = selectedFilter == NotificationFilter.ALL,
                onClick = { onFilterSelected(NotificationFilter.ALL) },
                icon = Icons.Filled.AllInbox,
                label = stringResource(R.string.filter_all),
                shape = chipShape
            )
        }
        item {
            ModernFilterChipItem(
                selected = selectedFilter == NotificationFilter.UNREAD,
                onClick = { onFilterSelected(NotificationFilter.UNREAD) },
                icon = Icons.Filled.MarkEmailUnread,
                label = stringResource(R.string.filter_unread),
                badgeCount = if (unreadCount > 0) unreadCount else null,
                shape = chipShape
            )
        }
        item {
            ModernFilterChipItem(
                selected = selectedFilter == NotificationFilter.PAYMENTS,
                onClick = { onFilterSelected(NotificationFilter.PAYMENTS) },
                icon = Icons.Filled.Payments,
                label = stringResource(R.string.filter_payments),
                shape = chipShape
            )
        }
        item {
            ModernFilterChipItem(
                selected = selectedFilter == NotificationFilter.REMINDERS,
                onClick = { onFilterSelected(NotificationFilter.REMINDERS) },
                icon = Icons.Filled.HourglassTop,
                label = stringResource(R.string.filter_reminders),
                shape = chipShape
            )
        }
        item {
            ModernFilterChipItem(
                selected = selectedFilter == NotificationFilter.NOTICES,
                onClick = { onFilterSelected(NotificationFilter.NOTICES) },
                icon = Icons.Filled.Campaign,
                label = stringResource(R.string.filter_notices),
                shape = chipShape
            )
        }
    }
}

@Composable
private fun ModernFilterChipItem(
    selected: Boolean,
    onClick: () -> Unit,
    icon: ImageVector,
    label: String,
    shape: RoundedCornerShape,
    modifier: Modifier = Modifier,
    badgeCount: Int? = null
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        shape = shape,
        leadingIcon = {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = if (selected) {
                    MaterialTheme.colorScheme.onPrimaryContainer
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
            )
        },
        label = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp)
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium
                )
                if (badgeCount != null) {
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary
                    ) {
                        Text(
                            text = badgeCount.toString(),
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp)
                        )
                    }
                }
            }
        },
        border = if (selected) {
            BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.5f))
        } else {
            BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
        },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer,
            containerColor = MaterialTheme.colorScheme.surface,
            labelColor = MaterialTheme.colorScheme.onSurfaceVariant
        ),
        modifier = modifier
    )
}
