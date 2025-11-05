//
//  DashboardViewModel.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//

import Foundation
import SwiftUI
import MapKit

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // published information
    
    //user information
    @Published var username: String = "Hawk"
    @Published var total_sightings: Int = 55
    @Published var total_species: Int = 6
    
    @Published var sighting_history: [Sighting] = []

    
    // flashcard information
    

    
    
    // mock data
    @Published var discoveredSpecies: [userSpeciesStatistics] = []
    
    func init_flashcards() {
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "yyyy-MM-dd"
        // do API call
        discoveredSpecies = [
            userSpeciesStatistics(species_name: "Flamingo", first_visited: date_formatter.date(from: "2025-09-28")!, times_sighted: 10),
            userSpeciesStatistics(species_name: "Panda", first_visited: date_formatter.date(from: "2024-08-08")!, times_sighted: 2),
            userSpeciesStatistics(species_name: "Beluga Whale", first_visited: date_formatter.date(from: "2025-01-24")!, times_sighted: 7),
            userSpeciesStatistics(species_name: "Penguin", first_visited: date_formatter.date(from: "2024-12-27")!, times_sighted: 15),
            userSpeciesStatistics(species_name: "Octopus", first_visited: date_formatter.date(from: "2025-05-25")!, times_sighted: 17),
            userSpeciesStatistics(species_name: "Giraffe", first_visited: date_formatter.date(from: "2024-12-02")!, times_sighted: 4)
        ]
        
    }
    
    // get sightings
    // code from sightingmapviewmodel
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var sightings: [Sighting] = []
    
    
    
    
    // TODO: how to user APISightingFilter to filter sightings based on user?
    
    // MARK: - API Integration
func loadSightings() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
        // 1) Build filter and fetch API sightings
        //let filter = APISightingFilter(
          //  area: nil,
        //    species_id: nil,
        //    start_time: nil,
        //    end_time: nil,
        //   username: nil //username
        //)
        
        let mapRegion = MKCoordinateRegion(
            center: .init(latitude: 37.334, longitude: -122.009),
            span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        
        let filter = APISightingFilter(
            area: APIService.shared.createBoundingBox(center: mapRegion.center, span: mapRegion.span),
            species_id: nil,
            start_time: nil,
            end_time: nil,
            username: nil
        )
        
        let apiSightings = try await APIService.shared.getSightings(filter: filter)
        //
        let _ = print("spi sightings tried. awaited. size \(apiSightings.count)")

        // 2) Prepare a species cache (seed with any already-loaded species)
        var speciesById: [Int: Species] = [:]//Dictionary(uniqueKeysWithValues: self.species.map { ($0.id, $0) })

        // 3) For each sighting, ensure we have its Species (using details endpoint)
        for apiSighting in apiSightings {
            let sid = apiSighting.species_id
            if speciesById[sid] == nil {
                let details = try await APIService.shared.getSpeciesDetails(id: sid)
                let mapped = Species(
                    id: sid,
                    common_name: details.english_name ?? "Unknown",
                    scientific_name: details.species,
                    habitat: nil,
                    diet: nil,
                    behavior: nil,
                    description: details.description,
                    other_sources: details.other_sources,
                    created_at: Date()
                )
                speciesById[sid] = mapped
            }
        }

        // 4) Convert API sightings to app models using the resolved Species
        let convertedSightings: [Sighting] = apiSightings.compactMap { api in
            guard let sp = speciesById[api.species_id] else { return nil }
            return Sighting(from: api, species: sp)
        }

        // 5) Commit state updates
        //self.species = Array(speciesById.values)
        self.sightings = convertedSightings

    } catch {
        errorMessage = "Failed to load sightings: \(error.localizedDescription)"
        print("Error loading sightings:", error)
    }
     
}
    
    
    
    
    
    
    
    
    


    
}



//edit based on API endpoint and put modified model into models

struct userSpeciesStatistics: Identifiable {
    let species_name: String
    let first_visited: Date
    let times_sighted: Int
    
    var id: String {
            species_name
        }
}
