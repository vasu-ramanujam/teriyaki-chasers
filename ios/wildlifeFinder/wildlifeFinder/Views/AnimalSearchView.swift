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
            SearchBarView(
                text: $text, placeholder: "Search for an animal...", onSubmit: {
                    path.append(text)
                },
                onChange: {_ in updateSuggestions() },
                onClear: { text = ""; suggestions = [] },
                suggestions: suggestions,
                onPickSuggestion: { pick in
                    path.append(pick)
                    suggestions = []
                }
            )
            
            Text("Search for an animal here!")
                .font(.title)
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.title)
                .scaledToFill()
        }
        .navigationDestination(for: String.self) { species in
            
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
