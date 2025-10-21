//
//  LocationManager.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/7/25.
//
import MapKit
import Observation

struct Location: Decodable {
    var lat: CLLocationDirection
    var lon: CLLocationDirection
    var speed: CLLocationSpeed
}

@Observable
final class LocationManagerViewModel {
    static let shared = LocationManagerViewModel()
    private init() {}
    
    private(set) var location = Location(lat: 0.0, lon: 0.0, speed: 0.0)
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: .init(location.lat), longitude: .init(location.lon))
    }
    
    @ObservationIgnored
    var speed: String {
        switch location.speed {
            case 0.5..<5: "walking"
            case 5..<7: "running"
            case 7..<13: "cycling"
            case 13..<90: "driving"
            case 90..<139: "in train"
            case 139..<225: "flying"
            default: "resting"
        }
    }
    
    func setLocation(lat: CLLocationDegrees, lon: CLLocationDegrees, speed: CLLocationSpeed) {
        location.lat = lat
        location.lon = lon
        location.speed = speed
    }
    
    private(set) var heading: CLLocationDirection? = nil
    private let compass = ["North", "NE", "East", "SE", "South", "SW", "West", "NW", "North"]
    var compassHeading: String {
        return if let heading {
            compass[Int(round(heading.truncatingRemainder(dividingBy: 360) / 45))]
        } else {
            "unknown"
        }
    }
    
    func setHeading(_ newHeading: CLLocationDirection?) {
        heading = newHeading
    }
}

final class LocManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocManager()
    private let locManager = CLLocationManager()
    
    override private init() {
        super.init()

        // configure the location manager
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.delegate = self
    }

    // start updates
    func startUpdates() {
        if locManager.authorizationStatus == .notDetermined {
            // ask for user permission if undetermined
            // Be sure to add 'Privacy - Location When In Use Usage Description' to
            // Info.plist, otherwise location read will fail silently, with (lat/lon = 0)
            locManager.requestWhenInUseAuthorization()
        }
    
        Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let loc = update.location {
                        LocationManagerViewModel.shared.setLocation(
                            lat: loc.coordinate.latitude,
                            lon: loc.coordinate.longitude,
                            speed: loc.speed)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }

        // start heading updates also
        Task {
            for await newHeading in headings {
                LocationManagerViewModel.shared.setHeading(newHeading)
            }
        }
    }

    // update headings
    var feeder: ((CLLocationDirection) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        feeder?(newHeading.magneticHeading)
    }

    var headings: AsyncStream<CLLocationDirection> { // getter
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont in
            feeder = { cont.yield($0) } // initialize feedr
            cont.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.locManager.stopUpdatingHeading()
                    self.feeder = nil
                }
            }
            locManager.startUpdatingHeading()
        }
    }
}

