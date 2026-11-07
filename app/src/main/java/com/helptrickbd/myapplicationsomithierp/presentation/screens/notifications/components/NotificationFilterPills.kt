package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.AccessTimeFilled
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.MarkEmailUnread
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.NotificationFilter

private data class FilterItemData(
    val filter: NotificationFilter,
    val labelBn: String,
    val labelEn: String,
    val icon: ImageVector,
    val badgeCount: Int? = null
)

@Composable
fun NotificationFilterPills(
    selectedFilter: NotificationFilter,
    unreadCount: Int,
    totalCount: Int,
    onFilterSelected: (NotificationFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    val items = listOf(
        FilterItemData(
            filter = NotificationFilter.ALL,
            labelBn = "সব",
            labelEn = "All",
            icon = Icons.Default.AllInclusive,
            badgeCount = totalCount
        ),
        FilterItemData(
            filter = NotificationFilter.UNREAD,
            labelBn = "অপঠিত",
            labelEn = "Unread",
            icon = Icons.Default.MarkEmailUnread,
            badgeCount = unreadCount
        ),
        FilterItemData(
            filter = NotificationFilter.PAYMENTS,
            labelBn = "জমা ও লেনদেন",
            labelEn = "Payments",
            icon = Icons.AutoMirrored.Filled.ReceiptLong
        ),
        FilterItemData(
            filter = NotificationFilter.REMINDERS,
            labelBn = "তাগাদা",
            labelEn = "Reminders",
            icon = Icons.Default.AccessTimeFilled
        ),
        FilterItemData(
            filter = NotificationFilter.NOTICES,
            labelBn = "নোটিশ",
            labelEn = "Notices",
            icon = Icons.Default.Campaign
        )
    )

    LazyRow(
        modifier = modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(items.size) { index ->
            val item = items[index]
            val isSelected = selectedFilter == item.filter

            val containerColor by animateColorAsState(
                targetValue = if (isSelected) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surface,
                label = "pillContainer"
            )
            val contentColor by animateColorAsState(
                targetValue = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer
                else MaterialTheme.colorScheme.onSurfaceVariant,
                label = "pillContent"
            )
            val borderColor = if (isSelected) MaterialTheme.colorScheme.primary
            else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)

            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(containerColor)
                    .border(1.dp, borderColor, RoundedCornerShape(16.dp))
                    .clickable { onFilterSelected(item.filter) }
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = item.icon,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier.size(16.dp)
                )

                Text(
                    text = if (isBangla) item.labelBn else item.labelEn,
                    style = MaterialTheme.typography.labelMedium.copy(fontSize = 12.sp),
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                    color = contentColor
                )

                if (item.badgeCount != null && item.badgeCount > 0) {
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(
                                if (isSelected) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.surfaceVariant
                            )
                            .padding(horizontal = 6.dp, vertical = 1.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "${item.badgeCount}",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                            fontWeight = FontWeight.Bold,
                            color = if (isSelected) MaterialTheme.colorScheme.onPrimary
                            else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
