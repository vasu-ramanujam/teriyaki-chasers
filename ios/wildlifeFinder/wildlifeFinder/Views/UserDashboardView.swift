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
                    .foregroundStyle(.white)

                VStack(alignment: .leading){
                    Text("\(vm.username)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(vm.total_sightings) sightings over \(vm.total_species) species")
                        .foregroundStyle(.white)

                }
                .padding()
                Spacer()
            }
            .background(ui_green)//Color.gray.opacity(0.2))
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
            .background(ui_green)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.bottom)
            
            
            
            //Sighting History
            Text("Sighting History")
                .font(.headline)
            List{
                //add sighting pins here
                ForEach(vm.sightings, id: \.id) {i in
                    
                    NavigationLink{
                        SightingPinInformationView(sighting: i, origin: .other, waypointObj: .sighting(i))
                    } label: {
                        HStack{
                            Text(i.species.name)
                            Spacer()
                            Text(i.createdAt.formatted(
                                Date.FormatStyle()
                                    .year(.twoDigits)
                                    .month(.twoDigits)
                                    .day(.defaultDigits)
                            ))
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ui_green)
            .clipShape(RoundedRectangle(cornerRadius: 15))

            
            
        }
        .padding()
        .sheet(item: $selected_flashcard) { item in
            FlashcardView(info: item)
        }
        .onAppear {
            Task {
                vm.init_flashcards()
                await vm.loadSightings()
            }
        }
    }
    
    
    private struct FlashcardPreview: View {
        
        @Binding var flashcard: userSpeciesStatistics?
        
        var flashcard_info: userSpeciesStatistics
        
        //display different info based on flashcard_info
        //let image_url = "Caribbean_Flamingo"
        
        var body: some View {
            Button{
                flashcard = flashcard_info
            } label: {
                ZStack {
                    Color(red: 255/255, green: 210/255, blue: 132/255)
                        .cornerRadius(10)
                    VStack{
                        Image(flashcard_info.image_url)
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

