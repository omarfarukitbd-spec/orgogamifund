package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Paid
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole

@Composable
fun DashboardModulesGrid(
    userRole: UserRole,
    onMembers: () -> Unit,
    onPayments: () -> Unit,
    onExpenses: () -> Unit,
    onLoans: () -> Unit,
    onBranches: () -> Unit,
    onReports: () -> Unit,
    onNotices: () -> Unit,
    onCommittee: () -> Unit,
    onDividends: () -> Unit,
    onAdminHub: () -> Unit,
    onIdCard: () -> Unit,
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = if (isBangla) "ব্যবস্থাপনা ও সেবা মডিউলসমূহ" else "Management & Services",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            // Row 1: Core Operations
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                ModuleItem(
                    icon = Icons.Default.Group,
                    title = if (isBangla) "সদস্য তালিকা" else "Members",
                    tint = MaterialTheme.colorScheme.primary,
                    onClick = onMembers,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.Paid,
                    title = if (isBangla) "চাঁদা ও সঞ্চয়" else "Collections",
                    tint = Color(0xFF10B981),
                    onClick = onPayments,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.Receipt,
                    title = if (isBangla) "খরচের খাতা" else "Expenses",
                    tint = Color(0xFFEF4444),
                    onClick = onExpenses,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.CreditCard,
                    title = if (isBangla) "ঋণ ও সাহায্য" else "Loans & Aid",
                    tint = Color(0xFFF59E0B),
                    onClick = onLoans,
                    modifier = Modifier.weight(1f)
                )
            }

            // Row 2: Community & Reports
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                ModuleItem(
                    icon = Icons.Default.Groups,
                    title = if (isBangla) "পরিচালনা কমিটি" else "Committee",
                    tint = Color(0xFF6366F1),
                    onClick = onCommittee,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.Campaign,
                    title = if (isBangla) "নোটিশ বোর্ড" else "Notices",
                    tint = Color(0xFFEC4899),
                    onClick = onNotices,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.PieChart,
                    title = if (isBangla) "লভ্যাংশ বণ্টন" else "Dividends",
                    tint = Color(0xFF8B5CF6),
                    onClick = onDividends,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.Print,
                    title = if (isBangla) "অডিট রিপোর্ট" else "Reports",
                    tint = Color(0xFF0EA5E9),
                    onClick = onReports,
                    modifier = Modifier.weight(1f)
                )
            }

            // Row 3: Admin & IDs
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                ModuleItem(
                    icon = Icons.Default.AccountBalance,
                    title = if (isBangla) "শাখা ব্যবস্থাপনা" else "Branches",
                    tint = Color(0xFF14B8A6),
                    onClick = onBranches,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.Badge,
                    title = if (isBangla) "আইডি কার্ড" else "ID Card",
                    tint = Color(0xFF3B82F6),
                    onClick = onIdCard,
                    modifier = Modifier.weight(1f)
                )
                ModuleItem(
                    icon = Icons.Default.AdminPanelSettings,
                    title = if (isBangla) "এডমিন হাব" else "Admin Hub",
                    tint = MaterialTheme.colorScheme.primary,
                    onClick = onAdminHub,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun ModuleItem(
    icon: ImageVector,
    title: String,
    tint: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(vertical = 4.dp, horizontal = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Surface(
            shape = CircleShape,
            color = tint.copy(alpha = 0.12f),
            modifier = Modifier.size(44.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = tint,
                    modifier = Modifier.size(22.dp)
                )
            }
        }

        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            maxLines = 1
        )
    }
}
