package com.helptrickbd.myapplicationsomithierp.domain.model

import com.helptrickbd.myapplicationsomithierp.core.util.safeRound

enum class ShomitiMembershipStatus {
    APPROVED_MEMBER,
    PENDING_APPROVAL,
    NOT_A_MEMBER
}

data class BankAccountDetails(
    val bankName: String = "Islami Bank Bangladesh PLC",
    val accountName: String = "অগ্রগামী কল্যাণ ফান্ড",
    val accountNumber: String = "2050123456789012",
    val branchName: String = "মিরপুর শাখা, ঢাকা",
    val routingNumber: String = "125263451"
)

data class SomithiPermissions(
    val canMembersViewTotalFund: Boolean = true,
    val canMembersViewExpenses: Boolean = true,
    val canMembersViewMemberList: Boolean = true,
    val canMembersViewNotices: Boolean = true
) {
    val allowMembersViewTotalFund: Boolean get() = canMembersViewTotalFund
    val allowMembersViewExpenses: Boolean get() = canMembersViewExpenses
    val allowMembersViewAllMembers: Boolean get() = canMembersViewMemberList
    val allowMembersViewNotices: Boolean get() = canMembersViewNotices
}

data class Branch(
    val id: String = "",
    val name: String = "",
    val code: String = "",
    val establishedYear: String = "২০২৩",
    val description: String = "",
    val monthlyDepositAmount: Double = 1000.0,
    val admissionFee: Double = 500.0,
    val sharePrice: Double = 1000.0,
    val memberCount: Int = 0,
    val treasurerUserId: String? = null,
    val balance: Double = 0.0,
    val bkashNumber: String = "01800000000",
    val nagadNumber: String = "01800000000",
    val bankDetails: BankAccountDetails = BankAccountDetails(),
    val permissions: SomithiPermissions = SomithiPermissions(),
    val termsAndConditions: List<String> = listOf(
        "প্রতি মাসে নির্ধারিত তারিখের মধ্যে বাধ্যতামূলক মাসিক সঞ্চয় বা চাঁদা পরিশোধ করতে হবে।",
        "সমিতির সাধারণ বিধিমালা এবং পরিচালনা পরিষদের যৌক্তিক সকল সিদ্ধান্ত মেনে চলতে হবে।",
        "ঋণ গ্রহণের পর নির্ধারিত কিস্তির তারিখে হিসাব ক্লিয়ার রাখা বাধ্যতামূলক।",
        "সমিতির অভ্যন্তরীণ গোপনীয়তা এবং শৃঙ্খলা বিরোধী কোনো কার্যকলাপে যুক্ত থাকা যাবে না।"
    )
)

enum class PaymentType {
    MONTHLY,
    YEARLY,
    SPECIAL,
    FINE
}

enum class PaymentMethod {
    CASH,
    BKASH,
    NAGAD,
    BANK_TRANSFER
}

data class Payment(
    val id: String = "",
    val memberId: String = "",
    val memberName: String = "",
    val branchId: String = "",
    val type: PaymentType = PaymentType.MONTHLY,
    val amount: Double = 0.0,
    val method: String = "Cash",
    val forMonth: String = "",
    val forYear: Int = 2026,
    val purposeNote: String = "",
    val date: Long = System.currentTimeMillis(),
    val recordedBy: String = "",
    val receiptNumber: String = "",
    val receiptPdfUrl: String? = null,
    val transactionId: String = "",
    val bankAccountInfo: String = "",
    val approvalStatus: ApprovalStatus = ApprovalStatus.APPROVED,
    val rejectionReason: String? = null
)

data class Expense(
    val id: String = "",
    val branchId: String = "",
    val category: String = "",
    val amount: Double = 0.0,
    val date: Long = System.currentTimeMillis(),
    val description: String = "",
    val attachmentUrl: String? = null,
    val recordedBy: String = ""
)

enum class LoanStatus {
    ACTIVE,
    PAID_OFF,
    DEFAULTED
}

data class LoanRepayment(
    val amount: Double = 0.0,
    val date: Long = System.currentTimeMillis(),
    val method: String = "Cash"
)

data class Loan(
    val id: String = "",
    val memberId: String = "",
    val memberName: String = "",
    val branchId: String = "",
    val amount: Double = 0.0,
    val dateIssued: Long = System.currentTimeMillis(),
    val reason: String = "",
    val interestEnabled: Boolean = false,
    val interestRate: Double = 0.0,
    val status: LoanStatus = LoanStatus.ACTIVE,
    val repayments: List<LoanRepayment> = emptyList()
) {
    val totalRepaid: Double
        get() = safeRound(repayments.sumOf { safeRound(it.amount) })

    val totalPayable: Double
        get() = safeRound(if (interestEnabled) safeRound(amount + safeRound(amount * interestRate / 100.0)) else safeRound(amount))

    val outstandingBalance: Double
        get() = safeRound((totalPayable - totalRepaid).coerceAtLeast(0.0))
}
