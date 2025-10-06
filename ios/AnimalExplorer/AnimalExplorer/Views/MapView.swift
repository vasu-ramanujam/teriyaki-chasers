import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @State private var showingSpeciesFilter = false
    @State private var searchText = ""
    @State private var searchResults: [Species] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.sightings) { sighting in
                    MapAnnotation(coordinate: sighting.coordinate) {
                        SightingAnnotation(sighting: sighting)
                    }
                }
                .onChange(of: viewModel.region) { _ in
                    Task {
                        await viewModel.loadSightings()
                    }
                }
                
                VStack {
                    // Search bar
                    HStack {
                        TextField("Search species...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                searchSpecies()
                            }
                        
                        Button("Filter") {
                            showingSpeciesFilter = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        ProgressView("Loading sightings...")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Animal Explorer")
            .sheet(isPresented: $showingSpeciesFilter) {
                SpeciesFilterView(selectedSpecies: $viewModel.selectedSpecies)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private func searchSpecies() {
        guard !searchText.isEmpty else { return }
        
        Task {
            do {
                let results = try await APIClient.shared.searchSpecies(query: searchText)
                searchResults = results
            } catch {
                viewModel.errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
}

struct SightingAnnotation: View {
    let sighting: Sighting
    
    var body: some View {
        Button(action: {
            // Handle tap
        }) {
            Image(systemName: "pawprint.fill")
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white))
                .frame(width: 30, height: 30)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(MapViewModel())
}

