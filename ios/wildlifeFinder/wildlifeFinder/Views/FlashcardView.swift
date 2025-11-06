//
//  FlashcardView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/28/25.
//
import SwiftUI


struct FlashcardView: View {
    
    @EnvironmentObject private var vm: DashboardViewModel
    
    // I HAVE ACCESS TO vm.SpeciesDetails as well as info
    
    
    var info: APIFlashcardDetails
    
    //let image_url = "Caribbean_Flamingo"
    
    func computed_date() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        print(info.first_seen)
        guard let date = dateFormatter.date(from:info.first_seen) else {
            return "Date unwrappable"
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
    
    @ViewBuilder
    func MediaUnwrap() -> some View {
        if let url = URL(string: (vm.speciesDetails?.main_image!)!)/*URL(string: "Caribbean_Flamingo")*/ {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(ProgressView())
            }
            .containerRelativeFrame(.horizontal) { size, axis in
                size * 0.93
            }
        } else {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(Color.gray.opacity(0.3))
        }
    }
    
    @ViewBuilder
    func unwrap_View() -> some View {
        if vm.speciesDetails != nil {
            VStack{
                
                Text(vm.speciesDetails!.name)
                    .font(.title)
                    .padding()
                
                // TODO: insert image
                MediaUnwrap()

                Text(vm.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .padding(.top, 5)
                //SpeciesView(species: vm.speciesDetails!, imgUrl: URL(string: "Caribbean_Flamingo")!)
                
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
            
            
            
            
            
        } else {
            Text("Unable to load species data.")
        }
    }
    
    var body: some View{
        unwrap_View()
    }
      
}
