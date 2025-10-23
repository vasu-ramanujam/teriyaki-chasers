import SwiftUI

struct SightingPinInformationView: View {
    @Environment(\.dismiss) var dismiss
    @State var showSoundAlert = false
    @EnvironmentObject private var vm: SightingMapViewModel
    
    @StateObject var pinvm: SightingPinInformationViewModel
    @State private var isShowingError = false
    @State private var localErrorMessage = ""
    var sightingObj: Waypoint
    
    init(sighting: Sighting, origin: where_from, waypointObj: Waypoint) {
        self.sightingObj = waypointObj
        self._pinvm = StateObject(wrappedValue: SightingPinInformationViewModel(s: sighting, o: origin))
    }
    
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
            return ""
        }
    }
    
    @ViewBuilder
func MediaUnwrap() -> some View {
    if let url = pinvm.imageURL {
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
            .opacity(0)
    }
}

@ViewBuilder
func MediaView() -> some View {
    ZStack(alignment: .bottom) {
        ZStack(alignment: pinvm.imageURL != nil ? .topTrailing : .top) {
            MediaUnwrap()
            Button {
                showSoundAlert = true
            } label: {
                ZStack {
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
                        .opacity(pinvm.soundURL != nil ? 0 : 0.8)
                }
            }
            .alert(isPresented: $showSoundAlert) {
                Alert(
                    title: pinvm.soundURL != nil ? Text("Playing sound...") : Text("No sound available"),
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
            
            ScrollView{
                if pinvm.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading species information...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    Text(pinvm.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .padding(.top, 5)
                }
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
        .onAppear {
            Task {
                await pinvm.loadSpeciesDetails()
                pinvm.loadMedia()
            }
        }
        .alert("Error", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { isShowingError = false }
        } message: {
            Text(localErrorMessage)
        }
    }
}
