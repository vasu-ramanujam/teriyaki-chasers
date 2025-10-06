import Foundation

struct Species: Codable, Identifiable {
    let id: UUID
    let commonName: String
    let scientificName: String
    let habitat: String?
    let diet: String?
    let behavior: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case habitat, diet, behavior
        case createdAt = "created_at"
    }
}

struct SpeciesSearch: Codable {
    let items: [Species]
}

