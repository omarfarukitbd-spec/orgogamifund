package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.EmergencyContact
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.PaymentType
import com.helptrickbd.myapplicationsomithierp.domain.repository.PaymentRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PaymentRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : PaymentRepository {

    override suspend fun checkDuplicatePayment(
        memberId: String,
        type: PaymentType,
        forMonth: String,
        forYear: Int
    ): Payment? {
        return try {
            val typeStr = type.name.lowercase()
            val querySnapshot = firestore.collection("payments")
                .whereEqualTo("memberId", memberId)
                .whereEqualTo("type", typeStr)
                .whereEqualTo("forMonth", forMonth)
                .whereEqualTo("forYear", forYear)
                .limit(1)
                .get()
                .await()

            if (!querySnapshot.isEmpty) {
                val doc = querySnapshot.documents.first()
                Payment(
                    id = doc.id,
                    memberId = doc.getString("memberId") ?: "",
                    memberName = doc.getString("memberName") ?: "",
                    branchId = doc.getString("branchId") ?: "",
                    type = type,
                    amount = doc.getDouble("amount") ?: 0.0,
                    method = doc.getString("method") ?: "Cash",
                    forMonth = doc.getString("forMonth") ?: "",
                    forYear = doc.getLong("forYear")?.toInt() ?: forYear,
                    receiptNumber = doc.getString("receiptNumber") ?: "",
                    date = doc.getLong("date") ?: System.currentTimeMillis()
                )
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun recordPayment(payment: Payment): Resource<Payment> {
        return try {
            val paymentDocRef = firestore.collection("payments").document()
            val datePrefix = SimpleDateFormat("yyyyMM", Locale.getDefault()).format(Date())
            val randomSuffix = (1000..9999).random()
            val receiptNo = "RCP-$datePrefix-$randomSuffix"

            val paymentToSave = payment.copy(
                id = paymentDocRef.id,
                receiptNumber = receiptNo,
                date = System.currentTimeMillis()
            )

            val branchDocRef = firestore.collection("branches").document(payment.branchId)
            val memberDocRef = firestore.collection("members").document(payment.memberId)

            // Atomic Firestore Transaction for Data Accuracy
            firestore.runTransaction { transaction ->
                val branchSnapshot = transaction.get(branchDocRef)
                val currentBranchBalance = branchSnapshot.getDouble("balance") ?: 0.0

                val memberSnapshot = transaction.get(memberDocRef)
                val currentContributed = memberSnapshot.getDouble("totalContributed") ?: 0.0
                val currentDues = memberSnapshot.getDouble("outstandingDues") ?: 0.0

                val paymentMap = hashMapOf(
                    "id" to paymentToSave.id,
                    "memberId" to paymentToSave.memberId,
                    "memberName" to paymentToSave.memberName,
                    "branchId" to paymentToSave.branchId,
                    "type" to paymentToSave.type.name.lowercase(),
                    "amount" to paymentToSave.amount,
                    "method" to paymentToSave.method,
                    "forMonth" to paymentToSave.forMonth,
                    "forYear" to paymentToSave.forYear,
                    "purposeNote" to paymentToSave.purposeNote,
                    "date" to paymentToSave.date,
                    "recordedBy" to paymentToSave.recordedBy,
                    "receiptNumber" to paymentToSave.receiptNumber,
                    "createdAt" to System.currentTimeMillis()
                )

                // 1. Write Payment document
                transaction.set(paymentDocRef, paymentMap)

                // 2. Increment Branch running balance
                transaction.update(branchDocRef, "balance", currentBranchBalance + paymentToSave.amount)

                // 3. Update Member cumulative contribution and decrease dues
                val newDues = (currentDues - paymentToSave.amount).coerceAtLeast(0.0)
                transaction.update(
                    memberDocRef,
                    mapOf(
                        "totalContributed" to (currentContributed + paymentToSave.amount),
                        "outstandingDues" to newDues,
                        "updatedAt" to System.currentTimeMillis()
                    )
                )
            }.await()

            Resource.Success(paymentToSave)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to record payment transaction", e)
        }
    }

    override fun getPaymentsFlow(
        branchId: String?,
        memberId: String?,
        forMonth: String?,
        forYear: Int?
    ): Flow<Resource<List<Payment>>> = callbackFlow {
        trySend(Resource.Loading)
        var query: Query = firestore.collection("payments").orderBy("date", Query.Direction.DESCENDING)

        if (!branchId.isNullOrEmpty()) {
            query = query.whereEqualTo("branchId", branchId)
        }
        if (!memberId.isNullOrEmpty()) {
            query = query.whereEqualTo("memberId", memberId)
        }
        if (!forMonth.isNullOrEmpty()) {
            query = query.whereEqualTo("forMonth", forMonth)
        }
        if (forYear != null) {
            query = query.whereEqualTo("forYear", forYear)
        }

        val registration: ListenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load payments", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val typeStr = doc.getString("type") ?: "monthly"
                val pType = when (typeStr.lowercase()) {
                    "yearly" -> PaymentType.YEARLY
                    "special" -> PaymentType.SPECIAL
                    "fine" -> PaymentType.FINE
                    else -> PaymentType.MONTHLY
                }

                Payment(
                    id = doc.id,
                    memberId = doc.getString("memberId") ?: "",
                    memberName = doc.getString("memberName") ?: "",
                    branchId = doc.getString("branchId") ?: "",
                    type = pType,
                    amount = doc.getDouble("amount") ?: 0.0,
                    method = doc.getString("method") ?: "Cash",
                    forMonth = doc.getString("forMonth") ?: "",
                    forYear = doc.getLong("forYear")?.toInt() ?: 2026,
                    purposeNote = doc.getString("purposeNote") ?: "",
                    date = doc.getLong("date") ?: System.currentTimeMillis(),
                    recordedBy = doc.getString("recordedBy") ?: "",
                    receiptNumber = doc.getString("receiptNumber") ?: "",
                    receiptPdfUrl = doc.getString("receiptPdfUrl")
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override fun getDefaultersFlow(branchId: String?): Flow<Resource<List<Member>>> = callbackFlow {
        trySend(Resource.Loading)
        var query: Query = firestore.collection("members")
            .whereEqualTo("status", "active")
            .whereGreaterThan("outstandingDues", 0.0)

        if (!branchId.isNullOrEmpty()) {
            query = query.whereEqualTo("branchId", branchId)
        }

        val registration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load defaulters", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val emergencyMap = doc.get("emergencyContact") as? Map<*, *>
                val emergencyContact = EmergencyContact(
                    name = emergencyMap?.get("name") as? String ?: "",
                    phone = emergencyMap?.get("phone") as? String ?: ""
                )

                Member(
                    id = doc.id,
                    name = doc.getString("name") ?: "",
                    phone = doc.getString("phone") ?: "",
                    address = doc.getString("address") ?: "",
                    photoUrl = doc.getString("photoUrl"),
                    nid = doc.getString("nid") ?: "",
                    emergencyContact = emergencyContact,
                    branchId = doc.getString("branchId") ?: "",
                    joinDate = doc.getLong("joinDate") ?: System.currentTimeMillis(),
                    status = MemberStatus.ACTIVE,
                    totalContributed = doc.getDouble("totalContributed") ?: 0.0,
                    outstandingDues = doc.getDouble("outstandingDues") ?: 0.0,
                    activeLoanBalance = doc.getDouble("activeLoanBalance") ?: 0.0
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }
}
