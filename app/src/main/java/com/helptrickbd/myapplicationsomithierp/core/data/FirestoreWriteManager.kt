package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import java.util.UUID

/**
 * Cloud Firestore Write & Transaction Manager.
 * Persists members, payments, expenses, branches, and applications to Firebase.
 * All callbacks dispatch safely via Firebase Task listeners on the Android main thread.
 */
object FirestoreWriteManager {

    private val firestore = FirebaseFirestore.getInstance()

    fun addMember(member: Member, onComplete: ((Boolean) -> Unit)? = null) {
        val memberId = if (member.id.isNotBlank()) member.id else "m-${System.currentTimeMillis() % 100000}"
        val memberMap = hashMapOf<String, Any>(
            "id" to memberId,
            "name" to member.name, "nameEn" to member.nameEn,
            "fatherName" to member.fatherName, "dateOfBirth" to member.dateOfBirth,
            "occupation" to member.occupation, "memberType" to member.memberType,
            "phone" to member.phone, "whatsappNumber" to member.whatsappNumber,
            "village" to member.village, "upazila" to member.upazila,
            "district" to member.district, "address" to member.address,
            "nid" to member.nid,
            "emergencyContact" to mapOf(
                "name" to member.emergencyContact.name,
                "relation" to member.emergencyContact.relation,
                "phone" to member.emergencyContact.phone
            ),
            "customFieldsPersonal" to member.customFieldsPersonal,
            "customFieldsContact" to member.customFieldsContact,
            "customFieldsDocs" to member.customFieldsDocs,
            "customFieldsEmergency" to member.customFieldsEmergency,
            "customFields" to member.customFields,
            "branchId" to member.branchId,
            "joinDate" to member.joinDate,
            "status" to member.status.name
        )
        member.photoUrl?.let { memberMap["photoUrl"] = it }
        member.nidPhotoUrl?.let { memberMap["nidPhotoUrl"] = it }
        member.linkedUserId?.let { memberMap["linkedUserId"] = it }
        member.exitDate?.let { memberMap["exitDate"] = it }

        firestore.collection("members").document(memberId)
            .set(memberMap, SetOptions.merge())
            .addOnSuccessListener {
                ShomitiDataManager.addMember(member.copy(id = memberId))
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun deleteMember(memberId: String, onComplete: ((Boolean) -> Unit)? = null) {
        FirebaseStorageManager.deleteMemberPhotos(memberId)
        firestore.collection("members").document(memberId).delete()
            .addOnSuccessListener {
                ShomitiDataManager.deleteMember(memberId)
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun recordPayment(payment: Payment, onComplete: ((Boolean) -> Unit)? = null) {
        val payId = if (payment.id.isNotBlank()) payment.id else "p-${System.currentTimeMillis()}"
        val toSave = payment.copy(id = payId)
        val payMap = hashMapOf<String, Any>(
            "id" to payId, "memberId" to toSave.memberId, "memberName" to toSave.memberName,
            "branchId" to toSave.branchId, "type" to toSave.type.name, "amount" to toSave.amount,
            "method" to toSave.method, "forMonth" to toSave.forMonth, "forYear" to toSave.forYear,
            "purposeNote" to toSave.purposeNote, "date" to toSave.date, "recordedBy" to toSave.recordedBy,
            "receiptNumber" to toSave.receiptNumber, "transactionId" to toSave.transactionId,
            "bankAccountInfo" to toSave.bankAccountInfo, "approvalStatus" to toSave.approvalStatus.name
        )
        toSave.receiptPdfUrl?.let { payMap["receiptPdfUrl"] = it }
        toSave.rejectionReason?.let { payMap["rejectionReason"] = it }

        firestore.collection("payments").document(payId)
            .set(payMap, SetOptions.merge())
            .addOnSuccessListener {
                ShomitiDataManager.recordPayment(toSave)
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun recordExpense(expense: Expense, onComplete: ((Boolean) -> Unit)? = null) {
        val expId = if (expense.id.isNotBlank()) expense.id else "exp-${System.currentTimeMillis()}"
        val toSave = expense.copy(id = expId)
        val expMap = hashMapOf<String, Any>(
            "id" to expId, "branchId" to toSave.branchId, "category" to toSave.category,
            "amount" to toSave.amount, "date" to toSave.date, "description" to toSave.description,
            "recordedBy" to toSave.recordedBy
        )
        toSave.attachmentUrl?.let { expMap["attachmentUrl"] = it }

        firestore.collection("expenses").document(expId)
            .set(expMap, SetOptions.merge())
            .addOnSuccessListener {
                ShomitiDataManager.recordExpense(toSave)
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }


    fun submitMemberApplication(app: MemberApplication, onComplete: ((Boolean) -> Unit)? = null) {
        val appId = if (app.id.isNotBlank()) app.id else "app-${UUID.randomUUID().toString().take(8)}"
        val toSave = app.copy(id = appId, status = ApprovalStatus.PENDING)
        val appMap = hashMapOf<String, Any>(
            "id" to appId, "applicantName" to toSave.applicantName, "phone" to toSave.phone,
            "email" to toSave.email, "fatherOrHusbandName" to toSave.fatherOrHusbandName,
            "occupation" to toSave.occupation, "bloodGroup" to toSave.bloodGroup,
            "dob" to toSave.dob, "presentAddress" to toSave.presentAddress,
            "permanentAddress" to toSave.permanentAddress, "nidNumber" to toSave.nidNumber,
            "hasNidDocument" to toSave.hasNidDocument, "hasPhotoDocument" to toSave.hasPhotoDocument,
            "nomineeName" to toSave.nomineeName, "nomineeRelation" to toSave.nomineeRelation,
            "nomineePhone" to toSave.nomineePhone, "nomineeNid" to toSave.nomineeNid,
            "targetShomitiId" to toSave.targetShomitiId, "targetShomitiName" to toSave.targetShomitiName,
            "shareCount" to toSave.shareCount, "monthlyDepositCommitment" to toSave.monthlyDepositCommitment,
            "status" to toSave.status.name, "appliedAt" to toSave.appliedAt
        )

        firestore.collection("memberApplications").document(appId)
            .set(appMap, SetOptions.merge())
            .addOnSuccessListener {
                ShomitiDataManager.submitMemberApplication(toSave)
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun approveMemberApplication(
        app: MemberApplication,
        branchCode: String = "OF-01",
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        val uniqueMemberId = "OG-${branchCode}-${System.currentTimeMillis() % 10000}"
        val newMember = Member(
            id = uniqueMemberId,
            name = app.applicantName,
            fatherName = app.fatherOrHusbandName,
            phone = app.phone,
            address = app.presentAddress.ifBlank { app.permanentAddress },
            nid = app.nidNumber,
            branchId = app.targetShomitiId,
            joinDate = System.currentTimeMillis(),
            status = MemberStatus.ACTIVE
        )

        firestore.collection("memberApplications").document(app.id)
            .update(mapOf("status" to ApprovalStatus.APPROVED.name, "reviewedAt" to System.currentTimeMillis()))
            .addOnSuccessListener {
                addMember(newMember) {
                    ShomitiDataManager.approveMemberApplication(app.id)
                    onComplete?.invoke(true)
                }
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun rejectMemberApplication(appId: String, reason: String, onComplete: ((Boolean) -> Unit)? = null) {
        firestore.collection("memberApplications").document(appId)
            .update(mapOf("status" to "REJECTED", "reviewerNote" to reason, "reviewedAt" to System.currentTimeMillis()))
            .addOnSuccessListener {
                ShomitiDataManager.rejectMemberApplication(appId, reason)
                onComplete?.invoke(true)
            }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun submitMemberDeposit(payment: Payment, onComplete: ((Boolean) -> Unit)? = null) {
        val payId = if (payment.id.isNotBlank()) payment.id else "dep-${System.currentTimeMillis()}"
        val toSave = payment.copy(
            id = payId,
            approvalStatus = ApprovalStatus.PENDING,
            receiptNumber = "PENDING-${System.currentTimeMillis() % 10000}"
        )
        recordPayment(toSave, onComplete)
    }

    fun approveDeposit(payment: Payment, receiptNumber: String, onComplete: ((Boolean) -> Unit)? = null) {
        val approved = payment.copy(approvalStatus = ApprovalStatus.APPROVED, receiptNumber = receiptNumber)
        recordPayment(approved, onComplete)
    }

    fun rejectDeposit(paymentId: String, reason: String, onComplete: ((Boolean) -> Unit)? = null) {
        firestore.collection("payments").document(paymentId)
            .update(mapOf("approvalStatus" to "REJECTED", "rejectionReason" to reason))
            .addOnSuccessListener { onComplete?.invoke(true) }
            .addOnFailureListener { e -> e.printStackTrace(); onComplete?.invoke(false) }
    }

    fun createBranch(branch: Branch, onComplete: ((Boolean) -> Unit)? = null) {
        val branchId = if (branch.id.isNotBlank()) branch.id else "b-${System.currentTimeMillis() % 10000}"
        val branchMap = hashMapOf<String, Any>(
            "id" to branchId, "name" to branch.name, "code" to branch.code,
            "establishedYear" to branch.establishedYear, "description" to branch.description,
            "monthlyDepositAmount" to branch.monthlyDepositAmount, "admissionFee" to branch.admissionFee,
            "sharePrice" to branch.sharePrice, "optionalDepositEnabled" to branch.optionalDepositEnabled,
            "minOptionalDeposit" to branch.minOptionalDeposit, "monthlyDueDay" to branch.monthlyDueDay,
            "lateFineAmount" to branch.lateFineAmount, "memberCount" to branch.memberCount,
            "balance" to branch.balance, "bkashNumber" to branch.bkashNumber, "nagadNumber" to branch.nagadNumber,
            "logoUrl" to branch.logoUrl, "bannerUrl" to branch.bannerUrl, "activityPhotos" to branch.activityPhotos,
            "bankDetails" to mapOf(
                "bankName" to branch.bankDetails.bankName, "accountName" to branch.bankDetails.accountName,
                "accountNumber" to branch.bankDetails.accountNumber, "branchName" to branch.bankDetails.branchName,
                "routingNumber" to branch.bankDetails.routingNumber
            ),
            "permissions" to mapOf(
                "canMembersViewTotalFund" to branch.permissions.canMembersViewTotalFund,
                "canMembersViewExpenses" to branch.permissions.canMembersViewExpenses,
                "canMembersViewMemberList" to branch.permissions.canMembersViewMemberList,
                "canMembersViewNotices" to branch.permissions.canMembersViewNotices,
                "canMembersViewPaymentHistory" to branch.permissions.canMembersViewPaymentHistory
            ),
            "termsAndConditions" to branch.termsAndConditions
        )
        branch.treasurerUserId?.let { branchMap["treasurerUserId"] = it }

        firestore.collection("branches").document(branchId)
            .set(branchMap, SetOptions.merge())
            .addOnSuccessListener { onComplete?.invoke(true) }
            .addOnFailureListener { e ->
                e.printStackTrace()
                onComplete?.invoke(false)
            }
    }

    fun updateBranchBranding(
        branchId: String,
        logoUrl: String,
        bannerUrl: String,
        activityPhotos: List<String>,
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        val map = mapOf("logoUrl" to logoUrl, "bannerUrl" to bannerUrl, "activityPhotos" to activityPhotos)
        firestore.collection("branches").document(branchId).update(map)
            .addOnSuccessListener { onComplete?.invoke(true) }
            .addOnFailureListener { onComplete?.invoke(false) }
    }
}
