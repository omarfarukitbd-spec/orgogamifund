package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Rule
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.ShomitiMembershipStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun BranchCarousel(
    branches: List<Branch>,
    selectedBranchId: String,
    currentStatus: ShomitiMembershipStatus,
    userRole: UserRole,
    onSelectBranch: (String) -> Unit,
    onViewTerms: (Branch) -> Unit,
    onViewIdCard: (Branch) -> Unit
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "অগ্রগামী ফান্ডের শাখাসমূহ",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "যেকোনো শাখায় ট্যাপ করে তথ্য ও লেনদেন দেখুন",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            items(branches) { branch ->
                val isSelected = branch.id == selectedBranchId

                val branchStatus = when {
                    userRole == UserRole.SUPER_ADMIN -> ShomitiMembershipStatus.APPROVED_MEMBER
                    isSelected -> currentStatus
                    branch.id == "b-1" -> ShomitiMembershipStatus.APPROVED_MEMBER
                    branch.id == "b-2" -> ShomitiMembershipStatus.PENDING_APPROVAL
                    else -> ShomitiMembershipStatus.NOT_A_MEMBER
                }

                Card(
                    modifier = Modifier
                        .width(280.dp)
                        .clickable { onSelectBranch(branch.id) },
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                        else MaterialTheme.colorScheme.surface
                    ),
                    border = BorderStroke(
                        width = if (isSelected) 2.dp else 1.dp,
                        color = if (isSelected) MaterialTheme.colorScheme.primary
                        else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)
                    ),
                    elevation = CardDefaults.cardElevation(defaultElevation = if (isSelected) 4.dp else 1.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                                ) {
                                    Text(
                                        text = branch.code.ifBlank { "শাখা" },
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                                if (branch.establishedYear.isNotBlank()) {
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "স্থাপিত ${branch.establishedYear}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }

                            // Status badge with Material 3 vector icon
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = when (branchStatus) {
                                    ShomitiMembershipStatus.APPROVED_MEMBER -> MoneyIncomeGreen.copy(alpha = 0.15f)
                                    ShomitiMembershipStatus.PENDING_APPROVAL -> MoneyDueAmber.copy(alpha = 0.15f)
                                    ShomitiMembershipStatus.NOT_A_MEMBER -> MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = when (branchStatus) {
                                            ShomitiMembershipStatus.APPROVED_MEMBER -> Icons.Default.CheckCircle
                                            ShomitiMembershipStatus.PENDING_APPROVAL -> Icons.Default.HourglassTop
                                            ShomitiMembershipStatus.NOT_A_MEMBER -> Icons.Default.Info
                                        },
                                        contentDescription = null,
                                        tint = when (branchStatus) {
                                            ShomitiMembershipStatus.APPROVED_MEMBER -> MoneyIncomeGreen
                                            ShomitiMembershipStatus.PENDING_APPROVAL -> MoneyDueAmber
                                            ShomitiMembershipStatus.NOT_A_MEMBER -> MaterialTheme.colorScheme.onSurfaceVariant
                                        },
                                        modifier = Modifier.size(12.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = when (branchStatus) {
                                            ShomitiMembershipStatus.APPROVED_MEMBER -> "অনুমোদিত সদস্য"
                                            ShomitiMembershipStatus.PENDING_APPROVAL -> "পর্যালোচনাধীন"
                                            ShomitiMembershipStatus.NOT_A_MEMBER -> "সদস্য নন"
                                        },
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.SemiBold,
                                        color = when (branchStatus) {
                                            ShomitiMembershipStatus.APPROVED_MEMBER -> MoneyIncomeGreen
                                            ShomitiMembershipStatus.PENDING_APPROVAL -> MoneyDueAmber
                                            ShomitiMembershipStatus.NOT_A_MEMBER -> MaterialTheme.colorScheme.onSurfaceVariant
                                        }
                                    )
                                }
                            }
                        }

                        Text(
                            text = branch.name,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 1
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column {
                                Text(
                                    text = "মাসিক সঞ্চয়",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "৳${branch.monthlyDepositAmount.toInt()}",
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    text = "সদস্য সংখ্যা",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "${branch.memberCount} জন",
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }

                        // Footer Actions
                        when (branchStatus) {
                            ShomitiMembershipStatus.APPROVED_MEMBER -> {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "নিয়ম ও শর্তাবলী",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.clickable { onViewTerms(branch) }
                                    )
                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                                        modifier = Modifier.clickable { onViewIdCard(branch) }
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.CreditCard,
                                                contentDescription = null,
                                                tint = MaterialTheme.colorScheme.primary,
                                                modifier = Modifier.size(13.dp)
                                            )
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text(
                                                text = "আইডি কার্ড",
                                                style = MaterialTheme.typography.labelSmall,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.primary
                                            )
                                        }
                                    }
                                }
                            }
                            ShomitiMembershipStatus.PENDING_APPROVAL -> {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = MoneyDueAmber.copy(alpha = 0.12f),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { onViewTerms(branch) }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.Center
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.HourglassTop,
                                            contentDescription = null,
                                            tint = MoneyDueAmber,
                                            modifier = Modifier.size(13.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = "আবেদন এডমিন যাচাই করছেন",
                                            style = MaterialTheme.typography.labelSmall,
                                            fontWeight = FontWeight.Bold,
                                            color = MoneyDueAmber
                                        )
                                    }
                                }
                            }
                            ShomitiMembershipStatus.NOT_A_MEMBER -> {
                                Button(
                                    onClick = { onViewTerms(branch) },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(34.dp),
                                    shape = RoundedCornerShape(8.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Rule,
                                        contentDescription = null,
                                        modifier = Modifier.size(13.dp)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "শর্তাবলী ও সদস্যপদ আবেদন",
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
