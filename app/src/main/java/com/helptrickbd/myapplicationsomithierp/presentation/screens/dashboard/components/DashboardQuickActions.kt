package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun DashboardQuickActions(
    onCollectPayment: () -> Unit,
    onAddExpense: () -> Unit,
    onIssueLoan: () -> Unit,
    onAddMember: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(
                text = if (isBangla) "তাত্ক্ষণিক লেনদেন ও কার্যক্রম" else "Quick Actions",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                QuickActionButton(
                    icon = Icons.Default.ArrowUpward,
                    label = if (isBangla) "টাকা জমা" else "Deposit",
                    tint = MoneyIncomeGreen,
                    onClick = onCollectPayment,
                    modifier = Modifier.weight(1f)
                )

                QuickActionButton(
                    icon = Icons.Default.ArrowDownward,
                    label = if (isBangla) "খরচ এন্ট্রি" else "Expense",
                    tint = MoneyExpenseRed,
                    onClick = onAddExpense,
                    modifier = Modifier.weight(1f)
                )

                QuickActionButton(
                    icon = Icons.Default.Add,
                    label = if (isBangla) "ঋণ ও সাহায্য" else "Issue Loan",
                    tint = MoneyDueAmber,
                    onClick = onIssueLoan,
                    modifier = Modifier.weight(1f)
                )

                QuickActionButton(
                    icon = Icons.Default.PersonAdd,
                    label = if (isBangla) "নতুন সদস্য" else "Add Member",
                    tint = MaterialTheme.colorScheme.primary,
                    onClick = onAddMember,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    tint: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(vertical = 4.dp, horizontal = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Surface(
            shape = CircleShape,
            color = tint.copy(alpha = 0.14f),
            modifier = Modifier.size(50.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = label,
                    tint = tint,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            maxLines = 1
        )
    }
}
