//
//  ContentView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: 0) {
                // SightingMapView()
            }
            
            Tab(value: 1) {
                // route view or wtv
            }
            
            Tab(value: 2) {
                // go to choose add pic / sound
            }
            
            Tab(value: 3) {
                // animal search
            }
            
            Tab(value: 4) {
                // user dashboard
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .overlay(alignment: .bottom){
            BottomTabBarView(selectedTab: $selectedTab)
        }.ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
