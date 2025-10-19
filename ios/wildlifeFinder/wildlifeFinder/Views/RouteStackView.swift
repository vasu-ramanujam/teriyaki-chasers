import SwiftUI
import MapKit

struct RouteStackView: View {
    let waypoints: [Waypoint]
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Map {
                    ForEach(waypoints) { wp in
                        Marker(wp.title, coordinate: wp.coordinate)
                    }
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