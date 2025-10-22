import Foundation
import CoreLocation

// MARK: - API Models
struct APISpecies: Codable, Identifiable {
    let id: Int
    let common_name: String
    let scientific_name: String
    let habitat: String?
    let diet: String?
    let behavior: String?
    let description: String?
    let other_sources: [String]?
    let created_at: String
}

struct APISighting: Codable, Identifiable {
    let id: String
    let user_id: String?
    let username: String?
    let species_id: Int
    let lat: Double
    let lon: Double
    let taken_at: String
    let is_private: Bool
    let media_url: String?
    let caption: String?
    let created_at: String
}

struct APIRoute: Codable, Identifiable {
    let id: String
    let provider: String
    let polyline: String
    let distance_m: Double
    let duration_s: Double
}

struct APIRouteCreate: Codable {
    let start: APIRoutePoint
    let end: APIRoutePoint
}

struct APIRoutePoint: Codable {
    let lat: Double
    let lon: Double
}

struct APISightingFilter: Codable {
    let area: String
    let species_id: Int?
    let start_time: String?
    let end_time: String?
}

struct APISpeciesSearch: Codable {
    let items: [APISpecies]
}

struct APISightingList: Codable {
    let items: [APISighting]
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/v1" // Update with your backend URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Species API
    func searchSpecies(query: String, limit: Int = 10) async throws -> [APISpecies] {
        let url = URL(string: "\(baseURL)/species")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(APISpeciesSearch.self, from: data)
        return response.items
    }
    
    func getSpecies(id: Int) async throws -> APISpecies {
        let url = URL(string: "\(baseURL)/species/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpecies.self, from: data)
    }
    
    // MARK: - Sightings API
    func getSightings(filter: APISightingFilter) async throws -> [APISighting] {
        let url = URL(string: "\(baseURL)/sightings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONEncoder().encode(filter)
        request.httpBody = jsonData
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(APISightingList.self, from: data)
        return response.items
    }
    
    func getSighting(id: String) async throws -> APISighting {
        let url = URL(string: "\(baseURL)/sightings/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISighting.self, from: data)
    }
    
    // MARK: - Route API
    func createRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) async throws -> APIRoute {
        let url = URL(string: "\(baseURL)/route")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let routeData = APIRouteCreate(
            start: APIRoutePoint(lat: start.latitude, lon: start.longitude),
            end: APIRoutePoint(lat: end.latitude, lon: end.longitude)
        )
        
        let jsonData = try JSONEncoder().encode(routeData)
        request.httpBody = jsonData
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APIRoute.self, from: data)
    }
    
    // MARK: - Helper Methods
    func createBoundingBox(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> String {
        let latDelta = span.latitudeDelta / 2
        let lonDelta = span.longitudeDelta / 2
        
        let west = center.longitude - lonDelta
        let south = center.latitude - latDelta
        let east = center.longitude + lonDelta
        let north = center.latitude + latDelta
        
        return "\(west),\(south),\(east),\(north)"
    }
}