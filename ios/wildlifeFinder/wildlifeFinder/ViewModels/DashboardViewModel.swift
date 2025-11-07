//
//  DashboardViewModel.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//

import Foundation
import SwiftUI
import Observation
import MapKit

@MainActor
@Observable
final class DashboardViewModel: SightingsLoadable, GetsSpeciesDetails {
    
    // published information
    
    //user information
    var username: String = "Hawk"
    var total_sightings: Int = 55
    var total_species: Int = 6
    
    var sighting_history: [Sighting] = []

    
    // flashcard information
    
    // mock data
    
    func init_flashcards() {
        
    }
    
    // get sightings
    // code from sightingmapviewmodel
    
    var isLoading = false
    var errorMessage: String?
    
    // required for sighting history
    var sightings: [Sighting] = []
    var species: [Species] = []
    
    //for flashcard / user aggregate stats
    var userStats: APIUserDetails = APIUserDetails(username: "", total_sightings: 0, total_species: 0, flashcards: [])
        
    var dash_filter = APISightingFilter(
        area: nil,
        species_id: nil,
        start_time: nil,
        end_time: nil,
        username: "Hawk",
    )
    
    func call_loadSightings() async {
        await loadSightings(filter: dash_filter)
        print("load sightings done successfully")
    }
    
    var FlashcardImages: [String: String] = [:]

    
    //var selected_flashcard: APIFlashcardDetails?
    
    var speciesDetails: Species? // aka the species to show
    
    
    func call_loadSpeciesDetails(current_flash: APIFlashcardDetails?) async {
        guard let current_flash else {
            return
        }
        await loadSpeciesDetails(currentSpecies: Species(sp_id: current_flash.species_id))
    }
    
    
    func loadUserStats() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // 1) fetch API stats
            userStats = try await APIService.shared.getUserStats() // this is the line thats giving error

        } catch {
            errorMessage = "Failed to load user details: \(error.localizedDescription)"
            print("Error loading user details:", error)
        }
        
        userStats.flashcards.forEach { flashcard in
            Task {
                let image_link = try await APIService.shared.getWikiImage(name: flashcard.species_name)
                FlashcardImages[flashcard.species_name] = image_link.link
                let _ = print(image_link.link)
            }
        }
        
    }
    

}


