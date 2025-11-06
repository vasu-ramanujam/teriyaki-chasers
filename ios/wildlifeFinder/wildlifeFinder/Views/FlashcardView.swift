//
//  FlashcardView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//
import SwiftUI


struct FlashcardView: View {
    
    //@EnvironmentObject private var vm: DashboardViewModel
    var info: APIFlashcardDetails
    
    let image_url = "Caribbean_Flamingo"
    
    func computed_date() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        print(info.first_seen)
        guard let date = dateFormatter.date(from:info.first_seen) else {
            return "Date unwrappable"
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
    
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
                    Text("First discovered: \(computed_date())")
                    Text("You've seen this species \(info.num_sightings) time\(info.num_sightings == 1 ? "" : "s").")
                }
                Spacer()
            }
            
            
            
            Spacer()
            
        }
        .padding()
        .background(Color(red: 255/255, green: 210/255, blue: 132/255))
        
    }
}
