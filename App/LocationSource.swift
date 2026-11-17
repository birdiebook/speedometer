import CoreLocation
import SpeedKit

/// The phone's GPS (BESLUT B3, B10): "When In Use", read only while the app is active, never stored as a track.
/// Only a `GPSSample` leaves this class: speed and accuracies, no coordinates.
final class LocationSource: NSObject, CLLocationManagerDelegate {
    var onSample: ((GPSSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    /// Asks for permission the first time, then starts updates once allowed.
    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        beginUpdatesIfAllowed()
    }

    /// BESLUT B10: no location with the app in the background.
    func stop() {
        manager.stopUpdatingLocation()
    }

    private func beginUpdatesIfAllowed() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(manager.authorizationStatus)
        beginUpdatesIfAllowed()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            // METOD M1: CLLocation reports negative values when the field is invalid.
            onSample?(GPSSample(
                time: location.timestamp.timeIntervalSinceReferenceDate,
                speed: location.speed,
                speedAccuracy: location.speedAccuracy,
                horizontalAccuracy: location.horizontalAccuracy
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Nothing to do: with no valid sample the engine falls back to finding GPS (METOD M3).
    }
}
