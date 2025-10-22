//
//  IdentifiedAnimalView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/22/25.
//

import SwiftUI

struct IdentifiedAnimalView: View {
    
    let animal = "Flamingo"
    
    @Environment(\.dismiss) var dismiss
        
    @EnvironmentObject private var vm: SightingMapViewModel
    
    let wiki_image = "Caribbean_Flamingo"
    
    var body: some View {
        VStack{
            Text("You found a \(animal)!")
                .font(.title)
            
            //insert image
            
            
            //insert description from wherever Owen has it
            
            
            Button("Post Sighting"){
                //redirect to post sighting page
            }
            
            
            Spacer()
        }
        
        
        
    }
}

