package com.helptrickbd.myapplicationsomithierp.core.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.helptrickbd.myapplicationsomithierp.MainActivity
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.domain.model.NotificationType

object NotificationHelper {

    const val CHANNEL_ID_PAYMENTS = "channel_payments"
    const val CHANNEL_ID_REMINDERS = "channel_reminders"
    const val CHANNEL_ID_NOTICES = "channel_notices"
    const val CHANNEL_ID_GENERAL = "channel_general"

    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val paymentChannel = NotificationChannel(
                CHANNEL_ID_PAYMENTS,
                "চাঁদা ও লেনদেন (Payments)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "টাকা জমা ও মানি রসিদ সংক্রান্ত নোটিফিকেশন"
                enableVibration(true)
            }

            val reminderChannel = NotificationChannel(
                CHANNEL_ID_REMINDERS,
                "বকেয়া ও কিস্তি তাগাদা (Reminders)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "মাসিক চাঁদা ও ঋণের কিস্তির প্রাক-স্মারক বার্তা"
                enableVibration(true)
            }

            val noticeChannel = NotificationChannel(
                CHANNEL_ID_NOTICES,
                "নোটিশ ও জরুরি সভা (Notices & AGM)",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "সমিতির জরুরি ঘোষণা ও নোটিশ বোর্ডের আপডেট"
            }

            val generalChannel = NotificationChannel(
                CHANNEL_ID_GENERAL,
                "সাধারণ নোটিফিকেশন (General)",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "অ্যাপের অন্যান্য সিস্টেম বার্তা"
            }

            notificationManager.createNotificationChannels(
                listOf(paymentChannel, reminderChannel, noticeChannel, generalChannel)
            )
        }
    }

    fun showSystemNotification(
        context: Context,
        title: String,
        message: String,
        type: NotificationType = NotificationType.SYSTEM_ALERT,
        targetRoute: String? = null,
        notificationId: Int = System.currentTimeMillis().toInt()
    ) {
        createNotificationChannels(context)

        // Permission check on Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
        }

        val channelId = when (type) {
            NotificationType.PAYMENT_RECEIVED -> CHANNEL_ID_PAYMENTS
            NotificationType.DUE_REMINDER, NotificationType.DEFAULTER_ALERT, NotificationType.LOAN_REMINDER -> CHANNEL_ID_REMINDERS
            NotificationType.NEW_NOTICE -> CHANNEL_ID_NOTICES
            else -> CHANNEL_ID_GENERAL
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            targetRoute?.let { putExtra("EXTRA_NAV_ROUTE", it) }
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        try {
            NotificationManagerCompat.from(context).notify(notificationId, builder.build())
        } catch (_: SecurityException) {
            // Ignored if permission was revoked
        }
    }
}
