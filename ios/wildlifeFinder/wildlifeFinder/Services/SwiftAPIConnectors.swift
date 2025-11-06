//
//  SwiftAPIConnectors.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/30/25.
//

import SwiftUI
import Foundation

@MainActor
protocol SightingsLoadable : AnyObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var sightings: [Sighting] {get set}
    var species: [Species] {get set}
    
    func loadSightings(filter: APISightingFilter) async
    func call_loadSightings() async
}

extension SightingsLoadable {
    func loadSightings(filter: APISightingFilter) async{
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1) fetch API sightings
            let apiSightings = try await APIService.shared.getSightings(filter: filter)
            //
            // 2) Prepare a species cache (seed with any already-loaded species)
            var speciesById: [Int: Species] = Dictionary(uniqueKeysWithValues: self.species.map { ($0.id, $0) })

            // 3) For each sighting, ensure we have its Species (using details endpoint)
            for apiSighting in apiSightings {
                let sid = apiSighting.species_id
//                guard let taken_at = apiSighting.created_at else { return }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.timeZone = TimeZone.current
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let testDate = formatter.date(from: apiSighting.created_at)
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
                        main_image: nil
                        created_at: testDate ?? Date()
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
            self.species = Array(speciesById.values)
            self.sightings = convertedSightings
            

        } catch {
            errorMessage = "Failed to load sightings: \(error.localizedDescription)"
            print("Error loading sightings:", error)
        }
    }
}

// ------------- gets species details ------------------


@MainActor
protocol GetsSpeciesDetails : AnyObject{
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var speciesDetails: Species? {get set}
    var description: LocalizedStringKey {get}
    func call_loadSpeciesDetails(current_flash: APIFlashcardDetails?) async

}

extension GetsSpeciesDetails {
    // MARK: - Load detailed species information
    func loadSpeciesDetails(currentSpecies: Species) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id = currentSpecies.id
        
        var some_details: Species?

        do {
            // Try the richer, canonical species endpoint first
            
            if let apiSpecies = try? await APIService.shared.getSpecies(id: id) {
                some_details = Species(from: apiSpecies)
                //self.speciesDetails = Species(from: apiSpecies)
                //return
            }
             

            // Fallback: supplement existing species with details payload
            let details = try await APIService.shared.getSpeciesDetails(id: id)

            let base = currentSpecies
            self.speciesDetails = Species(
                id: id,
                common_name: details.english_name ?? some_details?.common_name ?? base.common_name,
                scientific_name: some_details?.scientific_name ?? details.species,
                habitat: some_details?.habitat ?? base.habitat,
                diet: some_details?.diet ?? base.diet,
                behavior: some_details?.behavior ?? base.behavior,
                description: details.description ?? some_details?.description ?? base.description,
                other_sources: some_details?.other_sources ?? details.other_sources,
                created_at: some_details?.created_at ?? base.created_at,
                main_image: some_details?.main_image ?? details.main_image ?? base.main_image
            )
        } catch {
            self.errorMessage = "Failed to load species details: \(error.localizedDescription)"
            // keep whatever we had so UI still renders something
        }
    }

    // MARK: - Derived text
    var description: LocalizedStringKey {
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

        let toReturn = parts.isEmpty ? "No additional information available." : parts.joined(separator: "\n\n")
        return LocalizedStringKey(toReturn)
    }

}
