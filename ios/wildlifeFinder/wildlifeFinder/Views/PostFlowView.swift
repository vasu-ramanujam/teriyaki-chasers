//
//  PostFlowView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct PostFlowView: View {
    var body: some View {
        NavigationStack {
            InitialView()
        }
    }
}

struct InitialView: View {
    @State var image: UIImage? = nil
    @State var audioURL: URL? = nil
    
    var body: some View {
        VStack {
            // Display image
            if let image = image {
                Text("Image goes here")
            }
            
            // Add an image
            Button {
                // Hook to taking the picture
            } label: {
                Image(systemName: "camera")
                    .foregroundStyle(.white)
                Text(image != nil ? "Retake Photo" : "Take Photo")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            // Display image
            if let sound = audioURL {
                Text("Sound goes here")
            }
            
            // Add a sound
            Button {
                // Hook to recording sound
                audioURL = URL(string: "https://en.wikipedia.org/wiki/American_red_squirrel")
            } label: {
                Image(systemName: "mic")
                    .foregroundStyle(.white)
                Text(audioURL != nil ? "Rerecord Audio" : "Record Audio")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            if image != nil || audioURL != nil {
                // Identify the sighting
                NavigationLink("Identify") {
                    IdentifyView()
                }
                .foregroundStyle(.black)
                .padding()
                .background(
                    buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                    alignment: .center
                )
                .navigationBarBackButtonHidden(true)
            }
        }
        .scaleEffect(1.5)
    }
}

struct buttonBackground: View {
    var color: Color
    var cornerRad = 10.0
    var shadowRad = 5.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRad)
            .fill(color)
            .shadow(radius: shadowRad)
    }
}

struct IdentifyView: View {
    @State private var isLoading: Bool = false
    @State private var animal: Species?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Identifying...")
            } else {
                if let animal = animal {
                    Text("You found: \(animal.common_name)!")
                        .font(.largeTitle) // Start with a large font size
                        .lineLimit(1) // Ensure the text stays on a single line
                        .minimumScaleFactor(0.1) // Allow scaling down to 10% of the original size
                        .frame(maxWidth: .infinity)
                        .padding(.leading)
                        .padding(.trailing)
                    
                    SpeciesView(species: animal)
                    
                    NavigationLink("Post Sighting"){
                        
                    }
                    .foregroundStyle(.black)
                    .padding()
                    .background(
                    buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                    alignment: .center
                    )
                } else {
                    Text("There should be an animal here lol")
                }
                
            }
        }
        .onAppear {
            isLoading = true
            
            Task {
                // call the identification API
                
                // this is mock data for now
                animal = MockSpecies.squirrel
            }
            
            isLoading = false
        }
    }
}
