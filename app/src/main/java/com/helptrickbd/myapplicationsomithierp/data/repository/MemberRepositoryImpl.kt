package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.EditRequest
import com.helptrickbd.myapplicationsomithierp.domain.model.EmergencyContact
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberExit
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import com.helptrickbd.myapplicationsomithierp.domain.repository.MemberRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class MemberRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : MemberRepository {

    override fun getMembersFlow(branchId: String?, status: MemberStatus?): Flow<Resource<List<Member>>> = callbackFlow {
        trySend(Resource.Loading)
        var query: Query = firestore.collection("members")

        if (!branchId.isNullOrEmpty()) {
            query = query.whereEqualTo("branchId", branchId)
        }
        if (status != null) {
            query = query.whereEqualTo("status", if (status == MemberStatus.ACTIVE) "active" else "left")
        }

        val registration: ListenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load members", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val emergencyMap = doc.get("emergencyContact") as? Map<*, *>
                val emergencyContact = EmergencyContact(
                    name = emergencyMap?.get("name") as? String ?: "",
                    phone = emergencyMap?.get("phone") as? String ?: ""
                )

                val statusStr = doc.getString("status") ?: "active"
                val memberStatus = if (statusStr.equals("left", ignoreCase = true)) MemberStatus.LEFT else MemberStatus.ACTIVE

                Member(
                    id = doc.id,
                    name = doc.getString("name") ?: "",
                    phone = doc.getString("phone") ?: "",
                    address = doc.getString("address") ?: "",
                    photoUrl = doc.getString("photoUrl"),
                    nid = doc.getString("nid") ?: "",
                    nidPhotoUrl = doc.getString("nidPhotoUrl"),
                    emergencyContact = emergencyContact,
                    branchId = doc.getString("branchId") ?: "",
                    joinDate = doc.getLong("joinDate") ?: System.currentTimeMillis(),
                    status = memberStatus,
                    exitDate = doc.getLong("exitDate"),
                    totalContributed = doc.getDouble("totalContributed") ?: 0.0,
                    outstandingDues = doc.getDouble("outstandingDues") ?: 0.0,
                    activeLoanBalance = doc.getDouble("activeLoanBalance") ?: 0.0
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override fun getMemberByIdFlow(memberId: String): Flow<Resource<Member>> = callbackFlow {
        trySend(Resource.Loading)
        val registration = firestore.collection("members").document(memberId).addSnapshotListener { doc, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load member", error))
                return@addSnapshotListener
            }

            if (doc != null && doc.exists()) {
                val emergencyMap = doc.get("emergencyContact") as? Map<*, *>
                val emergencyContact = EmergencyContact(
                    name = emergencyMap?.get("name") as? String ?: "",
                    phone = emergencyMap?.get("phone") as? String ?: ""
                )
                val statusStr = doc.getString("status") ?: "active"
                val memberStatus = if (statusStr.equals("left", ignoreCase = true)) MemberStatus.LEFT else MemberStatus.ACTIVE

                val member = Member(
                    id = doc.id,
                    name = doc.getString("name") ?: "",
                    phone = doc.getString("phone") ?: "",
                    address = doc.getString("address") ?: "",
                    photoUrl = doc.getString("photoUrl"),
                    nid = doc.getString("nid") ?: "",
                    nidPhotoUrl = doc.getString("nidPhotoUrl"),
                    emergencyContact = emergencyContact,
                    branchId = doc.getString("branchId") ?: "",
                    joinDate = doc.getLong("joinDate") ?: System.currentTimeMillis(),
                    status = memberStatus,
                    exitDate = doc.getLong("exitDate"),
                    totalContributed = doc.getDouble("totalContributed") ?: 0.0,
                    outstandingDues = doc.getDouble("outstandingDues") ?: 0.0,
                    activeLoanBalance = doc.getDouble("activeLoanBalance") ?: 0.0
                )
                trySend(Resource.Success(member))
            } else {
                trySend(Resource.Error("Member record not found"))
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun addMember(member: Member): Resource<String> {
        return try {
            val docRef = if (member.id.isNotEmpty()) {
                firestore.collection("members").document(member.id)
            } else {
                firestore.collection("members").document()
            }

            val map = hashMapOf(
                "name" to member.name,
                "phone" to member.phone,
                "address" to member.address,
                "photoUrl" to member.photoUrl,
                "nid" to member.nid,
                "nidPhotoUrl" to member.nidPhotoUrl,
                "emergencyContact" to mapOf(
                    "name" to member.emergencyContact.name,
                    "phone" to member.emergencyContact.phone
                ),
                "branchId" to member.branchId,
                "joinDate" to member.joinDate,
                "status" to if (member.status == MemberStatus.ACTIVE) "active" else "left",
                "customFields" to member.customFields,
                "totalContributed" to 0.0,
                "outstandingDues" to 0.0,
                "activeLoanBalance" to 0.0,
                "createdAt" to System.currentTimeMillis()
            )

            docRef.set(map).await()
            Resource.Success(docRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to add member", e)
        }
    }

    override suspend fun updateMember(member: Member): Resource<Unit> {
        return try {
            val map = hashMapOf(
                "name" to member.name,
                "phone" to member.phone,
                "address" to member.address,
                "photoUrl" to member.photoUrl,
                "nid" to member.nid,
                "nidPhotoUrl" to member.nidPhotoUrl,
                "emergencyContact" to mapOf(
                    "name" to member.emergencyContact.name,
                    "phone" to member.emergencyContact.phone
                ),
                "branchId" to member.branchId,
                "customFields" to member.customFields,
                "updatedAt" to System.currentTimeMillis()
            )
            firestore.collection("members").document(member.id).update(map as Map<String, Any>).await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to update member", e)
        }
    }

    override suspend fun deleteMember(memberId: String): Resource<Unit> {
        return try {
            firestore.collection("members").document(memberId).delete().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to delete member", e)
        }
    }

    override suspend fun submitEditRequest(editRequest: EditRequest): Resource<String> {
        return try {
            val docRef = firestore.collection("editRequests").document()
            val map = hashMapOf(
                "memberId" to editRequest.memberId,
                "requestedChanges" to editRequest.requestedChanges,
                "status" to "pending",
                "requestedAt" to System.currentTimeMillis()
            )
            docRef.set(map).await()
            Resource.Success(docRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to submit edit request", e)
        }
    }

    override fun getPendingEditRequestsFlow(branchId: String?): Flow<Resource<List<EditRequest>>> = callbackFlow {
        trySend(Resource.Loading)
        val query = firestore.collection("editRequests").whereEqualTo("status", "pending")

        val registration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load edit requests", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                val changes = (doc.get("requestedChanges") as? Map<*, *>)?.mapNotNull { (k, v) ->
                    if (k is String && v is String) k to v else null
                }?.toMap() ?: emptyMap()

                EditRequest(
                    id = doc.id,
                    memberId = doc.getString("memberId") ?: "",
                    requestedChanges = changes,
                    status = ApprovalStatus.PENDING,
                    requestedAt = doc.getLong("requestedAt") ?: System.currentTimeMillis()
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override suspend fun reviewEditRequest(requestId: String, isApproved: Boolean, reviewerId: String): Resource<Unit> {
        return try {
            val requestDoc = firestore.collection("editRequests").document(requestId).get().await()
            if (!requestDoc.exists()) return Resource.Error("Request not found")

            val memberId = requestDoc.getString("memberId") ?: return Resource.Error("MemberId missing in request")
            val changes = requestDoc.get("requestedChanges") as? Map<*, *>

            val batch = firestore.batch()
            val requestRef = firestore.collection("editRequests").document(requestId)

            if (isApproved && changes != null) {
                val memberRef = firestore.collection("members").document(memberId)
                val updateMap = mutableMapOf<String, Any>()
                changes.forEach { (k, v) ->
                    if (k is String && v != null) {
                        updateMap[k] = v
                    }
                }
                updateMap["updatedAt"] = System.currentTimeMillis()
                batch.update(memberRef, updateMap)

                batch.update(
                    requestRef,
                    mapOf(
                        "status" to "approved",
                        "reviewedBy" to reviewerId,
                        "reviewedAt" to System.currentTimeMillis()
                    )
                )
            } else {
                batch.update(
                    requestRef,
                    mapOf(
                        "status" to "rejected",
                        "reviewedBy" to reviewerId,
                        "reviewedAt" to System.currentTimeMillis()
                    )
                )
            }

            batch.commit().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to review request", e)
        }
    }

    override suspend fun processMemberExit(exit: MemberExit): Resource<Unit> {
        return try {
            val batch = firestore.batch()

            // 1. Mark member status as 'LEFT'
            val memberRef = firestore.collection("members").document(exit.memberId)
            batch.update(
                memberRef,
                mapOf(
                    "status" to "left",
                    "exitDate" to exit.payoutDate,
                    "updatedAt" to System.currentTimeMillis()
                )
            )

            // 2. Record the exit settlement document
            val exitRef = firestore.collection("memberExits").document()
            batch.set(
                exitRef,
                mapOf(
                    "id" to exitRef.id,
                    "memberId" to exit.memberId,
                    "memberName" to exit.memberName,
                    "totalContributed" to exit.totalContributed,
                    "outstandingDues" to exit.outstandingDues,
                    "outstandingLoan" to exit.outstandingLoan,
                    "finalSettlementAmount" to exit.finalSettlementAmount,
                    "payoutDate" to exit.payoutDate,
                    "payoutMethod" to exit.payoutMethod,
                    "processedBy" to exit.processedBy,
                    "createdAt" to System.currentTimeMillis()
                )
            )

            batch.commit().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to process member exit settlement", e)
        }
    }
}
