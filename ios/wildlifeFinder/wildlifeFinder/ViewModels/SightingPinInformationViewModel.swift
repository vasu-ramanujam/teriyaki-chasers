import Foundation
import SwiftUI

@MainActor
public class SightingPinInformationViewModel: ObservableObject {
    
    @Published var currentSighting: Sighting
    @Published var origin: where_from
    @Published var speciesDetails: Species?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(s: Sighting, o: where_from) {
        self.currentSighting = s
        self.origin = o
        self.speciesDetails = s.species
    }
    
    // Load detailed species information from backend
    func loadSpeciesDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiSpecies = try await APIService.shared.getSpecies(id: currentSighting.species.id)
            self.speciesDetails = Species(from: apiSpecies)
        } catch {
            errorMessage = "Failed to load species details: \(error.localizedDescription)"
            print("Error loading species details: \(error)")
        }
        
        isLoading = false
    }
    
    // Computed property for description
    var description: String {
        guard let species = speciesDetails else {
            return "Loading species information..."
        }
        
        var desc = ""
        
        if let habitat = species.habitat, !habitat.isEmpty {
            desc += "**Habitat:** \(habitat)\n\n"
        }
        
        if let diet = species.diet, !diet.isEmpty {
            desc += "**Diet:** \(diet)\n\n"
        }
        
        if let behavior = species.behavior, !behavior.isEmpty {
            desc += "**Behavior:** \(behavior)\n\n"
        }
        
        if let description = species.description, !description.isEmpty {
            desc += "**Description:** \(description)\n\n"
        }
        
        if let sources = species.other_sources, !sources.isEmpty {
            desc += "**Learn more:**\n"
            for source in sources {
                desc += "• \(source)\n"
            }
        }
        
        return desc.isEmpty ? "No additional information available." : desc
    }
    
    // Media handling
    @Published var image_url: String? = nil
    @Published var sound_url: String? = nil
    
    func loadMedia() {
        // Set image URL from sighting's media_url
        image_url = currentSighting.media_url
        // Sound URL would be loaded from backend if available
        sound_url = nil
    }
}