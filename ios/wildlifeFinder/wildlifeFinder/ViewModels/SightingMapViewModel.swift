import Foundation
import MapKit
import SwiftUI

@MainActor
final class SightingMapViewModel: ObservableObject {
    // Region (Apple Park-ish mock coords so you see pins immediately)
    @Published var mapRegion = MKCoordinateRegion(
        center: .init(latitude: 37.334, longitude: -122.009),
        span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
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

    // MARK: - API Integration
    func loadSightings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let filter = APISightingFilter(
                area: APIService.shared.createBoundingBox(center: mapRegion.center, span: mapRegion.span),
                species_id: nil,
                start_time: nil,
                end_time: nil
            )
            
            let apiSightings = try await APIService.shared.getSightings(filter: filter)
            
            // Convert API sightings to app models
            var convertedSightings: [Sighting] = []
            for apiSighting in apiSightings {
                // Find or create species
                let species: Species
                if let existingSpecies = species.first(where: { $0.id == apiSighting.species_id }) {
                    species = existingSpecies
                } else {
                    // Fetch species details
                    let apiSpecies = try await APIService.shared.getSpecies(id: apiSighting.species_id)
                    let newSpecies = Species(from: apiSpecies)
                    species.append(newSpecies)
                    species = newSpecies
                }
                
                let sighting = Sighting(from: apiSighting, species: species)
                convertedSightings.append(sighting)
            }
            
            self.sightings = convertedSightings
            
        } catch {
            errorMessage = "Failed to load sightings: \(error.localizedDescription)"
            print("Error loading sightings: \(error)")
        }
        
        isLoading = false
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