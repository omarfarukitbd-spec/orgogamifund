package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.CommitteeMember
import com.helptrickbd.myapplicationsomithierp.domain.model.Notice
import com.helptrickbd.myapplicationsomithierp.domain.model.NoticeScope
import com.helptrickbd.myapplicationsomithierp.domain.model.NoticeType
import com.helptrickbd.myapplicationsomithierp.domain.repository.GovernanceRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class GovernanceRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : GovernanceRepository {

    override fun getCommitteeFlow(): Flow<Resource<List<CommitteeMember>>> = callbackFlow {
        trySend(Resource.Loading)
        val registration: ListenerRegistration = firestore.collection("committee")
            .orderBy("termStart", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(Resource.Error(error.localizedMessage ?: "Failed to load committee", error))
                    return@addSnapshotListener
                }

                val list = snapshot?.documents?.mapNotNull { doc ->
                    CommitteeMember(
                        id = doc.id,
                        memberId = doc.getString("memberId") ?: "",
                        memberName = doc.getString("memberName") ?: "",
                        photoUrl = doc.getString("photoUrl"),
                        designation = doc.getString("designation") ?: "",
                        termStart = doc.getLong("termStart") ?: System.currentTimeMillis(),
                        termEnd = doc.getLong("termEnd")
                    )
                } ?: emptyList()

                trySend(Resource.Success(list))
            }

        awaitClose { registration.remove() }
    }

    override suspend fun addCommitteeMember(committeeMember: CommitteeMember): Resource<String> {
        return try {
            val docRef = firestore.collection("committee").document()
            val map = hashMapOf(
                "id" to docRef.id,
                "memberId" to committeeMember.memberId,
                "memberName" to committeeMember.memberName,
                "photoUrl" to committeeMember.photoUrl,
                "designation" to committeeMember.designation,
                "termStart" to committeeMember.termStart,
                "termEnd" to committeeMember.termEnd,
                "createdAt" to System.currentTimeMillis()
            )
            docRef.set(map).await()
            Resource.Success(docRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to add committee member", e)
        }
    }

    override suspend fun updateCommitteeMember(committeeMember: CommitteeMember): Resource<Unit> {
        return try {
            val map = hashMapOf(
                "designation" to committeeMember.designation,
                "termStart" to committeeMember.termStart,
                "termEnd" to committeeMember.termEnd
            )
            firestore.collection("committee").document(committeeMember.id).update(map as Map<String, Any>).await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to update committee member", e)
        }
    }

    override suspend fun removeCommitteeMember(committeeMemberId: String): Resource<Unit> {
        return try {
            firestore.collection("committee").document(committeeMemberId).delete().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to remove committee member", e)
        }
    }

    override fun getNoticesFlow(branchId: String?): Flow<Resource<List<Notice>>> = callbackFlow {
        trySend(Resource.Loading)
        val query: Query = firestore.collection("notices").orderBy("postedAt", Query.Direction.DESCENDING)

        val registration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load notices", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val typeStr = doc.getString("type") ?: "notice"
                val nType = if (typeStr.equals("meetingminutes", ignoreCase = true)) NoticeType.MEETING_MINUTES else NoticeType.NOTICE

                val scopeStr = doc.getString("scope") ?: "org"
                val nScope = if (scopeStr.equals("branch", ignoreCase = true)) NoticeScope.BRANCH else NoticeScope.ORGANIZATION

                Notice(
                    id = doc.id,
                    title = doc.getString("title") ?: "",
                    body = doc.getString("body") ?: "",
                    attachmentUrl = doc.getString("attachmentUrl"),
                    type = nType,
                    scope = nScope,
                    branchId = doc.getString("branchId"),
                    postedBy = doc.getString("postedBy") ?: "",
                    postedAt = doc.getLong("postedAt") ?: System.currentTimeMillis()
                )
            }?.filter { notice ->
                // Filter by scope (org-wide or matching branch)
                notice.scope == NoticeScope.ORGANIZATION || branchId.isNullOrEmpty() || notice.branchId == branchId
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override suspend fun publishNotice(notice: Notice): Resource<String> {
        return try {
            val docRef = firestore.collection("notices").document()
            val map = hashMapOf(
                "id" to docRef.id,
                "title" to notice.title,
                "body" to notice.body,
                "attachmentUrl" to notice.attachmentUrl,
                "type" to notice.type.name.lowercase(),
                "scope" to notice.scope.name.lowercase(),
                "branchId" to notice.branchId,
                "postedBy" to notice.postedBy,
                "postedAt" to notice.postedAt
            )
            docRef.set(map).await()
            Resource.Success(docRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to publish notice", e)
        }
    }

    override suspend fun deleteNotice(noticeId: String): Resource<Unit> {
        return try {
            firestore.collection("notices").document(noticeId).delete().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to delete notice", e)
        }
    }
}
