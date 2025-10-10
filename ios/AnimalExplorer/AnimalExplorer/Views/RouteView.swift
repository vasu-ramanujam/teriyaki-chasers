import SwiftUI
import MapKit

struct RouteView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @State private var startLocation: CLLocationCoordinate2D?
    @State private var endLocation: CLLocationCoordinate2D?
    @State private var currentRoute: Route?
    @State private var nearbySightings: [SightingNearRoute] = []
    @State private var showingAR = false
    
    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.sightings) { sighting in
                    MapAnnotation(coordinate: sighting.coordinate) {
                        SightingAnnotation(sighting: sighting)
                    }
                }
                .onTapGesture { location in
                    // Handle map tap to set start/end points
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Button("Set Start") {
                            // Set start location
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Set End") {
                            // Set end location
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let route = currentRoute {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Information")
                                .font(.headline)
                            
                            Text("Distance: \(Int(route.distanceM))m")
                            Text("Duration: \(Int(route.durationS / 60))min")
                            
                            if !nearbySightings.isEmpty {
                                Text("Nearby Sightings: \(nearbySightings.count)")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Button("Add Sightings") {
                                // Show nearby sightings to add to route
                            }
                            .buttonStyle(.bordered)
                            
                            Button("AR Mode") {
                                showingAR = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Route")
            .sheet(isPresented: $showingAR) {
                ARRouteView(route: currentRoute)
            }
        }
    }
}

struct ARRouteView: View {
    let route: Route?
    
    var body: some View {
        VStack {
            Text("AR Route View")
                .font(.title)
                .padding()
            
            Text("AR implementation would go here")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("AR Route")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RouteView()
        .environmentObject(MapViewModel())
}

