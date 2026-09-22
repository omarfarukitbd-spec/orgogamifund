package com.helptrickbd.myapplicationsomithierp.presentation.navigation

sealed class Screen(val route: String) {
    data object Onboarding : Screen("onboarding")
    data object Auth : Screen("auth")
    data object PendingApproval : Screen("pending_approval")
    data object Dashboard : Screen("dashboard")
    data object Members : Screen("members")
    data object MemberDetail : Screen("member_detail/{memberId}") {
        fun createRoute(memberId: String) = "member_detail/$memberId"
    }
    data object AddMember : Screen("add_member")
    data object Contributions : Screen("contributions")
    data object RecordPayment : Screen("record_payment")
    data object Expenses : Screen("expenses")
    data object AddExpense : Screen("add_expense")
    data object Loans : Screen("loans")
    data object IssueLoan : Screen("issue_loan")
    data object Committee : Screen("committee")
    data object Notices : Screen("notices")
    data object Reports : Screen("reports")
    data object Settings : Screen("settings")
    data object GlobalSearch : Screen("global_search")
    data object NotificationCenter : Screen("notification_center")
    data object Defaulters : Screen("defaulters")
    data object Dividends : Screen("dividends")
    data object Sessions : Screen("sessions")
    data object Branches : Screen("branches")
    data object EditRequests : Screen("edit_requests")
    data object MemberApplication : Screen("member_application?branchId={branchId}") {
        fun createRoute(branchId: String? = null) = if (!branchId.isNullOrBlank()) "member_application?branchId=$branchId" else "member_application"
    }
    data object AdminApprovals : Screen("admin_approvals")
    data object AdminHub : Screen("admin_hub")
    data object IDCardPreview : Screen("id_card_preview/{memberId}") {
        fun createRoute(memberId: String) = "id_card_preview/$memberId"
    }
    data object MemberDeposit : Screen("member_deposit")
    data object AdminPendingDeposits : Screen("admin_pending_deposits")
    data object CreateSomithiFund : Screen("create_somithi_fund")
    data object MemberPassbook : Screen("member_passbook/{memberId}") {
        fun createRoute(memberId: String) = "member_passbook/$memberId"
    }
}
