//
//  GeoData.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/7/25.
//
import MapKit

struct GeoData: Hashable {
    var lat: Double = 0.0
    var lon: Double = 0.0
    var facing: String = "unkown"
    var speed: String = "unkown"
    
    // get a user friendly string for our location
    var place: String {
        get async {
            if let geolocs = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) {
                return geolocs[0].locality ?? geolocs[0].administrativeArea ?? geolocs[0].country ?? "place unknown"
            }
            return "place unkown"
        }
    }
}
