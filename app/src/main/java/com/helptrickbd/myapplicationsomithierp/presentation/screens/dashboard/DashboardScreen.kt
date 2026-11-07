package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.ShomitiMembershipStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components.*

data class DashboardUiState(
    val isLoading: Boolean = false,
    val isOffline: Boolean = false,
    val orgName: String = "অগ্রগামী ফান্ড",
    val userRole: UserRole = UserRole.SUPER_ADMIN,
    val userName: String = "",
    val userPhotoUrl: String? = null,
    val userEmail: String = "",
    val activeMemberId: String? = "m-101",
    val selectedBranchId: String = "b-1",
    val branches: List<Branch> = emptyList(),
    val currentBranchMembershipStatus: ShomitiMembershipStatus = ShomitiMembershipStatus.APPROVED_MEMBER,
    val totalFundBalance: Double = 850000.0,
    val thisMonthCollection: Double = 85000.0,
    val totalExpenses: Double = 18500.0,
    val totalOutstandingDues: Double = 12000.0,
    val topDefaulterCount: Int = 3,
    val unreadNotificationCount: Int = 2,
    val pendingApplicationsCount: Int = 0,
    val recentPayments: List<Payment> = emptyList()
)

@Composable
fun DashboardScreen(
    state: DashboardUiState = DashboardUiState(),
    onOpenDrawer: () -> Unit = {},
    onSelectBranch: (String) -> Unit = {},
    onApplyForMembership: (branchId: String) -> Unit = {},
    onNavigateToMemberCard: (memberId: String) -> Unit = {},
    onNavigateToSearch: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToCollectPayment: () -> Unit = {},
    onNavigateToAddExpense: () -> Unit = {},
    onNavigateToAddMember: () -> Unit = {},
    onNavigateToDefaulters: () -> Unit = {},
    onNavigateToMembers: () -> Unit = {},
    onNavigateToPayments: () -> Unit = {},
    onNavigateToCommittee: () -> Unit = {},
    onNavigateToNotices: () -> Unit = {},
    onNavigateToDividends: () -> Unit = {},
    onNavigateToExpenses: () -> Unit = {},
    onNavigateToBranches: () -> Unit = {},
    onNavigateToReports: () -> Unit = {},
    onNavigateToAdminHub: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {},
    onNavigateToPassbook: (memberId: String) -> Unit = {},
    onNavigateToCreateSomithi: () -> Unit = {},
    onNavigateToEditSomithi: (String) -> Unit = {},
    onAddActivityPhoto: (branchId: String, photoUrl: String) -> Unit = { _, _ -> }
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var termsBranchToView by remember { mutableStateOf<Branch?>(null) }
    var showSomithiSwitcher by remember { mutableStateOf(false) }
    var showAddPhotoDialog by remember { mutableStateOf(false) }
    var newPhotoUrlInput by remember { mutableStateOf("") }

    val activeBranch = state.branches.find { it.id == state.selectedBranchId }
        ?: state.branches.firstOrNull()
        ?: Branch(id = "", name = if (isBangla) "অগ্রগামী ফান্ড" else "Ogrogami Fund")

    val isApprovedAccess = state.userRole == UserRole.SUPER_ADMIN ||
        state.currentBranchMembershipStatus == ShomitiMembershipStatus.APPROVED_MEMBER

    Scaffold(
        topBar = {
            DashboardTopBar(
                state = state,
                onOpenDrawer = onOpenDrawer,
                onNavigateToNotifications = onNavigateToNotifications,
                onNavigateToSearch = onNavigateToSearch,
                onNavigateToProfile = onNavigateToSettings,
                onSwitchSomithi = { showSomithiSwitcher = true }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. Somithi Hero Banner with Cover, Logo, Name & Quick Switcher
            item {
                SomithiHeroBanner(
                    branch = activeBranch,
                    onSwitchSomithi = { showSomithiSwitcher = true },
                    onEditSomithi = if (state.userRole == UserRole.SUPER_ADMIN) {
                        { onNavigateToEditSomithi(activeBranch.id) }
                    } else null
                )
            }

            // 2. Main Financial Hero Summary Card
            item {
                HeroFinancialCard(
                    state = state,
                    branchName = activeBranch.name,
                    onNavigateToIdCard = { onNavigateToMemberCard(state.activeMemberId ?: "m-101") },
                    onNavigateToPassbook = { onNavigateToPassbook(state.activeMemberId ?: "m-101") }
                )
            }

            // 3. Quick Actions
            if (isApprovedAccess) {
                item {
                    DashboardQuickActions(
                        onCollectPayment = onNavigateToCollectPayment,
                        onAddExpense = onNavigateToAddExpense,
                        onAddMember = onNavigateToAddMember,
                        onNavigateToDefaulters = onNavigateToDefaulters
                    )
                }

                // 4. Somithi Activities Photo Album
                item {
                    SomithiActivitiesGallery(
                        photos = activeBranch.activityPhotos,
                        isAdmin = state.userRole == UserRole.SUPER_ADMIN,
                        onAddPhoto = {
                            newPhotoUrlInput = ""
                            showAddPhotoDialog = true
                        }
                    )
                }

                // 5. System Modules Grid
                item {
                    DashboardModulesGrid(
                        userRole = state.userRole,
                        onMembers = onNavigateToMembers,
                        onPayments = onNavigateToPayments,
                        onExpenses = onNavigateToExpenses,
                        onDefaulters = onNavigateToDefaulters,
                        onBranches = onNavigateToBranches,
                        onReports = onNavigateToReports,
                        onNotices = onNavigateToNotices,
                        onCommittee = onNavigateToCommittee,
                        onDividends = onNavigateToDividends,
                        onAdminHub = onNavigateToAdminHub,
                        onIdCard = { onNavigateToMemberCard(state.activeMemberId ?: "m-101") }
                    )
                }

                // 6. Recent Activity Ledger
                item {
                    DashboardRecentTransactions(
                        payments = state.recentPayments,
                        onViewAll = onNavigateToPayments
                    )
                }
            } else {
                item {
                    ShomitiStatusView(
                        branch = activeBranch,
                        isPending = state.currentBranchMembershipStatus == ShomitiMembershipStatus.PENDING_APPROVAL,
                        onViewTerms = { termsBranchToView = activeBranch },
                        onApplyForMembership = { onApplyForMembership(activeBranch.id) },
                        onNavigateToAdminHub = onNavigateToAdminHub
                    )
                }
            }
        }
    }

    // Modal: Somithi Switcher Sheet
    if (showSomithiSwitcher) {
        SomithiSwitcherSheet(
            branches = state.branches,
            selectedBranchId = state.selectedBranchId,
            isSuperAdmin = state.userRole == UserRole.SUPER_ADMIN,
            onSelectBranch = { branchId ->
                onSelectBranch(branchId)
                showSomithiSwitcher = false
            },
            onCreateNewSomithi = {
                showSomithiSwitcher = false
                onNavigateToCreateSomithi()
            },
            onDismiss = { showSomithiSwitcher = false }
        )
    }

    // Modal: Add Activity Photo Dialog
    if (showAddPhotoDialog) {
        AlertDialog(
            onDismissRequest = { showAddPhotoDialog = false },
            title = {
                Text(
                    text = if (isBangla) "কার্যক্রমের ছবি যোগ করুন" else "Add Activity Photo",
                    style = MaterialTheme.typography.titleMedium
                )
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = if (isBangla) "ছবির লিঙ্ক বা ইউআরএল (Image URL) প্রদান করুন:" else "Enter photo image URL:",
                        style = MaterialTheme.typography.bodySmall
                    )
                    OutlinedTextField(
                        value = newPhotoUrlInput,
                        onValueChange = { newPhotoUrlInput = it },
                        placeholder = { Text("https://example.com/photo.jpg") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newPhotoUrlInput.isNotBlank()) {
                            onAddActivityPhoto(activeBranch.id, newPhotoUrlInput.trim())
                        }
                        showAddPhotoDialog = false
                    },
                    enabled = newPhotoUrlInput.isNotBlank()
                ) {
                    Text(text = if (isBangla) "সংরক্ষণ" else "Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddPhotoDialog = false }) {
                    Text(text = if (isBangla) "বাতিল" else "Cancel")
                }
            }
        )
    }

    // Terms & Conditions Modal Dialog
    val branchForTerms = termsBranchToView
    if (branchForTerms != null) {
        TermsModalDialog(
            branch = branchForTerms,
            onDismiss = { termsBranchToView = null },
            onProceedToApplication = { branchId ->
                termsBranchToView = null
                onApplyForMembership(branchId)
            }
        )
    }
}
