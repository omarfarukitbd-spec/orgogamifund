package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DrawerState
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components.DashboardBottomBar
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components.DashboardDrawer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

@Composable
fun MainAppScaffold(
    navController: NavHostController,
    currentRoute: String?,
    showBottomBar: Boolean,
    drawerState: DrawerState,
    scope: CoroutineScope,
    dashboardState: DashboardUiState,
    activeMemberId: String,
    content: @Composable () -> Unit
) {
    val closeAndNavigate: (String) -> Unit = { route ->
        scope.launch { drawerState.close() }
        navController.navigate(route) {
            launchSingleTop = true
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        gesturesEnabled = showBottomBar,
        drawerContent = {
            DashboardDrawer(
                state = dashboardState,
                onCloseDrawer = { scope.launch { drawerState.close() } },
                onNavigateToBranches = { closeAndNavigate(Screen.Branches.route) },
                onNavigateToMembers = { closeAndNavigate(Screen.Members.route) },
                onNavigateToPayments = { closeAndNavigate(Screen.Contributions.route) },
                onNavigateToLoans = { closeAndNavigate(Screen.Loans.route) },
                onNavigateToExpenses = { closeAndNavigate(Screen.Expenses.route) },
                onNavigateToNotices = { closeAndNavigate(Screen.Notices.route) },
                onNavigateToCommittee = { closeAndNavigate(Screen.Committee.route) },
                onNavigateToDividends = { closeAndNavigate(Screen.Dividends.route) },
                onNavigateToReports = { closeAndNavigate(Screen.Reports.route) },
                onNavigateToAdminHub = { closeAndNavigate(Screen.AdminHub.route) },
                onNavigateToSettings = { closeAndNavigate(Screen.Settings.route) }
            )
        }
    ) {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            bottomBar = {
                if (showBottomBar) {
                    val bottomBarRoute = when {
                        currentRoute == Screen.Dashboard.route -> "home"
                        currentRoute == Screen.Branches.route -> "branches"
                        currentRoute in setOf(
                            Screen.Contributions.route,
                            Screen.RecordPayment.route,
                            Screen.MemberDeposit.route,
                            Screen.Defaulters.route,
                            Screen.AdminPendingDeposits.route
                        ) -> "payments"
                        currentRoute != null && (currentRoute == Screen.IDCardPreview.route || currentRoute.startsWith("id_card_preview")) -> "idCard"
                        else -> ""
                    }

                    DashboardBottomBar(
                        currentRoute = bottomBarRoute,
                        userPhotoUrl = dashboardState.userPhotoUrl,
                        userName = dashboardState.userName,
                        userEmail = dashboardState.userEmail,
                        onNavigateHome = {
                            if (currentRoute != Screen.Dashboard.route) {
                                navController.navigate(Screen.Dashboard.route) {
                                    launchSingleTop = true
                                }
                            }
                        },
                        onNavigateBranches = {
                            if (currentRoute != Screen.Branches.route) {
                                navController.navigate(Screen.Branches.route) {
                                    launchSingleTop = true
                                }
                            }
                        },
                        onNavigatePayments = {
                            if (currentRoute != Screen.Contributions.route) {
                                navController.navigate(Screen.Contributions.route) {
                                    launchSingleTop = true
                                }
                            }
                        },
                        onNavigateIdCard = {
                            val targetRoute = Screen.IDCardPreview.createRoute(activeMemberId.ifBlank { "m-101" })
                            if (currentRoute != targetRoute) {
                                navController.navigate(targetRoute) {
                                    launchSingleTop = true
                                }
                            }
                        },
                        onOpenDrawer = {
                            scope.launch { drawerState.open() }
                        }
                    )
                }
            }
        ) { innerPadding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = innerPadding.calculateBottomPadding())
                    .consumeWindowInsets(innerPadding)
            ) {
                content()
            }
        }
    }
}
