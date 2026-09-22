package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun SystemModulesGrid(
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
    onIdCard: () -> Unit
) {
    Column {
        Text(
            text = "ব্যবস্থাপনা ও কার্যক্রম",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 10.dp)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModuleTile(
                title = "আমার মেম্বার কার্ড",
                icon = Icons.Default.Badge,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.weight(1f),
                onClick = onIdCard
            )
            ModuleTile(
                title = "সদস্য তালিকা",
                icon = Icons.Default.Groups,
                color = Color(0xFF0284C7),
                modifier = Modifier.weight(1f),
                onClick = onMembers
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModuleTile(
                title = "লেনদেন বিবরণী",
                icon = Icons.Default.Receipt,
                color = MoneyIncomeGreen,
                modifier = Modifier.weight(1f),
                onClick = onPayments
            )
            ModuleTile(
                title = "খরচ রেজিস্টার",
                icon = Icons.Default.MoneyOff,
                color = MoneyExpenseRed,
                modifier = Modifier.weight(1f),
                onClick = onExpenses
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModuleTile(
                title = "ঋণ ও দাদন",
                icon = Icons.Default.CreditCard,
                color = Color(0xFFD97706),
                modifier = Modifier.weight(1f),
                onClick = onLoans
            )
            ModuleTile(
                title = "শাখা ব্যবস্থাপনা",
                icon = Icons.Default.Apartment,
                color = Color(0xFF0D9488),
                modifier = Modifier.weight(1f),
                onClick = onBranches
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModuleTile(
                title = "রিপোর্টস ও প্রিন্ট",
                icon = Icons.Default.Print,
                color = Color(0xFF4F46E5),
                modifier = Modifier.weight(1f),
                onClick = onReports
            )
            ModuleTile(
                title = "নোটিশ ও রেজুলেশন",
                icon = Icons.Default.Campaign,
                color = Color(0xFFE11D48),
                modifier = Modifier.weight(1f),
                onClick = onNotices
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModuleTile(
                title = "কমিটি ডিরেক্টরি",
                icon = Icons.Default.Star,
                color = Color(0xFF8B5CF6),
                modifier = Modifier.weight(1f),
                onClick = onCommittee
            )
            ModuleTile(
                title = "বার্ষিক লভ্যাংশ",
                icon = Icons.Default.PieChart,
                color = Color(0xFFF59E0B),
                modifier = Modifier.weight(1f),
                onClick = onDividends
            )
        }
    }
}

@Composable
private fun ModuleTile(
    title: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = color.copy(alpha = 0.12f),
                modifier = Modifier.size(42.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(imageVector = icon, contentDescription = title, tint = color, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1
            )
        }
    }
}
