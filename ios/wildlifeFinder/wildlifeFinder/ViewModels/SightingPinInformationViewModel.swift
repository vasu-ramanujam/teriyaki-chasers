import Foundation
import SwiftUI

@MainActor
public final class SightingPinInformationViewModel: ObservableObject {

    // MARK: - Published state
    @Published private(set) var currentSighting: Sighting
    @Published private(set) var origin: where_from
    @Published private(set) var speciesDetails: Species?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

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

    // MARK: - Load detailed species information
    func loadSpeciesDetails() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id = currentSighting.species.id

        do {
            // Try the richer, canonical species endpoint first
            if let apiSpecies = try? await APIService.shared.getSpecies(id: id) {
                self.speciesDetails = Species(from: apiSpecies)
                return
            }

            // Fallback: supplement existing species with details payload
            let details = try await APIService.shared.getSpeciesDetails(id: id)

            let base = currentSighting.species
            self.speciesDetails = Species(
                id: id,
                common_name: details.english_name ?? base.common_name,
                scientific_name: details.species,
                habitat: base.habitat,
                diet: base.diet,
                behavior: base.behavior,
                description: details.description ?? base.description,
                other_sources: details.other_sources,
                created_at: base.created_at
            )
        } catch {
            self.errorMessage = "Failed to load species details: \(error.localizedDescription)"
            // keep whatever we had so UI still renders something
        }
    }

    // MARK: - Derived text
    var description: String {
        guard let s = speciesDetails else { return "Loading species information..." }

        var parts: [String] = []

        func add(_ title: String, _ value: String?) {
            if let v = value, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("**\(title):** \(v)")
            }
        }

        add("Habitat", s.habitat)
        add("Diet", s.diet)
        add("Behavior", s.behavior)
        add("Description", s.description)

        if let sources = s.other_sources, !sources.isEmpty {
            parts.append("**Learn more:**\n" + sources.map { "• \($0)" }.joined(separator: "\n"))
        }

        return parts.isEmpty ? "No additional information available." : parts.joined(separator: "\n\n")
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
