//
//  ContentView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            // added temp UI icons. tbd: figure out how to make the + pop out like in the UI mockups
            TabView{
                VStack{
                    SightingMapView()
                }
                .tabItem {
                    Image(systemName: "map")
                    Text("Sighting Map")
                }
                
                VStack{
                    //wherever route mapmode/armode is
                }
                .tabItem{
                    Image(systemName: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill")
                    Text("Current Route")
                }
                VStack{
                    // sight a wildlife
                }
                .tabItem{
                    Image(systemName: "plus")
                        .font(.system(size: 25))
                }
                
                VStack{
                    // Animal Search view
                }
                .tabItem{
                    Image(systemName: "magnifyingglass")
                    Text("Animal Search")
                }
                VStack{
                    // User Dashboard view
                }
                .tabItem{
                    Image(systemName: "house.fill")
                    Text("User Dashboard")
                }
                 
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
