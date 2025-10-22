//
//  SightingPinInformationView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/6/25.
//

// view called from Sighting Map

// also called from high volume sighting > See more info > click on one of the sightings that make it up

// View should show add to route with accessed from sighting map, add HVA to route when accessed from high volume sighting
import SwiftUI

// HARDCODED INFORMATION
// TODO: remove hardcoded info and replace with calls to SMVM

let flamingo = Species(name: "flamingo", emoji: "🦩")
let test_sighting = Sighting(species: flamingo, coordinate: .init(latitude: 37.334, longitude: -122.008), createdAt: .now, note: "Whoa.. I didn't expect to see a flamingo here! I was just on my way to class when I found this...", username: "Named Teriyaki", isPrivate: false)



struct SightingPinInformationView: View {
    // TODO: insert state, binding, etc variables

    // built-in dismiss, returns to the previous screen
    @Environment(\.dismiss) var dismiss
    
    @State var showSoundAlert = false
    
    @EnvironmentObject private var vm: SightingMapViewModel
    
    //@Binding var sighting: Sighting
    //@Binding var origin: where_from
    @State var pinvm: SightingPinInformationViewModel
    
    init(sighting: Sighting, origin: where_from, waypointObj: Waypoint) {
        self.showSoundAlert = false
        self.pinvm = SightingPinInformationViewModel(s: sighting, o: origin)
        self.sightingObj = waypointObj
    }
    
    
    
    var sightingObj: Waypoint
    
    func routeButtonText() -> String {
        switch pinvm.origin {
        case .hva:
            if vm.selectedWaypoints.contains(sightingObj) {
                return "Remove High Volume Area from Route"
            } else {
                return "Add High Volume Area to Route"
            }
        case .map:
            if vm.selectedWaypoints.contains(sightingObj) {
                return "Remove from Route"
            } else {
                return "Add to Route"
            }
        case .other:
            //break
            return ""
        }
    }
    
    @ViewBuilder
    func MediaUnwrap() -> some View {
        if let img = pinvm.image_url {
            Image(img)
                .resizable()
                .scaledToFit()
                .containerRelativeFrame(.horizontal) { size, axis in
                    size * 0.93
                    }
        } else {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 100)
                .opacity(0)
        }
    }
    

    
    @ViewBuilder
    func MediaView() -> some View {
        ZStack(alignment: .bottom){
            ZStack(alignment: pinvm.image_url != nil ? .topTrailing: .top){
                MediaUnwrap()
                Button {
                    showSoundAlert = true
                    //TODO: if sound, display sound
                } label: {
                    ZStack{
                        Image(systemName: "play.square.fill")
                            .resizable()
                            .frame(width: 40 , height: 40)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(.black.opacity(0.6))
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .padding(5)
                            .foregroundColor(.black)
                            .opacity(pinvm.sound_url != nil ? 0 : 0.8)
                    }
                }
                .alert(isPresented: $showSoundAlert){
                    Alert(
                        title: pinvm.sound_url != nil ?  Text("Playing sound...") : Text("No sound available"),
                        
                        message: Text("Sound available only in MVP")
                    )
                }
            }
            if let caption = pinvm.currentSighting.note {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(.black.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            
        }
    }
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "mappin")
                    .font(.title)
                Text(pinvm.currentSighting.species.name)
                    .font(.title)
                Spacer()
            }
            MediaView()
            
            HStack{
                Text("Posted by: \(pinvm.currentSighting.isPrivate ? "Anonymous" : pinvm.currentSighting.username)")
                Spacer()
                Text("\(pinvm.currentSighting.createdAt.formatted(date: .numeric, time: .shortened))")
            }
                .padding(.top, 5)
            
            ScrollView{ // I don't think description will be this long
                Text("**Description:**")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                Text(pinvm.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
            }
            if pinvm.origin != .other {
                Button(routeButtonText()){
                    vm.toggleWaypoint(sightingObj)
                    dismiss()
                }
                .padding([.top])
                .buttonStyle(OrangeButtonStyle())
                .font(.headline)
            }
            Spacer()
            
            HStack{
                Button("< Back"){
                    dismiss()
                }
                .padding([.leading])
                .buttonStyle(GreenButtonStyle())
                Spacer()
            }
            
        }
        .padding()
    }
}
