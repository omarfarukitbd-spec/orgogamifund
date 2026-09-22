package com.helptrickbd.myapplicationsomithierp.domain.model

enum class NotificationType {
    PAYMENT_RECEIVED,
    DUE_REMINDER,
    DEFAULTER_ALERT,
    NEW_NOTICE,
    LOAN_REMINDER,
    EDIT_REQUEST_STATUS,
    DIVIDEND_PAYOUT,
    SYSTEM_ALERT
}

data class NotificationItem(
    val id: String,
    val title: String,
    val message: String,
    val timestamp: Long = System.currentTimeMillis(),
    val type: NotificationType = NotificationType.SYSTEM_ALERT,
    val isRead: Boolean = false,
    val targetRoute: String? = null,
    val relatedEntityId: String? = null
)
