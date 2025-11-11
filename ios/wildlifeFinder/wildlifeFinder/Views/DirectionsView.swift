//
//  DirectionsView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 11/11/25.
//
import SwiftUI
import MapKit

struct DirectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RouteViewModel.self) private var routeVM
    @Environment(SightingMapViewModel.self) private var vm
    @State private var currentLeg: RouteLeg?
    @State private var routeFinished: Bool = false
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State var waypoints: [Waypoint]
    @State private var showSteps = false

    var body: some View {
        VStack {
            Map(position: $position) {
                ForEach(waypoints) { wp in
                    Marker(wp.title, coordinate: wp.coordinate)
                }
                
                if let appRoute = routeVM.appRoute {
                    let legs = appRoute.legs
                    ForEach(legs) { leg in
                        if let line = leg.polyline {
                            MapPolyline(line)
                                .stroke(.blue, lineWidth: 3)
                        }
                    }
                }

                Marker("You", systemImage: "location.circle.fill", coordinate: LocationManagerViewModel.shared.coordinate)
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            
            HStack {
                Button("Show Steps", systemImage: "location.north") {
                    showSteps = true
                }
                .padding(.horizontal)
                .sheet(isPresented: $showSteps){
                    StepView(currentLeg: routeVM.appRoute?.legs.first )
                }
                
                Button("End Navigation", systemImage: "xmark.circle") {
                    dismiss()
                }
                .padding(.horizontal)
            }
        }
    }
    
    struct StepView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(RouteViewModel.self) private var routeVM
        let currentLeg: RouteLeg?
        
        var body: some View {
            if let _ = routeVM.appRoute {
                NavigationStack {
                    List {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text("From my location")
                            Spacer()
                        }

                        if let currentLeg, let steps = currentLeg.steps {
                            ForEach(1..<steps.count, id: \.self) { idx in
                                VStack(alignment: .leading) {
                                    Text("Walk \(distance(meters: steps[idx].distance))")
                                        .bold()
                                    Text(" - \(steps[idx].instructions)")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Steps")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func nextWaypoint() {
        guard let leg = currentLeg else { return }
        guard let idx = routeVM.appRoute?.legs.firstIndex(of: leg) else { return }
        
        routeVM.appRoute?.legs.remove(at: idx)
        
        if routeVM.appRoute?.legs.isEmpty ?? true {
            routeFinished = true
        } else {
            currentLeg = routeVM.appRoute?.legs.first
        }
    }
   
    // return a locale friendly distance
    private static func distance(meters: Double) -> String {
        let userLocale = Locale.current
        let formatter = MeasurementFormatter()
        var options: MeasurementFormatter.UnitOptions = []
        options.insert(.providedUnit)
        options.insert(.naturalScale)
        formatter.unitOptions = options
        let meterVal = Measurement(value: meters, unit: UnitLength.meters)
        let yardVal = Measurement(value: meters, unit: UnitLength.yards)
        return formatter.string(from: userLocale.measurementSystem == .metric ? meterVal : yardVal)
    }
}
