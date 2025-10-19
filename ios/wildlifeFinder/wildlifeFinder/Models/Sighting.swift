import Foundation
import CoreLocation
import MapKit

public enum privacySetting: String, Codable {
    case pub
    case priv
}

public struct Species: Identifiable, Hashable {
    public let id: UUID = .init()
    public let name: String
    public let emoji: String
}

public struct Sighting: Identifiable, Hashable {
    public let id: UUID = .init()
    public let species: Species
    public let coordinate: CLLocationCoordinate2D
    public let createdAt: Date
    public let note: String? //caption
    public let username: String
    public let privacy: privacySetting
}

public struct Hotspot: Identifiable, Hashable {
    public let id: UUID = .init()
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    public let densityScore: Double
    public let sightingList: [Sighting]
    public let numSightings: Int
    public let numSpecies: Int
}

public enum Waypoint: Identifiable, Hashable {
    case sighting(Sighting)
    case hotspot(Hotspot)
    
    public var id: String {
        switch self {
        case .sighting(let s): return "s-\(s.id)"
        case .hotspot(let h):  return "h-\(h.id)"
        }
    }
    
    public var coordinate: CLLocationCoordinate2D {
        switch self {
        case .sighting(let s): return s.coordinate
        case .hotspot(let h):  return h.coordinate
        }
    }
    
    public var title: String {
        switch self {
        case .sighting(let s): return "\(s.species.emoji) \(s.species.name)"
        case .hotspot(let h):  return "High Volume: \(h.name)"
        }
    }
    

}

// MARK: - Explicit conformance (because CLLocationCoordinate2D isn't Hashable)
extension Sighting: Equatable {
    public static func == (lhs: Sighting, rhs: Sighting) -> Bool { lhs.id == rhs.id }
}
extension Sighting {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Hotspot: Equatable {
    public static func == (lhs: Hotspot, rhs: Hotspot) -> Bool { lhs.id == rhs.id }
}
extension Hotspot {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Waypoint {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
        lhs.id == rhs.id
    }
}

// based on InfoView, every Sighting needs the following:
//species = "Flamingo" - done
// caption aka note - done
// date_posted - done

// username = "Named Teriyaki"
// priv_setting: privacy = ._public

// every hotspot needs
// list of sightings it's made up of, num species and num sightings

// every waypoint needs -- origin: where_from = (enum of map / ar / hva)


// image_url; sound_url -- use sighting ID (not necessary)
// description: use species ID and api
