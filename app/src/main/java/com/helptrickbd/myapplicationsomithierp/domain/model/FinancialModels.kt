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
    val canMembersViewNotices: Boolean = true,
    val canMembersViewPaymentHistory: Boolean = true
) {
    val allowMembersViewTotalFund: Boolean get() = canMembersViewTotalFund
    val allowMembersViewExpenses: Boolean get() = canMembersViewExpenses
    val allowMembersViewAllMembers: Boolean get() = canMembersViewMemberList
    val allowMembersViewNotices: Boolean get() = canMembersViewNotices
    val allowMembersViewPaymentHistory: Boolean get() = canMembersViewPaymentHistory
}

data class Branch(
    val id: String = "",
    val name: String = "",
    val code: String = "",
    val establishedYear: String = "২০২৪",
    val description: String = "",
    val monthlyDepositAmount: Double = 500.0,
    val admissionFee: Double = 0.0,
    val sharePrice: Double = 0.0,
    val optionalDepositEnabled: Boolean = false,
    val minOptionalDeposit: Double = 0.0,
    val monthlyDueDay: Int = 10,
    val lateFineAmount: Double = 0.0,
    val memberCount: Int = 0,
    val treasurerUserId: String? = null,
    val balance: Double = 0.0,
    val bkashNumber: String = "",
    val nagadNumber: String = "",
    val logoUrl: String = "",
    val bannerUrl: String = "",
    val activityPhotos: List<String> = emptyList(),
    val bankDetails: BankAccountDetails = BankAccountDetails(),
    val permissions: SomithiPermissions = SomithiPermissions(),
    val termsAndConditions: List<String> = listOf(
        "প্রতি মাসে নির্ধারিত তারিখের মধ্যে বাধ্যতামূলক মাসিক চাঁদা পরিশোধ করতে হবে।",
        "মাদ্রাসার উন্নয়ন ও শিক্ষার্থীদের কল্যাণে সংগৃহীত অর্থ ব্যয় করা হবে।",
        "সমিতির সাধারণ বিধিমালা ও পরিচালনা পরিষদের সিদ্ধান্ত মেনে চলতে হবে।",
        "সমিতির অভ্যন্তরীণ শৃঙ্খলা ও ঐক্য বজায় রাখতে হবে।"
    )
)

typealias Somithi = Branch

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
