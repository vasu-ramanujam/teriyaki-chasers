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

    var canGenerateRoute: Bool { !selectedWaypoints.isEmpty }

    func loadMock() {
        // quick mock; swap with API later
        let flamingo = Species(name: "flamingo", emoji: "🦩")
        let turkey   = Species(name: "turkey", emoji: "🦃")
        let swan     = Species(name: "mute swan", emoji: "🦢")

        self.sightings = [
            .init(species: flamingo, coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "near marsh"),
            .init(species: turkey,   coordinate: .init(latitude: 37.333, longitude: -122.010), createdAt: .now, note: "trail edge"),
            .init(species: turkey,   coordinate: .init(latitude: 37.335, longitude: -122.006), createdAt: .now, note: nil),
            .init(species: swan,     coordinate: .init(latitude: 37.336, longitude: -122.005), createdAt: .now, note: "lake")
        ]
        self.hotspots = [
            .init(name: "Wetlands", coordinate: .init(latitude: 37.332, longitude: -122.004), densityScore: 0.82),
            .init(name: "North Meadow", coordinate: .init(latitude: 37.337, longitude: -122.012), densityScore: 0.65)
        ]
    }

    var filteredSightings: [Sighting] {
        guard let species = selectedSpecies, !species.isEmpty else { return sightings }
        return sightings.filter { $0.species.name.localizedCaseInsensitiveContains(species) }
    }

    func updateSuggestions() {
        let all = ["flamingo", "turkey", "turtle", "mute swan", "bear", "horse"]
        suggestions = searchText.isEmpty ? [] : all.filter { $0.localizedCaseInsensitiveContains(searchText) }.prefix(5).map { $0 }
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
}