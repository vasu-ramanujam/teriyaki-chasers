import Foundation

struct Route: Codable, Identifiable {
    let id: UUID
    let provider: String
    let polyline: String
    let distanceM: Double
    let durationS: Double
    
    enum CodingKeys: String, CodingKey {
        case id, provider, polyline
        case distanceM = "distance_m"
        case durationS = "duration_s"
    }
}

struct RoutePoint: Codable {
    let lat: Double
    let lon: Double
}

struct RouteCreate: Codable {
    let start: RoutePoint
    let end: RoutePoint
}

struct RouteWaypoint: Codable {
    let lat: Double
    let lon: Double
    let sightingId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case lat, lon
        case sightingId = "sighting_id"
    }
}

struct RouteAugment: Codable {
    let waypoints: [RouteWaypoint]
    let maxExtraDurationS: Int?
    
    enum CodingKeys: String, CodingKey {
        case waypoints
        case maxExtraDurationS = "max_extra_duration_s"
    }
}

struct SightingNearRoute: Codable, Identifiable {
    let id = UUID()
    let sightingId: UUID
    let speciesId: UUID
    let lat: Double
    let lon: Double
    let detourCostS: Int
    
    enum CodingKeys: String, CodingKey {
        case sightingId = "sighting_id"
        case speciesId = "species_id"
        case lat, lon
        case detourCostS = "detour_cost_s"
    }
}

struct SightingNearRouteList: Codable {
    let items: [SightingNearRoute]
}

