package com.dailymemory.data.service

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.dailymemory.R
import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.model.RepeatType
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.LocalDateTime
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        const val CHANNEL_ID_REMINDERS = "dailymemory_reminders"
        const val CHANNEL_NAME_REMINDERS = "Reminders"

        const val EXTRA_REMINDER_ID = "reminder_id"
        const val EXTRA_REMINDER_TITLE = "reminder_title"
        const val EXTRA_REMINDER_BODY = "reminder_body"

        const val ACTION_COMPLETE = "com.dailymemory.ACTION_COMPLETE_REMINDER"
        const val ACTION_SNOOZE = "com.dailymemory.ACTION_SNOOZE_REMINDER"
    }

    private val alarmManager: AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private val notificationManager: NotificationManagerCompat =
        NotificationManagerCompat.from(context)

    init {
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID_REMINDERS,
                CHANNEL_NAME_REMINDERS,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminder notifications"
                enableVibration(true)
                enableLights(true)
            }

            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    /**
     * Check if notification permission is granted
     */
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    /**
     * Check if exact alarm permission is granted (Android 12+)
     */
    fun hasExactAlarmPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    /**
     * Schedule a reminder notification
     */
    fun scheduleReminder(reminder: Reminder) {
        if (!reminder.isActive) return

        val triggerTime = reminder.scheduledAt
            .atZone(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()

        // Don't schedule if time has passed
        if (triggerTime < System.currentTimeMillis()) {
            return
        }

        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra(EXTRA_REMINDER_ID, reminder.id)
            putExtra(EXTRA_REMINDER_TITLE, reminder.title)
            putExtra(EXTRA_REMINDER_BODY, reminder.body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            reminder.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                // Fall back to inexact alarm
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            // Fall back to inexact alarm
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }
    }

    /**
     * Cancel a scheduled reminder
     */
    fun cancelReminder(reminderId: String) {
        val intent = Intent(context, ReminderReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            reminderId.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }

    /**
     * Reschedule reminder for next occurrence based on repeat type
     */
    fun rescheduleRepeatingReminder(reminder: Reminder): Reminder? {
        if (reminder.repeatType == RepeatType.NONE) return null

        val nextScheduledAt = when (reminder.repeatType) {
            RepeatType.DAILY -> reminder.scheduledAt.plusDays(1)
            RepeatType.WEEKLY -> reminder.scheduledAt.plusWeeks(1)
            RepeatType.MONTHLY -> reminder.scheduledAt.plusMonths(1)
            RepeatType.YEARLY -> reminder.scheduledAt.plusYears(1)
            RepeatType.NONE -> return null
        }

        val updatedReminder = reminder.copy(
            scheduledAt = nextScheduledAt,
            triggeredAt = null
        )

        scheduleReminder(updatedReminder)
        return updatedReminder
    }

    /**
     * Show a notification immediately
     */
    fun showNotification(
        id: Int,
        title: String,
        body: String,
        reminderId: String? = null
    ) {
        if (!hasNotificationPermission()) return

        // Create intent for notification tap
        val tapIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                reminderId?.let { putExtra(EXTRA_REMINDER_ID, it) }
            }

        val tapPendingIntent = tapIntent?.let {
            PendingIntent.getActivity(
                context,
                id,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID_REMINDERS)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(tapPendingIntent)

        // Add actions if reminder ID is provided
        if (reminderId != null) {
            // Complete action
            val completeIntent = Intent(context, ReminderActionReceiver::class.java).apply {
                action = ACTION_COMPLETE
                putExtra(EXTRA_REMINDER_ID, reminderId)
            }
            val completePendingIntent = PendingIntent.getBroadcast(
                context,
                "$reminderId-complete".hashCode(),
                completeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, "Done", completePendingIntent)

            // Snooze action
            val snoozeIntent = Intent(context, ReminderActionReceiver::class.java).apply {
                action = ACTION_SNOOZE
                putExtra(EXTRA_REMINDER_ID, reminderId)
            }
            val snoozePendingIntent = PendingIntent.getBroadcast(
                context,
                "$reminderId-snooze".hashCode(),
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, "Snooze", snoozePendingIntent)
        }

        try {
            notificationManager.notify(id, builder.build())
        } catch (e: SecurityException) {
            // Permission not granted
        }
    }

    /**
     * Cancel a notification
     */
    fun cancelNotification(id: Int) {
        notificationManager.cancel(id)
    }
}

/**
 * Receiver for scheduled reminder alarms
 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reminderId = intent.getStringExtra(NotificationService.EXTRA_REMINDER_ID) ?: return
        val title = intent.getStringExtra(NotificationService.EXTRA_REMINDER_TITLE) ?: "Reminder"
        val body = intent.getStringExtra(NotificationService.EXTRA_REMINDER_BODY) ?: ""

        val notificationService = NotificationService(context)
        notificationService.showNotification(
            id = reminderId.hashCode(),
            title = title,
            body = body,
            reminderId = reminderId
        )
    }
}

/**
 * Receiver for notification actions (complete, snooze)
 */
class ReminderActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reminderId = intent.getStringExtra(NotificationService.EXTRA_REMINDER_ID) ?: return

        when (intent.action) {
            NotificationService.ACTION_COMPLETE -> {
                // Cancel the notification
                NotificationManagerCompat.from(context).cancel(reminderId.hashCode())
                // TODO: Mark reminder as completed via use case
            }
            NotificationService.ACTION_SNOOZE -> {
                // Cancel the notification
                NotificationManagerCompat.from(context).cancel(reminderId.hashCode())
                // TODO: Snooze reminder via use case (reschedule for 15 minutes later)
            }
        }
    }
}

/**
 * Receiver for device boot to reschedule reminders
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // TODO: Reschedule all active reminders from database
        }
    }
}
