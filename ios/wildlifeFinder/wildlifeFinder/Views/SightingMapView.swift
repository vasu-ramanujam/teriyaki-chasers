//
//  SightingMapView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import SwiftUI
import MapKit

struct SightingMapView: View {
    @Environment(SightingMapViewModel.self) var vm

    var body: some View {
        @Bindable var vm = vm
        Map(coordinateRegion: $vm.region, annotationItems: vm.sightings) { sighting in
            MapAnnotation(coordinate: sighting.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .onTapGesture {
                        print("Tapped \(sighting.name)")
                    }
            }
        }
        .ignoresSafeArea()
    }
}

