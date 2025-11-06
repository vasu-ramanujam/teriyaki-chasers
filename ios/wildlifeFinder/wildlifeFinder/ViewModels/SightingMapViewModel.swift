import Foundation
import MapKit
import SwiftUI

@MainActor
final class SightingMapViewModel: ObservableObject, SightingsLoadable {
    // Region (Apple Park-ish mock coords so you see pins immediately)
    @Published var mapRegion = MKCoordinateRegion(
        center: .init(latitude: 42.2808, longitude: -83.7430),
        span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)
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
    private static let isoNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // Clamp the search window if the camera span is gigantic
    private func clampedSpan(for span: MKCoordinateSpan) -> MKCoordinateSpan {
        let maxDelta: CLLocationDegrees = 2.0    // ~ a large city/metro area
        let minDelta: CLLocationDegrees = 0.02   // ~ 1–2 km
        let lat = min(max(span.latitudeDelta,  minDelta), maxDelta)
        let lon = min(max(span.longitudeDelta, minDelta), maxDelta)
        return MKCoordinateSpan(latitudeDelta: lat, longitudeDelta: lon)
    }

    func recenterOnUser() {
        let c = LocationManagerViewModel.shared.coordinate
        mapRegion = MKCoordinateRegion(center: c, span: clampedSpan(for: mapRegion.span))
    }
    func centerOnFirstValidLocationAndLoad() async {
        let deadline = Date().addingTimeInterval(3.0) // wait up to ~3s for GPS
        while Date() < deadline {
            let c = LocationManagerViewModel.shared.coordinate
            if abs(c.latitude) > .ulpOfOne || abs(c.longitude) > .ulpOfOne {
                recenterOnUser()
                await call_loadSightings()
                return
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        // Fallback: keep default Ann Arbor center, but still load pins for the 24h window
        await call_loadSightings()
    }


    
    func call_loadSightings() async {
        let now = Date()
        let start = now.addingTimeInterval(-24 * 60 * 60)
        let startISO = Self.isoNoFrac.string(from: start)
        let endISO = Self.isoNoFrac.string(from: now)

        let clamped = clampedSpan(for: mapRegion.span)
        let area = APIService.shared.createBoundingBox(center: mapRegion.center, span: clamped)

        let filter = APISightingFilter(
            area: area,
            species_id: nil,
            start_time: startISO,
            end_time: endISO,
            username: nil
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
        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        let timeFiltered = sightings.filter { $0.createdAt >= cutoff && $0.createdAt <= now }
        guard let species = selectedSpecies, !species.isEmpty else { return timeFiltered }
        return timeFiltered.filter { $0.species.name.localizedCaseInsensitiveContains(species) }
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
