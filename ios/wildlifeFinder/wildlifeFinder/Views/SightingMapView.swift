//
//  SightingMapView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//
import SwiftUI
struct SightingMapView: View {
    
    @State var bound_flamingo = bound_entry(entry: sighting_entry(), is_presented: false)
    var body: some View {
        Text("SightingMapView - Sheet Ver")
        
        Button("Flamingo Pin"){
            bound_flamingo.is_presented = true
        }.sheet(isPresented: $bound_flamingo.is_presented) {
            SightingPinInformationView(entry: $bound_flamingo.entry, is_presented: $bound_flamingo.is_presented)
        }
        
        
    }
}
