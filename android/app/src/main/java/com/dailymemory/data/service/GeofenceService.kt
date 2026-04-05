package com.dailymemory.data.service

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.dailymemory.domain.model.LocationTriggerType
import com.dailymemory.domain.model.Reminder
import com.dailymemory.domain.model.RepeatType
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume

/**
 * Service for managing location-based reminders using Google Geofencing API
 */
@Singleton
class GeofenceService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val notificationService: NotificationService
) {
    companion object {
        private const val TAG = "GeofenceService"
        private const val GEOFENCE_REQUEST_CODE = 1001
        private const val MAX_GEOFENCES = 100 // Google limit

        const val EXTRA_REMINDER_ID = "geofence_reminder_id"
        const val EXTRA_IS_ENTRY = "geofence_is_entry"

        const val ACTION_GEOFENCE_EVENT = "com.dailymemory.ACTION_GEOFENCE_EVENT"
    }

    private val geofencingClient: GeofencingClient =
        LocationServices.getGeofencingClient(context)

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private val _isMonitoring = MutableStateFlow(false)
    val isMonitoring: StateFlow<Boolean> = _isMonitoring.asStateFlow()

    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> = _currentLocation.asStateFlow()

    private val _monitoredReminders = MutableStateFlow<Set<String>>(emptySet())
    val monitoredReminders: StateFlow<Set<String>> = _monitoredReminders.asStateFlow()

    // MARK: - Authorization

    /**
     * Check if we have location permission
     */
    fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Check if we have background location permission (required for geofencing)
     */
    fun hasBackgroundLocationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            hasLocationPermission()
        }
    }

    /**
     * Check if we have sufficient permissions for geofencing
     */
    fun hasGeofencePermission(): Boolean {
        return hasLocationPermission() && hasBackgroundLocationPermission()
    }

    // MARK: - Current Location

    /**
     * Request current location
     */
    @SuppressLint("MissingPermission")
    suspend fun requestCurrentLocation(): Location? {
        if (!hasLocationPermission()) {
            Log.w(TAG, "Location permission not granted")
            return null
        }

        return suspendCancellableCoroutine { continuation ->
            val cancellationToken = CancellationTokenSource()

            fusedLocationClient.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                cancellationToken.token
            ).addOnSuccessListener { location ->
                _currentLocation.value = location
                continuation.resume(location)
            }.addOnFailureListener { exception ->
                Log.e(TAG, "Failed to get location: ${exception.message}")
                continuation.resume(null)
            }

            continuation.invokeOnCancellation {
                cancellationToken.cancel()
            }
        }
    }

    // MARK: - Geofence Management

    /**
     * Start monitoring a location-based reminder
     */
    @SuppressLint("MissingPermission")
    fun startMonitoring(reminder: Reminder, onResult: (Boolean) -> Unit = {}) {
        if (!hasGeofencePermission()) {
            Log.w(TAG, "Geofence permission not granted")
            onResult(false)
            return
        }

        if (!reminder.isLocationBased) {
            Log.w(TAG, "Reminder ${reminder.id} is not location-based")
            onResult(false)
            return
        }

        val latitude = reminder.latitude ?: return
        val longitude = reminder.longitude ?: return
        val triggerType = reminder.locationTriggerType ?: return
        val radius = reminder.radius ?: 100.0

        // Check max geofences limit
        if (_monitoredReminders.value.size >= MAX_GEOFENCES) {
            Log.w(TAG, "Maximum geofences reached ($MAX_GEOFENCES)")
            onResult(false)
            return
        }

        // Create geofence
        val transitionTypes = when (triggerType) {
            LocationTriggerType.ENTER -> Geofence.GEOFENCE_TRANSITION_ENTER
            LocationTriggerType.EXIT -> Geofence.GEOFENCE_TRANSITION_EXIT
            LocationTriggerType.BOTH -> Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT
        }

        val geofence = Geofence.Builder()
            .setRequestId("reminder_${reminder.id}")
            .setCircularRegion(latitude, longitude, radius.toFloat())
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(transitionTypes)
            .build()

        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        geofencingClient.addGeofences(geofencingRequest, getGeofencePendingIntent())
            .addOnSuccessListener {
                Log.d(TAG, "Started monitoring geofence for reminder ${reminder.id}")
                _monitoredReminders.value = _monitoredReminders.value + reminder.id
                _isMonitoring.value = _monitoredReminders.value.isNotEmpty()
                onResult(true)
            }
            .addOnFailureListener { exception ->
                Log.e(TAG, "Failed to add geofence: ${exception.message}")
                onResult(false)
            }
    }

    /**
     * Stop monitoring a reminder
     */
    fun stopMonitoring(reminder: Reminder) {
        stopMonitoring(reminder.id)
    }

    /**
     * Stop monitoring a reminder by ID
     */
    fun stopMonitoring(reminderId: String) {
        val requestId = "reminder_$reminderId"

        geofencingClient.removeGeofences(listOf(requestId))
            .addOnSuccessListener {
                Log.d(TAG, "Stopped monitoring geofence for reminder $reminderId")
                _monitoredReminders.value = _monitoredReminders.value - reminderId
                _isMonitoring.value = _monitoredReminders.value.isNotEmpty()
            }
            .addOnFailureListener { exception ->
                Log.e(TAG, "Failed to remove geofence: ${exception.message}")
            }
    }

    /**
     * Stop monitoring all geofences
     */
    fun stopAllMonitoring() {
        geofencingClient.removeGeofences(getGeofencePendingIntent())
            .addOnSuccessListener {
                Log.d(TAG, "Stopped monitoring all geofences")
                _monitoredReminders.value = emptySet()
                _isMonitoring.value = false
            }
            .addOnFailureListener { exception ->
                Log.e(TAG, "Failed to remove all geofences: ${exception.message}")
            }
    }

    /**
     * Check if a reminder is being monitored
     */
    fun isMonitoring(reminderId: String): Boolean {
        return _monitoredReminders.value.contains(reminderId)
    }

    /**
     * Get list of monitored reminder IDs
     */
    fun getMonitoredReminderIds(): List<String> {
        return _monitoredReminders.value.toList()
    }

    private fun getGeofencePendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = ACTION_GEOFENCE_EVENT
        }

        return PendingIntent.getBroadcast(
            context,
            GEOFENCE_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    // MARK: - Geofence Event Handling

    /**
     * Handle geofence transition event
     */
    internal fun handleGeofenceEvent(geofencingEvent: GeofencingEvent?) {
        if (geofencingEvent == null) {
            Log.e(TAG, "Geofencing event is null")
            return
        }

        if (geofencingEvent.hasError()) {
            Log.e(TAG, "Geofencing error: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition
        val isEntry = geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER

        val triggeringGeofences = geofencingEvent.triggeringGeofences
        if (triggeringGeofences == null) {
            Log.w(TAG, "No triggering geofences")
            return
        }

        for (geofence in triggeringGeofences) {
            val requestId = geofence.requestId
            val reminderId = extractReminderId(requestId)

            if (reminderId != null) {
                Log.d(TAG, "Geofence ${if (isEntry) "ENTER" else "EXIT"} for reminder $reminderId")
                showGeofenceNotification(reminderId, isEntry)
            }
        }
    }

    private fun extractReminderId(requestId: String): String? {
        return if (requestId.startsWith("reminder_")) {
            requestId.removePrefix("reminder_")
        } else {
            null
        }
    }

    private fun showGeofenceNotification(reminderId: String, isEntry: Boolean) {
        // In a real app, we'd load the reminder from the repository
        // For now, we show a generic notification
        val title = "Location Reminder"
        val locationAction = if (isEntry) "arrived at" else "left"
        val body = "You $locationAction a location with an active reminder"

        notificationService.showNotification(
            id = "location_${reminderId}_${if (isEntry) "entry" else "exit"}".hashCode(),
            title = title,
            body = body,
            reminderId = reminderId
        )
    }

    // MARK: - Utilities

    /**
     * Calculate distance between two points
     */
    fun distanceTo(latitude: Double, longitude: Double): Float? {
        val current = _currentLocation.value ?: return null
        val results = FloatArray(1)
        Location.distanceBetween(
            current.latitude,
            current.longitude,
            latitude,
            longitude,
            results
        )
        return results[0]
    }

    /**
     * Format distance for display
     */
    fun formatDistance(meters: Float): String {
        return if (meters < 1000) {
            "${meters.toInt()}m"
        } else {
            String.format("%.1fkm", meters / 1000)
        }
    }
}

/**
 * BroadcastReceiver for geofence events
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != GeofenceService.ACTION_GEOFENCE_EVENT) {
            return
        }

        val geofencingEvent = GeofencingEvent.fromIntent(intent)

        // We need to get the service instance
        // In a real app, this would be done via Hilt or a service locator
        // For now, we'll use a simple notification
        handleGeofenceTransition(context, geofencingEvent)
    }

    private fun handleGeofenceTransition(context: Context, geofencingEvent: GeofencingEvent?) {
        if (geofencingEvent == null) {
            Log.e("GeofenceBroadcastReceiver", "Geofencing event is null")
            return
        }

        if (geofencingEvent.hasError()) {
            Log.e("GeofenceBroadcastReceiver", "Geofencing error: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition
        val isEntry = geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER

        val triggeringGeofences = geofencingEvent.triggeringGeofences
        if (triggeringGeofences == null) {
            Log.w("GeofenceBroadcastReceiver", "No triggering geofences")
            return
        }

        for (geofence in triggeringGeofences) {
            val requestId = geofence.requestId
            val reminderId = if (requestId.startsWith("reminder_")) {
                requestId.removePrefix("reminder_")
            } else {
                continue
            }

            Log.d("GeofenceBroadcastReceiver", "Geofence ${if (isEntry) "ENTER" else "EXIT"} for reminder $reminderId")

            // Show notification
            val notificationService = NotificationService(context)
            val title = "Location Reminder"
            val locationAction = if (isEntry) "arrived at" else "left"
            val body = "You $locationAction a location with an active reminder"

            notificationService.showNotification(
                id = "location_${reminderId}_${if (isEntry) "entry" else "exit"}".hashCode(),
                title = title,
                body = body,
                reminderId = reminderId
            )
        }
    }
}
