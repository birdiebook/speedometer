import Foundation
import CoreLocation
import SpeedKit

/// Holds the engine, saves the trip after every change and the trail every 30 s, and restores both on launch
/// (BESLUT B10, B16).
@MainActor
final class TripStore: ObservableObject {
    @Published private(set) var engine: TripEngine
    @Published private(set) var locationOff = false
    /// Counts resets, so the view can fire a haptic (BESLUT B6).
    @Published private(set) var resetCount = 0

    /// BESLUT B7: set once from the phone's region.
    let unit: SpeedUnit

    private let defaults: UserDefaults
    private let source = LocationSource()
    private var timer: Timer?
    private static let key = "trip.v1"
    // METOD M9: the trail is written this often (s) while the app is open, and when it leaves the foreground.
    private static let trailSaveInterval: TimeInterval = 30
    private var savedTrail = Trail()
    private var lastTrailSave: TimeInterval = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.unit = TripStore.unitForCurrentRegion()
        // BESLUT B10: the numbers of the last trip come back; the mode starts as finding GPS.
        var restored = Trip()
        if let data = defaults.data(forKey: TripStore.key),
           let trip = try? JSONDecoder().decode(Trip.self, from: data) {
            restored = trip
        }
        // BESLUT B16: the trail belongs to the trip; without the trip it is not restored.
        var restoredTrail = Trail()
        if !restored.isEmpty, let trail = TrailFile.load() {
            restoredTrail = trail
        }
        self.engine = TripEngine(trip: restored, trail: restoredTrail)
        self.savedTrail = restoredTrail

        source.onSample = { [weak self] sample in
            MainActor.assumeIsolated { self?.ingest(sample) }
        }
        source.onAuthorizationChange = { [weak self] status in
            MainActor.assumeIsolated { self?.updateAuthorization(status) }
        }
        updateAuthorization(source.authorizationStatus)
    }

    var state: TripState { engine.state }
    var trip: Trip { engine.trip }
    var trail: Trail { engine.trail }
    var displayedSpeed: Double? { engine.displayedSpeed }

    /// BESLUT B7: metric regions get km/h and km, the US and the UK get mph and mi.
    private static func unitForCurrentRegion() -> SpeedUnit {
        let system = Locale.current.measurementSystem
        return (system == .us || system == .uk) ? .imperial : .metric
    }

    // MARK: lifecycle (BESLUT B10: location only while the app is active)

    func activate() {
        source.start()
        timer?.invalidate()
        // METOD M3: the 5 s no-fix timeout is checked once a second.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        tick()
    }

    func deactivate() {
        source.stop()
        timer?.invalidate()
        timer = nil
        saveTrail() // METOD M9
    }

    // MARK: engine

    private func ingest(_ sample: GPSSample) {
        let before = engine.trip
        engine.ingest(sample)
        saveIfChanged(from: before)
    }

    private func tick() {
        let now = Date().timeIntervalSinceReferenceDate
        engine.tick(now: now)
        // METOD M9: the trail every 30 s.
        if now - lastTrailSave >= TripStore.trailSaveInterval { saveTrail(now: now) }
    }

    /// BESLUT B6: long-press resets the trip.
    func reset() {
        engine.reset()
        resetCount += 1
        save()
        saveTrail() // BESLUT B16: the empty trail removes the file
    }

    private func updateAuthorization(_ status: CLAuthorizationStatus) {
        locationOff = (status == .denied || status == .restricted)
    }

    // MARK: saving (BESLUT B10)

    private func saveIfChanged(from before: Trip) {
        if engine.trip != before { save() }
    }

    /// METOD M9: writes the trail if it changed since the last write.
    private func saveTrail(now: TimeInterval = Date().timeIntervalSinceReferenceDate) {
        lastTrailSave = now
        guard engine.trail != savedTrail else { return }
        TrailFile.save(engine.trail)
        savedTrail = engine.trail
    }

    private func save() {
        if let data = try? JSONEncoder().encode(engine.trip) {
            defaults.set(data, forKey: TripStore.key)
        }
    }
}
