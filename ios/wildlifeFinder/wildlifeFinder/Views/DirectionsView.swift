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
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var showSteps = false
    @State private var nearWaypoint: Bool = false
    @State private var userToWaypointLine: MKPolyline?

    var body: some View {
        VStack {
            Map(position: $position) {
                ForEach(vm.selectedWaypoints) { wp in
                    Marker(wp.title, coordinate: wp.coordinate)
                }
                
                if let appRoute = routeVM.appRoute {
                    let legs = appRoute.legs
                    ForEach(legs) { leg in
                        if let line = leg.polyline, appRoute.legs.firstIndex(of: leg) != 0{
                            MapPolyline(line)
                                .stroke(.blue, lineWidth: 3)
                        }
                    }
                }

                Marker("You", systemImage: "location.circle.fill", coordinate: LocationManagerViewModel.shared.coordinate)
                
                // Draw a polyline from your location to the first waypoint
                if let line = userToWaypointLine {
                    MapPolyline(line)
                        .stroke(.blue, lineWidth: 3)
                }
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
                
                if vm.selectedWaypoints.count > 1 {
                    Button("Next Waypoint!") {
                        nextWaypoint()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $nearWaypoint) {
            VStack {
                Text("Waypoint reached")
                    .font(.headline)
                Text("You have reached your destination")
                    .font(.caption)
                    .padding(.bottom)
                
                // display next or end options
                if vm.selectedWaypoints.count > 1 {
                    Button("Next Waypoint!") {
                        nextWaypoint()
                    }
                } else {
                    Button("End Navigation") {
                        vm.selectedWaypoints = []
                        routeVM.appRoute = nil
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            fetchCurrentPoly()
        }
        .onChange(of: LocationManagerViewModel.shared.eqCoord) {
            fetchCurrentPoly()
            
            if !vm.selectedWaypoints.isEmpty {
                nearWaypoint = withinRange(LocationManagerViewModel.shared.coordinate, vm.selectedWaypoints[0].coordinate)
            }
        }
    }
    
    struct StepView: View {
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
    
    func nextWaypoint() {
        guard !vm.selectedWaypoints.isEmpty else { dismiss(); return }
        
        routeVM.appRoute?.legs.removeFirst()
        vm.selectedWaypoints.removeFirst()
        
        if vm.selectedWaypoints.isEmpty {
            routeVM.appRoute = nil
            userToWaypointLine = nil
            dismiss()
        }
        
        nearWaypoint = false
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
    
    private func withinRange(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        let threshold: Double = 10
        
        let loc1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let loc2 = CLLocation(latitude: b.latitude, longitude: b.longitude)
        
        return loc1.distance(from: loc2) <= threshold
    }
    
    func fetchCurrentPoly() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: LocationManagerViewModel.shared.coordinate))
        guard let first = vm.selectedWaypoints.first else { return }
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: first.coordinate))
        request.transportType = .walking
        
        Task {
            do {
                let response = try await MKDirections(request: request).calculate()
                if let r = response.routes.first {
                    userToWaypointLine = r.polyline
                }
            }
        }

    }
}
