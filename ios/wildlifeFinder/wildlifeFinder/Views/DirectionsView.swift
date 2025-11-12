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
            }
        }
        .sheet(isPresented: $nearWaypoint) {
            DestinationPopup()
        }
        .onAppear {
            fetchCurrentPoly()
        }
        .onChange(of: LocationManagerViewModel.shared.eqCoord) {
            fetchCurrentPoly()
            nearWaypoint = withinThreeMeters(LocationManagerViewModel.shared.coordinate, vm.selectedWaypoints[0].coordinate)
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
    
    struct DestinationPopup: View {
        var body: some View {
            ZStack {
                Color.black
                    .opacity(0.5)
                VStack {
                    Text("Destination reached")
                        .font(.headline)
                    Text("You have reached your destination")
                        .font(.caption)
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
    
    private func withinThreeMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        let loc1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let loc2 = CLLocation(latitude: b.latitude, longitude: b.longitude)
        
        return loc1.distance(from: loc2) <= 3
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
