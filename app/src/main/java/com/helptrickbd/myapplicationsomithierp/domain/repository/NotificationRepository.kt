package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import kotlinx.coroutines.flow.Flow

interface NotificationRepository {
    fun getNotifications(): Flow<List<NotificationItem>>
    fun getUnreadCount(): Flow<Int>
    suspend fun addNotification(notification: NotificationItem)
    suspend fun markAsRead(id: String)
    suspend fun markAllAsRead()
    suspend fun deleteNotification(id: String)
    suspend fun clearAll()
}
