//
//  wildlifeFinderApp.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI

@main
struct wildlifeFinderApp: App {
    @State private var bonjourKick = BonjourKick()
    @State private var sightingMapViewModel = SightingMapViewModel()
    @State private var routeViewModel = RouteViewModel()
    @State private var dashboardViewModel = DashboardViewModel()
    // start collecting GPS info
    init() {
        bonjourKick.start()
        LocManager.shared.startUpdates()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sightingMapViewModel)
                .environment(routeViewModel)
                .environment(dashboardViewModel)
        }
    }
}
