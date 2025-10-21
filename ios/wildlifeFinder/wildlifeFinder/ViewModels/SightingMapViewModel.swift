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
    
    // for SPIV
    @Published var selectedSighting: Sighting? = nil
    @Published var selectedHotspot: Hotspot? = nil
    @Published var pinOrigin: where_from = .map
    
    // Information view - compiled description
    @Published var sightingCompiledDescription: String = "" //when pin is selected, compile description given species

    var canGenerateRoute: Bool { !selectedWaypoints.isEmpty }
    
    //assume the call to API requires some species parameter
    //TODO: add parameter based on backend API schema
    func compileDescription() {
        // quick mock with hard data; swap with API call later
        
        // info from API:
        let summary = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Ex sapien vitae pellentesque sem placerat in id. Pretium tellus duis convallis tempus leo eu aenean. Urna tempor pulvinar vivamus fringilla lacus nec metus. Iaculis massa nisl malesuada lacinia integer nunc posuere. Semper vel class aptent taciti sociosqu ad litora. Conubia nostra inceptos himenaeos orci varius natoque penatibus. Dis parturient montes nascetur ridiculus mus donec rhoncus. Nulla molestie mattis scelerisque maximus eget fermentum odio. Purus est efficitur laoreet mauris pharetra vestibulum fusce."
        let other_sources: [String]? = ["wikipedia.com/flamingo", "wikipedia.org/wiki/Chilean_flamingo", "google.com"]
        
        //compile
        var description = summary
        if  let sources = other_sources {
            description +=  "\n\nLearn more at: "
            sources.forEach { src in
                description += "\n- \(src)"
            }
        }
        sightingCompiledDescription = description
    }

    func loadMock() {
        // quick mock; swap with API later
        let flamingo = Species(name: "flamingo", emoji: "🦩")
        let turkey   = Species(name: "turkey", emoji: "🦃")
        let swan     = Species(name: "mute swan", emoji: "🦢")

        self.sightings = [
            .init(species: flamingo, coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "near marsh", username: "Named Teriyaki", isPrivate: false),
            .init(species: turkey,   coordinate: .init(latitude: 37.333, longitude: -122.010), createdAt: .now, note: "trail edge", username: "Named Turkey", isPrivate: false),
            .init(species: turkey,   coordinate: .init(latitude: 37.335, longitude: -122.006), createdAt: .now, note: nil, username: "Teriyaki", isPrivate: false),
            .init(species: swan,     coordinate: .init(latitude: 37.336, longitude: -122.005), createdAt: .now, note: "lake", username: "Tester", isPrivate: true)
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
