package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import android.content.Context
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import com.helptrickbd.myapplicationsomithierp.core.backup.BackupPayload
import com.helptrickbd.myapplicationsomithierp.core.backup.DataBackupManager
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreDataManager
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.core.data.ShomitiDataManager
import com.helptrickbd.myapplicationsomithierp.domain.repository.NotificationRepository
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.AdminHubScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.AdminPendingDepositsScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.CreateSomithiFundScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.branches.BranchManagementScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dividends.DividendDistributionScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.AdminApprovalScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.CommitteeScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.NoticeBoardScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.EditRequestReviewScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.ReportsScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.SessionManagementScreen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

fun NavGraphBuilder.addAdminNavRoutes(
    navController: NavHostController,
    context: Context,
    scope: CoroutineScope,
    userRole: UserRole,
    members: List<Member>,
    payments: List<Payment>,
    expenses: List<Expense>,
    loans: List<Loan>,
    branches: List<Branch>,
    committee: List<CommitteeMember>,
    notices: List<Notice>,
    editRequests: List<EditRequest>,
    memberApplications: List<MemberApplication>,
    totalFundBalance: Double,
    backupManager: DataBackupManager,
    notificationRepo: NotificationRepository,
    launchCall: (Context, String) -> Unit
) {
    composable(Screen.Branches.route) {
        BranchManagementScreen(
            branches = branches,
            onAddBranch = { newBranch ->
                ShomitiDataManager.addBranch(newBranch)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Reports.route) {
        ReportsScreen(
            members = members,
            payments = payments,
            expenses = expenses,
            loans = loans,
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.EditRequests.route) {
        EditRequestReviewScreen(
            requests = editRequests,
            onApprove = { reqId ->
                ShomitiDataManager.reviewEditRequest(reqId, true)
            },
            onReject = { reqId ->
                ShomitiDataManager.reviewEditRequest(reqId, false)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Dividends.route) {
        DividendDistributionScreen(
            members = members,
            onConfirmDividendPayout = { run ->
                ShomitiDataManager.distributeDividends(run)
                navController.popBackStack()
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Committee.route) {
        CommitteeScreen(
            committeeMembers = committee,
            isAdmin = true,
            onAddCommitteeMember = { newMember ->
                ShomitiDataManager.addCommitteeMember(newMember)
            },
            onRemoveCommitteeMember = { id ->
                ShomitiDataManager.removeCommitteeMember(id)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Notices.route) {
        NoticeBoardScreen(
            notices = notices,
            isAdmin = true,
            onPublishNotice = { newNotice ->
                ShomitiDataManager.publishNotice(newNotice)
            },
            onDeleteNotice = { id ->
                ShomitiDataManager.deleteNotice(id)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Sessions.route) {
        SessionManagementScreen(
            currentSessionId = "current-device-session",
            onRevokeSession = { /* Session revoked */ },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.AdminApprovals.route) {
        AdminApprovalScreen(
            applications = memberApplications,
            onApprove = { appId ->
                val approvedMember = ShomitiDataManager.approveMemberApplication(appId)
                val app = memberApplications.find { it.id == appId }
                if (app != null && approvedMember != null) {
                    FirestoreWriteManager.approveMemberApplication(app, "OF-01")
                }
                approvedMember
            },
            onReject = { appId, reason ->
                FirestoreWriteManager.rejectMemberApplication(appId, reason)
            },
            onViewIdCard = { memberId ->
                navController.navigate(Screen.IDCardPreview.createRoute(memberId))
            },
            onCallApplicant = { phone -> launchCall(context, phone) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.AdminHub.route) {
        AdminHubScreen(
            userRole = userRole,
            pendingApplicationsCount = memberApplications.count { it.status == ApprovalStatus.PENDING },
            totalMembersCount = members.size,
            totalFundBalance = totalFundBalance,
            activeBranchesCount = branches.size,
            pendingDepositsCount = payments.count { it.approvalStatus == ApprovalStatus.PENDING },
            onNavigateToApprovals = { navController.navigate(Screen.AdminApprovals.route) },
            onNavigateToPendingDeposits = { navController.navigate(Screen.AdminPendingDeposits.route) },
            onNavigateToCreateSomithi = { navController.navigate(Screen.CreateSomithiFund.route) },
            onNavigateToMembers = { navController.navigate(Screen.Members.route) },
            onNavigateToAddMember = { navController.navigate(Screen.AddMember.route) },
            onNavigateToEditRequests = { navController.navigate(Screen.EditRequests.route) },
            onNavigateToCollectPayment = { navController.navigate(Screen.RecordPayment.route) },
            onNavigateToAddExpense = { navController.navigate(Screen.AddExpense.route) },
            onNavigateToIssueLoan = { navController.navigate(Screen.IssueLoan.route) },
            onNavigateToDividends = { navController.navigate(Screen.Dividends.route) },
            onNavigateToDefaulters = { navController.navigate(Screen.Defaulters.route) },
            onNavigateToBranches = { navController.navigate(Screen.Branches.route) },
            onNavigateToCommittee = { navController.navigate(Screen.Committee.route) },
            onNavigateToNotices = { navController.navigate(Screen.Notices.route) },
            onNavigateToReports = { navController.navigate(Screen.Reports.route) },
            onTriggerBackup = {
                val backupFile = backupManager.generateBackupJson(
                    BackupPayload(
                        members = members,
                        payments = payments,
                        expenses = expenses,
                        loans = loans
                    )
                )
                backupManager.shareBackupFile(backupFile)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.AdminPendingDeposits.route) {
        AdminPendingDepositsScreen(
            payments = payments,
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.CreateSomithiFund.route) {
        CreateSomithiFundScreen(
            onNavigateBack = { navController.popBackStack() }
        )
    }
}
