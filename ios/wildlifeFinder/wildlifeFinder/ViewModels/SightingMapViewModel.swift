//
//  SightingMapViewModel.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI
import MapKit
import Observation


@Observable
final class SightingMapViewModel {
    var sightings: [Sighting] = []
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.2808, longitude: -83.7430),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    var errorMessage = ""
    var showError = false
}

@main
struct WildlifeFinderApp: App {
    @State private var sightingVM = SightingMapViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sightingVM)
        }
    }
}

