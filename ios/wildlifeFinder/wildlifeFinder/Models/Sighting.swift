import Foundation
import CoreLocation
import MapKit

// MARK: - Updated Models to match backend
public struct Species: Identifiable, Hashable {
    public let id: Int
    public let common_name: String
    public let scientific_name: String
    public let habitat: String?
    public let diet: String?
    public let behavior: String?
    public let description: String?
    public let other_sources: [String]?
    public let created_at: Date
    public let main_image: String?
    
    // Computed properties for UI compatibility
    public var name: String { common_name }

    
    public init(from apiSpecies: APISpecies) {
        self.id = apiSpecies.id
        self.common_name = apiSpecies.common_name
        self.scientific_name = apiSpecies.scientific_name
        self.habitat = apiSpecies.habitat
        self.diet = apiSpecies.diet
        self.behavior = apiSpecies.behavior
        self.description = apiSpecies.description
        self.other_sources = apiSpecies.other_sources
        self.created_at = ISO8601DateFormatter().date(from: apiSpecies.created_at) ?? Date()
        self.main_image = apiSpecies.main_image
    }
    
    public init(sp_id: Int) {
        self.id = sp_id
        self.common_name = ""
        self.scientific_name = ""
        self.habitat = ""
        self.diet = ""
        self.behavior = ""
        self.description = ""
        self.other_sources = []
        self.created_at = Date()
        self.main_image = ""
    }
}

public struct Sighting: Identifiable, Hashable {
    public let id: String
    public let species: Species
    public let coordinate: CLLocationCoordinate2D
    public let createdAt: Date
    public let note: String?
    public let username: String?
    public let isPrivate: Bool
    public let media_url: String?
    public let audio_url: String?
    
    public init(from apiSighting: APISighting, species: Species) {
        self.id = apiSighting.id
        self.species = species
        self.coordinate = CLLocationCoordinate2D(latitude: apiSighting.lat, longitude: apiSighting.lon)
        if let taken = apiSighting.taken_at {
            self.createdAt = Self.parse(dateString: taken)
        } else {
            self.createdAt = Self.parse(dateString: apiSighting.created_at)
        }
        self.note = apiSighting.caption
        self.username = apiSighting.username ?? "Anonymous"
        self.isPrivate = apiSighting.is_private
        self.media_url = apiSighting.media_url
        self.audio_url = apiSighting.audio_url
    }
}

extension Sighting {
    private static func parse(dateString: String) -> Date {
        // First try ISO8601 with fractional seconds (FastAPI default)
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = isoFractional.date(from: dateString) {
            return parsed
        }

        // Fallback to standard ISO8601 without fractional seconds
        let iso = ISO8601DateFormatter()
        if let parsed = iso.date(from: dateString) {
            return parsed
        }

        // Final fallback for bare sqlite-style strings "yyyy-MM-dd HH:mm:ss"
        let fallback = DateFormatter()
        fallback.calendar = Calendar(identifier: .iso8601)
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.timeZone = TimeZone(secondsFromGMT: 0)
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let parsed = fallback.date(from: dateString) {
            return parsed
        } else {
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let parsed = fallback.date(from: dateString) {
                return parsed
            }
        }

        return Date()
    }
}

public struct Hotspot: Identifiable, Hashable {
    public let id: UUID = .init()
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    public let densityScore: Double
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
        case .sighting(let s): return s.species.name
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

public enum where_from {
    case hva, map, other
}
