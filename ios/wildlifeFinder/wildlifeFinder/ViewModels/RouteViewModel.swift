import Foundation
import MapKit

@MainActor
final class RouteViewModel: ObservableObject {
    @Published var appRoute: AppRoute?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func buildRoute(from waypoints: [Waypoint]) async {
        errorMessage = nil
        guard waypoints.count >= 2 else {
            appRoute = nil
            return
        }
        isLoading = true
        defer { isLoading = false }

        // Make ordered legs (0->1, 1->2, ...)
        var legs: [RouteLeg] = []
        legs.append(RouteLeg(from: LocationManagerViewModel.shared.coordinate, to: waypoints[0].coordinate))
        for i in 0..<(waypoints.count - 1) {
            let a = waypoints[i].coordinate
            let b = waypoints[i + 1].coordinate
            legs.append(RouteLeg(from: a, to: b))
        }

        // Resolve each leg via MKDirections
        for idx in legs.indices {
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: .init(coordinate: legs[idx].from))
            req.destination = MKMapItem(placemark: .init(coordinate: legs[idx].to))
            req.transportType = .walking

            do {
                let response = try await MKDirections(request: req).calculate()
                if let r = response.routes.first {
                    legs[idx].distance = r.distance
                    legs[idx].expectedTravelTime = r.expectedTravelTime
                    legs[idx].polyline = r.polyline
                }
            } catch {
                errorMessage = "Failed to fetch route: \(error.localizedDescription)"
            }
        }

        self.appRoute = AppRoute(legs: legs)
    }
}
