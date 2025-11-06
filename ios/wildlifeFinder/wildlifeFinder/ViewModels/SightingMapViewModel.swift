import Foundation
import MapKit
import SwiftUI

@MainActor
final class SightingMapViewModel: ObservableObject, SightingsLoadable {
    // Region (Apple Park-ish mock coords so you see pins immediately)
    @Published var mapRegion = MKCoordinateRegion(
        center: .init(latitude: 42.2808, longitude: -83.7430),
        span: .init(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    // Data
    @Published var sightings: [Sighting] = []
    @Published var hotspots: [Hotspot] = []
    @Published var species: [Species] = []

    // Toggles (chips in your UI)
    @Published var showSightings = true
    @Published var showHotspots = false

    // Search + suggestions
    @Published var searchText: String = ""
    @Published var selectedSpecies: String? = nil
    @Published var suggestions: [String] = []

    // Selection
    @Published var selectedPin: Waypoint? = nil
    @Published var selectedWaypoints: Set<Waypoint> = []
    
    // Loading and error states
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canGenerateRoute: Bool { !selectedWaypoints.isEmpty }
    
    func call_loadSightings() async {
        let filter = APISightingFilter(
            area: APIService.shared.createBoundingBox(center: mapRegion.center, span: mapRegion.span),
            species_id: nil,
            start_time: nil,
            end_time: nil,
            username: nil,
        )
        await loadSightings(filter: filter)
    }

    func searchSpecies(query: String) async {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        do {
            let apiSpecies = try await APIService.shared.searchSpecies(query: query, limit: 5)
            suggestions = apiSpecies.map { $0.common_name }
        } catch {
            print("Error searching species: \(error)")
            suggestions = []
        }
    }

    var filteredSightings: [Sighting] {
        guard let species = selectedSpecies, !species.isEmpty else { return sightings }
        return sightings.filter { $0.species.name.localizedCaseInsensitiveContains(species) }
    }

    func updateSuggestions() {
        Task {
            await searchSpecies(query: searchText)
        }
    }

    func clearFilter() {
        selectedSpecies = nil
        searchText = ""
        suggestions = []
    }

    func toggleWaypoint(_ wp: Waypoint) {
        if selectedWaypoints.contains(wp) { selectedWaypoints.remove(wp) }
        else { selectedWaypoints.insert(wp) }
    }
    
    // // MARK: - Legacy mock method (remove after testing)
    // func loadMock() {
    //     // Keep this for fallback during development
    //     let flamingo = Species(id: 1, common_name: "flamingo", scientific_name: "Phoenicopterus ruber", habitat: nil, diet: nil, behavior: nil, description: nil, other_sources: nil, created_at: Date())
    //     let turkey = Species(id: 2, common_name: "turkey", scientific_name: "Meleagris gallopavo", habitat: nil, diet: nil, behavior: nil, description: nil, other_sources: nil, created_at: Date())
    //     let swan = Species(id: 3, common_name: "mute swan", scientific_name: "Cygnus olor", habitat: nil, diet: nil, behavior: nil, description: nil, other_sources: nil, created_at: Date())

    //     self.sightings = [
    //         Sighting(id: "1", species: flamingo, coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "near marsh", username: "Named Teriyaki", isPrivate: false, media_url: nil),
    //         Sighting(id: "2", species: turkey, coordinate: .init(latitude: 37.333, longitude: -122.010), createdAt: .now, note: "trail edge", username: "Named Turkey", isPrivate: false, media_url: nil),
    //         Sighting(id: "3", species: turkey, coordinate: .init(latitude: 37.335, longitude: -122.006), createdAt: .now, note: nil, username: "Teriyaki", isPrivate: false, media_url: nil),
    //         Sighting(id: "4", species: swan, coordinate: .init(latitude: 37.336, longitude: -122.005), createdAt: .now, note: "lake", username: "Tester", isPrivate: true, media_url: nil)
    //     ]
    //     self.hotspots = [
    //         Hotspot(name: "Wetlands", coordinate: .init(latitude: 37.332, longitude: -122.004), densityScore: 0.82),
    //         Hotspot(name: "North Meadow", coordinate: .init(latitude: 37.337, longitude: -122.012), densityScore: 0.65)
    //     ]
    // }
}
