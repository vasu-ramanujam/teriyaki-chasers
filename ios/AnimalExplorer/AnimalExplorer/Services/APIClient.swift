import Foundation
import UIKit

class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let baseURL = "http://127.0.0.1:8000/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Species API
    
    func searchSpecies(query: String, limit: Int = 10) async throws -> [Species] {
        let url = URL(string: "\(baseURL)/species?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&limit=\(limit)")!
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(SpeciesSearch.self, from: data)
        return response.items
    }
    
    func getSpecies(id: UUID) async throws -> Species {
        let url = URL(string: "\(baseURL)/species/\(id)")!
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(Species.self, from: data)
    }
    
    // MARK: - Sightings API
    
    func getSightings(bbox: String, since: Date? = nil, speciesId: UUID? = nil) async throws -> [Sighting] {
        var components = URLComponents(string: "\(baseURL)/sightings")!
        var queryItems = [URLQueryItem(name: "bbox", value: bbox)]
        
        if let since = since {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
        }
        
        if let speciesId = speciesId {
            queryItems.append(URLQueryItem(name: "species_id", value: speciesId.uuidString))
        }
        
        components.queryItems = queryItems
        
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(SightingList.self, from: data)
        return response.items
    }
    
    func createSighting(speciesId: UUID, lat: Double, lon: Double, isPrivate: Bool, image: UIImage) async throws -> Sighting {
        let url = URL(string: "\(baseURL)/sightings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"species_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(speciesId.uuidString)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"lat\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(lat)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"lon\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(lon)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"is_private\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(isPrivate)\r\n".data(using: .utf8)!)
        
        // Add image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Sighting.self, from: data)
    }
    
    // MARK: - Identification API
    
    func identifyPhoto(image: UIImage) async throws -> [IdentificationCandidate] {
        let url = URL(string: "\(baseURL)/identify/photo")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(IdentificationResult.self, from: data)
        return response.candidates
    }
    
    // MARK: - Routing API
    
    func createRoute(start: RoutePoint, end: RoutePoint) async throws -> Route {
        let url = URL(string: "\(baseURL)/route")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let routeCreate = RouteCreate(start: start, end: end)
        request.httpBody = try JSONEncoder().encode(routeCreate)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Route.self, from: data)
    }
    
    func getSightingsNearRoute(routeId: UUID, radiusM: Int = 200) async throws -> [SightingNearRoute] {
        let url = URL(string: "\(baseURL)/route/sightings-near?route_id=\(routeId)&radius_m=\(radiusM)")!
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(SightingNearRouteList.self, from: data)
        return response.items
    }
    
    func augmentRoute(routeId: UUID, waypoints: [RouteWaypoint], maxExtraDurationS: Int? = nil) async throws -> Route {
        let url = URL(string: "\(baseURL)/route/\(routeId)/augment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let augment = RouteAugment(waypoints: waypoints, maxExtraDurationS: maxExtraDurationS)
        request.httpBody = try JSONEncoder().encode(augment)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Route.self, from: data)
    }
}

