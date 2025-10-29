//
//  UserDashboardView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//

import SwiftUI


struct UserDashboardView : View {
    // state/env variables
    @EnvironmentObject private var vm: DashboardViewModel
    
    //mock data

    @State var selected_flashcard: userSpeciesStatistics?
    
    
    var body: some View {
        VStack (alignment: .leading){
            // User info stack
            
            HStack{
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .padding([.leading, .top, .bottom])
                VStack(alignment: .leading){
                    Text("\(vm.username)")
                        .font(.headline)
                    Text("\(vm.total_sightings) sightings over \(vm.total_species) species")
                    
                }
                .padding()
                Spacer()
            }
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.bottom)
            
            
            
            Text("Species Discovered")
                .font(.headline)
            // Species Discovered Flashcards
            VStack(alignment: .leading){
                
                ScrollView(.horizontal){
                    HStack{
                        ForEach(vm.discoveredSpecies, id: \.id) {item in

                            FlashcardPreview(flashcard: $selected_flashcard, flashcard_info: item)
                        }
                    }
                }
                .frame(height: 150)
                .padding()
            }
            .background(Color.gray.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.bottom)
            //Sighting History
            Text("Sighting History")
                .font(.headline)
            List{
                //add sighting pins here
                ForEach(vm.sighting_history)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))

            
            
        }
        .padding()
        .sheet(item: $selected_flashcard) { item in
            FlashcardView(info: item)
        }
        .onAppear {
            Task {
                vm.init_flashcards()
            }
        }
    }
    
    
    private struct FlashcardPreview: View {
        
        @Binding var flashcard: userSpeciesStatistics?
        
        var flashcard_info: userSpeciesStatistics
        
        let image_url = "Caribbean_Flamingo"
        
        var body: some View {
            Button{
                flashcard = flashcard_info
            } label: {
                ZStack {
                    Color.gray
                        .cornerRadius(10)
                    VStack{
                        Image(image_url)
                            .resizable()
                            .scaledToFit()
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxWidth: 70, maxHeight: 80)
                            .padding(5)
                        
                        VStack(spacing: 0){
                            Image("wave")
                                .resizable()
                                .frame(width: 70, height: 20)
                            Image("wave")
                                .resizable()
                                .frame(width: 70, height: 20)
                            Image("wave")
                                .resizable()
                                .frame(width: 70, height: 20)
                        }
                        Spacer()
                    }
                    .padding(2)
                    .frame(width: 90)
                }
            }
        }
    }
}

