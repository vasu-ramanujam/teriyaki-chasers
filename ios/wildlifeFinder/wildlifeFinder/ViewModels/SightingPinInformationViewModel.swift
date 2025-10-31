import Foundation
import SwiftUI

@MainActor
public final class SightingPinInformationViewModel: ObservableObject , GetsSpeciesDetails{

    // MARK: - Published state
    @Published private(set) var currentSighting: Sighting
    @Published private(set) var origin: where_from
    @Published var speciesDetails: Species?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Media (camelCase)
    @Published private(set) var imageURL: URL?
    @Published private(set) var soundURL: URL?

    // MARK: - Init
    public init(s: Sighting, o: where_from) {
        self.currentSighting = s
        self.origin = o
        self.speciesDetails = s.species
        self.imageURL = URL(string: s.media_url ?? "")
        self.soundURL = nil
    }
    func call_loadSpeciesDetails() async {
        await loadSpeciesDetails(currentSpecies: currentSighting.species)
    }

    // MARK: - Media refresh
    func reloadMediaFromSighting() {
        imageURL = URL(string: currentSighting.media_url ?? "")
        soundURL = nil
    }

    /// Backwards-compat shim for the view that calls `loadMedia()`
    func loadMedia() {
        reloadMediaFromSighting()
    }
}

extension Species {
    init(
        id: Int,
        common_name: String,
        scientific_name: String,
        habitat: String?,
        diet: String?,
        behavior: String?,
        description: String?,
        other_sources: [String]?,
        created_at: Date
    ) {
        self.id = id
        self.common_name = common_name
        self.scientific_name = scientific_name
        self.habitat = habitat
        self.diet = diet
        self.behavior = behavior
        self.description = description
        self.other_sources = other_sources
        self.created_at = created_at
    }
}
