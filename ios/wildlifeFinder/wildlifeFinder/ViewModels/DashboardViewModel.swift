//
//  DashboardViewModel.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//

import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // published information
    
    //user information
    @Published var username: String = "Teriyaki"
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
    
    func loadSightings() async {
        
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
