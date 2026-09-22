package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanRepayment
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanStatus
import com.helptrickbd.myapplicationsomithierp.domain.repository.LoanRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class LoanRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : LoanRepository {

    override suspend fun disburseLoan(loan: Loan): Resource<String> {
        return try {
            val loanDocRef = firestore.collection("loans").document()
            val branchDocRef = firestore.collection("branches").document(loan.branchId)
            val memberDocRef = firestore.collection("members").document(loan.memberId)

            val loanMap = hashMapOf(
                "id" to loanDocRef.id,
                "memberId" to loan.memberId,
                "memberName" to loan.memberName,
                "branchId" to loan.branchId,
                "amount" to loan.amount,
                "dateIssued" to loan.dateIssued,
                "reason" to loan.reason,
                "interestEnabled" to loan.interestEnabled,
                "interestRate" to loan.interestRate,
                "status" to "active",
                "repayments" to emptyList<Map<String, Any>>(),
                "createdAt" to System.currentTimeMillis()
            )

            // Atomic Firestore Transaction for Loan Disbursement
            firestore.runTransaction { transaction ->
                val branchSnapshot = transaction.get(branchDocRef)
                val currentBranchBalance = branchSnapshot.getDouble("balance") ?: 0.0

                val memberSnapshot = transaction.get(memberDocRef)
                val currentLoanBalance = memberSnapshot.getDouble("activeLoanBalance") ?: 0.0

                // 1. Write Loan document
                transaction.set(loanDocRef, loanMap)

                // 2. Deduct disbursed amount from Branch running balance
                transaction.update(branchDocRef, "balance", currentBranchBalance - loan.amount)

                // 3. Increment Member's active loan balance
                transaction.update(memberDocRef, "activeLoanBalance", currentLoanBalance + loan.totalPayable)
            }.await()

            Resource.Success(loanDocRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to disburse loan", e)
        }
    }

    override suspend fun recordLoanRepayment(loanId: String, repayment: LoanRepayment): Resource<Unit> {
        return try {
            val loanDocRef = firestore.collection("loans").document(loanId)

            firestore.runTransaction { transaction ->
                val loanSnapshot = transaction.get(loanDocRef)
                val branchId = loanSnapshot.getString("branchId") ?: ""
                val memberId = loanSnapshot.getString("memberId") ?: ""
                val principal = loanSnapshot.getDouble("amount") ?: 0.0
                val interestEnabled = loanSnapshot.getBoolean("interestEnabled") ?: false
                val interestRate = loanSnapshot.getDouble("interestRate") ?: 0.0

                val totalPayable = if (interestEnabled) principal + (principal * interestRate / 100.0) else principal

                val repaymentsRaw = loanSnapshot.get("repayments") as? List<*> ?: emptyList<Any>()
                val existingTotalRepaid = repaymentsRaw.sumOf { rep ->
                    (rep as? Map<*, *>)?.get("amount") as? Double ?: 0.0
                }

                val newTotalRepaid = existingTotalRepaid + repayment.amount
                val isFullyPaid = newTotalRepaid >= totalPayable

                val branchDocRef = firestore.collection("branches").document(branchId)
                val branchSnapshot = transaction.get(branchDocRef)
                val currentBranchBalance = branchSnapshot.getDouble("balance") ?: 0.0

                val memberDocRef = firestore.collection("members").document(memberId)
                val memberSnapshot = transaction.get(memberDocRef)
                val currentMemberLoanBal = memberSnapshot.getDouble("activeLoanBalance") ?: 0.0

                // 1. Append Repayment map
                val repMap = mapOf(
                    "amount" to repayment.amount,
                    "date" to repayment.date,
                    "method" to repayment.method
                )
                transaction.update(loanDocRef, "repayments", FieldValue.arrayUnion(repMap))
                if (isFullyPaid) {
                    transaction.update(loanDocRef, "status", "paid_off")
                }

                // 2. Increment Branch Fund Balance
                transaction.update(branchDocRef, "balance", currentBranchBalance + repayment.amount)

                // 3. Decrement Member Active Loan Balance
                val newMemberLoanBal = (currentMemberLoanBal - repayment.amount).coerceAtLeast(0.0)
                transaction.update(memberDocRef, "activeLoanBalance", newMemberLoanBal)
            }.await()

            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to record loan repayment", e)
        }
    }

    override fun getLoansFlow(
        branchId: String?,
        memberId: String?,
        status: LoanStatus?
    ): Flow<Resource<List<Loan>>> = callbackFlow {
        trySend(Resource.Loading)
        var query: Query = firestore.collection("loans").orderBy("dateIssued", Query.Direction.DESCENDING)

        if (!branchId.isNullOrEmpty()) {
            query = query.whereEqualTo("branchId", branchId)
        }
        if (!memberId.isNullOrEmpty()) {
            query = query.whereEqualTo("memberId", memberId)
        }
        if (status != null) {
            val statusStr = when (status) {
                LoanStatus.ACTIVE -> "active"
                LoanStatus.PAID_OFF -> "paid_off"
                LoanStatus.DEFAULTED -> "defaulted"
            }
            query = query.whereEqualTo("status", statusStr)
        }

        val registration: ListenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load loans", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val statusStr = doc.getString("status") ?: "active"
                val loanStatus = when (statusStr.lowercase()) {
                    "paid_off" -> LoanStatus.PAID_OFF
                    "defaulted" -> LoanStatus.DEFAULTED
                    else -> LoanStatus.ACTIVE
                }

                val repaymentsRaw = doc.get("repayments") as? List<*> ?: emptyList<Any>()
                val repayments = repaymentsRaw.mapNotNull { rep ->
                    val map = rep as? Map<*, *> ?: return@mapNotNull null
                    LoanRepayment(
                        amount = map["amount"] as? Double ?: 0.0,
                        date = map["date"] as? Long ?: System.currentTimeMillis(),
                        method = map["method"] as? String ?: "Cash"
                    )
                }

                Loan(
                    id = doc.id,
                    memberId = doc.getString("memberId") ?: "",
                    memberName = doc.getString("memberName") ?: "",
                    branchId = doc.getString("branchId") ?: "",
                    amount = doc.getDouble("amount") ?: 0.0,
                    dateIssued = doc.getLong("dateIssued") ?: System.currentTimeMillis(),
                    reason = doc.getString("reason") ?: "",
                    interestEnabled = doc.getBoolean("interestEnabled") ?: false,
                    interestRate = doc.getDouble("interestRate") ?: 0.0,
                    status = loanStatus,
                    repayments = repayments
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override fun getLoanByIdFlow(loanId: String): Flow<Resource<Loan>> = callbackFlow {
        trySend(Resource.Loading)
        val registration = firestore.collection("loans").document(loanId).addSnapshotListener { doc, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load loan", error))
                return@addSnapshotListener
            }

            if (doc != null && doc.exists()) {
                val statusStr = doc.getString("status") ?: "active"
                val loanStatus = when (statusStr.lowercase()) {
                    "paid_off" -> LoanStatus.PAID_OFF
                    "defaulted" -> LoanStatus.DEFAULTED
                    else -> LoanStatus.ACTIVE
                }

                val repaymentsRaw = doc.get("repayments") as? List<*> ?: emptyList<Any>()
                val repayments = repaymentsRaw.mapNotNull { rep ->
                    val map = rep as? Map<*, *> ?: return@mapNotNull null
                    LoanRepayment(
                        amount = map["amount"] as? Double ?: 0.0,
                        date = map["date"] as? Long ?: System.currentTimeMillis(),
                        method = map["method"] as? String ?: "Cash"
                    )
                }

                val loan = Loan(
                    id = doc.id,
                    memberId = doc.getString("memberId") ?: "",
                    memberName = doc.getString("memberName") ?: "",
                    branchId = doc.getString("branchId") ?: "",
                    amount = doc.getDouble("amount") ?: 0.0,
                    dateIssued = doc.getLong("dateIssued") ?: System.currentTimeMillis(),
                    reason = doc.getString("reason") ?: "",
                    interestEnabled = doc.getBoolean("interestEnabled") ?: false,
                    interestRate = doc.getDouble("interestRate") ?: 0.0,
                    status = loanStatus,
                    repayments = repayments
                )
                trySend(Resource.Success(loan))
            } else {
                trySend(Resource.Error("Loan not found"))
            }
        }

        awaitClose { registration.remove() }
    }
}
