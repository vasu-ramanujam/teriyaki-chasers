import Foundation
import CoreLocation
import MapKit

// MARK: - API Models
public struct APISpecies: Codable, Identifiable {
    public let id: Int
    public let common_name: String
    public let scientific_name: String
    public let habitat: String?
    public let diet: String?
    public let behavior: String?
    public let description: String?
    public let other_sources: [String]?
    public let created_at: String
}

public struct APISighting: Codable, Identifiable {
    public let id: String
    public let user_id: String?
    public let username: String?
    public let species_id: Int
    public let lat: Double
    public let lon: Double
    public let taken_at: String
    public let is_private: Bool
    public let media_url: String?
    public let caption: String?
    public let created_at: String
}

public struct APIRoute: Codable, Identifiable {
    public let id: String
    public let provider: String
    public let polyline: String
    public let distance_m: Double
    public let duration_s: Double
}

public struct APIRouteCreate: Codable {
    public let start: APIRoutePoint
    public let end: APIRoutePoint
}

public struct APIRoutePoint: Codable {
    public let lat: Double
    public let lon: Double
}

public struct APISightingFilter: Codable {
    public let area: String
    public let species_id: Int?
    public let start_time: String?
    public let end_time: String?
}

public struct APISpeciesSearch: Codable {
    public let items: [APISpecies]
}

public struct APISightingList: Codable {
    public let items: [APISighting]
}

public struct APISpeciesDetails: Codable {
    public let species: String             // scientific name
    public let english_name: String?
    public let description: String?
    public let other_sources: [String]?
}
extension APIService {
    public func getSpeciesDetails(id: Int) async throws -> APISpeciesDetails {
        let url = URL(string: "\(baseURL)/species/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpeciesDetails.self, from: data)
    }
}

// MARK: - API Service
public class APIService: ObservableObject {
    public static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/v1" // Update with your backend URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Species API
    public func searchSpecies(query: String, limit: Int = 10) async throws -> [APISpecies] {
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
    
    public func getSpecies(id: Int) async throws -> APISpecies {
        let url = URL(string: "\(baseURL)/species/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpecies.self, from: data)
    }
    
    // MARK: - Sightings API
    public func getSightings(filter: APISightingFilter) async throws -> [APISighting] {
        let url = URL(string: "\(baseURL)/sightings/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONEncoder().encode(filter)
        request.httpBody = jsonData
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(APISightingList.self, from: data)
        return response.items
    }
    
    public func getSighting(id: String) async throws -> APISighting {
        let url = URL(string: "\(baseURL)/sightings/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISighting.self, from: data)
    }
    
    // MARK: - Route API
    public func createRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) async throws -> APIRoute {
        let url = URL(string: "\(baseURL)/route/")!
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
    public func createBoundingBox(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> String {
        let latDelta = span.latitudeDelta / 2
        let lonDelta = span.longitudeDelta / 2
        
        let west = center.longitude - lonDelta
        let south = center.latitude - latDelta
        let east = center.longitude + lonDelta
        let north = center.latitude + latDelta
        
        return "\(west),\(south),\(east),\(north)"
    }
}