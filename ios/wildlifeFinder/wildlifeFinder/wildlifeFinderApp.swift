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
    // start collecting GPS info
    init() {
        bonjourKick.start()
        LocManager.shared.startUpdates()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SightingMapViewModel())
                .environmentObject(RouteViewModel())
        }
    }
}
