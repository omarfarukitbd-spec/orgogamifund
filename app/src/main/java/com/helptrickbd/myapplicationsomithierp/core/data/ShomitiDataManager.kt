package com.helptrickbd.myapplicationsomithierp.core.data

import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Central Reactive Data & Accounting Engine for Shomiti Manager ERP.
 * Strictly enforces `safeRound()` on every financial addition, subtraction,
 * balance equation, and dividend calculation.
 */
object ShomitiDataManager {

    private val initialBranches = emptyList<Branch>()
    private val initialMembers = emptyList<Member>()
    private val initialPayments = emptyList<Payment>()
    private val initialExpenses = emptyList<Expense>()
    private val initialCommittee = emptyList<CommitteeMember>()
    private val initialNotices = emptyList<Notice>()
    private val initialEditRequests = emptyList<EditRequest>()
    private val initialMemberApplications = emptyList<MemberApplication>()

    // Reactive State Flows
    internal val _members = MutableStateFlow(initialMembers)
    val members: StateFlow<List<Member>> = _members.asStateFlow()

    internal val _payments = MutableStateFlow(initialPayments)
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    internal val _expenses = MutableStateFlow(initialExpenses)
    val expenses: StateFlow<List<Expense>> = _expenses.asStateFlow()

    internal val _loans = MutableStateFlow(initialLoans)
    val loans: StateFlow<List<Loan>> = _loans.asStateFlow()

    internal val _branches = MutableStateFlow(initialBranches)
    val branches: StateFlow<List<Branch>> = _branches.asStateFlow()

    internal val _committee = MutableStateFlow(initialCommittee)
    val committee: StateFlow<List<CommitteeMember>> = _committee.asStateFlow()

    internal val _notices = MutableStateFlow(initialNotices)
    val notices: StateFlow<List<Notice>> = _notices.asStateFlow()

    internal val _editRequests = MutableStateFlow(initialEditRequests)
    val editRequests: StateFlow<List<EditRequest>> = _editRequests.asStateFlow()

    internal val _memberApplications = MutableStateFlow(initialMemberApplications)
    val memberApplications: StateFlow<List<MemberApplication>> = _memberApplications.asStateFlow()

    internal val _selectedBranchId = MutableStateFlow("b-1")
    val selectedBranchId: StateFlow<String> = _selectedBranchId.asStateFlow()

    internal val _dashboardState = MutableStateFlow(computeDashboardState())
    val dashboardState: StateFlow<DashboardUiState> = _dashboardState.asStateFlow()

    fun selectBranch(branchId: String) {
        _selectedBranchId.value = branchId
        refreshState()
    }

    fun getMembershipStatus(
        branchId: String,
        userEmail: String = "",
        userRole: UserRole = UserRole.SUPER_ADMIN
    ): ShomitiMembershipStatus {
        if (userRole == UserRole.SUPER_ADMIN ||
            userEmail.equals("omarfaruktitbd@gmail.com", ignoreCase = true) ||
            userEmail.equals("omarfarukitbd@gmail.com", ignoreCase = true)) {
            return ShomitiMembershipStatus.APPROVED_MEMBER
        }

        val hasPendingApp = _memberApplications.value.any { app ->
            (app.targetShomitiId == branchId || app.targetShomitiName == branchId) &&
            (userEmail.isBlank() || app.email.equals(userEmail, ignoreCase = true)) &&
            app.status == ApprovalStatus.PENDING
        }
        if (hasPendingApp) return ShomitiMembershipStatus.PENDING_APPROVAL

        val isMember = _members.value.any { m ->
            m.branchId == branchId && m.status == MemberStatus.ACTIVE &&
            (userEmail.isNotBlank() && (m.phone == userEmail || m.name.contains(userEmail)))
        }
        if (isMember) return ShomitiMembershipStatus.APPROVED_MEMBER

        if (userEmail.isBlank()) {
            return ShomitiMembershipStatus.NOT_A_MEMBER
        }

        return ShomitiMembershipStatus.NOT_A_MEMBER
    }

    fun getCurrentMemberForUser(branchId: String = "", userEmail: String = ""): Member? {
        val membersInBranch = _members.value.filter { 
            (branchId.isBlank() || it.branchId == branchId) && it.status == MemberStatus.ACTIVE 
        }
        if (userEmail.isNotBlank()) {
            val matched = membersInBranch.find { 
                it.phone.equals(userEmail, ignoreCase = true) || 
                it.name.contains(userEmail, ignoreCase = true) 
            }
            if (matched != null) return matched
        }
        return membersInBranch.firstOrNull() ?: _members.value.firstOrNull()
    }

    /**
     * Recomputes the entire dashboard financial metrics using the Central Accounting Formula (§6.3)
     * and strictly rounds all sums via `safeRound`.
     */
    private fun computeDashboardState(): DashboardUiState {
        val selBranchId = _selectedBranchId.value
        val branchPayments = _payments.value.filter { it.branchId == selBranchId }
        val branchExpenses = _expenses.value.filter { it.branchId == selBranchId }
        val branchMembers = _members.value.filter { it.branchId == selBranchId && it.status == MemberStatus.ACTIVE }

        val totalContributions = safeRound(branchPayments.sumOf { safeRound(it.amount) })
        val totalExpensesAmount = safeRound(branchExpenses.sumOf { safeRound(it.amount) })
        
        val targetBranch = _branches.value.find { it.id == selBranchId }
        val baseSeedFund = targetBranch?.balance ?: 0.0
        val totalFundBalance = safeRound(
            baseSeedFund + totalContributions - totalExpensesAmount
        )

        val thisMonthCollection = safeRound(
            branchPayments.sumOf { safeRound(it.amount) }
        )

        val totalOutstandingDues = safeRound(
            branchMembers.sumOf { safeRound(it.outstandingDues) }
        )

        val topDefaulterCount = branchMembers.count { it.outstandingDues > 0.0 }
        val pendingAppsCount = _memberApplications.value.count { it.status == ApprovalStatus.PENDING }

        return DashboardUiState(
            isLoading = false,
            isOffline = false,
            orgName = "অগ্রগামী ফান্ড",
            userRole = UserRole.SUPER_ADMIN,
            selectedBranchId = selBranchId,
            branches = _branches.value,
            currentBranchMembershipStatus = getMembershipStatus(selBranchId, "", UserRole.SUPER_ADMIN),
            totalFundBalance = totalFundBalance,
            thisMonthCollection = thisMonthCollection,
            totalExpenses = totalExpensesAmount,
            totalOutstandingDues = totalOutstandingDues,
            topDefaulterCount = topDefaulterCount,
            pendingApplicationsCount = pendingAppsCount,
            unreadNotificationCount = 0,
            recentPayments = branchPayments.take(5)
        )
    }

    internal fun refreshState() {
        _dashboardState.value = computeDashboardState()
    }

    // --- Financial Operations Delegation ---
    fun recordPayment(payment: Payment) = ShomitiFinancialMutations.recordPayment(this, payment)
    fun recordExpense(expense: Expense) = ShomitiFinancialMutations.recordExpense(this, expense)
    fun disburseLoan(loan: Loan) = ShomitiFinancialMutations.disburseLoan(this, loan)
    fun repayLoanInstallment(loanId: String, repaymentAmount: Double, method: String = "Cash") =
        ShomitiFinancialMutations.repayLoanInstallment(this, loanId, repaymentAmount, method)
    fun processMemberExit(memberId: String, payoutMethod: String = "Cash", note: String = ""): MemberExit? =
        ShomitiFinancialMutations.processMemberExit(this, memberId, payoutMethod, note)
    fun distributeDividends(run: DividendRun) = ShomitiFinancialMutations.distributeDividends(this, run)

    // --- Governance & Management Delegation ---
    fun addMember(member: Member) = ShomitiGovernanceMutations.addMember(this, member)
    fun updateMember(updated: Member) = ShomitiGovernanceMutations.updateMember(this, updated)
    fun deleteMember(memberId: String) = ShomitiGovernanceMutations.deleteMember(this, memberId)
    fun addBranch(branch: Branch) = ShomitiGovernanceMutations.addBranch(this, branch)
    fun addCommitteeMember(member: CommitteeMember) = ShomitiGovernanceMutations.addCommitteeMember(this, member)
    fun removeCommitteeMember(id: String) = ShomitiGovernanceMutations.removeCommitteeMember(this, id)
    fun publishNotice(notice: Notice) = ShomitiGovernanceMutations.publishNotice(this, notice)
    fun deleteNotice(id: String) = ShomitiGovernanceMutations.deleteNotice(this, id)
    fun submitEditRequest(request: EditRequest) = ShomitiGovernanceMutations.submitEditRequest(this, request)
    fun reviewEditRequest(requestId: String, approved: Boolean) = ShomitiGovernanceMutations.reviewEditRequest(this, requestId, approved)
    fun submitMemberApplication(application: MemberApplication) = ShomitiGovernanceMutations.submitMemberApplication(this, application)
    fun approveMemberApplication(applicationId: String): Member? = ShomitiGovernanceMutations.approveMemberApplication(this, applicationId)
    fun rejectMemberApplication(applicationId: String, reason: String = "তথ্য অপূর্ণ বা অনুপযুক্ত") =
        ShomitiGovernanceMutations.rejectMemberApplication(this, applicationId, reason)
}
