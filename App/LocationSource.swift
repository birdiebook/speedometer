import CoreLocation
import SpeedKit

/// The phone's GPS (BESLUT B3, B17): "When In Use"; the store decides how it runs (`GPSMode`, METOD M11), also in the
/// background, with iOS's blue location indicator.
/// Only a `GPSSample` leaves this class: speed, accuracies and the coordinates for the trail of the current trip,
/// which stays on the phone (BESLUT B16).
final class LocationSource: NSObject, CLLocationManagerDelegate {
    var onSample: ((GPSSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    private let manager = CLLocationManager()
    /// BESLUT B17: keeps the "When In Use" app in use in the background while the GPS runs.
    private var backgroundSession: CLBackgroundActivitySession?
    /// Whether the store wants updates; an authorization change must not start them otherwise.
    private var wanted = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        // BESLUT B17: needs `UIBackgroundModes: location` in Info.plist (project.yml).
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    /// METOD M11: full or saving accuracy, or off.
    func run(_ mode: GPSMode) {
        switch mode {
        case .off:
            stop()
        case .full:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            start()
        case .saving:
            manager.desiredAccuracy = GPSPlan.savingAccuracy
            manager.distanceFilter = GPSPlan.savingDistanceFilter
            start()
        }
    }

    /// Asks for permission the first time, then starts updates once allowed.
    private func start() {
        wanted = true
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        beginUpdatesIfAllowed()
    }

    /// BESLUT B17: the GPS off, the background session ended.
    private func stop() {
        wanted = false
        manager.stopUpdatingLocation()
        backgroundSession?.invalidate()
        backgroundSession = nil
    }

    private func beginUpdatesIfAllowed() {
        guard wanted else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if backgroundSession == nil { backgroundSession = CLBackgroundActivitySession() }
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
            #if DEBUG
            NSLog("LOC speed=%.2f speedAcc=%.2f hAcc=%.1f", location.speed, location.speedAccuracy, location.horizontalAccuracy)
            #endif
            // METOD M1: CLLocation reports negative values when the field is invalid.
            onSample?(GPSSample(
                time: location.timestamp.timeIntervalSinceReferenceDate,
                speed: location.speed,
                speedAccuracy: location.speedAccuracy,
                horizontalAccuracy: location.horizontalAccuracy,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Nothing to do: with no valid sample the engine falls back to finding GPS (METOD M3).
    }
}
