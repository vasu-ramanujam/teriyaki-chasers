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
    @ObservedObject var vm: SightingMapViewModel

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
    
    var entries: [String: Sighting] = [
    "Flamingo": Sighting(species: Species(name: "flamingo", emoji: "🦩"), coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "near marsh", username: "Named Teriyaki", isPrivate: false),
    "Turkey 1": Sighting(species: Species(name: "turkey", emoji: "🦃"),   coordinate: .init(latitude: 37.333, longitude: -122.010), createdAt: .now, note: "trail edge", username: "Named Turkey", isPrivate: false),
    "Turkey": Sighting(species: Species(name: "turkey", emoji: "🦃"),   coordinate: .init(latitude: 37.335, longitude: -122.006), createdAt: .now, note: nil, username: "Teriyaki", isPrivate: false),
    "Mute Swan": Sighting(species: Species(name: "mute swan", emoji: "🦢"),     coordinate: .init(latitude: 37.336, longitude: -122.005), createdAt: .now, note: "lake", username: "Tester", isPrivate: true)
    ]
    
    
    
    // private let hvaID: UUID = UUID() // could remove
    @State private var sheetEntry: Sighting? = nil // the entry object associated with the selected pin
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
            
            //TODO: variables
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
                )
                .presentationBackground(.regularMaterial)
        }
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
