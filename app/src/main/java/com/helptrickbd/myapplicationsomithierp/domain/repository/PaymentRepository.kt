package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.PaymentType
import kotlinx.coroutines.flow.Flow

interface PaymentRepository {
    suspend fun checkDuplicatePayment(
        memberId: String,
        type: PaymentType,
        forMonth: String,
        forYear: Int
    ): Payment?

    suspend fun recordPayment(payment: Payment): Resource<Payment>

    fun getPaymentsFlow(
        branchId: String? = null,
        memberId: String? = null,
        forMonth: String? = null,
        forYear: Int? = null
    ): Flow<Resource<List<Payment>>>

    fun getDefaultersFlow(branchId: String? = null): Flow<Resource<List<Member>>>
}
