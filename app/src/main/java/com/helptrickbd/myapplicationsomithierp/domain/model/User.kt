package com.helptrickbd.myapplicationsomithierp.domain.model

enum class UserRole {
    SUPER_ADMIN,
    BRANCH_ADMIN,
    MEMBER
}

enum class ApprovalStatus {
    PENDING,
    APPROVED,
    REJECTED
}

data class UserPreferencesData(
    val language: String = "en",
    val theme: String = "SYSTEM",
    val notificationMutes: List<String> = emptyList(),
    val biometricLockEnabled: Boolean = false
)

data class User(
    val id: String = "",
    val email: String = "",
    val displayName: String = "",
    val photoUrl: String? = null,
    val role: UserRole = UserRole.MEMBER,
    val branchId: String? = null,
    val linkedMemberId: String? = null,
    val approvalStatus: ApprovalStatus = ApprovalStatus.PENDING,
    val preferences: UserPreferencesData = UserPreferencesData()
)
