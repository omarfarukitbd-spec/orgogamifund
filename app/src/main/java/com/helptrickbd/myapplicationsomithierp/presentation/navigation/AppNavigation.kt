package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.helptrickbd.myapplicationsomithierp.core.backup.BackupPayload
import com.helptrickbd.myapplicationsomithierp.core.backup.DataBackupManager
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreDataManager
import com.helptrickbd.myapplicationsomithierp.core.data.ShomitiDataManager
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode
import com.helptrickbd.myapplicationsomithierp.core.datastore.UserPreferencesRepository
import com.helptrickbd.myapplicationsomithierp.data.repository.NotificationRepositoryImpl
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.NotificationCenterScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.MemberDepositScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.search.GlobalSearchScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.SettingsScreen
import kotlinx.coroutines.launch

@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController(),
    currentUser: User? = null,
    startDestination: String? = null
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val preferencesRepo = remember { UserPreferencesRepository(context) }
    val preferences by preferencesRepo.userPreferencesFlow.collectAsStateWithLifecycle(initialValue = null)
    val notificationRepo = remember { NotificationRepositoryImpl.instance }
    val notifications by notificationRepo.getNotifications().collectAsStateWithLifecycle(initialValue = emptyList())
    val backupManager = remember { DataBackupManager(context) }

    val members by FirestoreDataManager.members.collectAsStateWithLifecycle()
    val payments by FirestoreDataManager.payments.collectAsStateWithLifecycle()
    val expenses by FirestoreDataManager.expenses.collectAsStateWithLifecycle()
    val loans by FirestoreDataManager.loans.collectAsStateWithLifecycle()
    val branches by FirestoreDataManager.branches.collectAsStateWithLifecycle()
    val committee by ShomitiDataManager.committee.collectAsStateWithLifecycle()
    val notices by ShomitiDataManager.notices.collectAsStateWithLifecycle()
    val editRequests by ShomitiDataManager.editRequests.collectAsStateWithLifecycle()
    val memberApplications by FirestoreDataManager.memberApplications.collectAsStateWithLifecycle()
    val dashboardState by FirestoreDataManager.dashboardState.collectAsStateWithLifecycle()

    if (preferences == null && startDestination == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {}
        return
    }

    var firebaseAuthUser by remember {
        mutableStateOf(com.google.firebase.auth.FirebaseAuth.getInstance().currentUser)
    }

    androidx.compose.runtime.DisposableEffect(Unit) {
        val auth = com.google.firebase.auth.FirebaseAuth.getInstance()
        val listener = com.google.firebase.auth.FirebaseAuth.AuthStateListener { fAuth ->
            firebaseAuthUser = fAuth.currentUser
        }
        auth.addAuthStateListener(listener)
        onDispose {
            auth.removeAuthStateListener(listener)
        }
    }

    val currentAuthEmail = currentUser?.email?.ifBlank { null }
        ?: firebaseAuthUser?.email?.ifBlank { null }
        ?: ""
    val isRootSuperAdmin = isSuperAdminEmail(currentAuthEmail)

    val authRepo = remember { com.helptrickbd.myapplicationsomithierp.data.repository.AuthRepositoryImpl() }
    val userProfileResource by remember(firebaseAuthUser?.uid) {
        val uid = firebaseAuthUser?.uid
        if (uid != null) authRepo.getUserProfileFlow(uid)
        else kotlinx.coroutines.flow.flowOf(null)
    }.collectAsStateWithLifecycle(initialValue = null)

    val firestoreUser = (userProfileResource as? com.helptrickbd.myapplicationsomithierp.core.util.Resource.Success)?.data

    val activeUser = firestoreUser ?: currentUser ?: firebaseAuthUser?.let { fbUser ->
        val userEmail = fbUser.email ?: ""
        val isSuper = isSuperAdminEmail(userEmail)
        User(
            id = fbUser.uid,
            email = userEmail,
            displayName = fbUser.displayName?.ifBlank { null } ?: if (isSuper) "মো: ওমর ফারুক" else "সম্মানিত সদস্য",
            photoUrl = fbUser.photoUrl?.toString(),
            role = if (isSuper) UserRole.SUPER_ADMIN else UserRole.MEMBER,
            approvalStatus = if (isSuper) ApprovalStatus.APPROVED else ApprovalStatus.PENDING
        )
    }
    val activeRole = if (isRootSuperAdmin) UserRole.SUPER_ADMIN else (activeUser?.role ?: UserRole.MEMBER)

    val resolvedStartDestination = startDestination ?: when {
        currentUser == null && firebaseAuthUser == null -> {
            if (preferences?.isOnboardingCompleted != true) Screen.Onboarding.route
            else Screen.Auth.route
        }
        isRootSuperAdmin -> Screen.Dashboard.route
        activeUser?.approvalStatus == ApprovalStatus.APPROVED -> Screen.Dashboard.route
        else -> Screen.PendingApproval.route
    }

    val currentMember = FirestoreDataManager.getCurrentMemberForUser(dashboardState.selectedBranchId, currentAuthEmail)
    val membershipStatus = FirestoreDataManager.getMembershipStatus(dashboardState.selectedBranchId, currentAuthEmail, activeRole)

    val fullDashboardState = dashboardState.copy(
        userRole = activeRole,
        userName = activeUser?.displayName?.ifBlank { null } ?: if (isRootSuperAdmin) "মো: ওমর ফারুক" else "সম্মানিত সদস্য",
        userPhotoUrl = activeUser?.photoUrl?.ifBlank { null } ?: firebaseAuthUser?.photoUrl?.toString(),
        userEmail = currentAuthEmail,
        currentBranchMembershipStatus = membershipStatus,
        activeMemberId = currentMember?.id ?: ""
    )

    val currentBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = currentBackStackEntry?.destination?.route
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)

    val hideBottomBarRoutes = setOf(
        Screen.Onboarding.route,
        Screen.Auth.route,
        Screen.PendingApproval.route
    )
    val effectiveRoute = currentRoute ?: resolvedStartDestination
    val showBottomBar = effectiveRoute !in hideBottomBarRoutes &&
        (isRootSuperAdmin || activeUser?.approvalStatus == ApprovalStatus.APPROVED)

    MainAppScaffold(
        navController = navController,
        currentRoute = currentRoute,
        showBottomBar = showBottomBar,
        drawerState = drawerState,
        scope = scope,
        dashboardState = fullDashboardState,
        activeMemberId = currentMember?.id ?: "m-101"
    ) {
        NavHost(
            navController = navController,
            startDestination = resolvedStartDestination
        ) {
            addAuthNavRoutes(navController, preferences, preferencesRepo, scope, activeUser, isRootSuperAdmin)

            addDashboardNavRoute(
                navController = navController,
                dashboardUiState = fullDashboardState,
                activeRole = activeRole,
                onOpenDrawer = { scope.launch { drawerState.open() } }
            )

        composable(Screen.MemberDeposit.route) {
            val currentBranch = branches.find { it.id == dashboardState.selectedBranchId } ?: branches.firstOrNull() ?: Branch()
            val currentMember = FirestoreDataManager.getCurrentMemberForUser(dashboardState.selectedBranchId, currentAuthEmail)
            MemberDepositScreen(
                branch = currentBranch,
                memberId = currentMember?.id ?: "m-101",
                memberName = currentMember?.name?.takeIf { it.isNotBlank() } ?: (activeUser?.displayName ?: "সদস্য"),
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.NotificationCenter.route) {
            NotificationCenterScreen(
                notifications = notifications,
                onNotificationClick = { item -> item.targetRoute?.let { route -> navController.navigate(route) } },
                onMarkAsRead = { id -> scope.launch { notificationRepo.markAsRead(id) } },
                onMarkAllAsRead = { scope.launch { notificationRepo.markAllAsRead() } },
                onDeleteNotification = { id -> scope.launch { notificationRepo.deleteNotification(id) } },
                onClearAll = { scope.launch { notificationRepo.clearAll() } },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.GlobalSearch.route) {
            GlobalSearchScreen(
                members = members,
                payments = payments,
                onMemberClick = { memberId -> navController.navigate(Screen.MemberDetail.createRoute(memberId)) },
                onPaymentClick = { _ -> },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                userRole = activeRole,
                currentLanguage = preferences?.language?.code ?: "bn",
                onLanguageChange = { langCode ->
                    scope.launch {
                        preferencesRepo.setLanguage(
                            if (langCode == "en") com.helptrickbd.myapplicationsomithierp.core.datastore.AppLanguage.ENGLISH
                            else com.helptrickbd.myapplicationsomithierp.core.datastore.AppLanguage.BANGLA
                        )
                    }
                },
                onThemeModeChange = { mode -> scope.launch { preferencesRepo.setThemeMode(mode) } },
                onNavigateToSessions = { navController.navigate(Screen.Sessions.route) },
                onNavigateToNotifications = { navController.navigate(Screen.NotificationCenter.route) },
                onNavigateToOnboarding = { navController.navigate(Screen.Onboarding.route) },
                onNavigateToAdminHub = { navController.navigate(Screen.AdminHub.route) },
                onNavigateToAuth = { navController.navigate(Screen.Auth.route) },
                onTriggerBackup = {
                    val backupFile = backupManager.generateBackupJson(BackupPayload(members = members, payments = payments, notices = notices, committee = committee))
                    backupManager.shareBackupFile(backupFile)
                },
                onSignOut = {
                    scope.launch { authRepo.signOut() }
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(Screen.Dashboard.route) { inclusive = true }
                    }
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        addMemberNavRoutes(
            navController = navController,
            context = context,
            members = members,
            branches = branches,
            payments = payments,
            launchCall = ::launchCall,
            launchWhatsApp = ::launchWhatsApp
        )

        addFinancialNavRoutes(
            navController = navController,
            scope = scope,
            notificationRepo = notificationRepo,
            members = members,
            payments = payments,
            expenses = expenses,
            loans = loans
        )

        addAdminNavRoutes(
            navController = navController,
            context = context,
            scope = scope,
            userRole = activeRole,
            members = members,
            payments = payments,
            expenses = expenses,
            loans = loans,
            branches = branches,
            committee = committee,
            notices = notices,
            editRequests = editRequests,
            memberApplications = memberApplications,
            totalFundBalance = dashboardState.totalFundBalance,
            backupManager = backupManager,
            notificationRepo = notificationRepo,
            launchCall = ::launchCall
        )
    }
}
}
