//
//  AnimalSearchView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 12/2/25.
//
import SwiftUI

struct AnimalSearchView: View {
    @State private var path = NavigationPath()
    @State private var text: String = ""
    @State private var suggestions: [String] = []
    @State private var errorMessage: String?
    
    func updateSuggestions() {
        guard !text.isEmpty else {
            suggestions = []
            return
        }
        
        Task {
            do {
                suggestions = try await APIService.shared.getSearchSuggestions(query: text)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                SearchBarView(
                    text: $text, placeholder: "Search for an animal...",
                    onSubmit: {
                        path.append(text)
                        suggestions = []
                    },
                    onChange: {_ in updateSuggestions() },
                    onClear: { text = ""; suggestions = []; path = NavigationPath() },
                    suggestions: suggestions,
                    onPickSuggestion: { pick in
                        text = ""
                        suggestions = []
                        path.append(pick)
                    }
                )
                .padding(.horizontal)
                
                Text("Search for an animal here!")
                    .font(.title)
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.title)
                    .scaledToFill()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationDestination(for: String.self) { species in
            SearchResultView(species: species, path: $path)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

struct SearchResultView: View {
    var species: String
    @State private var isLoading = false
    @State private var isValid: Bool = false
    @Binding var path: NavigationPath
    @State private var errorMessage: String?

    @State private var speciesObj: Species?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                HStack {
                    Button {
                        path = NavigationPath()
                    } label: {
                        Text("Back")
                    }
                    .buttonStyle(GreenButtonStyle())
                    
                    Spacer()
                }
                .padding(.leading)
                
                if isValid{
                    if let speciesObj {
                        SpeciesView(species: speciesObj, imgUrl: URL(string: speciesObj.main_image!))
                    } else {
                        Text("Error getting species to display")
                    }
                } else {
                    Text("\"\(species)\" is not a valid animal!")
                        .font(.title)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            isLoading = true
            
            Task {
                defer { isLoading = false }
                do {
                    let validateName = try await APIService.shared.validateName(species)
                    
                    isValid = validateName.is_valid
                    
                    if isValid {
                        let details = try await APIService.shared.searchName(species)
                        speciesObj = Species(from: details)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
