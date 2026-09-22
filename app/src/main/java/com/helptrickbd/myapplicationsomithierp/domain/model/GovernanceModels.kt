package com.helptrickbd.myapplicationsomithierp.domain.model

data class CommitteeMember(
    val id: String = "",
    val memberId: String = "",
    val memberName: String = "",
    val photoUrl: String? = null,
    val designation: String = "", // e.g. President, General Secretary, Treasurer
    val termStart: Long = System.currentTimeMillis(),
    val termEnd: Long? = null
)

enum class NoticeType {
    NOTICE,
    MEETING_MINUTES
}

enum class NoticeScope {
    ORGANIZATION,
    BRANCH
}

data class Notice(
    val id: String = "",
    val title: String = "",
    val body: String = "",
    val attachmentUrl: String? = null,
    val type: NoticeType = NoticeType.NOTICE,
    val scope: NoticeScope = NoticeScope.ORGANIZATION,
    val branchId: String? = null,
    val postedBy: String = "",
    val postedAt: Long = System.currentTimeMillis()
)

data class DividendAllocation(
    val memberId: String = "",
    val memberName: String = "",
    val contributionShare: Double = 0.0,
    val amountPaid: Double = 0.0
)

data class DividendRun(
    val id: String = "",
    val year: Int = 2026,
    val totalDistributableAmount: Double = 0.0,
    val calculatedAt: Long = System.currentTimeMillis(),
    val confirmedBy: String = "",
    val allocations: List<DividendAllocation> = emptyList()
)

data class MemberExit(
    val id: String = "",
    val memberId: String = "",
    val memberName: String = "",
    val totalContributed: Double = 0.0,
    val outstandingDues: Double = 0.0,
    val outstandingLoan: Double = 0.0,
    val finalSettlementAmount: Double = 0.0,
    val payoutDate: Long = System.currentTimeMillis(),
    val payoutMethod: String = "Cash",
    val processedBy: String = ""
)

data class EditRequest(
    val id: String = "",
    val memberId: String = "",
    val requestedChanges: Map<String, String> = emptyMap(),
    val status: ApprovalStatus = ApprovalStatus.PENDING,
    val requestedAt: Long = System.currentTimeMillis(),
    val reviewedBy: String? = null,
    val reviewedAt: Long? = null
)

enum class AuditAction {
    CREATE,
    EDIT,
    DELETE
}

data class AuditLog(
    val id: String = "",
    val entityType: String = "", // e.g. "Payment", "Expense", "Loan"
    val entityId: String = "",
    val action: AuditAction = AuditAction.EDIT,
    val changedBy: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val before: Map<String, String> = emptyMap(),
    val after: Map<String, String> = emptyMap(),
    val note: String = ""
)

data class CustomFieldDefinition(
    val key: String = "",
    val label: String = "",
    val type: String = "text" // text, number, date
)

data class Organization(
    val id: String = "",
    val name: String = "Shomiti Manager",
    val logoUrl: String? = null,
    val paymentMethods: List<String> = listOf("Cash", "bKash", "Bank Transfer"),
    val customMemberFields: List<CustomFieldDefinition> = emptyList()
)
