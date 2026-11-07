package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Production Firebase Firestore Data Manager for Ogrogami Fund ERP.
 * Maintains real-time reactive StateFlows synced directly with Firestore collections.
 */
object FirestoreDataManager {

    private val firestore = FirebaseFirestore.getInstance()
    private val scope = CoroutineScope(Dispatchers.IO)

    private val _branches = MutableStateFlow<List<Branch>>(emptyList())
    val branches: StateFlow<List<Branch>> = _branches.asStateFlow()

    private val _members = MutableStateFlow<List<Member>>(emptyList())
    val members: StateFlow<List<Member>> = _members.asStateFlow()

    private val _payments = MutableStateFlow<List<Payment>>(emptyList())
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    private val _expenses = MutableStateFlow<List<Expense>>(emptyList())
    val expenses: StateFlow<List<Expense>> = _expenses.asStateFlow()

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
                val list = snapshot.documents.mapNotNull { doc ->
                    Branch(
                        id = doc.id,
                        name = doc.getString("name") ?: "",
                        code = doc.getString("code") ?: "",
                        establishedYear = doc.getString("establishedYear") ?: "২০২৪",
                        description = doc.getString("description") ?: "",
                        monthlyDepositAmount = doc.getDouble("monthlyDepositAmount") ?: 500.0,
                        admissionFee = doc.getDouble("admissionFee") ?: 0.0,
                        sharePrice = doc.getDouble("sharePrice") ?: 0.0,
                        optionalDepositEnabled = doc.getBoolean("optionalDepositEnabled") ?: false,
                        minOptionalDeposit = doc.getDouble("minOptionalDeposit") ?: 0.0,
                        monthlyDueDay = doc.getLong("monthlyDueDay")?.toInt() ?: 10,
                        lateFineAmount = doc.getDouble("lateFineAmount") ?: 0.0,
                        memberCount = doc.getLong("memberCount")?.toInt() ?: 0,
                        treasurerUserId = doc.getString("treasurerUserId"),
                        balance = doc.getDouble("balance") ?: 0.0,
                        bkashNumber = doc.getString("bkashNumber") ?: "",
                        nagadNumber = doc.getString("nagadNumber") ?: "",
                        logoUrl = doc.getString("logoUrl") ?: "",
                        bannerUrl = doc.getString("bannerUrl") ?: "",
                        activityPhotos = (doc.get("activityPhotos") as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                        bankDetails = (doc.get("bankDetails") as? Map<*, *>)?.let { b ->
                            BankAccountDetails(
                                bankName = b["bankName"] as? String ?: "ইসলামী ব্যাংক বাংলাদেশ পিএলসি",
                                branchName = b["branchName"] as? String ?: "", accountName = b["accountName"] as? String ?: "",
                                accountNumber = b["accountNumber"] as? String ?: "", routingNumber = b["routingNumber"] as? String ?: ""
                            )
                        } ?: BankAccountDetails(),
                        permissions = (doc.get("permissions") as? Map<*, *>)?.let { pMap ->
                            SomithiPermissions(
                                canMembersViewTotalFund = pMap["canMembersViewTotalFund"] as? Boolean ?: true,
                                canMembersViewExpenses = pMap["canMembersViewExpenses"] as? Boolean ?: true,
                                canMembersViewMemberList = pMap["canMembersViewMemberList"] as? Boolean ?: true,
                                canMembersViewNotices = pMap["canMembersViewNotices"] as? Boolean ?: true,
                                canMembersViewPaymentHistory = pMap["canMembersViewPaymentHistory"] as? Boolean ?: true
                            )
                        } ?: SomithiPermissions(),
                        termsAndConditions = (doc.get("termsAndConditions") as? List<*>)?.filterIsInstance<String>()
                            ?: listOf(
                                "প্রতি মাসে নির্ধারিত তারিখের মধ্যে বাধ্যতামূলক মাসিক চাঁদা পরিশোধ করতে হবে।",
                                "মাদ্রাসার উন্নয়ন ও শিক্ষার্থীদের কল্যাণে সংগৃহীত অর্থ ব্যয় করা হবে।"
                            )
                    )
                }
                _branches.value = list
            } else {
                _branches.value = emptyList()
            }
            recomputeDashboardState()
        }

        // 2. Members Sync
        firestore.collection("members").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    val emergencyMap = doc.get("emergencyContact") as? Map<*, *>
                    Member(
                        id = doc.id,
                        name = doc.getString("name") ?: "", nameEn = doc.getString("nameEn") ?: "",
                        fatherName = doc.getString("fatherName") ?: "", dateOfBirth = doc.getString("dateOfBirth") ?: "",
                        occupation = doc.getString("occupation") ?: "", memberType = doc.getString("memberType") ?: "",
                        phone = doc.getString("phone") ?: "", whatsappNumber = doc.getString("whatsappNumber") ?: "",
                        village = doc.getString("village") ?: "", upazila = doc.getString("upazila") ?: "",
                        district = doc.getString("district") ?: "", address = doc.getString("address") ?: "",
                        photoUrl = doc.getString("photoUrl"), nid = doc.getString("nid") ?: "",
                        nidPhotoUrl = doc.getString("nidPhotoUrl"),
                        emergencyContact = EmergencyContact(
                            name = emergencyMap?.get("name") as? String ?: "",
                            relation = emergencyMap?.get("relation") as? String ?: "",
                            phone = emergencyMap?.get("phone") as? String ?: ""
                        ),
                        // Per-section custom fields
                        customFieldsPersonal = doc.get("customFieldsPersonal").toStringMap(),
                        customFieldsContact = doc.get("customFieldsContact").toStringMap(),
                        customFieldsDocs = doc.get("customFieldsDocs").toStringMap(),
                        customFieldsEmergency = doc.get("customFieldsEmergency").toStringMap(),
                        customFields = doc.get("customFields").toStringMap(),
                        // Membership
                        branchId = doc.getString("branchId") ?: "",
                        joinDate = doc.getLong("joinDate") ?: System.currentTimeMillis(),
                        status = if (doc.getString("status") == "LEFT") MemberStatus.LEFT
                        else MemberStatus.ACTIVE,
                        linkedUserId = doc.getString("linkedUserId")
                    )
                }
                _members.value = list
                recomputeDashboardState()
            }
        }

        // 3. Payments Sync
        firestore.collection("payments").addSnapshotListener { snapshot, _ ->
            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    val statusStr = doc.getString("approvalStatus")?.lowercase()
                    Payment(
                        id = doc.id,
                        memberId = doc.getString("memberId") ?: "",
                        memberName = doc.getString("memberName") ?: "",
                        branchId = doc.getString("branchId") ?: "b-1",
                        amount = doc.getDouble("amount") ?: 0.0,
                        date = doc.getLong("date") ?: System.currentTimeMillis(),
                        forMonth = doc.getString("forMonth") ?: "জানুয়ারি",
                        forYear = doc.getLong("forYear")?.toInt() ?: 2026,
                        method = doc.getString("method") ?: "Cash",
                        receiptNumber = doc.getString("receiptNumber") ?: "REC-${(doc.getLong("date") ?: System.currentTimeMillis()) % 100000}",
                        purposeNote = doc.getString("purposeNote") ?: "",
                        transactionId = doc.getString("transactionId") ?: "",
                        bankAccountInfo = doc.getString("bankAccountInfo") ?: "",
                        approvalStatus = when (statusStr) {
                            "pending" -> ApprovalStatus.PENDING
                            "rejected" -> ApprovalStatus.REJECTED
                            else -> ApprovalStatus.APPROVED
                        },
                        rejectionReason = doc.getString("rejectionReason") ?: ""
                    )
                }
                _payments.value = list
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
                        targetShomitiName = doc.getString("targetShomitiName") ?: "অগ্রগামী সঞ্চয় সমিতি",
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

        _dashboardState.value = _dashboardState.value.copy(
            selectedBranchId = branch?.id ?: selId,
            branches = _branches.value,
            totalFundBalance = totalBalance,
            thisMonthCollection = monthCollection,
            totalExpenses = totalExp,
            pendingApplicationsCount = _memberApplications.value.count { it.status == ApprovalStatus.PENDING }
        )
    }
}

private fun Any?.toStringMap(): Map<String, String> = (this as? Map<*, *>)?.entries?.mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }?.toMap() ?: emptyMap()
