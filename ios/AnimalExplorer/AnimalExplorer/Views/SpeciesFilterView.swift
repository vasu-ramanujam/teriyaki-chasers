import SwiftUI

struct SpeciesFilterView: View {
    @Binding var selectedSpecies: Species?
    @State private var searchText = ""
    @State private var searchResults: [Species] = []
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search species...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchSpecies()
                        }
                    
                    Button("Search") {
                        searchSpecies()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                if isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { species in
                        SpeciesRow(species: species) {
                            selectedSpecies = species
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Filter by Species")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedSpecies = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func searchSpecies() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let results = try await APIClient.shared.searchSpecies(query: searchText)
                searchResults = results
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

struct SpeciesRow: View {
    let species: Species
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(species.commonName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(species.scientificName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SpeciesFilterView(selectedSpecies: .constant(nil))
}

