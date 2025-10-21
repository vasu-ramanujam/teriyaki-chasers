//
//  wildlifeFinderApp.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI

@main
struct wildlifeFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SightingMapViewModel())
                .environmentObject(RouteViewModel())
        }
    }
}
