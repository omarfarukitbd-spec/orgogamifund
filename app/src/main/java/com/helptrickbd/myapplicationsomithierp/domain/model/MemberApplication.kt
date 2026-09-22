package com.helptrickbd.myapplicationsomithierp.domain.model

data class MemberApplication(
    val id: String = "",
    val applicantName: String = "",
    val phone: String = "",
    val email: String = "",
    val fatherOrHusbandName: String = "",
    val occupation: String = "",
    val bloodGroup: String = "B+",
    val dob: String = "",
    val presentAddress: String = "",
    val permanentAddress: String = "",
    val nidNumber: String = "",
    val hasNidDocument: Boolean = true,
    val hasPhotoDocument: Boolean = true,
    val nomineeName: String = "",
    val nomineeRelation: String = "",
    val nomineePhone: String = "",
    val nomineeNid: String = "",
    val targetShomitiId: String = "branch-1",
    val targetShomitiName: String = "অগ্রগামী ফান্ড - মূল শাখা",
    val shareCount: Int = 1,
    val monthlyDepositCommitment: Double = 1000.0,
    val status: ApprovalStatus = ApprovalStatus.PENDING,
    val appliedAt: Long = System.currentTimeMillis(),
    val reviewedAt: Long? = null,
    val reviewerNote: String? = null
)
