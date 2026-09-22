package com.helptrickbd.myapplicationsomithierp.data.repository

import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import com.helptrickbd.myapplicationsomithierp.domain.repository.NotificationRepository
import com.helptrickbd.myapplicationsomithierp.presentation.navigation.Screen
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map

class NotificationRepositoryImpl : NotificationRepository {

    private val _notifications = MutableStateFlow<List<NotificationItem>>(
        listOf(
            NotificationItem(
                id = "notif-1",
                title = "টাকা জমার নিশ্চিতকরণ",
                message = "মোহাম্মদ আব্দুল করিম-এর ফেব্রুয়ারি ২০২৬ মাসের চাঁদা ৳ ২,০০০ সফলভাবে জমা হয়েছে। রসিদ নম্বর: RCP-202602-1082।",
                timestamp = System.currentTimeMillis() - (1000 * 60 * 25), // 25 mins ago
                type = NotificationType.PAYMENT_RECEIVED,
                isRead = false,
                targetRoute = Screen.Contributions.route
            ),
            NotificationItem(
                id = "notif-2",
                title = "মাসিক চাঁদা পরিশোধের তাগাদা",
                message = "আগামী ১০ তারিখের মধ্যে চলতি মাসের কিস্তি/চাঁদা পরিশোধ করতে অনুরোধ করা যাচ্ছে।",
                timestamp = System.currentTimeMillis() - (1000 * 60 * 60 * 3), // 3 hours ago
                type = NotificationType.DUE_REMINDER,
                isRead = false,
                targetRoute = Screen.Defaulters.route
            ),
            NotificationItem(
                id = "notif-3",
                title = "বার্ষিক সাধারণ সভা (AGM ২০২৬)",
                message = "কার্যনির্বাহী কমিটির সিদ্ধান্ত অনুযায়ী আগামী ১৫ মার্চ প্রধান কার্যালয়ে সাধারণ সভা অনুষ্ঠিত হবে।",
                timestamp = System.currentTimeMillis() - (1000 * 60 * 60 * 24), // 1 day ago
                type = NotificationType.NEW_NOTICE,
                isRead = true,
                targetRoute = Screen.Notices.route
            ),
            NotificationItem(
                id = "notif-4",
                title = "ঋণ বিতরণ ও কিস্তি অনুমোদন",
                message = "আপনার আবেদনের প্রেক্ষিতে সদস্য ঋণ নং LN-004 অনুমোদিত হয়েছে। বিস্তারিত লেজারে দেখুন।",
                timestamp = System.currentTimeMillis() - (1000 * 60 * 60 * 48), // 2 days ago
                type = NotificationType.LOAN_REMINDER,
                isRead = true,
                targetRoute = Screen.Loans.route
            )
        )
    )

    override fun getNotifications(): Flow<List<NotificationItem>> = _notifications.asStateFlow()

    override fun getUnreadCount(): Flow<Int> = _notifications.map { list ->
        list.count { !it.isRead }
    }

    override suspend fun addNotification(notification: NotificationItem) {
        val current = _notifications.value.toMutableList()
        current.add(0, notification)
        _notifications.value = current
    }

    override suspend fun markAsRead(id: String) {
        _notifications.value = _notifications.value.map {
            if (it.id == id) it.copy(isRead = true) else it
        }
    }

    override suspend fun markAllAsRead() {
        _notifications.value = _notifications.value.map { it.copy(isRead = true) }
    }

    override suspend fun deleteNotification(id: String) {
        _notifications.value = _notifications.value.filter { it.id != id }
    }

    override suspend fun clearAll() {
        _notifications.value = emptyList()
    }

    companion object {
        val instance by lazy { NotificationRepositoryImpl() }
    }
}
