//
//  SpeciesView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct SpeciesView: View {
    var species: Species
    
    var body: some View {
        LazyVStack {
            Image(systemName: "photo")
                .scaledToFit()
                .padding(.bottom)

            Text("**Scientific Name**: \(species.scientific_name)")
                .padding(.bottom)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let hab = species.habitat {
                Text("**Habitat**: \(hab)")
                    .padding(.bottom)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let diet = species.diet {
                Text("**Diet**: \(diet)")
                    .padding(.bottom)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                
            if let behavior = species.behavior {
                Text("**Behavior**: \(behavior)")
                    .padding(.bottom)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                
            if let description = species.description {
                Text("**Description**: \(description)")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
