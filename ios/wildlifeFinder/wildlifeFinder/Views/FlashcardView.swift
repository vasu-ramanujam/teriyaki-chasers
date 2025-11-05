//
//  FlashcardView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//
import SwiftUI


struct FlashcardView: View {
    
    //@EnvironmentObject private var vm: DashboardViewModel
    var info: userSpeciesStatistics
    
    let image_url = "Caribbean_Flamingo"
    
    var body: some View{
        VStack{
            
            Text(info.species_name)
                .font(.title)
                .padding()

            
            Image(image_url)
                .resizable()
                .scaledToFit()
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(maxWidth: 300, maxHeight: 200)
                .padding(10)
            
            HStack{
                Text("Description -- add once functions are consolidated. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ")
                Spacer()
            }
            Text("")
            HStack{
                VStack(alignment: .leading){
                    Text("First discovered: \(info.first_visited.formatted(date: .numeric, time: .omitted))")
                    Text("You've seen this species \(info.times_sighted) time\(info.times_sighted == 1 ? "" : "s").")
                }
                Spacer()
            }
            
            
            
            Spacer()
            
        }
        .padding()
        
    }
}
