import Foundation
import MapKit
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.009),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @Published var sightings: [Sighting] = []
    @Published var hotspots: [Hotspot] = []

    // UI state
    @Published var showSightings = true
    @Published var showHotspots = false

    @Published var searchText: String = ""
    @Published var selectedSpecies: String? = nil
    @Published var suggestions: [String] = []
    @Published var selectedPin: Waypoint? = nil

    // Route
    @Published var selectedWaypoints: Set<Waypoint> = []

    private let api: APIService

    init(api: APIService = MockAPIService()) {
        self.api = api
    }

    func load() async {
        do {
            async let s = api.fetchSightings()
            async let h = api.fetchHotspots()
            (sightings, hotspots) = try await (s, h)
        } catch {
            print("Failed to load: \(error)")
        }
    }

    var filteredSightings: [Sighting] {
        guard let species = selectedSpecies, !species.isEmpty else { return sightings }
        return sightings.filter { $0.species.name.localizedCaseInsensitiveContains(species) }
    }

    func updateSuggestions() {
        Task {
            suggestions = await api.speciesSuggestions(prefix: searchText)
        }
    }

    func clearFilter() {
        selectedSpecies = nil
        searchText = ""
        suggestions = []
    }

    func toggleWaypoint(_ wp: Waypoint) {
        if selectedWaypoints.contains(wp) {
            selectedWaypoints.remove(wp)
        } else {
            selectedWaypoints.insert(wp)
        }
    }

    var canGenerateRoute: Bool { !selectedWaypoints.isEmpty }
}