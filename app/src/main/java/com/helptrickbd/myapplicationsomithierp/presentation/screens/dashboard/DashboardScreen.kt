package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.ShomitiMembershipStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components.*
import kotlinx.coroutines.launch

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
    val activeLoans: Double = 350000.0,
    val totalOutstandingDues: Double = 12000.0,
    val topDefaulterCount: Int = 3,
    val unreadNotificationCount: Int = 2,
    val pendingApplicationsCount: Int = 0,
    val recentPayments: List<Payment> = emptyList()
)

@Composable
fun DashboardScreen(
    state: DashboardUiState = DashboardUiState(),
    onSelectBranch: (String) -> Unit = {},
    onApplyForMembership: (branchId: String) -> Unit = {},
    onNavigateToMemberCard: (memberId: String) -> Unit = {},
    onNavigateToSearch: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToCollectPayment: () -> Unit = {},
    onNavigateToAddExpense: () -> Unit = {},
    onNavigateToIssueLoan: () -> Unit = {},
    onNavigateToAddMember: () -> Unit = {},
    onNavigateToDefaulters: () -> Unit = {},
    onNavigateToMembers: () -> Unit = {},
    onNavigateToPayments: () -> Unit = {},
    onNavigateToCommittee: () -> Unit = {},
    onNavigateToNotices: () -> Unit = {},
    onNavigateToDividends: () -> Unit = {},
    onNavigateToExpenses: () -> Unit = {},
    onNavigateToLoans: () -> Unit = {},
    onNavigateToBranches: () -> Unit = {},
    onNavigateToReports: () -> Unit = {},
    onNavigateToAdminHub: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {},
    onNavigateToPassbook: (memberId: String) -> Unit = {}
) {
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    var termsBranchToView by remember { mutableStateOf<Branch?>(null) }

    val activeBranch = state.branches.find { it.id == state.selectedBranchId }
        ?: state.branches.firstOrNull()
        ?: Branch(id = "", name = "অগ্রগামী ফান্ড")

    val isApprovedAccess = state.userRole == UserRole.SUPER_ADMIN ||
        state.currentBranchMembershipStatus == ShomitiMembershipStatus.APPROVED_MEMBER

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            DashboardDrawer(
                state = state,
                onCloseDrawer = { scope.launch { drawerState.close() } },
                onNavigateToBranches = onNavigateToBranches,
                onNavigateToMembers = onNavigateToMembers,
                onNavigateToPayments = onNavigateToPayments,
                onNavigateToLoans = onNavigateToLoans,
                onNavigateToExpenses = onNavigateToExpenses,
                onNavigateToNotices = onNavigateToNotices,
                onNavigateToCommittee = onNavigateToCommittee,
                onNavigateToDividends = onNavigateToDividends,
                onNavigateToReports = onNavigateToReports,
                onNavigateToAdminHub = onNavigateToAdminHub,
                onNavigateToSettings = onNavigateToSettings
            )
        }
    ) {
        Scaffold(
            topBar = {
                DashboardTopBar(
                    state = state,
                    onOpenDrawer = { scope.launch { drawerState.open() } },
                    onNavigateToNotifications = onNavigateToNotifications
                )
            },
            bottomBar = {
                DashboardBottomBar(
                    currentRoute = "home",
                    userPhotoUrl = state.userPhotoUrl,
                    userName = state.userName,
                    userEmail = state.userEmail,
                    onNavigateHome = {},
                    onNavigateBranches = onNavigateToBranches,
                    onNavigatePayments = onNavigateToPayments,
                    onNavigateIdCard = { onNavigateToMemberCard(state.activeMemberId ?: "m-101") },
                    onOpenDrawer = { scope.launch { drawerState.open() } }
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
                // 1. Sleek Branch Selector Bar
                item {
                    BranchSelectorBar(
                        branches = state.branches,
                        selectedBranchId = state.selectedBranchId,
                        currentStatus = state.currentBranchMembershipStatus,
                        userRole = state.userRole,
                        onSelectBranch = onSelectBranch,
                        onViewTerms = { branch -> termsBranchToView = branch }
                    )
                }

                // 2. Active Branch View: Unlocked Financials OR Single Status Card
                if (isApprovedAccess) {
                    item {
                        HeroFinancialCard(
                            state = state,
                            branchName = activeBranch.name,
                            onNavigateToIdCard = { onNavigateToMemberCard(state.activeMemberId ?: "m-101") },
                            onNavigateToPassbook = { onNavigateToPassbook(state.activeMemberId ?: "m-101") }
                        )
                    }

                    item {
                        DashboardQuickActions(
                            onCollectPayment = onNavigateToCollectPayment,
                            onAddExpense = onNavigateToAddExpense,
                            onIssueLoan = onNavigateToIssueLoan,
                            onAddMember = onNavigateToAddMember
                        )
                    }

                    item {
                        FinancialStatsGrid(
                            state = state,
                            onNavigateToMembers = onNavigateToMembers,
                            onNavigateToLoans = onNavigateToLoans,
                            onNavigateToExpenses = onNavigateToExpenses,
                            onNavigateToDefaulters = onNavigateToDefaulters
                        )
                    }

                    item {
                        DashboardModulesGrid(
                            userRole = state.userRole,
                            onMembers = onNavigateToMembers,
                            onPayments = onNavigateToPayments,
                            onExpenses = onNavigateToExpenses,
                            onLoans = onNavigateToLoans,
                            onBranches = onNavigateToBranches,
                            onReports = onNavigateToReports,
                            onNotices = onNavigateToNotices,
                            onCommittee = onNavigateToCommittee,
                            onDividends = onNavigateToDividends,
                            onAdminHub = onNavigateToAdminHub,
                            onIdCard = { onNavigateToMemberCard(state.activeMemberId ?: "m-101") }
                        )
                    }

                    item {
                        DashboardRecentTransactions(
                            payments = state.recentPayments,
                            onViewAll = onNavigateToPayments
                        )
                    }
                } else {
                    // Single clean status card: NO duplicate stacked cards!
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
}
