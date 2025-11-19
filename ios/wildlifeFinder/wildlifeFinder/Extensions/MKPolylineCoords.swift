//
//  MKPolylineCoords.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 11/19/25.
//
import MapKit


// TODO: move extension to a separate file
extension MKPolyline {
    
    var coords: [CLLocationCoordinate2D] {
        guard pointCount > 1 else { return [] }
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }

    // Returns total length of the polyline in meters.
    var totalDistance: CLLocationDistance {
        let points = self.coords
        return totalDistance(using: points)
    }

    // Returns a coordinate X meters along the polyline.
    // If distance exceeds the polyline length, returns the end point.
    // See doc for how this works exactly
    func coordinate(at distance: CLLocationDistance) -> CLLocationCoordinate2D? {
        return coordinate(at: distance, using: self.coords)
    }

    // Returns evenly spaced coordinates every `interval` meters.
    func evenlySpacedCoordinates(every interval: CLLocationDistance = 0.5) -> [CLLocationCoordinate2D] {
        let points = self.coords
        let total = self.totalDistance(using: points) // no need to recompute every time
        guard interval > 0, total > 0 else { return [] }

        let count = Int(total / interval)
        return (0...count).compactMap { i in
            self.coordinate(at: Double(i) * interval)
        }
    }
    
    // Private helper that calculates distance using an existing array to avoid re-fetching.
    private func totalDistance(using coords: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard self.coords.count > 1 else { return 0 }
        var dist: CLLocationDistance = 0
        for i in 0..<(coords.count - 1) {
            let a = CLLocation(latitude: self.coords[i].latitude, longitude: self.coords[i].longitude)
            let b = CLLocation(latitude: self.coords[i+1].latitude, longitude: self.coords[i+1].longitude)
            dist += a.distance(from: b)
        }
        return dist
    }
    
    // Private helper that performs the math on an existing array.
    private func coordinate(at distance: CLLocationDistance, using coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard self.coords.count > 1 else { return self.coords.first }

        let target = max(0, distance)
        var traveled: CLLocationDistance = 0

        for i in 0..<(coords.count - 1) {
            let start = coords[i]
            let end = coords[i + 1]

            let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLoc = CLLocation(latitude: end.latitude, longitude: end.longitude)
            let segmentLength = startLoc.distance(from: endLoc)

            if traveled + segmentLength >= target {
                let remaining = target - traveled
                let t = remaining / segmentLength
                
                // Linear Interpolation
                let lat = start.latitude + (end.latitude - start.latitude) * t
                let lon = start.longitude + (end.longitude - start.longitude) * t
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            traveled += segmentLength
        }

        return coords.last
    }
}
