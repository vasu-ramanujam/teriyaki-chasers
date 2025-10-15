import Foundation
import CoreLocation
import MapKit

struct Species: Identifiable, Hashable {
    let id: UUID = .init()
    let name: String
    let emoji: String
}

struct Sighting: Identifiable, Hashable {
    let id: UUID = .init()
    let species: Species
    let coordinate: CLLocationCoordinate2D
    let createdAt: Date
    let note: String?
}

struct Hotspot: Identifiable, Hashable {
    let id: UUID = .init()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let densityScore: Double
}

enum Waypoint: Identifiable, Hashable {
    case sighting(Sighting)
    case hotspot(Hotspot)

    var id: String {
        switch self {
        case .sighting(let s): return "s-\(s.id)"
        case .hotspot(let h):  return "h-\(h.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .sighting(let s): return s.coordinate
        case .hotspot(let h):  return h.coordinate
        }
    }

    var title: String {
        switch self {
        case .sighting(let s): return "\(s.species.emoji) \(s.species.name)"
        case .hotspot(let h):  return "High Volume: \(h.name)"
        }
    }
}