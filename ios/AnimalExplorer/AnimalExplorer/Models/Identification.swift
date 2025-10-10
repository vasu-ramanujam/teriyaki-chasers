import Foundation

struct IdentificationCandidate: Codable {
    let speciesId: UUID
    let label: String
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case speciesId = "species_id"
        case label, score
    }
}

struct IdentificationResult: Codable {
    let candidates: [IdentificationCandidate]
}

