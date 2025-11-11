import Foundation
import CoreLocation
import MapKit

public struct RouteLeg: Identifiable, Hashable {
    public let id: UUID = .init()
    public let from: CLLocationCoordinate2D
    public let to: CLLocationCoordinate2D
    public var distance: CLLocationDistance?
    public var expectedTravelTime: TimeInterval?
    public var polyline: MKPolyline?
    public var steps: [MKRoute.Step]?

    public init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.from = from
        self.to = to
    }
}

public struct AppRoute: Identifiable, Hashable {
    public let id: UUID = .init()
    public var legs: [RouteLeg]

    public var totalDistance: CLLocationDistance {
        legs.compactMap { $0.distance }.reduce(0, +)
    }
    public var totalExpectedTime: TimeInterval {
        legs.compactMap { $0.expectedTravelTime }.reduce(0, +)
    }
}

// MARK: - Explicit conformance (from/to and polyline aren't Hashable)
extension RouteLeg: Equatable {
    public static func == (lhs: RouteLeg, rhs: RouteLeg) -> Bool {
        lhs.id == rhs.id
    }
}
extension RouteLeg {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Optional: make AppRoute conformance robust to internal changes
extension AppRoute: Equatable {
    public static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        lhs.id == rhs.id
    }
}
extension AppRoute {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
