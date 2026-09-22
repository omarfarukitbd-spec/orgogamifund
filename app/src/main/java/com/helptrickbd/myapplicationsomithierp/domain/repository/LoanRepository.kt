package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanRepayment
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanStatus
import kotlinx.coroutines.flow.Flow

interface LoanRepository {
    suspend fun disburseLoan(loan: Loan): Resource<String>
    suspend fun recordLoanRepayment(loanId: String, repayment: LoanRepayment): Resource<Unit>
    fun getLoansFlow(branchId: String? = null, memberId: String? = null, status: LoanStatus? = null): Flow<Resource<List<Loan>>>
    fun getLoanByIdFlow(loanId: String): Flow<Resource<Loan>>
}
