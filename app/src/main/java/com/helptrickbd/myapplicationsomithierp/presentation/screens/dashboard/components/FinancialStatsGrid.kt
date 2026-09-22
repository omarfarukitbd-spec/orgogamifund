package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AssignmentLate
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun FinancialStatsGrid(
    state: DashboardUiState,
    onNavigateToMembers: () -> Unit,
    onNavigateToLoans: () -> Unit,
    onNavigateToExpenses: () -> Unit,
    onNavigateToDefaulters: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(
            text = if (isBangla) "আর্থিক সারসংক্ষেপ ও প্রধান সূচক" else "Financial Overview & Key Metrics",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            MetricCard(
                title = if (isBangla) "সক্রিয় ঋণ ও সাহায্য" else "Active Loans & Aid",
                value = CurrencyFormatter.formatBDT(state.activeLoans, toBanglaDigits = isBangla),
                subtitle = if (isBangla) "বিনা লাভে ঋণ তহবিল" else "Interest-free fund",
                icon = Icons.Default.AttachMoney,
                tint = MaterialTheme.colorScheme.primary,
                onClick = onNavigateToLoans,
                modifier = Modifier.weight(1f)
            )

            MetricCard(
                title = if (isBangla) "মোট খরচ ও ভাউচার" else "Total Expenses",
                value = CurrencyFormatter.formatBDT(state.totalExpenses, toBanglaDigits = isBangla),
                subtitle = if (isBangla) "মাদরাসা ও পরিচালন ব্যয়" else "Aid & operations",
                icon = Icons.Default.ReceiptLong,
                tint = MoneyExpenseRed,
                onClick = onNavigateToExpenses,
                modifier = Modifier.weight(1f)
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            MetricCard(
                title = if (isBangla) "বকেয়া চাঁদা ও কিস্তি" else "Outstanding Dues",
                value = CurrencyFormatter.formatBDT(state.totalOutstandingDues, toBanglaDigits = isBangla),
                subtitle = if (isBangla) "${state.topDefaulterCount} জন সদস্য বকেয়া" else "${state.topDefaulterCount} members due",
                icon = Icons.Default.AssignmentLate,
                tint = MoneyDueAmber,
                onClick = onNavigateToDefaulters,
                modifier = Modifier.weight(1f)
            )

            MetricCard(
                title = if (isBangla) "সমিতির সদস্যবৃন্দ" else "Active Members",
                value = if (isBangla) "সদস্য তালিকা" else "Member Directory",
                subtitle = if (isBangla) "অনুমোদিত খতিয়ান" else "Approved register",
                icon = Icons.Default.Group,
                tint = MoneyIncomeGreen,
                onClick = onNavigateToMembers,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun MetricCard(
    title: String,
    value: String,
    subtitle: String,
    icon: ImageVector,
    tint: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = tint.copy(alpha = 0.12f),
                    modifier = Modifier.size(32.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            tint = tint,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                    color = tint,
                    maxLines = 1
                )
            }
        }
    }
}
