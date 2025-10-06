import Foundation
import CoreLocation

struct Sighting: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let speciesId: UUID
    let lat: Double
    let lon: Double
    let takenAt: Date
    let isPrivate: Bool
    let mediaThumbUrl: String?
    let createdAt: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case speciesId = "species_id"
        case lat, lon
        case takenAt = "taken_at"
        case isPrivate = "is_private"
        case mediaThumbUrl = "media_thumb_url"
        case createdAt = "created_at"
    }
}

struct SightingList: Codable {
    let items: [Sighting]
}

struct SightingCreate: Codable {
    let speciesId: UUID
    let lat: Double
    let lon: Double
    let takenAt: Date
    let isPrivate: Bool
    let mediaUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case speciesId = "species_id"
        case lat, lon
        case takenAt = "taken_at"
        case isPrivate = "is_private"
        case mediaUrl = "media_url"
    }
}

