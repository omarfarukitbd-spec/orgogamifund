package com.helptrickbd.myapplicationsomithierp.data.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.User
import com.helptrickbd.myapplicationsomithierp.domain.model.UserPreferencesData
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.domain.repository.AuthRepository
import com.helptrickbd.myapplicationsomithierp.domain.repository.UserSession
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.util.UUID

class AuthRepositoryImpl(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance(),
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : AuthRepository {

    companion object {
        const val ROOT_SUPER_ADMIN_EMAIL = "omarfaruktitbd@gmail.com"
        const val LEGACY_SUPER_ADMIN_EMAIL = "omarfarukitbd@gmail.com"

        fun isSuperAdminEmail(email: String?): Boolean {
            if (email.isNullOrBlank()) return false
            val clean = email.trim()
            return clean.equals(ROOT_SUPER_ADMIN_EMAIL, ignoreCase = true) ||
                   clean.equals(LEGACY_SUPER_ADMIN_EMAIL, ignoreCase = true)
        }

        fun parseRole(roleStr: String?, isRootAdmin: Boolean): UserRole =
            if (isRootAdmin) UserRole.SUPER_ADMIN
            else when (roleStr?.lowercase()) {
                "superadmin" -> UserRole.SUPER_ADMIN
                "branchadmin" -> UserRole.BRANCH_ADMIN
                else -> UserRole.MEMBER
            }

        fun parseStatus(statusStr: String?, isRootAdmin: Boolean): ApprovalStatus =
            if (isRootAdmin) ApprovalStatus.APPROVED
            else when (statusStr?.lowercase()) {
                "approved" -> ApprovalStatus.APPROVED
                "rejected" -> ApprovalStatus.REJECTED
                else -> ApprovalStatus.PENDING
            }
    }

    override fun getCurrentUserId(): String? = auth.currentUser?.uid

    override fun isUserLoggedIn(): Boolean = auth.currentUser != null

    override fun getUserProfileFlow(userId: String): Flow<Resource<User>> = callbackFlow {
        trySend(Resource.Loading)
        val docRef = firestore.collection("users").document(userId)

        val registration: ListenerRegistration = docRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to listen to user profile", error))
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                val userEmail = snapshot.getString("email") ?: ""
                val isRootAdmin = isSuperAdminEmail(userEmail)

                val role = parseRole(snapshot.getString("role"), isRootAdmin)
                val status = parseStatus(snapshot.getString("approvalStatus"), isRootAdmin)

                val user = User(
                    id = snapshot.id,
                    email = userEmail,
                    displayName = snapshot.getString("displayName") ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else "",
                    photoUrl = snapshot.getString("photoUrl"),
                    role = role,
                    branchId = snapshot.getString("branchId"),
                    linkedMemberId = snapshot.getString("linkedMemberId"),
                    approvalStatus = status,
                    preferences = UserPreferencesData(
                        language = snapshot.getString("preferences.language") ?: "en",
                        theme = snapshot.getString("preferences.theme") ?: "SYSTEM",
                        biometricLockEnabled = snapshot.getBoolean("preferences.biometricLockEnabled") ?: false
                    )
                )
                trySend(Resource.Success(user))
            } else {
                trySend(Resource.Error("User record not found in database"))
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun signInWithEmail(email: String, password: String): Resource<User> {
        return try {
            val result = auth.signInWithEmailAndPassword(email, password).await()
            val firebaseUser = result.user ?: return Resource.Error("Authentication failed: user is null")
            
            val userEmail = firebaseUser.email ?: email
            val isRootAdmin = isSuperAdminEmail(userEmail)

            val doc = firestore.collection("users").document(firebaseUser.uid).get().await()
            if (doc.exists()) {
                val role = parseRole(doc.getString("role"), isRootAdmin)
                val status = parseStatus(doc.getString("approvalStatus"), isRootAdmin)

                val user = User(
                    id = doc.id,
                    email = doc.getString("email") ?: userEmail,
                    displayName = doc.getString("displayName") ?: (firebaseUser.displayName ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else ""),
                    photoUrl = doc.getString("photoUrl") ?: firebaseUser.photoUrl?.toString(),
                    role = role,
                    branchId = doc.getString("branchId"),
                    linkedMemberId = doc.getString("linkedMemberId"),
                    approvalStatus = status
                )
                Resource.Success(user)
            } else {
                // If user document is missing, create a default user document (approved super admin for root admin)
                val newUser = User(
                    id = firebaseUser.uid,
                    email = userEmail,
                    displayName = firebaseUser.displayName ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else "",
                    photoUrl = firebaseUser.photoUrl?.toString(),
                    role = if (isRootAdmin) UserRole.SUPER_ADMIN else UserRole.MEMBER,
                    approvalStatus = if (isRootAdmin) ApprovalStatus.APPROVED else ApprovalStatus.PENDING
                )
                saveUserDoc(newUser)
                Resource.Success(newUser)
            }
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to sign in", e)
        }
    }

    override suspend fun signUpWithEmail(email: String, password: String): Resource<User> {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val firebaseUser = result.user ?: return Resource.Error("User registration failed")

            val userEmail = firebaseUser.email ?: email
            val isRootAdmin = isSuperAdminEmail(userEmail)

            val newUser = User(
                id = firebaseUser.uid,
                email = userEmail,
                displayName = firebaseUser.displayName ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else "",
                photoUrl = firebaseUser.photoUrl?.toString(),
                role = if (isRootAdmin) UserRole.SUPER_ADMIN else UserRole.MEMBER,
                approvalStatus = if (isRootAdmin) ApprovalStatus.APPROVED else ApprovalStatus.PENDING
            )
            saveUserDoc(newUser)
            Resource.Success(newUser)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to sign up", e)
        }
    }

    override suspend fun signInWithGoogleAccount(
        uid: String,
        email: String,
        displayName: String?,
        photoUrl: String?
    ): Resource<User> {
        return try {
            val isRootAdmin = isSuperAdminEmail(email)
            val doc = firestore.collection("users").document(uid).get().await()

            val user = if (doc.exists()) {
                val role = parseRole(doc.getString("role"), isRootAdmin)
                val status = parseStatus(doc.getString("approvalStatus"), isRootAdmin)
                User(
                    id = uid,
                    email = email,
                    displayName = doc.getString("displayName") ?: (displayName ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else ""),
                    photoUrl = photoUrl ?: doc.getString("photoUrl"),
                    role = role,
                    branchId = doc.getString("branchId"),
                    linkedMemberId = doc.getString("linkedMemberId"),
                    approvalStatus = status
                )
            } else {
                User(
                    id = uid,
                    email = email,
                    displayName = displayName ?: if (isRootAdmin) "মো: ওমর ফারুক (Super Admin)" else "",
                    photoUrl = photoUrl,
                    role = if (isRootAdmin) UserRole.SUPER_ADMIN else UserRole.MEMBER,
                    approvalStatus = if (isRootAdmin) ApprovalStatus.APPROVED else ApprovalStatus.PENDING
                )
            }
            saveUserDoc(user)
            Resource.Success(user)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to sign in with Google", e)
        }
    }

    private suspend fun saveUserDoc(user: User) {
        val userMap = hashMapOf(
            "email" to user.email,
            "displayName" to user.displayName,
            "photoUrl" to user.photoUrl,
            "role" to when (user.role) {
                UserRole.SUPER_ADMIN -> "superAdmin"
                UserRole.BRANCH_ADMIN -> "branchAdmin"
                UserRole.MEMBER -> "member"
            },
            "branchId" to user.branchId,
            "linkedMemberId" to user.linkedMemberId,
            "approvalStatus" to when (user.approvalStatus) {
                ApprovalStatus.APPROVED -> "approved"
                ApprovalStatus.REJECTED -> "rejected"
                ApprovalStatus.PENDING -> "pending"
            },
            "preferences" to mapOf(
                "language" to user.preferences.language,
                "theme" to user.preferences.theme,
                "biometricLockEnabled" to user.preferences.biometricLockEnabled
            ),
            "createdAt" to System.currentTimeMillis()
        )
        firestore.collection("users").document(user.id).set(userMap).await()
    }

    override suspend fun signOut() {
        auth.signOut()
    }

    override suspend fun registerCurrentSession(userId: String, deviceInfo: String): Resource<String> {
        return try {
            val sessionId = UUID.randomUUID().toString()
            val sessionMap = hashMapOf(
                "id" to sessionId,
                "userId" to userId,
                "deviceInfo" to deviceInfo,
                "loginTime" to System.currentTimeMillis(),
                "lastActiveTime" to System.currentTimeMillis(),
                "isActive" to true
            )
            firestore.collection("sessions").document(sessionId).set(sessionMap).await()
            Resource.Success(sessionId)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to register session", e)
        }
    }

    override fun getActiveSessionsFlow(userId: String): Flow<Resource<List<UserSession>>> = callbackFlow {
        trySend(Resource.Loading)
        val query = firestore.collection("sessions")
            .whereEqualTo("userId", userId)
            .whereEqualTo("isActive", true)
        val registration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                trySend(Resource.Error(error.localizedMessage ?: "Failed to load active sessions", error))
                return@addSnapshotListener
            }

            val list = snapshot?.documents?.mapNotNull { doc ->
                UserSession(
                    id = doc.id,
                    userId = doc.getString("userId") ?: "",
                    deviceInfo = doc.getString("deviceInfo") ?: "Android Device",
                    loginTime = doc.getLong("loginTime") ?: System.currentTimeMillis(),
                    lastActiveTime = doc.getLong("lastActiveTime") ?: System.currentTimeMillis(),
                    isActive = doc.getBoolean("isActive") ?: true
                )
            } ?: emptyList()

            trySend(Resource.Success(list))
        }

        awaitClose { registration.remove() }
    }

    override suspend fun deactivateSession(sessionId: String): Resource<Unit> {
        return try {
            firestore.collection("sessions").document(sessionId)
                .update("isActive", false)
                .await()
            Resource.Success(Unit)
        } catch (e: Exception) {
            Resource.Error(e.localizedMessage ?: "Failed to deactivate session", e)
        }
    }

    override fun observeSessionActiveStatus(sessionId: String): Flow<Boolean> = callbackFlow {
        val docRef = firestore.collection("sessions").document(sessionId)
        val registration = docRef.addSnapshotListener { snapshot, _ ->
            val isActive = snapshot?.getBoolean("isActive") ?: true
            trySend(isActive)
        }
        awaitClose { registration.remove() }
    }
}
