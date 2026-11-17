package com.helptrickbd.myapplicationsomithierp.domain.model

enum class MemberStatus {
    ACTIVE,
    LEFT
}

data class EmergencyContact(
    val name: String = "",
    val relation: String = "",
    val phone: String = ""
)

data class Member(
    val id: String = "",
    // Section 1: Personal
    val name: String = "",
    val nameEn: String = "",
    val fatherName: String = "",
    val dateOfBirth: String = "",
    val occupation: String = "",
    val memberType: String = "",   // স্বেচ্ছাসেবী / ব্যবসায়ী / শিক্ষার্থী etc.
    // Section 2: Contact
    val phone: String = "",
    val whatsappNumber: String = "",
    val village: String = "",
    val upazila: String = "",
    val district: String = "",
    val address: String = "",      // kept for backwards compat
    // Section 3: Documents & Photos
    val photoUrl: String? = null,
    val nid: String = "",
    val nidPhotoUrl: String? = null,
    // Section 4: Emergency
    val emergencyContact: EmergencyContact = EmergencyContact(),
    // Admin-extensible custom fields per section
    val customFieldsPersonal: Map<String, String> = emptyMap(),
    val customFieldsContact: Map<String, String> = emptyMap(),
    val customFieldsDocs: Map<String, String> = emptyMap(),
    val customFieldsEmergency: Map<String, String> = emptyMap(),
    // Legacy custom fields (kept for backward compat)
    val customFields: Map<String, String> = emptyMap(),
    // Membership
    val branchId: String = "",
    val joinDate: Long = System.currentTimeMillis(),
    val status: MemberStatus = MemberStatus.ACTIVE,
    val exitDate: Long? = null,
    val linkedUserId: String? = null,
    // Transient / calculated fields for UI
    val totalContributed: Double = 0.0,
    val outstandingDues: Double = 0.0
)
