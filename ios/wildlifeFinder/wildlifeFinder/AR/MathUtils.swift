//
//  MathUtils.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 11/26/25.
//
import Foundation
import CoreLocation
import simd


extension simd_float4 {
    var xyz: simd_float3 { simd_make_float3(self.x, self.y, self.z) }
}


extension CLLocationCoordinate2D {
    /// Calculates distance in meters to another coordinate
    func distance(to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return from.distance(from: to)
    }
    
    
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let fromLat = latitude.degreesToRadians
        let fromLon = longitude.degreesToRadians
        let toLat = destination.latitude.degreesToRadians
        let toLon = destination.longitude.degreesToRadians
        
        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)
        return atan2(y, x).radiansToDegrees // degrees from true north
    }
}


extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
