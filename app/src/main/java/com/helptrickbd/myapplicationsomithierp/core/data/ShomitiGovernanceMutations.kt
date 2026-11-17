package com.helptrickbd.myapplicationsomithierp.core.data

import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import java.util.UUID

/**
 * Handles governance, member lifecycle, branches, notices, and applications for Shomiti ERP.
 */
internal object ShomitiGovernanceMutations {

    fun addMember(dataManager: ShomitiDataManager, member: Member) {
        val sanitized = member.copy(
            id = if (member.id.isEmpty()) "m-${UUID.randomUUID().toString().take(6)}" else member.id,
            totalContributed = safeRound(member.totalContributed),
            outstandingDues = safeRound(member.outstandingDues),
            activeLoanBalance = safeRound(member.activeLoanBalance)
        )
        dataManager._members.value = dataManager._members.value + sanitized
        dataManager.refreshState()
    }

    fun updateMember(dataManager: ShomitiDataManager, updated: Member) {
        val sanitized = updated.copy(
            totalContributed = safeRound(updated.totalContributed),
            outstandingDues = safeRound(updated.outstandingDues),
            activeLoanBalance = safeRound(updated.activeLoanBalance)
        )
        dataManager._members.value = dataManager._members.value.map { if (it.id == sanitized.id) sanitized else it }
        dataManager.refreshState()
    }

    fun deleteMember(dataManager: ShomitiDataManager, memberId: String) {
        dataManager._members.value = dataManager._members.value.filter { it.id != memberId }
        dataManager.refreshState()
    }

    fun addBranch(dataManager: ShomitiDataManager, branch: Branch) {
        val sanitized = branch.copy(
            id = if (branch.id.isEmpty()) "b-${UUID.randomUUID().toString().take(6)}" else branch.id,
            balance = safeRound(branch.balance)
        )
        dataManager._branches.value = dataManager._branches.value + sanitized
        dataManager.refreshState()
    }

    fun addCommitteeMember(dataManager: ShomitiDataManager, member: CommitteeMember) {
        val sanitized = member.copy(
            id = if (member.id.isEmpty()) "cm-${UUID.randomUUID().toString().take(6)}" else member.id
        )
        dataManager._committee.value = dataManager._committee.value + sanitized
    }

    fun removeCommitteeMember(dataManager: ShomitiDataManager, id: String) {
        dataManager._committee.value = dataManager._committee.value.filterNot { it.id == id }
    }

    fun publishNotice(dataManager: ShomitiDataManager, notice: Notice) {
        val sanitized = notice.copy(
            id = if (notice.id.isEmpty()) "n-${UUID.randomUUID().toString().take(6)}" else notice.id,
            postedAt = if (notice.postedAt == 0L) System.currentTimeMillis() else notice.postedAt
        )
        dataManager._notices.value = listOf(sanitized) + dataManager._notices.value
    }

    fun deleteNotice(dataManager: ShomitiDataManager, id: String) {
        dataManager._notices.value = dataManager._notices.value.filterNot { it.id == id }
    }

    fun submitEditRequest(dataManager: ShomitiDataManager, request: EditRequest) {
        val sanitized = request.copy(
            id = if (request.id.isEmpty()) "req-${UUID.randomUUID().toString().take(6)}" else request.id,
            status = ApprovalStatus.PENDING,
            requestedAt = System.currentTimeMillis()
        )
        dataManager._editRequests.value = listOf(sanitized) + dataManager._editRequests.value
    }

    fun reviewEditRequest(dataManager: ShomitiDataManager, requestId: String, approved: Boolean) {
        val request = dataManager._editRequests.value.find { it.id == requestId } ?: return

        dataManager._editRequests.value = dataManager._editRequests.value.map { req ->
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
            dataManager._members.value = dataManager._members.value.map { member ->
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

    fun submitMemberApplication(dataManager: ShomitiDataManager, application: MemberApplication) {
        dataManager._memberApplications.value = listOf(application) + dataManager._memberApplications.value
        dataManager.refreshState()
    }

    fun approveMemberApplication(dataManager: ShomitiDataManager, applicationId: String): Member? {
        val application = dataManager._memberApplications.value.find { it.id == applicationId } ?: return null

        val newMemberId = "m-${100 + dataManager._members.value.size + 1}"
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

        dataManager._members.value = dataManager._members.value + newMember

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
            dataManager._payments.value = listOf(payment) + dataManager._payments.value
        }

        dataManager._memberApplications.value = dataManager._memberApplications.value.map {
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

        dataManager.refreshState()
        return newMember
    }

    fun rejectMemberApplication(
        dataManager: ShomitiDataManager,
        applicationId: String,
        reason: String = "তথ্য অপূর্ণ বা অনুপযুক্ত"
    ) {
        dataManager._memberApplications.value = dataManager._memberApplications.value.map {
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
        dataManager.refreshState()
    }
}
