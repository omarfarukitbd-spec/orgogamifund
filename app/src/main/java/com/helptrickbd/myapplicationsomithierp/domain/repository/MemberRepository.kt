package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.EditRequest
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberExit
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import kotlinx.coroutines.flow.Flow

interface MemberRepository {
    fun getMembersFlow(branchId: String? = null, status: MemberStatus? = null): Flow<Resource<List<Member>>>
    fun getMemberByIdFlow(memberId: String): Flow<Resource<Member>>
    suspend fun addMember(member: Member): Resource<String>
    suspend fun updateMember(member: Member): Resource<Unit>
    suspend fun deleteMember(memberId: String): Resource<Unit>
    
    // Self-Service Edit Requests (§6.1)
    suspend fun submitEditRequest(editRequest: EditRequest): Resource<String>
    fun getPendingEditRequestsFlow(branchId: String? = null): Flow<Resource<List<EditRequest>>>
    suspend fun reviewEditRequest(requestId: String, isApproved: Boolean, reviewerId: String): Resource<Unit>

    // Member Exit / Resignation Settlement (§6.1)
    suspend fun processMemberExit(exit: MemberExit): Resource<Unit>
}
