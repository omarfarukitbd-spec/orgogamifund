package com.helptrickbd.myapplicationsomithierp.core.notification

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.helptrickbd.myapplicationsomithierp.data.repository.NotificationRepositoryImpl
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationItem
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.UUID

class ShomitiFirebaseMessagingService : FirebaseMessagingService() {

    private val serviceScope = CoroutineScope(Dispatchers.IO)

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM Device Token received: $token")
        // In production, sync this token to Firestore under users/{userId}/fcmTokens
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "FCM Message received from: ${remoteMessage.from}")

        val title = remoteMessage.notification?.title
            ?: remoteMessage.data["title"]
            ?: "সমিতি ম্যানেজার নোটিফিকেশন"

        val message = remoteMessage.notification?.body
            ?: remoteMessage.data["message"]
            ?: remoteMessage.data["body"]
            ?: "আপনার একটি নতুন আপডেট রয়েছে।"

        val typeStr = remoteMessage.data["type"]
        val notificationType = try {
            if (typeStr != null) NotificationType.valueOf(typeStr) else NotificationType.SYSTEM_ALERT
        } catch (_: Exception) {
            NotificationType.SYSTEM_ALERT
        }

        val targetRoute = remoteMessage.data["target_route"]
        val entityId = remoteMessage.data["entity_id"]

        // 1. Show system notification in Android status bar
        NotificationHelper.showSystemNotification(
            context = applicationContext,
            title = title,
            message = message,
            type = notificationType,
            targetRoute = targetRoute
        )

        // 2. Add to in-app Notification Center history
        serviceScope.launch {
            val item = NotificationItem(
                id = UUID.randomUUID().toString(),
                title = title,
                message = message,
                timestamp = System.currentTimeMillis(),
                type = notificationType,
                isRead = false,
                targetRoute = targetRoute,
                relatedEntityId = entityId
            )
            NotificationRepositoryImpl.instance.addNotification(item)
        }
    }

    companion object {
        private const val TAG = "ShomitiFCM"
    }
}
