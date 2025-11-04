
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
final class FlashcardViewModel: ObservableObject, GetsSpeciesDetails{
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published var speciesDetails: Species?
    //TODO: unwrap w error messages in Flashcard View
    
    var currentSpecies: Species
    
    func call_loadSpeciesDetails() async {
        await loadSpeciesDetails(currentSpecies: currentSpecies)
    }
    
    init(species: Species){
        isLoading = false
        currentSpecies = species
    }
    
    
    //TODO: connect from API get user information
    
    @Published var first_sighted: Date = Date()
    @Published var times_sighted: Int = 7
    @Published var image_url: String = "Caribbean_Flamingo"
    
    //mock data??
    //TODO: flashcard can use var description
    

}
