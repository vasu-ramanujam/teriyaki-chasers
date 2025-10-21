import SwiftUI
import MapKit

struct RouteStackView: View {
    @EnvironmentObject private var routeVM: RouteViewModel
    @EnvironmentObject private var vm: SightingMapViewModel
    let waypoints: [Waypoint]
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
            .navigationTitle("Current Route")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") { /* hook to Directions later */ }
                }
            }
        }
    }
}
