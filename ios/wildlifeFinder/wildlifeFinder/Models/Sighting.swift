//
//  Sighting.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

import Foundation
import CoreLocation

struct Sighting: Identifiable {
    let id: Int
    let name: String
    let species: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
