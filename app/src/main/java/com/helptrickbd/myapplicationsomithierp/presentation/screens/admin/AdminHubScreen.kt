package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.AdminFinancialControlCategory
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.AdminMemberControlCategory
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.AdminProfileHeroCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.AdminQuickStatItem
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.AdminSystemControlCategory
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminHubScreen(
    userRole: UserRole = UserRole.SUPER_ADMIN,
    pendingApplicationsCount: Int = 0,
    totalMembersCount: Int = 0,
    totalFundBalance: Double = 0.0,
    activeBranchesCount: Int = 0,
    pendingDepositsCount: Int = 0,
    onNavigateToApprovals: () -> Unit = {},
    onNavigateToPendingDeposits: () -> Unit = {},
    onNavigateToCreateSomithi: () -> Unit = {},
    onNavigateToMembers: () -> Unit = {},
    onNavigateToAddMember: () -> Unit = {},
    onNavigateToEditRequests: () -> Unit = {},
    onNavigateToCollectPayment: () -> Unit = {},
    onNavigateToAddExpense: () -> Unit = {},
    onNavigateToIssueLoan: () -> Unit = {},
    onNavigateToDividends: () -> Unit = {},
    onNavigateToDefaulters: () -> Unit = {},
    onNavigateToBranches: () -> Unit = {},
    onNavigateToCommittee: () -> Unit = {},
    onNavigateToNotices: () -> Unit = {},
    onNavigateToReports: () -> Unit = {},
    onTriggerBackup: () -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var isSuperAdminOverride by remember { mutableStateOf(false) }
    val effectiveRole = if (isSuperAdminOverride) UserRole.SUPER_ADMIN else userRole
    val isAdmin = effectiveRole == UserRole.SUPER_ADMIN || effectiveRole == UserRole.BRANCH_ADMIN
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            painter = painterResource(id = R.drawable.ogrogami_fund_logo),
                            contentDescription = "Logo",
                            modifier = Modifier
                                .size(32.dp)
                                .clip(RoundedCornerShape(8.dp))
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = if (isBangla) "এডমিন হাব" else "Admin Hub",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = if (isBangla) "অগ্রগামী ফান্ড • কেন্দ্রীয় প্রশাসনিক নিয়ন্ত্রণ" else "Ogrogami Fund • Central Administration",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { innerPadding ->
        if (!isAdmin) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(28.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(90.dp)
                            .clip(CircleShape)
                            .background(MoneyExpenseRed.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = null,
                            tint = MoneyExpenseRed,
                            modifier = Modifier.size(48.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = if (isBangla) "এডমিন অনুমোদন প্রয়োজন" else "Admin Approval Required",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = if (isBangla) "আপনি কি সিস্টেমের মূল পরিচালক (ফারুক)? নিচের বাটনে চাপ দিয়ে সরাসরি সুপার এডমিন হিসেবে হাব উন্মুক্ত করুন।" 
                        else "Are you the system owner (Faruk)? Tap below to immediately unlock the Super Admin Hub.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    Button(
                        onClick = { isSuperAdminOverride = true },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        modifier = Modifier.fillMaxWidth().height(48.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.AdminPanelSettings,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (isBangla) "সুপার এডমিন হিসেবে প্রবেশ করুন (ফারুক)" else "Enter as Super Admin (Faruk)",
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedButton(
                        onClick = onNavigateBack,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth().height(44.dp)
                    ) {
                        Text(if (isBangla) "ড্যাশবোর্ডে ফিরে যান" else "Back to Dashboard")
                    }
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                AdminProfileHeroCard(
                    userRole = effectiveRole,
                    pendingCount = pendingApplicationsCount,
                    onViewPending = onNavigateToApprovals
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    AdminQuickStatItem(
                        label = if (isBangla) "অপেক্ষমাণ আবেদন" else "Pending Apps",
                        value = if (isBangla) "$pendingApplicationsCount টি" else "$pendingApplicationsCount",
                        color = if (pendingApplicationsCount > 0) MoneyDueAmber else MoneyIncomeGreen,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToApprovals
                    )
                    AdminQuickStatItem(
                        label = if (isBangla) "অপেক্ষমাণ জমা" else "Pending Deposits",
                        value = if (isBangla) "$pendingDepositsCount টি" else "$pendingDepositsCount",
                        color = if (pendingDepositsCount > 0) MoneyDueAmber else MoneyIncomeGreen,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToPendingDeposits
                    )
                    AdminQuickStatItem(
                        label = if (isBangla) "মোট সদস্য" else "Total Members",
                        value = if (isBangla) "$totalMembersCount জন" else "$totalMembersCount",
                        color = Color(0xFF0284C7),
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToMembers
                    )
                    AdminQuickStatItem(
                        label = if (isBangla) "সক্রিয় সমিতি" else "Active Somithi",
                        value = if (isBangla) "$activeBranchesCount টি" else "$activeBranchesCount",
                        color = Color(0xFF0D9488),
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToBranches
                    )
                }

                AdminMemberControlCategory(
                    isBangla = isBangla,
                    pendingApplicationsCount = pendingApplicationsCount,
                    onNavigateToApprovals = onNavigateToApprovals,
                    onNavigateToMembers = onNavigateToMembers,
                    onNavigateToAddMember = onNavigateToAddMember,
                    onNavigateToEditRequests = onNavigateToEditRequests
                )

                AdminFinancialControlCategory(
                    isBangla = isBangla,
                    pendingDepositsCount = pendingDepositsCount,
                    onNavigateToPendingDeposits = onNavigateToPendingDeposits,
                    onNavigateToCollectPayment = onNavigateToCollectPayment,
                    onNavigateToAddExpense = onNavigateToAddExpense,
                    onNavigateToIssueLoan = onNavigateToIssueLoan,
                    onNavigateToDividends = onNavigateToDividends,
                    onNavigateToDefaulters = onNavigateToDefaulters
                )

                AdminSystemControlCategory(
                    isBangla = isBangla,
                    onNavigateToCreateSomithi = onNavigateToCreateSomithi,
                    onNavigateToBranches = onNavigateToBranches,
                    onNavigateToCommittee = onNavigateToCommittee,
                    onNavigateToNotices = onNavigateToNotices,
                    onNavigateToReports = onNavigateToReports,
                    onTriggerBackup = onTriggerBackup
                )

                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
}
