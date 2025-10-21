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
    // built-in dismiss, returns to the previous screen
    @Environment(\.dismiss) var dismiss
    
    //TODO: replace with entries from smvm
    let pins = [
        Pin(name: "Black Bear"),
        Pin(name: "Flamingo"),
        Pin(name: "Turkey")
        
    ]
    
    let hotspotObj: Waypoint
    
    @EnvironmentObject private var vm: SightingMapViewModel
    
    let entries: [String: sighting_entry] = [
         "Black Bear": sighting_entry(
             species: "Black Bear",
             image_url: "black_bear",
             sound_url: "sound2.mp3",
             description: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
             caption: "Whoa.. I didn't expect to see a black bear here!"
         ),
         "Flamingo": sighting_entry(
             species: "Flamingo",
             image_url: "Caribbean_Flamingo",
             sound_url: "sound1.mp3",
             description: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
             caption: "Whoa.. I didn't expect to see a flamingo here!"
         ),
         "Turkey": sighting_entry(
             species: "Turkey",
             image_url: "turkey",
             sound_url: "sound3.mp3",
             description: "Ex sapien vitae pellentesque sem placerat in id.",
             caption: "Whoa.. I didn't expect to see a turkey here!"
         )
     ]
    
    // private let hvaID: UUID = UUID() // could remove
    @State private var sheetEntry: sighting_entry? = nil // the entry object associated with the selected pin
    @State private var showSightingSheet = false
        
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
                        // change this implementation
                        if let entry = entries[pin.name] {
                            sheetEntry = entry // assign the correct entry
                            showSightingSheet = true
                        }
                        showSightingSheet = true // trigger the sheet
                    } label: {
                        HStack {
                            Image(systemName: "mappin")
                            Text(pin.name)
                        }
                    }
                }
            }
            Button(vm.selectedWaypoints.contains(hotspotObj) ? "Remove High-Volume Area from Route" : "Add High-Volume Area to Route"){
                //TODO: add to route list and return to sighting map
                //TODO: depending on fromHVA flag
                vm.toggleWaypoint(hotspotObj)
                dismiss()
            }
            .padding([.top])
            .buttonStyle(.borderedProminent)
            .font(.headline)

            Spacer()
            
            HStack{
                Button("< Back"){
                    dismiss()
                }
                .padding([.leading])
                Spacer()
            }
            
        }
        .padding()
        .sheet(item: $sheetEntry) {entry in
                SightingPinInformationView(
                    fromHVA: .constant(true),
                    entry: Binding(
                        get: { entry },
                        set: { newValue in sheetEntry = newValue }
                    ),
                    sightingObj: hotspotObj
                )
                .presentationBackground(.regularMaterial)
        }
    }
}


//#Preview {
//    struct Preview: View{
//        var body: some View{
//            HVAPinInformationView(hotspotObj: Hotspot(name: "Wetlands", coordinate: .init(latitude: 37.332, longitude: -122.004), densityScore: 0.82))
//        }
//    }
//    return Preview()
//}
