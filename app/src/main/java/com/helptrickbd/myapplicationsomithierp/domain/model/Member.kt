package com.helptrickbd.myapplicationsomithierp.domain.model

enum class MemberStatus {
    ACTIVE,
    LEFT
}

data class EmergencyContact(
    val name: String = "",
    val phone: String = ""
)

data class Member(
    val id: String = "",
    val name: String = "",
    val phone: String = "",
    val address: String = "",
    val photoUrl: String? = null,
    val nid: String = "",
    val nidPhotoUrl: String? = null,
    val emergencyContact: EmergencyContact = EmergencyContact(),
    val branchId: String = "",
    val joinDate: Long = System.currentTimeMillis(),
    val status: MemberStatus = MemberStatus.ACTIVE,
    val exitDate: Long? = null,
    val customFields: Map<String, String> = emptyMap(),
    val linkedUserId: String? = null,
    // Transient / calculated fields for UI
    val totalContributed: Double = 0.0,
    val outstandingDues: Double = 0.0,
    val activeLoanBalance: Double = 0.0
)
