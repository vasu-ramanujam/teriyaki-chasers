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
                .border(ui_green, width: 5)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(maxWidth: 300, maxHeight: 200)
                .padding(10)
            
            HStack{
                Text("Description -- replace with flashcard view model . description ")
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
        .background(Color(red: 255/255, green: 210/255, blue: 132/255))
        
    }
}
