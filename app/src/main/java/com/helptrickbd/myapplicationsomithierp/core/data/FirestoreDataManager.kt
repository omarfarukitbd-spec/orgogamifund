package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.FirebaseFirestore
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Production Firebase Firestore Data Manager for Ogrogami Fund ERP.
 * Maintains real-time reactive StateFlows synced directly with Firestore collections.
 */
object FirestoreDataManager {

    private val firestore = FirebaseFirestore.getInstance()

    private val _branches = MutableStateFlow<List<Branch>>(emptyList())
    val branches: StateFlow<List<Branch>> = _branches.asStateFlow()

    private val _members = MutableStateFlow<List<Member>>(emptyList())
    val members: StateFlow<List<Member>> = _members.asStateFlow()

    private val _payments = MutableStateFlow<List<Payment>>(emptyList())
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    private val _expenses = MutableStateFlow<List<Expense>>(emptyList())
    val expenses: StateFlow<List<Expense>> = _expenses.asStateFlow()

    private val _loans = MutableStateFlow<List<Loan>>(emptyList())
    val loans: StateFlow<List<Loan>> = _loans.asStateFlow()

    private val _memberApplications = MutableStateFlow<List<MemberApplication>>(emptyList())
    val memberApplications: StateFlow<List<MemberApplication>> = _memberApplications.asStateFlow()

    private val _selectedBranchId = MutableStateFlow("")
    val selectedBranchId: StateFlow<String> = _selectedBranchId.asStateFlow()

    private val _dashboardState = MutableStateFlow(
        DashboardUiState(
            branches = emptyList(),
            selectedBranchId = ""
        )
    )
    val dashboardState: StateFlow<DashboardUiState> = _dashboardState.asStateFlow()

    init {
        startRealtimeSync()
    }

    private fun startRealtimeSync() {
        // 1. Branches Sync
        firestore.collection("branches").addSnapshotListener { snapshot, _ ->
            if (snapshot != null && !snapshot.isEmpty) {
                _branches.value = snapshot.documents.mapNotNull { it.toBranchModel() }
            } else {
                _branches.value = emptyList()
            }
            recomputeDashboardState()
        }

        // 2. Members Sync
        firestore.collection("members").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    Member(
                        id = doc.id,
                        name = doc.getString("name") ?: "",
                        phone = doc.getString("phone") ?: "",
                        address = doc.getString("address") ?: "",
                        photoUrl = doc.getString("photoUrl"),
                        nid = doc.getString("nid") ?: "",
                        branchId = doc.getString("branchId") ?: "b-1",
                        status = if (doc.getString("status") == "left") MemberStatus.LEFT else MemberStatus.ACTIVE
                    )
                }
                _members.value = list
                recomputeDashboardState()
            }
        }

        // 3. Payments Sync
        firestore.collection("payments").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                _payments.value = snapshot.documents.mapNotNull { it.toPaymentModel() }
                recomputeDashboardState()
            }
        }

        // 4. Expenses Sync
        firestore.collection("expenses").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    Expense(
                        id = doc.id,
                        branchId = doc.getString("branchId") ?: "b-1",
                        amount = doc.getDouble("amount") ?: 0.0,
                        description = doc.getString("description") ?: doc.getString("title") ?: "",
                        category = doc.getString("category") ?: "সাধারণ"
                    )
                }
                _expenses.value = list
                recomputeDashboardState()
            }
        }

        // 5. Member Applications Sync
        firestore.collection("memberApplications").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    MemberApplication(
                        id = doc.id,
                        applicantName = doc.getString("applicantName") ?: "",
                        phone = doc.getString("phone") ?: "",
                        email = doc.getString("email") ?: "",
                        targetShomitiId = doc.getString("targetShomitiId") ?: "b-1",
                        targetShomitiName = doc.getString("targetShomitiName") ?: "অগ্রগামী ফান্ড",
                        status = when (doc.getString("status")) {
                            "APPROVED" -> ApprovalStatus.APPROVED
                            "REJECTED" -> ApprovalStatus.REJECTED
                            else -> ApprovalStatus.PENDING
                        }
                    )
                }
                _memberApplications.value = list
                recomputeDashboardState()
            }
        }

        // 6. Loans (Qard Hasan) Sync
        firestore.collection("loans").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                _loans.value = snapshot.documents.mapNotNull { it.toLoanModel() }
                recomputeDashboardState()
            }
        }
    }

    fun selectBranch(branchId: String) {
        _selectedBranchId.value = branchId
        recomputeDashboardState()
    }

    fun getMembershipStatus(branchId: String, userEmail: String, userRole: UserRole): ShomitiMembershipStatus {
        val cleanEmail = userEmail.trim()
        if (userRole == UserRole.SUPER_ADMIN ||
            cleanEmail.equals("omarfaruktitbd@gmail.com", ignoreCase = true) ||
            cleanEmail.equals("omarfarukitbd@gmail.com", ignoreCase = true)) {
            return ShomitiMembershipStatus.APPROVED_MEMBER
        }
        if (cleanEmail.isNotBlank()) {
            val hasPending = _memberApplications.value.any {
                it.targetShomitiId == branchId && it.status == ApprovalStatus.PENDING &&
                    it.email.equals(cleanEmail, ignoreCase = true)
            }
            if (hasPending) return ShomitiMembershipStatus.PENDING_APPROVAL

            val hasApprovedApp = _memberApplications.value.any {
                it.targetShomitiId == branchId && it.status == ApprovalStatus.APPROVED &&
                    it.email.equals(cleanEmail, ignoreCase = true)
            }
            if (hasApprovedApp) return ShomitiMembershipStatus.APPROVED_MEMBER
        }

        val isMember = _members.value.any { m ->
            m.branchId == branchId && m.status == MemberStatus.ACTIVE &&
            (cleanEmail.isNotBlank() && (m.phone.equals(cleanEmail, ignoreCase = true) || m.name.contains(cleanEmail, ignoreCase = true)))
        }
        if (isMember) return ShomitiMembershipStatus.APPROVED_MEMBER

        return ShomitiMembershipStatus.NOT_A_MEMBER
    }

    fun getCurrentMemberForUser(branchId: String, userEmail: String): Member? {
        val cleanEmail = userEmail.trim()
        val membersInBranch = _members.value.filter {
            (branchId.isBlank() || it.branchId == branchId) && it.status == MemberStatus.ACTIVE
        }
        if (cleanEmail.isNotBlank()) {
            val matched = membersInBranch.find {
                it.phone.equals(cleanEmail, ignoreCase = true) ||
                it.name.contains(cleanEmail, ignoreCase = true)
            }
            if (matched != null) return matched
        }
        return membersInBranch.firstOrNull()
    }

    private fun recomputeDashboardState() {
        val selId = _selectedBranchId.value
        val branch = _branches.value.find { it.id == selId } ?: _branches.value.firstOrNull()
        val totalBalance = branch?.balance ?: 0.0
        val monthCollection = _payments.value.filter { it.branchId == selId }.sumOf { it.amount }.safeRound()
        val totalExp = _expenses.value.filter { it.branchId == selId }.sumOf { it.amount }.safeRound()
        val totalLoans = _loans.value.filter { it.branchId == selId && it.status == LoanStatus.ACTIVE }.sumOf { it.outstandingBalance }.safeRound()

        _dashboardState.value = _dashboardState.value.copy(
            selectedBranchId = branch?.id ?: selId,
            branches = _branches.value,
            totalFundBalance = totalBalance,
            thisMonthCollection = monthCollection,
            totalExpenses = totalExp,
            activeLoans = totalLoans,
            pendingApplicationsCount = _memberApplications.value.count { it.status == ApprovalStatus.PENDING }
        )
    }
}
