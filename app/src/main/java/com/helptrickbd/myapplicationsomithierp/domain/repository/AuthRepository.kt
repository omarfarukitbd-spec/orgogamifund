package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.User
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import kotlinx.coroutines.flow.Flow

data class UserSession(
    val id: String = "",
    val userId: String = "",
    val deviceInfo: String = "",
    val loginTime: Long = System.currentTimeMillis(),
    val lastActiveTime: Long = System.currentTimeMillis(),
    val isActive: Boolean = true
)

interface AuthRepository {
    fun getCurrentUserId(): String?
    fun isUserLoggedIn(): Boolean
    fun getUserProfileFlow(userId: String): Flow<Resource<User>>
    suspend fun signInWithEmail(email: String, password: String): Resource<User>
    suspend fun signUpWithEmail(email: String, password: String): Resource<User>
    suspend fun signInWithGoogleAccount(uid: String, email: String, displayName: String?, photoUrl: String?): Resource<User>
    suspend fun signOut()
    
    // Session & Device Management (§6.16)
    suspend fun registerCurrentSession(userId: String, deviceInfo: String): Resource<String>
    fun getActiveSessionsFlow(userId: String): Flow<Resource<List<UserSession>>>
    suspend fun deactivateSession(sessionId: String): Resource<Unit>
    fun observeSessionActiveStatus(sessionId: String): Flow<Boolean>
}
