import Foundation
import CoreLocation
import MapKit
import Alamofire
import KDTree


// MARK: - API Models
public struct AnimalSearchRequest: Codable {
    public let name: String
}

public struct AnimalSearchResponse: Codable {
    public let name: String
    public let is_valid: Bool
}

public struct APISpecies: Codable, Identifiable, Hashable {
    public let id: Int
    public let common_name: String
    public let scientific_name: String
    public let habitat: String?
    public let diet: String?
    public let behavior: String?
    public let description: String?
    public let other_sources: [String]?
    public let created_at: String
    public let main_image: String?

}

public struct APISighting: Codable, Identifiable, Hashable {
    public let id: String
    public let username: String?
    public let species_id: Int
    public let lat: Double
    public let lon: Double
    public let taken_at: String?
    public let is_private: Bool
    public let media_url: String?
    public let audio_url: String?
    public let caption: String?
    public let created_at: String
}

func radians(_ degree: Double) -> Double {
    return degree * (Double.pi / 180.0)
}

// get the distance in miles between two [latitude, longitude] pairings
func getDistanceBetweenDegrees(_ x: [Double], _ y: [Double]) -> Double {
    let meanLat = (x[0] + y[0]) / 2
    let deltaY = (y[0] - x[0]) * 69.17
    let deltaX = (y[1] - x[1]) * cos(radians(meanLat)) * 69.17
    
    return pow(pow(deltaY, 2) + pow(deltaX, 2), 0.5)
}

extension APISighting: KDTreePoint {
    static public var dimensions = 2
    
    public func kdDimension(_ dimension: Int) -> Double {
        return dimension == 0 ? lat : lon
    }
    
    public func squaredDistance(to otherPoint: APISighting) -> Double {
        return getDistanceBetweenDegrees([self.lat, self.lon], [otherPoint.lat, otherPoint.lon])
    }
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
    public let area: String?
    public let species_id: Int?
    public let start_time: String?
    public let end_time: String?
    public let username: String?
}

public struct APISpeciesSearch: Codable {
    public let items: [APISpecies]
}

public struct APISightingList: Codable {
    public let items: [APISighting]
}

//user
public struct APIFlashcardDetails: Codable, Identifiable {
    public let species_id: Int
    public let species_name: String
    public let first_seen: String
    public let num_sightings: Int
    
    public var id: Int {
        species_id
    }
    
}
public struct APIUserDetails: Codable {
    public let username: String
    public let total_sightings: Int
    public let total_species: Int
    public let flashcards: [APIFlashcardDetails]
}

public struct ImageLink: Codable {
    public let link: String
}

// Identify DTOs
public struct IdentifyResponse: Codable {
    public let label: String
    public let species_id: Int?
    public let wikiData: WikiData?
    
    enum CodingKeys: String, CodingKey {
            case label
            case species_id
            case wikiData = "wiki_data"
        }
}

public struct WikiData: Codable {
    let englishName: String?
    let description: String?
    let otherSources: [String]?
    let mainImage: String?

    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case description
        case otherSources = "other_sources"
        case mainImage = "main_image"
    }
}

public struct APISpeciesDetails: Codable {
    public let species: String             // scientific name
    public let english_name: String?
    public let description: String?
    public let other_sources: [String]?
    public let main_image: String?
}
extension APIService {
    public func getSpeciesDetails(id: Int) async throws -> APISpeciesDetails {
        let url = URL(string: "\(baseURL)/species/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpeciesDetails.self, from: data)
    }
}

// MARK: - API Service
public class APIService {
    public static let shared = APIService()
    
    // APIService.swift
    private let baseURL: String = {
        #if targetEnvironment(simulator)
            return "http://127.0.0.1:8000/v1"
        #else
            return "http://Owens-MacBook-Air-10.local:8000/v1"
        #endif
    }()


    private let session = URLSession.shared
    
    private init() {}
    
    public func getWikiImage(name: String) async throws -> ImageLink {
        let url = URL(string: "\(baseURL)/species/\(name)/image")! 
        
        let (data, _) = try await session.data(from: url)
        let _ = print(data)
        return try JSONDecoder().decode(ImageLink.self, from: data)
    }
    
    //TODO: check if this works. new user code
    public func getUserStats() async throws -> APIUserDetails {
        let user_loggedin = "Hawk"
        let url = URL(string: "\(baseURL)/user/\(user_loggedin)")! // TODO: replace with hardcoded user_id
        let (data, _) = try await session.data(from: url)
        print("ofc its a json decoder error")
        return try JSONDecoder().decode(APIUserDetails.self, from: data)
        
        //return try JSONDecoder().decode(APIUserDetails.self, from: data)
    }
    
    
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
        let url = URL(string: "\(baseURL)/species/id/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpecies.self, from: data)
    }
    
    public func getSpeciesFromName(name: String) async throws -> APISpecies {
        let url = URL(string: "\(baseURL)/identify/species/\(name)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APISpecies.self, from: data)
    }
    
    public func getSightings(filter: APISightingFilter) async throws -> [APISighting] {
        
        let url = URL(string: "\(baseURL)/sightings/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")


        let jsonData = try JSONEncoder().encode(filter)
        request.httpBody = jsonData


        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            print("POST \(url.absoluteString) → \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(APISightingList.self, from: data)
        
        return decoded.items
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
    
    public func identifyPhoto(imageData: Data) async throws -> IdentifyResponse {
        let url = "\(baseURL)/identify/photo"
        
        return try await AF.upload(
            multipartFormData: { form in
                form.append(
                    imageData,
                    withName: "photo",
                    fileName: "photo.jpg",
                    mimeType: "image/jpeg"
                )
            },
            to: url,
            method: .post
        )
        .validate()
        .serializingDecodable(IdentifyResponse.self)
        .value
    }

    public func identifyAudio(audioData: Data) async throws -> IdentifyResponse {
        let url = "\(baseURL)/identify/audio"

        return try await AF.upload(
            multipartFormData: { form in
                form.append(
                    audioData,
                    withName: "audio",
                    fileName: "audio.wav",
                    mimeType: "audio/wav"
                )
            },
            to: url,
            method: .post
        )
        .validate()
        .serializingDecodable(IdentifyResponse.self)
        .value
    }

    public func identifyPhotoAndAudio(imageData: Data, audioData: Data) async throws -> IdentifyResponse {
        let url = "\(baseURL)/identify/photo-audio"
        
        return try await AF.upload(
            multipartFormData: { form in
                form.append(
                    imageData,
                    withName: "photo",
                    fileName: "photo.jpg",
                    mimeType: "image/jpeg"
                )
                form.append(
                    audioData,
                    withName: "audio",
                    fileName: "audio.wav",
                    mimeType: "audio/wav"
                )
            },
            to: url,
            method: .post
        )
        .validate()
        .serializingDecodable(IdentifyResponse.self)
        .value
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
        let url = "\(baseURL)/sightings/create"

        return try await AF.upload(
            multipartFormData: { form in
                form.append(Data("\(speciesId)".utf8), withName: "species_id")
                form.append(Data("\(coordinate.latitude)".utf8), withName: "lat")
                form.append(Data("\(coordinate.longitude)".utf8), withName: "lon")
                form.append(Data((isPublic ? "false" : "true").utf8), withName: "is_private")
                form.append(
                    Data((username?.isEmpty == false ? username! : "Hawk").utf8),
                    withName: "username"
                )
                if let caption, !caption.isEmpty {
                    form.append(Data(caption.utf8), withName: "caption")
                }
                form.append(
                    imageJPEGData,
                    withName: "photo",
                    fileName: "photo.jpg",
                    mimeType: "image/jpeg"
                )
            },
            to: url,
            method: .post
        )
        .validate()
        .serializingDecodable(APISighting.self)
        .value
    }
    
    // MARK: - Animal Search
    public func getSearchSuggestions(query: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/animal-search/\(query)") else { return [] }
        let (data, _) = try await session.data(from: url)
        
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    public func validateName(_ name: String) async throws -> AnimalSearchResponse {
        guard let url = URL(string: "\(baseURL)/animal-search/validate-name") else { return AnimalSearchResponse(name: "dur", is_valid: false) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let objData = AnimalSearchRequest(name: name)
        let jsonData = try JSONEncoder().encode(objData)
        
        request.httpBody = jsonData
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AnimalSearchResponse.self, from: data)
    }
    
    public func searchName(_ name: String) async throws -> APISpeciesDetails {
        guard let url = URL(string: "\(baseURL)/animal-search/wiki/\(name)") else { return APISpeciesDetails(species: "invalid", english_name: nil, description: nil, other_sources: nil, main_image: nil) }
        
        let (data, _) = try await session.data(from: url)
        
        return try JSONDecoder().decode(APISpeciesDetails.self, from: data)
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
