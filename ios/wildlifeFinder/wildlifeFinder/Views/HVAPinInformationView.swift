//
//  HVAPinInformationView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/8/25.
//
import SwiftUI

struct Pin: Identifiable {
    var id: UUID = UUID()
    var name: String
    //TODO: get sightingpin_id to request from DB
}

struct HVAPinInformationView: View {

    // @Binding var entries: [sighting_entry]
    //TODO: replace with entries from smvm
    let pins = [
        Pin(name: "Black Bear"),
        Pin(name: "Flamingo"),
        Pin(name: "Turkey")
        
    ]
        
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "mappin")
                    .font(.title)
                Text("High Volume Area")
                    .font(.title)
                Spacer()
            }
            Text("Over the last week, people saw 6 animals of 3 different species in this area!")
            
            List {
                ForEach(pins) {pin in
                    Button {
                        // open the sighting pin info page
                    } label: {
                        HStack {
                            Image(systemName: "mappin")
                            Text(pin.name)
                        }
                    }
                }
            }
            
            Button("Add High-Volume Area to Route"){
                //TODO: add to route list and return to sighting map
                //TODO: depending on fromHVA flag
            }
            .padding([.top])
            .buttonStyle(.borderedProminent)
            .font(.headline)

            Spacer()
            
            HStack{
                Button("< Back"){
                    //TODO: return to sighting map
                }
                .padding([.leading])
                Spacer()
            }
            
        }
        .padding()
    }
}


#Preview {
    struct Preview: View{
        var body: some View{
            HVAPinInformationView()
        }
    }
    return Preview()
}
