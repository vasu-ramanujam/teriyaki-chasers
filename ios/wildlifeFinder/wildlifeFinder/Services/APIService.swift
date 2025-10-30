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

// Identify DTOs
public struct IdentificationCandidateDTO: Codable {
    public let species_id: String
    public let label: String
    public let score: Double
}

public struct IdentificationResultDTO: Codable {
    public let candidates: [IdentificationCandidateDTO]
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
    
    // Choose API base per environment (simulator vs device)
    private let baseURL: String = {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000/v1"
        #else
        return "http://192.168.1.12:8000/v1" // <-- replace with your Mac's IP
        #endif
    }()

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
    
    // MARK: - Identify API (photo/audio uploads)
    public func identifyPhoto(imageData: Data) async throws -> IdentificationResultDTO {
        guard let url = URL(string: "\(baseURL)/identify/photo") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // multipart/form-data body
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(IdentificationResultDTO.self, from: data)
    }

    public func identifyAudio(audioData: Data) async throws -> IdentificationResultDTO {
        guard let url = URL(string: "\(baseURL)/identify/audio") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(IdentificationResultDTO.self, from: data)
    }

    // MARK: - Create Sighting (multipart/form-data)
    public func createSighting(
        speciesId: Int,
        coordinate: CLLocationCoordinate2D,
        isPublic: Bool,
        caption: String?,
        username: String?,
        imageJPEGData: Data
    ) async throws -> APISighting {
        guard let url = URL(string: "\(baseURL)/sightings/create") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        addField(name: "species_id", value: String(speciesId))
        addField(name: "lat", value: String(coordinate.latitude))
        addField(name: "lon", value: String(coordinate.longitude))
        addField(name: "is_private", value: isPublic ? "false" : "true")
        if let username, !username.isEmpty { addField(name: "username", value: username) }
        if let caption, !caption.isEmpty { addField(name: "caption", value: caption) }

        // Photo part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageJPEGData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APISighting.self, from: data)
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