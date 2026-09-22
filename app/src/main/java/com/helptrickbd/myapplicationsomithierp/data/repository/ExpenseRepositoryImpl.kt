package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.repository.ExpenseRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class ExpenseRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : ExpenseRepository {

    override suspend fun recordExpense(expense: Expense): Resource<String> {
        return try {
            val expenseDocRef = firestore.collection("expenses").document()
            val branchDocRef = firestore.collection("branches").document(expense.branchId)

            val expenseMap = hashMapOf(
                "id" to expenseDocRef.id,
                "branchId" to expense.branchId,
                "category" to expense.category,
                "amount" to expense.amount,
                "date" to expense.date,
                "description" to expense.description,
                "attachmentUrl" to expense.attachmentUrl,
                "recordedBy" to expense.recordedBy,
                "createdAt" to System.currentTimeMillis()
            )

            // Atomic Firestore Transaction: Save Expense & Deduct Branch Running Balance
            firestore.runTransaction { transaction ->
                val branchSnapshot = transaction.get(branchDocRef)
                val currentBalance = branchSnapshot.getDouble("balance") ?: 0.0

                transaction.set(expenseDocRef, expenseMap)
                transaction.update(branchDocRef, "balance", currentBalance - expense.amount)
            }.await()

            Resource.Success(expenseDocRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to record expense", e)
        }
    }

    override fun getExpensesFlow(branchId: String?): Flow<Resource<List<Expense>>> = callbackFlow {
        trySend(Resource.Loading)
        var query: Query = firestore.collection("expenses").orderBy("date", Query.Direction.DESCENDING)

        if (!branchId.isNullOrEmpty()) {
            query = query.whereEqualTo("branchId", branchId)
        }

        val registration: ListenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load expenses", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                Expense(
                    id = doc.id,
                    branchId = doc.getString("branchId") ?: "",
                    category = doc.getString("category") ?: "সাধারণ খরচ",
                    amount = doc.getDouble("amount") ?: 0.0,
                    date = doc.getLong("date") ?: System.currentTimeMillis(),
                    description = doc.getString("description") ?: "",
                    attachmentUrl = doc.getString("attachmentUrl"),
                    recordedBy = doc.getString("recordedBy") ?: ""
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override suspend fun deleteExpense(expenseId: String, branchId: String, amount: Double): Resource<Unit> {
        return try {
            val expenseDocRef = firestore.collection("expenses").document(expenseId)
            val branchDocRef = firestore.collection("branches").document(branchId)

            firestore.runTransaction { transaction ->
                val branchSnapshot = transaction.get(branchDocRef)
                val currentBalance = branchSnapshot.getDouble("balance") ?: 0.0

                transaction.delete(expenseDocRef)
                transaction.update(branchDocRef, "balance", currentBalance + amount)
            }.await()

            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to delete expense", e)
        }
    }
}
