package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.DocumentSnapshot
import com.helptrickbd.myapplicationsomithierp.domain.model.*

fun DocumentSnapshot.toBranchModel(): Branch {
    return Branch(
        id = id,
        name = getString("name") ?: "",
        code = getString("code") ?: "",
        establishedYear = getString("establishedYear") ?: "২০২৩",
        description = getString("description") ?: "",
        monthlyDepositAmount = getDouble("monthlyDepositAmount") ?: 1000.0,
        admissionFee = getDouble("admissionFee") ?: 500.0,
        sharePrice = getDouble("sharePrice") ?: 1000.0,
        memberCount = getLong("memberCount")?.toInt() ?: 0,
        treasurerUserId = getString("treasurerUserId"),
        balance = getDouble("balance") ?: 0.0,
        bkashNumber = getString("bkashNumber") ?: "01824797072",
        nagadNumber = getString("nagadNumber") ?: "01824797072",
        bankDetails = (get("bankDetails") as? Map<*, *>)?.let { bMap ->
            BankAccountDetails(
                bankName = bMap["bankName"] as? String ?: "ইসলামী ব্যাংক বাংলাদেশ পিএলসি",
                branchName = bMap["branchName"] as? String ?: "ফেনী শাখা",
                accountName = bMap["accountName"] as? String ?: "অগ্রগামী ফান্ড",
                accountNumber = bMap["accountNumber"] as? String ?: "20501234567890123",
                routingNumber = bMap["routingNumber"] as? String ?: "125261453"
            )
        } ?: BankAccountDetails(),
        permissions = (get("permissions") as? Map<*, *>)?.let { pMap ->
            SomithiPermissions(
                canMembersViewTotalFund = pMap["canMembersViewTotalFund"] as? Boolean ?: true,
                canMembersViewExpenses = pMap["canMembersViewExpenses"] as? Boolean ?: true,
                canMembersViewMemberList = pMap["canMembersViewMemberList"] as? Boolean ?: true,
                canMembersViewNotices = pMap["canMembersViewNotices"] as? Boolean ?: true
            )
        } ?: SomithiPermissions(),
        termsAndConditions = (get("termsAndConditions") as? List<*>)?.filterIsInstance<String>()
            ?: listOf(
                "১. প্রতি মাসে নির্ধারিত তারিখের মধ্যে মাসিক সঞ্চয় পরিশোধ করতে হবে।",
                "২. সমিতির সাধারণ সিদ্ধান্ত ও পরিচালনা পরিষদের নিয়ম মেনে চলতে হবে।",
                "৩. নিয়মিত সঞ্চয় ও শৃঙ্খলার মাধ্যমে ঋণ সুবিধা নিশ্চিত করা হবে।"
            )
    )
}

fun DocumentSnapshot.toPaymentModel(): Payment {
    val statusStr = getString("approvalStatus")?.lowercase()
    return Payment(
        id = id,
        memberId = getString("memberId") ?: "",
        memberName = getString("memberName") ?: "",
        branchId = getString("branchId") ?: "b-1",
        amount = getDouble("amount") ?: 0.0,
        date = getLong("date") ?: System.currentTimeMillis(),
        forMonth = getString("forMonth") ?: "জানুয়ারি",
        forYear = getLong("forYear")?.toInt() ?: 2026,
        method = getString("method") ?: "Cash",
        receiptNumber = getString("receiptNumber") ?: "REC-${(getLong("date") ?: System.currentTimeMillis()) % 100000}",
        purposeNote = getString("purposeNote") ?: "",
        transactionId = getString("transactionId") ?: "",
        bankAccountInfo = getString("bankAccountInfo") ?: "",
        approvalStatus = when (statusStr) {
            "pending" -> ApprovalStatus.PENDING
            "rejected" -> ApprovalStatus.REJECTED
            else -> ApprovalStatus.APPROVED
        },
        rejectionReason = getString("rejectionReason") ?: ""
    )
}

fun DocumentSnapshot.toLoanModel(): Loan {
    val statusStr = getString("status")?.lowercase()
    val repaymentsRaw = get("repayments") as? List<*> ?: emptyList<Any>()
    val repayments = repaymentsRaw.mapNotNull { rep ->
        val map = rep as? Map<*, *> ?: return@mapNotNull null
        LoanRepayment(
            amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
            date = (map["date"] as? Number)?.toLong() ?: System.currentTimeMillis(),
            method = map["method"] as? String ?: "Cash"
        )
    }
    return Loan(
        id = id,
        memberId = getString("memberId") ?: "",
        memberName = getString("memberName") ?: "",
        branchId = getString("branchId") ?: "b-1",
        amount = getDouble("amount") ?: 0.0,
        dateIssued = getLong("dateIssued") ?: System.currentTimeMillis(),
        reason = getString("reason") ?: "",
        status = when (statusStr) {
            "paid_off" -> LoanStatus.PAID_OFF
            "defaulted" -> LoanStatus.DEFAULTED
            else -> LoanStatus.ACTIVE
        },
        repayments = repayments
    )
}

fun DocumentSnapshot.toMemberModel(): Member? {
    if (!exists()) return null
    val emergencyMap = get("emergencyContact") as? Map<*, *>
    val emergencyContact = EmergencyContact(
        name = emergencyMap?.get("name") as? String ?: "",
        phone = emergencyMap?.get("phone") as? String ?: ""
    )
    val statusStr = getString("status") ?: "active"
    val memberStatus = if (statusStr.equals("left", ignoreCase = true)) MemberStatus.LEFT else MemberStatus.ACTIVE

    return Member(
        id = id,
        name = getString("name") ?: "",
        phone = getString("phone") ?: "",
        address = getString("address") ?: "",
        photoUrl = getString("photoUrl"),
        nid = getString("nid") ?: "",
        nidPhotoUrl = getString("nidPhotoUrl"),
        emergencyContact = emergencyContact,
        branchId = getString("branchId") ?: "",
        joinDate = getLong("joinDate") ?: System.currentTimeMillis(),
        status = memberStatus,
        exitDate = getLong("exitDate"),
        totalContributed = getDouble("totalContributed") ?: 0.0,
        outstandingDues = getDouble("outstandingDues") ?: 0.0,
        activeLoanBalance = getDouble("activeLoanBalance") ?: 0.0
    )
}
