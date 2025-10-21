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
    
    //information from SMVM
    @ObservedObject var vm: SightingMapViewModel

    
    //SMVM - from media get?? -- check in with backend bc it's not implemented yet; change to @Binding
    @State var image_url: String? = "Caribbean_Flamingo"
    @State var sound_url: String? = nil
    // -
    
    // built-in dismiss, returns to the previous screen
    @Environment(\.dismiss) var dismiss
    
    @State var showSoundAlert = false
    
    @EnvironmentObject private var vm: SightingMapViewModel
    
    let sightingObj: Waypoint
    
    func routeButtonText() -> String {
        switch vm.pinOrigin {
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
        case .ar:
            //break
            return ""
        }
    }
    
    @ViewBuilder
    func MediaUnwrap() -> some View {
        if let img = image_url {
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
    
    // delete / move to SMVM
    @ViewBuilder
    func compile_description(description: String, other_sources: [String]?) -> some View {
        
        if  other_sources != nil {
            Text(description + "\n\nLearn more at: ")
        } else {
            Text(description)
        }
        if let other_sources{
            ForEach(other_sources, id: \.self){
                Link($0, destination: URL(string: $0)!)
            }
        }
        
    }
    
    @ViewBuilder
    func MediaView() -> some View {
        ZStack(alignment: .bottom){
            ZStack(alignment: image_url != nil ? .topTrailing: .top){
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
                            .opacity(sound_url != nil ? 0 : 0.8)
                    }
                }
                .alert(isPresented: $showSoundAlert){
                    Alert(
                        title: sound_url != nil ?  Text("Playing sound...") : Text("No sound available"),
                        
                        message: Text("Sound available only in MVP")
                    )
                }
            }
            if let _entry = vm.selectedSighting , let caption = _entry.note {
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
                Text(vm.selectedSighting!.species.name)
                    .font(.title)
                Spacer()
            }
            MediaView()
            
            HStack{
                Text("Posted by: \(vm.selectedSighting!.isPrivate ? "Anonymous" : vm.selectedSighting!.username)")
                Spacer()
                Text("\(vm.selectedSighting!.createdAt.formatted(date: .numeric, time: .shortened))")
            }
                .padding(.top, 5)
            
            ScrollView{ // I don't think description will be this long
                Text("**Description:**")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                Text(vm.sightingCompiledDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
            }
            Button(routeButtonText()){
                //TODO: add to route list and return to sighting map
                //TODO: depending on fromHVA flag
                vm.toggleWaypoint(sightingObj)
                dismiss()
            }
            .padding([.top])
            .buttonStyle(OrangeButtonStyle())
            .font(.headline)

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
