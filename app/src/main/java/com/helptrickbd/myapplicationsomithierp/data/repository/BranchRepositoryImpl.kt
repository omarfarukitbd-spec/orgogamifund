package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Organization
import com.helptrickbd.myapplicationsomithierp.domain.repository.BranchRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class BranchRepositoryImpl(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : BranchRepository {

    override fun getOrganizationFlow(): Flow<Resource<Organization>> = callbackFlow {
        trySend(Resource.Loading)
        val docRef = firestore.collection("organizations").document("default_org")

        val registration: ListenerRegistration = docRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to fetch organization", error))
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                val org = Organization(
                    id = snapshot.id,
                    name = snapshot.getString("name") ?: "সোনার বাংলা সমবায় সমিতি",
                    logoUrl = snapshot.getString("logoUrl"),
                    paymentMethods = (snapshot.get("paymentMethods") as? List<*>)?.filterIsInstance<String>()
                        ?: listOf("Cash", "bKash", "Bank Transfer")
                )
                trySend(Resource.Success(org))
            } else {
                // Default organization setup
                val defaultOrg = Organization(id = "default_org")
                trySend(Resource.Success(defaultOrg))
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun updateOrganizationBranding(name: String, logoUrl: String?): Resource<Unit> {
        return try {
            val map = hashMapOf(
                "name" to name,
                "logoUrl" to logoUrl,
                "updatedAt" to System.currentTimeMillis()
            )
            firestore.collection("organizations").document("default_org").set(map, com.google.firebase.firestore.SetOptions.merge()).await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to update branding", e)
        }
    }

    override fun getBranchesFlow(): Flow<Resource<List<Branch>>> = callbackFlow {
        trySend(Resource.Loading)
        val registration = firestore.collection("branches").addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load branches", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                Branch(
                    id = doc.id,
                    name = doc.getString("name") ?: "",
                    treasurerUserId = doc.getString("treasurerUserId"),
                    balance = doc.getDouble("balance") ?: 0.0
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override fun getBranchByIdFlow(branchId: String): Flow<Resource<Branch>> = callbackFlow {
        trySend(Resource.Loading)
        val registration = firestore.collection("branches").document(branchId).addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load branch", error))
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                val branch = Branch(
                    id = snapshot.id,
                    name = snapshot.getString("name") ?: "",
                    treasurerUserId = snapshot.getString("treasurerUserId"),
                    balance = snapshot.getDouble("balance") ?: 0.0
                )
                trySend(Resource.Success(branch))
            } else {
                trySend(Resource.Error("Branch not found"))
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun createBranch(branch: Branch): Resource<String> {
        return try {
            val docRef = if (branch.id.isNotEmpty()) {
                firestore.collection("branches").document(branch.id)
            } else {
                firestore.collection("branches").document()
            }

            val map = hashMapOf(
                "name" to branch.name,
                "treasurerUserId" to branch.treasurerUserId,
                "balance" to branch.balance,
                "createdAt" to System.currentTimeMillis()
            )
            docRef.set(map).await()
            Resource.Success(docRef.id)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to create branch", e)
        }
    }

    override suspend fun updateBranch(branch: Branch): Resource<Unit> {
        return try {
            val map = hashMapOf(
                "name" to branch.name,
                "treasurerUserId" to branch.treasurerUserId,
                "balance" to branch.balance
            )
            firestore.collection("branches").document(branch.id).update(map as Map<String, Any>).await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to update branch", e)
        }
    }

    override suspend fun deleteBranch(branchId: String): Resource<Unit> {
        return try {
            firestore.collection("branches").document(branchId).delete().await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to delete branch", e)
        }
    }
}
