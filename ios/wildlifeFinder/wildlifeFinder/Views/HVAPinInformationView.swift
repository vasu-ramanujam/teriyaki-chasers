import SwiftUI
import MapKit

struct HVAPinInformationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(SightingMapViewModel.self) private var vm
    
    let hotspotObj: Waypoint
    
    @State private var sheetEntry: Sighting? = nil
    @State private var showSightingSheet = false
    @State private var sightings: [Sighting] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack{
                HStack{
                    Image(systemName: "mappin")
                        .font(.title)
                    Text("High Volume Area")
                        .font(.title)
                        .navigationBarBackButtonHidden(true)
                    Spacer()
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading sightings...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    Text("Found \(sightings.count) sightings in this area!")
                }
                
                List {
                    ForEach(sightings) { sighting in
                        NavigationLink {
                            SightingPinInformationView(
                                sighting: sighting,
                                origin: .hva,
                                waypointObj: .sighting(sighting)
                            )
                        } label: {
                            HStack {
                                Image(systemName: "mappin")
                                VStack(alignment: .leading) {
                                    Text(sighting.species.name)
                                        .font(.headline)
                                    Text(sighting.createdAt.formatted(
                                        Date.FormatStyle()
                                            .year(.twoDigits)
                                            .month(.twoDigits)
                                            .day(.defaultDigits)
                                    ))
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                Button(vm.selectedWaypoints.contains(hotspotObj) ? "Remove High-Volume Area from Route" : "Add High-Volume Area to Route"){
                    vm.toggleWaypoint(hotspotObj)
                    dismiss()
                }
                .padding([.top])
                .buttonStyle(OrangeButtonStyle())
                .buttonStyle(.borderedProminent)
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
        }
        .padding()
        .onAppear {
            Task {
                await loadSightingsInArea()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Backend Integration
    private func loadSightingsInArea() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the hotspot coordinate to create a bounding box
            guard case .hotspot(let hotspot) = hotspotObj else {
                errorMessage = "Invalid hotspot data"
                return
            }
            
            // Convert API sightings to app models
            var convertedSightings: [Sighting] = []
            for apiSighting in hotspot.sightings {
                // Fetch species details for each sighting
                let apiSpecies = try await APIService.shared.getSpecies(id: apiSighting.species_id)
                let species = Species(from: apiSpecies)
                let sighting = Sighting(from: apiSighting, species: species)
                convertedSightings.append(sighting)
            }
            
            self.sightings = convertedSightings
            
        } catch {
            errorMessage = "Failed to load sightings: \(error.localizedDescription)"
            print("Error loading sightings in HVA: \(error)")
        }
        
        isLoading = false
    }
}
