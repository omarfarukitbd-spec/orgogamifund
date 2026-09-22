package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import android.content.Context
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.core.data.ShomitiDataManager
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.*

fun NavGraphBuilder.addMemberNavRoutes(
    navController: NavHostController,
    context: Context,
    members: List<Member>,
    branches: List<Branch>,
    payments: List<Payment>,
    launchCall: (Context, String) -> Unit,
    launchWhatsApp: (Context, String) -> Unit
) {
    composable(Screen.Members.route) {
        MemberListScreen(
            members = members,
            onMemberClick = { memberId -> navController.navigate(Screen.MemberDetail.createRoute(memberId)) },
            onAddMemberClick = { navController.navigate(Screen.AddMember.route) },
            onCallClick = { phone -> launchCall(context, phone) },
            onWhatsAppClick = { phone -> launchWhatsApp(context, phone) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.AddMember.route) {
        AddEditMemberScreen(
            onSaveMember = { newMember ->
                FirestoreWriteManager.addMember(newMember)
                navController.popBackStack()
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(
        route = Screen.MemberDetail.route,
        arguments = listOf(navArgument("memberId") { type = NavType.StringType })
    ) { backStackEntry ->
        val memberId = backStackEntry.arguments?.getString("memberId") ?: ""
        val member = members.find { it.id == memberId } ?: members.firstOrNull() ?: Member()
        MemberDetailScreen(
            member = member,
            onCallClick = { phone -> launchCall(context, phone) },
            onWhatsAppClick = { phone -> launchWhatsApp(context, phone) },
            onEditClick = { navController.navigate(Screen.AddMember.route) },
            onDeleteMember = { id ->
                FirestoreWriteManager.deleteMember(id) {
                    navController.popBackStack()
                }
            },
            onNavigateToIdCard = { id -> navController.navigate(Screen.IDCardPreview.createRoute(id)) },
            onNavigateToPassbook = { id -> navController.navigate(Screen.MemberPassbook.createRoute(id)) },
            onExitSettlementClick = {},
            onConfirmExit = { payoutMethod, note -> ShomitiDataManager.processMemberExit(member.id, payoutMethod, note) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(
        route = Screen.MemberPassbook.route,
        arguments = listOf(navArgument("memberId") { type = NavType.StringType })
    ) { backStackEntry ->
        val memberId = backStackEntry.arguments?.getString("memberId") ?: ""
        val member = members.find { it.id == memberId } ?: members.firstOrNull() ?: Member()
        val currentBranch = branches.find { it.id == member.branchId } ?: branches.firstOrNull() ?: Branch()
        MemberPassbookScreen(
            member = member,
            branchName = currentBranch.name.ifEmpty { "অগ্রগামী ফান্ড (দাখিল ব্যাচ ২০১৫)" },
            payments = payments,
            onNavigateToDeposit = { navController.navigate(Screen.MemberDeposit.route) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(
        route = Screen.MemberApplication.route,
        arguments = listOf(navArgument("branchId") { type = NavType.StringType; nullable = true; defaultValue = null })
    ) { backStackEntry ->
        val branchId = backStackEntry.arguments?.getString("branchId")
        MemberRegistrationApplicationScreen(
            availableBranches = branches,
            initialBranchId = branchId,
            onSubmitApplication = { newApp ->
                FirestoreWriteManager.submitMemberApplication(newApp)
                navController.navigate(Screen.PendingApproval.route) {
                    popUpTo(Screen.MemberApplication.route) { inclusive = true }
                }
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(
        route = Screen.IDCardPreview.route,
        arguments = listOf(navArgument("memberId") { type = NavType.StringType })
    ) { backStackEntry ->
        val memberId = backStackEntry.arguments?.getString("memberId") ?: ""
        val member = members.find { it.id == memberId } ?: members.firstOrNull() ?: Member()
        MemberIdCardPreviewScreen(
            member = member,
            orgName = "অগ্রগামী ফান্ড",
            onNavigateBack = { navController.popBackStack() }
        )
    }
}
