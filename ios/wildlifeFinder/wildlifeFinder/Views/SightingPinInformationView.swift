import SwiftUI

struct SightingPinInformationView: View {
    @Environment(\.dismiss) var dismiss
    @State var showSoundAlert = false
    @Environment(SightingMapViewModel.self) private var vm
    
    @State private var pinvm: SightingPinInformationViewModel
    @State private var isShowingError = false
    @State private var localErrorMessage = ""
    var sightingObj: Waypoint
    
    init(sighting: Sighting, origin: where_from, waypointObj: Waypoint) {
        self.sightingObj = waypointObj
        self._pinvm = State(initialValue: SightingPinInformationViewModel(s: sighting, o: origin))
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
    if let url = pinvm.imageURL, url.scheme == "https" {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                // Placeholder while the image is loading
                ProgressView()
            case .success(let image):
                // Display the loaded image
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                // Display an error or placeholder if loading fails
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            @unknown default:
                // Handle future cases
                EmptyView()
            }
        }
        .containerRelativeFrame(.horizontal) { size, axis in
            size * 0.93
        }
    } else {
        if let url = pinvm.imageURL {
            if let imageData = try? Data(contentsOf: url) {
                let image = UIImage(data: imageData)!
                Image(uiImage: image)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .opacity(0)
            }
        }
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
                .navigationBarBackButtonHidden(true)
            
            HStack{
                Text("Posted by: \(pinvm.currentSighting.isPrivate ? "Anonymous" : pinvm.currentSighting.username ?? "Anonymous")")
                Spacer()
                Text("\(pinvm.currentSighting.createdAt.formatted(date: .numeric, time: .shortened))")
            }
            .padding(.top, 5)
            
            ScrollView{
                if pinvm.isLoading { // error here likely
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
                await pinvm.call_loadSpeciesDetails()
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
