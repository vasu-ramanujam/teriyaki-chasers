import SwiftUI
import MapKit

struct HVAPinInformationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: SightingMapViewModel
    
    let hotspotObj: Waypoint
    
    @State private var sheetEntry: Sighting? = nil
    @State private var showSightingSheet = false
    @State private var sightings: [Sighting] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "mappin")
                    .font(.title)
                Text("High Volume Area")
                    .font(.title)
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
                    Button {
                        sheetEntry = sighting
                        showSightingSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin")
                            VStack(alignment: .leading) {
                                Text(sighting.species.name)
                                    .font(.headline)
                                Text("Posted by \(sighting.username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let note = sighting.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
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
        .onAppear {
            Task {
                await loadSightingsInArea()
            }
        }
        .sheet(item: $sheetEntry) { sighting in
            SightingPinInformationView(
                sighting: sighting, 
                origin: .hva, 
                waypointObj: .sighting(sighting)
            )
            .presentationBackground(.regularMaterial)
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
            
            // Create a small bounding box around the hotspot
            let center = hotspot.coordinate
            let span = 0.01 // Small area around the hotspot
            let boundingBox = APIService.shared.createBoundingBox(
                center: center, 
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
            
            let filter = APISightingFilter(
                area: boundingBox,
                species_id: nil,
                start_time: nil,
                end_time: nil
            )
            
            let apiSightings = try await APIService.shared.getSightings(filter: filter)
            
            // Convert API sightings to app models
            var convertedSightings: [Sighting] = []
            for apiSighting in apiSightings {
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