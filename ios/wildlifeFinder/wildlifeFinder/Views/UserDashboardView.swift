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

    @State var selected_flashcard: APIFlashcardDetails?
    
    
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
                    Text(vm.username)
                        .font(.headline)
                        .foregroundStyle(.white)
                    let _ = print("wtf\n")
                    let _ = print(vm.userStats as Any)
                    Text("\(vm.userStats.total_sightings) sightings over \(vm.userStats.total_species) species")
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
                        ForEach(vm.userStats.flashcards, id: \.species_id) {item in
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
        .sheet(item: $selected_flashcard, onDismiss: {
            selected_flashcard = nil
            vm.speciesDetails = nil
        }) { item in
            FlashcardView(info: item)
        }
        .onAppear {
            Task {
                //vm.init_flashcards()
                await vm.call_loadSightings()
                await vm.loadUserStats()
                print("\ngot all information\n")
            }
        }
    }
    
    
    private struct FlashcardPreview: View {
        @EnvironmentObject private var vm: DashboardViewModel
        
        @Binding var flashcard: APIFlashcardDetails?
        
        var flashcard_info: APIFlashcardDetails
        
        //display different info based on flashcard_info
        //let image_url = "Caribbean_Flamingo"
        
        @ViewBuilder
        func MediaUnwrap(name: String) -> some View {
            if let url = vm.FlashcardImages[name] {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: 70, maxHeight: 80)
                        .padding(5)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                //.containerRelativeFrame(.horizontal) { size, axis in
                //    size * 0.93
                //}
            } else {
                Rectangle()
                    .frame(width: 70, height: 80)
                    .background(Color.gray.opacity(0.3))
            }
        }
        
        
        var body: some View {
            Button{
                Task {
                    await vm.call_loadSpeciesDetails(current_flash: flashcard_info)
                    flashcard = flashcard_info
                }
                
            } label: {
                ZStack {
                    Color(red: 255/255, green: 210/255, blue: 132/255)
                        .cornerRadius(10)
                    VStack{
                        MediaUnwrap(name: flashcard_info.species_name)
                        
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

