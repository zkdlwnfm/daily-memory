import Foundation
import CoreLocation
import UserNotifications

/// Service for managing location-based reminders using geofencing
final class GeofenceService: NSObject, ObservableObject {
    static let shared = GeofenceService()

    private let locationManager = CLLocationManager()
    private let notificationService = NotificationService.shared

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isMonitoring: Bool = false
    @Published var monitoredRegions: [CLCircularRegion] = []

    // Maximum regions that can be monitored (iOS limit is 20)
    private let maxRegions = 20

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    /// Request location authorization for geofencing
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Request always authorization (required for background geofencing)
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Check if we have sufficient authorization for geofencing
    var hasGeofenceAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }

    /// Check if location services are enabled
    var isLocationEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    // MARK: - Current Location

    /// Request current location
    func requestCurrentLocation() {
        locationManager.requestLocation()
    }

    /// Start continuous location updates
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    /// Stop continuous location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Geofence Management

    /// Start monitoring a location-based reminder
    func startMonitoring(reminder: Reminder) -> Bool {
        guard hasGeofenceAuthorization else {
            print("GeofenceService: Not authorized for geofencing")
            return false
        }

        guard let latitude = reminder.latitude,
              let longitude = reminder.longitude,
              let triggerType = reminder.locationTriggerType else {
            print("GeofenceService: Reminder has no location data")
            return false
        }

        // Check if we've hit the region limit
        if locationManager.monitoredRegions.count >= maxRegions {
            print("GeofenceService: Maximum regions reached (\(maxRegions))")
            return false
        }

        let radius = reminder.radius ?? 100.0 // Default 100 meters
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        // Create a unique identifier for this region
        let identifier = "reminder_\(reminder.id)"

        // Remove existing region with same identifier if any
        if let existingRegion = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: existingRegion)
        }

        // Create the region
        let region = CLCircularRegion(
            center: center,
            radius: min(radius, locationManager.maximumRegionMonitoringDistance),
            identifier: identifier
        )

        // Set notification triggers based on type
        switch triggerType {
        case .enter:
            region.notifyOnEntry = true
            region.notifyOnExit = false
        case .exit:
            region.notifyOnEntry = false
            region.notifyOnExit = true
        case .both:
            region.notifyOnEntry = true
            region.notifyOnExit = true
        }

        // Start monitoring
        locationManager.startMonitoring(for: region)
        isMonitoring = true
        updateMonitoredRegions()

        print("GeofenceService: Started monitoring region \(identifier)")
        return true
    }

    /// Stop monitoring a reminder
    func stopMonitoring(reminder: Reminder) {
        let identifier = "reminder_\(reminder.id)"

        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: region)
            updateMonitoredRegions()
            print("GeofenceService: Stopped monitoring region \(identifier)")
        }
    }

    /// Stop monitoring a region by ID
    func stopMonitoring(reminderId: String) {
        let identifier = "reminder_\(reminderId)"

        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: region)
            updateMonitoredRegions()
        }
    }

    /// Stop monitoring all regions
    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoring = false
        updateMonitoredRegions()
    }

    /// Get list of currently monitored reminder IDs
    func getMonitoredReminderIds() -> [String] {
        return locationManager.monitoredRegions.compactMap { region in
            if region.identifier.hasPrefix("reminder_") {
                return String(region.identifier.dropFirst("reminder_".count))
            }
            return nil
        }
    }

    /// Check if a reminder is being monitored
    func isMonitoring(reminderId: String) -> Bool {
        let identifier = "reminder_\(reminderId)"
        return locationManager.monitoredRegions.contains { $0.identifier == identifier }
    }

    private func updateMonitoredRegions() {
        monitoredRegions = locationManager.monitoredRegions.compactMap { $0 as? CLCircularRegion }
        isMonitoring = !monitoredRegions.isEmpty
    }

    // MARK: - Geofence Event Handling

    private func handleRegionEntry(region: CLRegion) {
        guard let reminderId = extractReminderId(from: region.identifier) else { return }

        // Load the reminder and show notification
        Task {
            await showLocationNotification(reminderId: reminderId, isEntry: true)
        }
    }

    private func handleRegionExit(region: CLRegion) {
        guard let reminderId = extractReminderId(from: region.identifier) else { return }

        Task {
            await showLocationNotification(reminderId: reminderId, isEntry: false)
        }
    }

    private func extractReminderId(from identifier: String) -> String? {
        if identifier.hasPrefix("reminder_") {
            return String(identifier.dropFirst("reminder_".count))
        }
        return nil
    }

    private func showLocationNotification(reminderId: String, isEntry: Bool) async {
        // Load reminder from repository
        let reminderRepository = DIContainer.shared.reminderRepository

        do {
            if let reminder = try await reminderRepository.getById(reminderId) {
                let locationAction = isEntry ? "arrived at" : "left"
                let locationName = reminder.locationName ?? "the location"

                // Schedule an immediate notification using the reminder system
                var notifReminder = reminder
                notifReminder.scheduledAt = Date()
                await notificationService.scheduleReminder(notifReminder)

                // If this is a one-time reminder, mark it as triggered
                if reminder.repeatType == .none {
                    var updatedReminder = reminder
                    updatedReminder.triggeredAt = Date()
                    try await reminderRepository.update(updatedReminder)

                    // Stop monitoring this region
                    stopMonitoring(reminderId: reminderId)
                }
            }
        } catch {
            print("GeofenceService: Error handling geofence event: \(error)")
        }
    }

    // MARK: - Utilities

    /// Calculate distance from current location to a point
    func distanceTo(latitude: Double, longitude: Double) -> Double? {
        guard let currentLocation = currentLocation else { return nil }

        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        return currentLocation.distance(from: targetLocation)
    }

    /// Format distance for display
    func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways {
            // Restore any pending geofences
            updateMonitoredRegions()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GeofenceService: Location error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("GeofenceService: Entered region \(region.identifier)")
        handleRegionEntry(region: region)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("GeofenceService: Exited region \(region.identifier)")
        handleRegionExit(region: region)
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("GeofenceService: Started monitoring \(region.identifier)")
        updateMonitoredRegions()
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("GeofenceService: Monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
}
