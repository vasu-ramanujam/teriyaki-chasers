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

enum privacy {
    case _public, _private
}

struct sighting_entry {
    var species = "Flamingo"
    var image_url: String? = "Caribbean_Flamingo"
    var sound_url: String? = "sound.mp3"
    var description = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Ex sapien vitae pellentesque sem placerat in id. Pretium tellus duis convallis tempus leo eu aenean. Urna tempor pulvinar vivamus fringilla lacus nec metus. Iaculis massa nisl malesuada lacinia integer nunc posuere. Semper vel class aptent taciti sociosqu ad litora. Conubia nostra inceptos himenaeos orci varius natoque penatibus. Dis parturient montes nascetur ridiculus mus donec rhoncus. Nulla molestie mattis scelerisque maximus eget fermentum odio. Purus est efficitur laoreet mauris pharetra vestibulum fusce. \n\nTo learn more, visit wikipedia.com/flamingo"
    var username = "Named Teriyaki"
    var date_posted = Date()
    var priv_setting: privacy = ._public
    var caption =  "Whoa.. I didn't expect to see a flamingo here! I was just on my way to class when I found this... "
}

//TODO: confirm w backend: description alr ends with learn more link


struct SightingPinInformationView: View {
    // TODO: insert state, binding, etc variables
    
    //information from SMVM
    @Binding var fromHVA: Bool
    @Binding var entry: sighting_entry
    // -
    
    @State var showSoundAlert = false
    
    func routeButtonText() -> String {
        if fromHVA {
            return "Add High Volume Area to Route"
        } else {
            return "Add to Route"
        }
    }
    
    @ViewBuilder
    func MediaUnwrap() -> some View {
        if let img = entry.image_url {
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
            ZStack(alignment: entry.image_url != nil ? .topTrailing: .top){
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
                            .opacity(entry.sound_url != nil ? 0 : 0.8)
                    }
                }
                .alert(isPresented: $showSoundAlert){
                    Alert(
                        title: entry.sound_url != nil ?  Text("Playing sound...") : Text("No sound available"),
                        
                        message: Text("Sound available only in MVP")
                    )
                }
            }
            Text(entry.caption)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(5)
                .background(.black.opacity(0.6))
                .frame(maxWidth: .infinity)
        }
    }
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "mappin") // TODO: change to loc pin?
                    .font(.title)
                Text(entry.species)
                    .font(.title)
                Spacer()
            }
            MediaView()
            
            HStack{
                Text("Posted by: \(entry.username)")
                Spacer()
                Text("\(entry.date_posted.formatted(date: .numeric, time: .shortened))")
            }
                .padding(.top, 5)
            
            ScrollView{ // I don't think description will be this long
                Text("**Description:** \(entry.description)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                    .lineLimit(nil)
            }
            Button(routeButtonText()){
                //TODO: add to route list and return to sighting map
                //TODO: depending on fromHVA flag
            }
            .padding([.top])
            .buttonStyle(.borderedProminent)
            .font(.headline)

            Spacer()
            
            HStack{
                Button("< Back"){
                    //TODO: return to prv call (sighting map OR HVA info)
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
        @State var fromHVA = false
        @State var entry = sighting_entry()
        var body: some View{
            SightingPinInformationView(fromHVA: $fromHVA, entry: $entry)
        }
    }
    return Preview()
}
