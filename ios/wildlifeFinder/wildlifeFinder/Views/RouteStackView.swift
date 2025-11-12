import SwiftUI
import MapKit

struct RouteStackView: View {
    @Environment(RouteViewModel.self) private var routeVM
    @Environment(SightingMapViewModel.self) private var vm
    @State var waypoints: [Waypoint]
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Map {
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
                        .tint(.blue)
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                List(waypoints) { wp in
                    VStack(alignment: .leading) {
                        Text(wp.title).bold()
                        Text("\(wp.coordinate.latitude), \(wp.coordinate.longitude)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                
                Button("Clear Route") {
                    routeVM.appRoute = nil
                    vm.selectedWaypoints = []
                }
                .disabled(routeVM.appRoute == nil)
            }
            // TODO: add "Current Route" text back to navTitle, remove second ToolbarItem
            .navigationTitle("Current Route")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Start Directions") {
                        DirectionsView(waypoints: $waypoints)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ARViewScreen(waypoints: waypoints)
                            .edgesIgnoringSafeArea(.all)
                    } label: {
                        Image(systemName: "arkit")
                            .font(.title2)
                            .padding(6)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}
