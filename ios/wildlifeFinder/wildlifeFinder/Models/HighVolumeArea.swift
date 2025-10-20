import Foundation
import CoreLocation
import MapKit

public struct HighVolumeArea: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    public let densityScore: Double

    public init(
        id: UUID = .init(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        densityScore: Double
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.densityScore = densityScore
    }
}



// Convenience conversions to/from your existing Hotspot model
public extension HighVolumeArea {
    init(_ hotspot: Hotspot) {
        self.init(
            id: hotspot.id,
            name: hotspot.name,
            coordinate: hotspot.coordinate,
            densityScore: hotspot.densityScore
        )
    }
}

public extension Hotspot {
    init(_ hva: HighVolumeArea) {
        self.init(
            name: hva.name,
            coordinate: hva.coordinate,
            densityScore: hva.densityScore
        )
    }
}

extension HighVolumeArea: Equatable {
    public static func == (lhs: HighVolumeArea, rhs: HighVolumeArea) -> Bool {
        lhs.id == rhs.id
    }
}
extension HighVolumeArea {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
