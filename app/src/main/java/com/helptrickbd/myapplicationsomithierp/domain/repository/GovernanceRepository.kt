package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.CommitteeMember
import com.helptrickbd.myapplicationsomithierp.domain.model.Notice
import kotlinx.coroutines.flow.Flow

interface GovernanceRepository {
    fun getCommitteeFlow(): Flow<Resource<List<CommitteeMember>>>
    suspend fun addCommitteeMember(committeeMember: CommitteeMember): Resource<String>
    suspend fun updateCommitteeMember(committeeMember: CommitteeMember): Resource<Unit>
    suspend fun removeCommitteeMember(committeeMemberId: String): Resource<Unit>

    fun getNoticesFlow(branchId: String? = null): Flow<Resource<List<Notice>>>
    suspend fun publishNotice(notice: Notice): Resource<String>
    suspend fun deleteNotice(noticeId: String): Resource<Unit>
}
