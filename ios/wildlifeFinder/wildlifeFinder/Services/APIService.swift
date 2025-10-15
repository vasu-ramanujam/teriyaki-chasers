import Foundation
import CoreLocation

protocol APIService {
    func fetchSightings() async throws -> [Sighting]
    func fetchHotspots() async throws -> [Hotspot]
    func speciesSuggestions(prefix: String) async -> [String]
}

/// Simple mock for now – swap with your real backend later.
final class MockAPIService: APIService {
    private let flamingo = Species(name: "flamingo", emoji: "🦩")
    private let turkey   = Species(name: "turkey", emoji: "🦃")
    private let swan     = Species(name: "mute swan", emoji: "🦢")

    func fetchSightings() async throws -> [Sighting] {
        [
            Sighting(species: flamingo, coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "near marsh"),
            Sighting(species: turkey,   coordinate: .init(latitude: 37.333, longitude: -122.010), createdAt: .now, note: "trail edge"),
            Sighting(species: turkey,   coordinate: .init(latitude: 37.335, longitude: -122.006), createdAt: .now, note: nil),
            Sighting(species: swan,     coordinate: .init(latitude: 37.336, longitude: -122.005), createdAt: .now, note: "lake")
        ]
    }

    func fetchHotspots() async throws -> [Hotspot] {
        [
            Hotspot(name: "Wetlands", coordinate: .init(latitude: 37.332, longitude: -122.004), densityScore: 0.82),
            Hotspot(name: "North Meadow", coordinate: .init(latitude: 37.337, longitude: -122.012), densityScore: 0.65)
        ]
    }

    func speciesSuggestions(prefix: String) async -> [String] {
        guard !prefix.isEmpty else { return [] }
        let all = ["flamingo", "turkey", "turtle", "mute swan", "bear", "horse"]
        return all.filter { $0.localizedCaseInsensitiveContains(prefix) }.prefix(5).map { $0 }
    }
}