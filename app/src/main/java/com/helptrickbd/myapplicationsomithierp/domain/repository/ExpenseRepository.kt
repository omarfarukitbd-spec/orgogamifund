package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import kotlinx.coroutines.flow.Flow

interface ExpenseRepository {
    suspend fun recordExpense(expense: Expense): Resource<String>
    fun getExpensesFlow(branchId: String? = null): Flow<Resource<List<Expense>>>
    suspend fun deleteExpense(expenseId: String, branchId: String, amount: Double): Resource<Unit>
}
