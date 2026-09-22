package com.helptrickbd.myapplicationsomithierp.core.data

import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard. DashboardUiState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

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
    private val initialLoans = emptyList<Loan>()
    private val initialCommittee = emptyList<CommitteeMember>()
    private val initialNotices = emptyList<Notice>()
    private val initialEditRequests = emptyList<EditRequest>()
    private val initialMemberApplications = emptyList<MemberApplication>()

    // Reactive State Flows
    private val _members = MutableStateFlow(initialMembers)
    val members: StateFlow<List<Member>> = _members.asStateFlow()

    private val _payments = MutableStateFlow(initialPayments)
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    private val _expenses = MutableStateFlow(initialExpenses)
    val expenses: StateFlow<List<Expense>> = _expenses.asStateFlow()

    private val _loans = MutableStateFlow(initialLoans)
    val loans: StateFlow<List<Loan>> = _loans.asStateFlow()

    private val _branches = MutableStateFlow(initialBranches)
    val branches: StateFlow<List<Branch>> = _branches.asStateFlow()

    private val _committee = MutableStateFlow(initialCommittee)
    val committee: StateFlow<List<CommitteeMember>> = _committee.asStateFlow()

    private val _notices = MutableStateFlow(initialNotices)
    val notices: StateFlow<List<Notice>> = _notices.asStateFlow()

    private val _editRequests = MutableStateFlow(initialEditRequests)
    val editRequests: StateFlow<List<EditRequest>> = _editRequests.asStateFlow()

    private val _memberApplications = MutableStateFlow(initialMemberApplications)
    val memberApplications: StateFlow<List<MemberApplication>> = _memberApplications.asStateFlow()

    private val _selectedBranchId = MutableStateFlow("b-1")
    val selectedBranchId: StateFlow<String> = _selectedBranchId.asStateFlow()

    private val _dashboardState = MutableStateFlow(computeDashboardState())
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
        val branchLoans = _loans.value.filter { it.branchId == selBranchId }
        val branchExpenses = _expenses.value.filter { it.branchId == selBranchId }
        val branchMembers = _members.value.filter { it.branchId == selBranchId && it.status == MemberStatus.ACTIVE }

        val totalContributions = safeRound(branchPayments.sumOf { safeRound(it.amount) })
        val totalLoanRepayments = safeRound(branchLoans.sumOf { safeRound(it.totalRepaid) })
        val totalExpensesAmount = safeRound(branchExpenses.sumOf { safeRound(it.amount) })
        val totalLoansDisbursed = safeRound(branchLoans.sumOf { safeRound(it.amount) })
        
        val targetBranch = _branches.value.find { it.id == selBranchId }
        val baseSeedFund = targetBranch?.balance ?: 0.0
        val totalFundBalance = safeRound(
            baseSeedFund + (totalContributions + totalLoanRepayments) - totalExpensesAmount - totalLoansDisbursed
        )

        val thisMonthCollection = safeRound(
            branchPayments.sumOf { safeRound(it.amount) }
        )

        val activeLoansBalance = safeRound(
            branchLoans.filter { it.status == LoanStatus.ACTIVE }
                .sumOf { safeRound(it.outstandingBalance) }
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
            activeLoans = activeLoansBalance,
            totalOutstandingDues = totalOutstandingDues,
            topDefaulterCount = topDefaulterCount,
            pendingApplicationsCount = pendingAppsCount,
            unreadNotificationCount = 0,
            recentPayments = branchPayments.take(5)
        )
    }

    private fun refreshState() {
        _dashboardState.value = computeDashboardState()
    }

    // --- Financial Operations ---

    fun recordPayment(payment: Payment) {
        val roundedAmount = safeRound(payment.amount)
        val sanitizedPayment = payment.copy(
            id = if (payment.id.isEmpty()) "p-${UUID.randomUUID().toString().take(8)}" else payment.id,
            amount = roundedAmount,
            receiptNumber = if (payment.receiptNumber.isEmpty()) "RCP-${System.currentTimeMillis() % 1000000}" else payment.receiptNumber,
            date = if (payment.date == 0L) System.currentTimeMillis() else payment.date
        )

        _payments.value = listOf(sanitizedPayment) + _payments.value

        // Update member dues and contributions with safeRound
        _members.value = _members.value.map { member ->
            if (member.id == sanitizedPayment.memberId) {
                member.copy(
                    totalContributed = safeRound(member.totalContributed + roundedAmount),
                    outstandingDues = safeRound((member.outstandingDues - roundedAmount).coerceAtLeast(0.0))
                )
            } else {
                member
            }
        }

        // Update branch balance with safeRound
        _branches.value = _branches.value.map { branch ->
            if (branch.id == sanitizedPayment.branchId) {
                branch.copy(balance = safeRound(branch.balance + roundedAmount))
            } else {
                branch
            }
        }

        refreshState()
    }

    fun recordExpense(expense: Expense) {
        val roundedAmount = safeRound(expense.amount)
        val sanitizedExpense = expense.copy(
            id = if (expense.id.isEmpty()) "exp-${UUID.randomUUID().toString().take(8)}" else expense.id,
            amount = roundedAmount,
            date = if (expense.date == 0L) System.currentTimeMillis() else expense.date
        )

        _expenses.value = listOf(sanitizedExpense) + _expenses.value

        // Deduct from branch balance with safeRound
        _branches.value = _branches.value.map { branch ->
            if (branch.id == sanitizedExpense.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - roundedAmount))
            } else {
                branch
            }
        }

        refreshState()
    }

    fun disburseLoan(loan: Loan) {
        val roundedAmount = safeRound(loan.amount)
        val roundedRate = safeRound(loan.interestRate)
        val sanitizedLoan = loan.copy(
            id = if (loan.id.isEmpty()) "ln-${UUID.randomUUID().toString().take(8)}" else loan.id,
            amount = roundedAmount,
            interestRate = roundedRate,
            dateIssued = if (loan.dateIssued == 0L) System.currentTimeMillis() else loan.dateIssued
        )

        _loans.value = listOf(sanitizedLoan) + _loans.value

        // Update member active loan balance with safeRound
        _members.value = _members.value.map { member ->
            if (member.id == sanitizedLoan.memberId) {
                member.copy(
                    activeLoanBalance = safeRound(member.activeLoanBalance + sanitizedLoan.totalPayable)
                )
            } else {
                member
            }
        }

        // Deduct principal from branch balance
        _branches.value = _branches.value.map { branch ->
            if (branch.id == sanitizedLoan.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - roundedAmount))
            } else {
                branch
            }
        }

        refreshState()
    }

    fun repayLoanInstallment(loanId: String, repaymentAmount: Double, method: String = "Cash") {
        val safeAmount = safeRound(repaymentAmount)
        var memberIdToUpdate: String? = null

        _loans.value = _loans.value.map { loan ->
            if (loan.id == loanId) {
                memberIdToUpdate = loan.memberId
                val newRepayment = LoanRepayment(amount = safeAmount, date = System.currentTimeMillis(), method = method)
                val updatedRepayments = loan.repayments + newRepayment
                val updatedLoan = loan.copy(repayments = updatedRepayments)
                val newStatus = if (updatedLoan.outstandingBalance <= 0.0) LoanStatus.PAID_OFF else LoanStatus.ACTIVE
                updatedLoan.copy(status = newStatus)
            } else {
                loan
            }
        }

        memberIdToUpdate?.let { mId ->
            _members.value = _members.value.map { member ->
                if (member.id == mId) {
                    member.copy(
                        activeLoanBalance = safeRound((member.activeLoanBalance - safeAmount).coerceAtLeast(0.0))
                    )
                } else {
                    member
                }
            }
        }

        // Credit to branch balance
        _branches.value = _branches.value.map { branch ->
            if (branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance + safeAmount))
            } else {
                branch
            }
        }

        refreshState()
    }

    // --- Member Resignation / Exit Settlement Workflow (§6.1) ---

    fun processMemberExit(memberId: String, payoutMethod: String = "Cash", note: String = ""): MemberExit? {
        val member = _members.value.find { it.id == memberId } ?: return null
        
        val safeContributed = safeRound(member.totalContributed)
        val safeDues = safeRound(member.outstandingDues)
        val safeLoans = safeRound(member.activeLoanBalance)

        // Settlement Formula: Net Refund = Contributed - Dues - ActiveLoans
        val netSettlement = safeRound((safeContributed - safeDues - safeLoans).coerceAtLeast(0.0))

        val exitRecord = MemberExit(
            id = "exit-${UUID.randomUUID().toString().take(8)}",
            memberId = member.id,
            memberName = member.name,
            totalContributed = safeContributed,
            outstandingDues = safeDues,
            outstandingLoan = safeLoans,
            finalSettlementAmount = netSettlement,
            payoutDate = System.currentTimeMillis(),
            payoutMethod = payoutMethod,
            processedBy = "Super Admin"
        )

        // Mark member as LEFT
        _members.value = _members.value.map { m ->
            if (m.id == memberId) {
                m.copy(
                    status = MemberStatus.LEFT,
                    exitDate = System.currentTimeMillis(),
                    outstandingDues = 0.0,
                    activeLoanBalance = 0.0
                )
            } else {
                m
            }
        }

        // Deduct payout from branch balance with safeRound
        _branches.value = _branches.value.map { branch ->
            if (branch.id == member.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - netSettlement))
            } else {
                branch
            }
        }

        refreshState()
        return exitRecord
    }

    // --- Member Management ---

    fun addMember(member: Member) {
        val sanitized = member.copy(
            id = if (member.id.isEmpty()) "m-${UUID.randomUUID().toString().take(6)}" else member.id,
            totalContributed = safeRound(member.totalContributed),
            outstandingDues = safeRound(member.outstandingDues),
            activeLoanBalance = safeRound(member.activeLoanBalance)
        )
        _members.value = _members.value + sanitized
        refreshState()
    }

    fun updateMember(updated: Member) {
        val sanitized = updated.copy(
            totalContributed = safeRound(updated.totalContributed),
            outstandingDues = safeRound(updated.outstandingDues),
            activeLoanBalance = safeRound(updated.activeLoanBalance)
        )
        _members.value = _members.value.map { if (it.id == sanitized.id) sanitized else it }
        refreshState()
    }

    // --- Branch Management ---

    fun addBranch(branch: Branch) {
        val sanitized = branch.copy(
            id = if (branch.id.isEmpty()) "b-${UUID.randomUUID().toString().take(6)}" else branch.id,
            balance = safeRound(branch.balance)
        )
        _branches.value = _branches.value + sanitized
        refreshState()
    }

    // --- Committee Management ---

    fun addCommitteeMember(member: CommitteeMember) {
        val sanitized = member.copy(
            id = if (member.id.isEmpty()) "cm-${UUID.randomUUID().toString().take(6)}" else member.id
        )
        _committee.value = _committee.value + sanitized
    }

    fun removeCommitteeMember(id: String) {
        _committee.value = _committee.value.filterNot { it.id == id }
    }

    // --- Notice Board ---

    fun publishNotice(notice: Notice) {
        val sanitized = notice.copy(
            id = if (notice.id.isEmpty()) "n-${UUID.randomUUID().toString().take(6)}" else notice.id,
            postedAt = if (notice.postedAt == 0L) System.currentTimeMillis() else notice.postedAt
        )
        _notices.value = listOf(sanitized) + _notices.value
    }

    fun deleteNotice(id: String) {
        _notices.value = _notices.value.filterNot { it.id == id }
    }

    // --- Edit Requests Workflow (§6.1) ---

    fun submitEditRequest(request: EditRequest) {
        val sanitized = request.copy(
            id = if (request.id.isEmpty()) "req-${UUID.randomUUID().toString().take(6)}" else request.id,
            status = ApprovalStatus.PENDING,
            requestedAt = System.currentTimeMillis()
        )
        _editRequests.value = listOf(sanitized) + _editRequests.value
    }

    fun reviewEditRequest(requestId: String, approved: Boolean) {
        val request = _editRequests.value.find { it.id == requestId } ?: return

        _editRequests.value = _editRequests.value.map { req ->
            if (req.id == requestId) {
                req.copy(
                    status = if (approved) ApprovalStatus.APPROVED else ApprovalStatus.REJECTED,
                    reviewedBy = "Super Admin",
                    reviewedAt = System.currentTimeMillis()
                )
            } else {
                req
            }
        }

        // If approved, merge requested changes into the Member record
        if (approved) {
            _members.value = _members.value.map { member ->
                if (member.id == request.memberId) {
                    var updated = member
                    request.requestedChanges.forEach { (field, value) ->
                        when (field) {
                            "phone" -> updated = updated.copy(phone = value)
                            "address" -> updated = updated.copy(address = value)
                            "nid" -> updated = updated.copy(nid = value)
                        }
                    }
                    updated
                } else {
                    member
                }
            }
        }
    }

    // --- Dividend Distribution Payout ---

    fun distributeDividends(run: DividendRun) {
        run.allocations.forEach { allocation ->
            val safePayout = safeRound(allocation.amountPaid)
            // Add dividend distribution as a special record or payout
        }
        refreshState()
    }

    // --- Member Application & Admin Approval Flow ---

    fun submitMemberApplication(application: MemberApplication) {
        _memberApplications.value = listOf(application) + _memberApplications.value
        refreshState()
    }

    fun approveMemberApplication(applicationId: String): Member? {
        val application = _memberApplications.value.find { it.id == applicationId } ?: return null

        val newMemberId = "m-${100 + _members.value.size + 1}"
        val initialDeposit = safeRound(application.monthlyDepositCommitment)

        val newMember = Member(
            id = newMemberId,
            name = application.applicantName,
            phone = application.phone,
            address = application.presentAddress,
            nid = application.nidNumber,
            emergencyContact = EmergencyContact(
                name = application.nomineeName,
                phone = application.nomineePhone
            ),
            branchId = application.targetShomitiName,
            joinDate = System.currentTimeMillis(),
            status = MemberStatus.ACTIVE,
            totalContributed = initialDeposit,
            outstandingDues = 0.0,
            activeLoanBalance = 0.0
        )

        _members.value = _members.value + newMember

        if (initialDeposit > 0.0) {
            val payment = Payment(
                id = "PAY-${System.currentTimeMillis().toString().takeLast(6)}",
                memberId = newMemberId,
                memberName = application.applicantName,
                branchId = application.targetShomitiName,
                type = PaymentType.MONTHLY,
                amount = initialDeposit,
                method = "Cash",
                forMonth = "ফেব্রুয়ারি",
                forYear = 2026,
                date = System.currentTimeMillis(),
                recordedBy = "Super Admin",
                receiptNumber = "REC-${System.currentTimeMillis().toString().takeLast(5)}"
            )
            _payments.value = listOf(payment) + _payments.value
        }

        _memberApplications.value = _memberApplications.value.map {
            if (it.id == applicationId) {
                it.copy(
                    status = ApprovalStatus.APPROVED,
                    reviewedAt = System.currentTimeMillis(),
                    reviewerNote = "অনুমোদিত এবং সদস্য আইডি #$newMemberId বরাদ্দ করা হয়েছে"
                )
            } else {
                it
            }
        }

        refreshState()
        return newMember
    }

    fun rejectMemberApplication(applicationId: String, reason: String = "তথ্য অপূর্ণ বা অনুপযুক্ত") {
        _memberApplications.value = _memberApplications.value.map {
            if (it.id == applicationId) {
                it.copy(
                    status = ApprovalStatus.REJECTED,
                    reviewedAt = System.currentTimeMillis(),
                    reviewerNote = reason
                )
            } else {
                it
            }
        }
        refreshState()
    }
}
