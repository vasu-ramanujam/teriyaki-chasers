//
//  SpeciesView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct SpeciesView: View {
    var species: Species
    var imgUrl: URL?
    
    var body: some View {
        LazyVStack {
            if let imgUrl {
                AsyncImage(url: imgUrl) { phase in
                    switch phase {
                    case .empty:
                        // Placeholder while the image is loading
                        ProgressView()
                    case .success(let image):
                        // Display the loaded image
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        // Display an error or placeholder if loading fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    @unknown default:
                        // Handle future cases
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.gray)
                    .padding()
                    .frame(height: 200)
            }
//            .scaledToFit()
//            .padding(.bottom)

            Text("**Scientific Name**: \(species.scientific_name)")
                .padding(.bottom)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("**Common Name**: \(species.common_name)")
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
