package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import android.app.Activity
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreDataManager
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.components.ExitConfirmationDialog
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState

fun NavGraphBuilder.addDashboardNavRoute(
    navController: NavHostController,
    dashboardUiState: DashboardUiState,
    activeRole: UserRole,
    onOpenDrawer: () -> Unit
) {
    composable(Screen.Dashboard.route) {
        val activity = LocalContext.current as? Activity
        var showExitDialog by remember { mutableStateOf(false) }

        BackHandler(enabled = true) {
            showExitDialog = true
        }

        if (showExitDialog) {
            ExitConfirmationDialog(
                onConfirm = {
                    showExitDialog = false
                    activity?.finish()
                },
                onDismiss = { showExitDialog = false }
            )
        }

        DashboardScreen(
            state = dashboardUiState,
            onOpenDrawer = onOpenDrawer,
            onSelectBranch = { branchId -> FirestoreDataManager.selectBranch(branchId) },
            onApplyForMembership = { branchId -> navController.navigate(Screen.MemberApplication.createRoute(branchId)) },
            onNavigateToMemberCard = { memberId -> navController.navigate(Screen.IDCardPreview.createRoute(memberId)) },
            onNavigateToSearch = { navController.navigate(Screen.GlobalSearch.route) },
            onNavigateToNotifications = { navController.navigate(Screen.NotificationCenter.route) },
            onNavigateToCollectPayment = {
                if (activeRole == UserRole.SUPER_ADMIN || activeRole == UserRole.BRANCH_ADMIN) {
                    navController.navigate(Screen.RecordPayment.route)
                } else {
                    navController.navigate(Screen.MemberDeposit.route)
                }
            },
            onNavigateToAddExpense = { navController.navigate(Screen.AddExpense.route) },
            onNavigateToIssueLoan = { navController.navigate(Screen.IssueLoan.route) },
            onNavigateToAddMember = { navController.navigate(Screen.AddMember.route) },
            onNavigateToDefaulters = { navController.navigate(Screen.Defaulters.route) },
            onNavigateToMembers = { navController.navigate(Screen.Members.route) },
            onNavigateToPayments = { navController.navigate(Screen.Contributions.route) },
            onNavigateToCommittee = { navController.navigate(Screen.Committee.route) },
            onNavigateToNotices = { navController.navigate(Screen.Notices.route) },
            onNavigateToDividends = { navController.navigate(Screen.Dividends.route) },
            onNavigateToExpenses = { navController.navigate(Screen.Expenses.route) },
            onNavigateToLoans = { navController.navigate(Screen.Loans.route) },
            onNavigateToBranches = { navController.navigate(Screen.Branches.route) },
            onNavigateToReports = { navController.navigate(Screen.Reports.route) },
            onNavigateToAdminHub = { navController.navigate(Screen.AdminHub.route) },
            onNavigateToSettings = { navController.navigate(Screen.Settings.route) },
            onNavigateToPassbook = { memberId -> navController.navigate(Screen.MemberPassbook.createRoute(memberId)) }
        )
    }
}
