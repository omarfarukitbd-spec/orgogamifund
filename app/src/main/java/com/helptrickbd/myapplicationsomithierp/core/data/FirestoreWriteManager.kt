package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * Cloud Firestore Write & Transaction Manager.
 * Directly persists applications, members, payments, expenses, and loans to Firebase.
 */
object FirestoreWriteManager {

    private val firestore = FirebaseFirestore.getInstance()
    private val scope = CoroutineScope(Dispatchers.IO)

    fun addMember(member: Member, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val memberId = if (member.id.isNotBlank()) member.id else "m-${System.currentTimeMillis() % 100000}"
                val toSave = member.copy(id = memberId)
                firestore.collection("members").document(memberId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.addMember(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun recordPayment(payment: Payment, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val payId = if (payment.id.isNotBlank()) payment.id else "p-${System.currentTimeMillis()}"
                val toSave = payment.copy(id = payId)
                firestore.collection("payments").document(payId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.recordPayment(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun recordExpense(expense: Expense, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val expId = if (expense.id.isNotBlank()) expense.id else "exp-${System.currentTimeMillis()}"
                val toSave = expense.copy(id = expId)
                firestore.collection("expenses").document(expId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.recordExpense(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun disburseLoan(loan: Loan, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val loanId = if (loan.id.isNotBlank()) loan.id else "ln-${System.currentTimeMillis()}"
                val toSave = loan.copy(id = loanId)
                firestore.collection("loans").document(loanId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.disburseLoan(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun submitMemberApplication(app: MemberApplication, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val appId = if (app.id.isNotBlank()) app.id else "app-${UUID.randomUUID().toString().take(8)}"
                val toSave = app.copy(id = appId, status = ApprovalStatus.PENDING)
                firestore.collection("memberApplications").document(appId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.submitMemberApplication(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun approveMemberApplication(
        app: MemberApplication,
        branchCode: String = "OF-01",
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        scope.launch {
            try {
                val updatedApp = app.copy(
                    status = ApprovalStatus.APPROVED,
                    reviewedAt = System.currentTimeMillis()
                )
                firestore.collection("memberApplications").document(app.id)
                    .set(updatedApp, SetOptions.merge())

                val uniqueMemberId = "OG-${branchCode}-${System.currentTimeMillis() % 10000}"
                val newMember = Member(
                    id = uniqueMemberId,
                    name = app.applicantName,
                    phone = app.phone,
                    address = app.presentAddress.ifBlank { app.permanentAddress },
                    nid = app.nidNumber,
                    branchId = app.targetShomitiId,
                    joinDate = System.currentTimeMillis(),
                    status = MemberStatus.ACTIVE
                )
                firestore.collection("members").document(uniqueMemberId)
                    .set(newMember, SetOptions.merge())

                ShomitiDataManager.approveMemberApplication(app.id)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun rejectMemberApplication(appId: String, reason: String, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                firestore.collection("memberApplications").document(appId)
                    .update(
                        mapOf(
                            "status" to "REJECTED",
                            "reviewerNote" to reason,
                            "reviewedAt" to System.currentTimeMillis()
                        )
                    )
                ShomitiDataManager.rejectMemberApplication(appId, reason)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun submitMemberDeposit(payment: Payment, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val payId = if (payment.id.isNotBlank()) payment.id else "dep-${System.currentTimeMillis()}"
                val toSave = payment.copy(
                    id = payId,
                    approvalStatus = ApprovalStatus.PENDING,
                    receiptNumber = "PENDING-${System.currentTimeMillis() % 10000}"
                )
                firestore.collection("payments").document(payId)
                    .set(toSave, SetOptions.merge())
                ShomitiDataManager.recordPayment(toSave)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun approveDeposit(
        payment: Payment,
        receiptNumber: String,
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        scope.launch {
            try {
                val approvedPayment = payment.copy(
                    approvalStatus = ApprovalStatus.APPROVED,
                    receiptNumber = receiptNumber
                )
                firestore.collection("payments").document(payment.id)
                    .set(approvedPayment, SetOptions.merge())
                ShomitiDataManager.recordPayment(approvedPayment)
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun rejectDeposit(
        paymentId: String,
        reason: String,
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        scope.launch {
            try {
                firestore.collection("payments").document(paymentId)
                    .update(
                        mapOf(
                            "approvalStatus" to "REJECTED",
                            "rejectionReason" to reason
                        )
                    )
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }

    fun createBranch(branch: Branch, onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            try {
                val branchId = if (branch.id.isNotBlank()) branch.id else "b-${System.currentTimeMillis() % 10000}"
                val toSave = branch.copy(id = branchId)
                firestore.collection("branches").document(branchId)
                    .set(toSave, SetOptions.merge())
                onComplete?.invoke(true)
            } catch (e: Exception) {
                e.printStackTrace()
                onComplete?.invoke(false)
            }
        }
    }
}
