import SwiftUI
import MapKit
import CoreLocation

@available(iOS 17.0, *)
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationPickerViewModel()

    let onSelect: (SelectedLocation) -> Void
    var initialLocation: SelectedLocation?

    init(initialLocation: SelectedLocation? = nil, onSelect: @escaping (SelectedLocation) -> Void) {
        self.initialLocation = initialLocation
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map View
                Map(position: $viewModel.cameraPosition, interactionModes: .all) {
                    // Selected location marker
                    if let selected = viewModel.selectedLocation {
                        Annotation("", coordinate: selected.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                    }

                    // Current location
                    if let userLocation = viewModel.userLocation {
                        Annotation("", coordinate: userLocation) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                    }
                }
                .mapStyle(.standard)
                .onTapGesture { location in
                    viewModel.handleMapTap(at: location)
                }
                .ignoresSafeArea(.keyboard)

                // Center crosshair
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.7))

                // Bottom Panel
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search for a place...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                Task {
                                    await viewModel.search()
                                }
                            }

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                                viewModel.searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Search Results
                    if !viewModel.searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.searchResults) { result in
                                    SearchResultRow(result: result) {
                                        viewModel.selectSearchResult(result)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Selected Location Info
                    if let selected = viewModel.selectedLocation {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)

                                VStack(alignment: .leading) {
                                    Text(selected.name)
                                        .font(.headline)

                                    if let address = selected.address {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }

                                Spacer()
                            }

                            // Radius Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Radius")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(viewModel.radius))m")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Slider(value: $viewModel.radius, in: 50...500, step: 10)
                            }

                            // Trigger Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trigger when I...")
                                    .font(.subheadline)

                                HStack(spacing: 8) {
                                    TriggerTypeButton(
                                        type: .enter,
                                        isSelected: viewModel.triggerType == .enter
                                    ) {
                                        viewModel.triggerType = .enter
                                    }

                                    TriggerTypeButton(
                                        type: .exit,
                                        isSelected: viewModel.triggerType == .exit
                                    ) {
                                        viewModel.triggerType = .exit
                                    }

                                    TriggerTypeButton(
                                        type: .both,
                                        isSelected: viewModel.triggerType == .both
                                    ) {
                                        viewModel.triggerType = .both
                                    }
                                }
                            }

                            // Confirm Button
                            Button {
                                let location = SelectedLocation(
                                    name: selected.name,
                                    address: selected.address,
                                    coordinate: selected.coordinate,
                                    radius: viewModel.radius,
                                    triggerType: viewModel.triggerType
                                )
                                onSelect(location)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Use This Location")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(16)
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .alert("Location Access Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location access to use location-based reminders.")
            }
            .task {
                viewModel.requestLocationPermission()
                if let initial = initialLocation {
                    viewModel.setInitialLocation(initial)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct SearchResultRow: View {
    let result: LocationSearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "mappin.circle")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading) {
                    Text(result.title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let subtitle = result.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        Divider()
            .padding(.leading, 44)
    }
}

private struct TriggerTypeButton: View {
    let type: LocationTriggerType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(type.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Models

struct SelectedLocation: Equatable {
    let name: String
    let address: String?
    let coordinate: CLLocationCoordinate2D
    var radius: Double
    var triggerType: LocationTriggerType

    static func == (lhs: SelectedLocation, rhs: SelectedLocation) -> Bool {
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct LocationSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
}

// MARK: - ViewModel

@available(iOS 17.0, *)
@MainActor
class LocationPickerViewModel: NSObject, ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var selectedLocation: SelectedLocation?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var searchQuery = ""
    @Published var searchResults: [LocationSearchResult] = []
    @Published var radius: Double = 100
    @Published var triggerType: LocationTriggerType = .enter
    @Published var showPermissionAlert = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var searchCompleter: MKLocalSearchCompleter?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        setupSearchCompleter()
    }

    private func setupSearchCompleter() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.resultTypes = [.address, .pointOfInterest]
    }

    func requestLocationPermission() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showPermissionAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }

    func setInitialLocation(_ location: SelectedLocation) {
        selectedLocation = location
        radius = location.radius
        triggerType = location.triggerType
        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func centerOnUserLocation() {
        guard let location = userLocation else {
            locationManager.requestLocation()
            return
        }

        cameraPosition = .region(MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func handleMapTap(at location: CGPoint) {
        // Convert screen point to coordinate
        // Note: In SwiftUI Map, we use the center of the visible region
        // For precise tap handling, we'd need UIViewRepresentable
        selectCenterLocation()
    }

    func selectCenterLocation() {
        // Use the user's location or a default as center
        if let location = userLocation {
            reverseGeocode(coordinate: location)
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            let name: String
            let address: String?

            if let placemark = placemarks?.first {
                name = placemark.name ?? placemark.locality ?? "Selected Location"
                address = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            } else {
                name = "Selected Location"
                address = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            }

            Task { @MainActor in
                self.selectedLocation = SelectedLocation(
                    name: name,
                    address: address,
                    coordinate: coordinate,
                    radius: self.radius,
                    triggerType: self.triggerType
                )
            }
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery

        if let location = userLocation {
            request.region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            searchResults = response.mapItems.prefix(10).map { item in
                LocationSearchResult(
                    title: item.name ?? "Unknown",
                    subtitle: item.placemark.title,
                    coordinate: item.placemark.coordinate
                )
            }
        } catch {
            searchResults = []
        }
    }

    func selectSearchResult(_ result: LocationSearchResult) {
        selectedLocation = SelectedLocation(
            name: result.title,
            address: result.subtitle,
            coordinate: result.coordinate,
            radius: radius,
            triggerType: triggerType
        )

        cameraPosition = .region(MKCoordinateRegion(
            center: result.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))

        searchQuery = ""
        searchResults = []
    }
}

// MARK: - CLLocationManagerDelegate

@available(iOS 17.0, *)
extension LocationPickerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate

        if selectedLocation == nil {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            showPermissionAlert = true
        default:
            break
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    LocationPickerView { location in
    }
}
