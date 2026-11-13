import CoreLocation

enum LocationError: LocalizedError {
    case denied

    var errorDescription: String? {
        switch self {
        case .denied:
            WeatherLocalization.string("weather.error.locationPermission")
        }
    }
}

@MainActor
final class WeatherLocationService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }


    func currentLocation() async throws -> CLLocation {
        try await ensureAuthorization()

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func cityName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
        let placemarks = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: locale)
        return placemarks?.first?.locality
    }

    private func ensureAuthorization() async throws {
        var status = manager.authorizationStatus

        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.denied
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in

            guard status != .notDetermined else { return }
            authContinuation?.resume(returning: status)
            authContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

@MainActor
protocol WeatherLocationProviding {
    func currentLocation() async throws -> CLLocation
    func cityName(for location: CLLocation) async -> String?
}

extension WeatherLocationService: WeatherLocationProviding {}
